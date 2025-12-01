import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import dayjs from 'dayjs';
import { v4 as uuid } from 'uuid';

import {
  ACTION_COSTS,
  COIN_BUNDLES,
  FIRST_PURCHASE_BONUS_RATE,
  Platform,
  SUBSCRIPTION_DAILY_COINS,
  SUBSCRIPTION_PLAN_ID,
  SUBSCRIPTION_WEEKLY_BOOST,
} from './config';
import { appendActionLog, flagFraud, recordCoinTransaction } from './firestoreHelpers';
import { verifyPurchase } from './purchaseVerifier';

admin.initializeApp();
const db = admin.firestore();

function assertAuth(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }
  return context.auth.uid;
}

export const verifyAndCreditPurchase = functions.https.onCall(async (data, context) => {
  const uid = assertAuth(context);
  const platform = (data.platform as Platform) ?? 'web';
  const bundleId = data.bundleId as string;
  const purchaseToken = data.purchaseToken as string;
  const receiptData = data.receiptData as string | undefined;

  if (!bundleId || !purchaseToken) {
    throw new functions.https.HttpsError('invalid-argument', 'bundleId and purchaseToken are required');
  }
  if (!COIN_BUNDLES[bundleId]) {
    throw new functions.https.HttpsError('invalid-argument', 'unknown bundleId');
  }

  const verifyResult = await verifyPurchase({
    uid,
    platform,
    bundleId,
    purchaseToken,
    receiptData,
  });

  const purchaseRef = db.collection('coin_purchases').doc(verifyResult.purchaseId);
  const existingVerified = await db
    .collection('coin_purchases')
    .where('uid', '==', uid)
    .where('status', '==', 'verified')
    .limit(1)
    .get();

  const isFirstPurchase = existingVerified.empty;
  const bonusCoins = isFirstPurchase ? verifyResult.bonusCoins : 0;
  const totalCoins = verifyResult.coins + bonusCoins;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(purchaseRef);
    if (snap.exists && snap.get('status') === 'verified') {
      throw new functions.https.HttpsError('already-exists', 'Purchase already processed');
    }

    const createdAt = snap.exists ? snap.get('createdAt') ?? admin.firestore.Timestamp.now() : admin.firestore.FieldValue.serverTimestamp();

    tx.set(
      purchaseRef,
      {
        uid,
        platform,
        bundleId,
        price: verifyResult.price,
        currency: verifyResult.currency,
        status: 'verified',
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        bonusCoins,
        totalCoins,
        createdAt,
      },
      { merge: true },
    );

    await recordCoinTransaction({
      uid,
      tx,
      amount: totalCoins,
      type: 'credit',
      reason: 'purchase',
      memo: `${platform}:${bundleId}`,
    });
  });

  await createPurchaseRecord({
    uid,
    platform,
    bundleId,
    price: verifyResult.price,
    currency: verifyResult.currency,
    status: 'verified',
    receipt: purchaseToken,
    bonusCoins,
    totalCoins,
  });

  return { success: true, coins: totalCoins, bonusCoins, isFirstPurchase };
});

export const spendCoins = functions.https.onCall(async (data, context) => {
  const uid = assertAuth(context);
  const actionType = data.actionType as string;
  const metadata = (data.metadata as Record<string, unknown>) ?? {};

  const cost = ACTION_COSTS[actionType];
  if (!cost) {
    throw new functions.https.HttpsError('invalid-argument', 'Unsupported action type');
  }

  const reasonMap: Record<string, string> = {
    swipe_extra: 'swipe_extra',
    special_like: 'special_like',
    super_like: 'super_like',
    boost: 'boost',
    priority: 'priority',
  };

  await db.runTransaction(async (tx) => {
    const newBalance = await recordCoinTransaction({
      uid,
      tx,
      amount: cost,
      type: 'debit',
      reason: reasonMap[actionType] as
        | 'swipe_extra'
        | 'special_like'
        | 'super_like'
        | 'boost'
        | 'priority',
    });

    await appendActionLog(tx, uid, actionType, cost, 'success', {
      metadata,
      balanceAfter: newBalance,
    });
  });

  return { success: true };
});

export const claimDailyReward = functions.https.onCall(async (data, context) => {
  const uid = assertAuth(context);
  const rewardType = (data.rewardType as string) ?? 'daily_login';
  const rewardCoins = data.coins as number | undefined;

  const coinsToGrant = rewardCoins ?? 10;

  await db.runTransaction(async (tx) => {
    const userRef = db.collection('users').doc(uid);
    const snap = await tx.get(userRef);
    const rewards = (snap.get('rewardLog') as Record<string, unknown>) ?? {};
    const key = `${rewardType}:${dayjs().format('YYYY-MM-DD')}`;
    if (rewards[key]) {
      throw new functions.https.HttpsError('failed-precondition', 'Reward already claimed today');
    }

    const newBalance = await recordCoinTransaction({
      uid,
      tx,
      amount: coinsToGrant,
      type: 'credit',
      reason: 'bonus',
      memo: rewardType,
    });

    tx.update(userRef, {
      [`rewardLog.${key}`]: admin.firestore.FieldValue.serverTimestamp(),
      coinBalance: newBalance,
    });
  });

  return { success: true, coins: coinsToGrant };
});

export const grantSubscriptionDailyCoins = functions.pubsub
  .schedule('0 0 * * *')
  .onRun(async () => {
    const snapshot = await db
      .collection('users')
      .where('subscription.active', '==', true)
      .get();

    await Promise.all(
      snapshot.docs.map(async (doc) => {
        const uid = doc.id;
        await db.runTransaction(async (tx) => {
          const newBalance = await recordCoinTransaction({
            uid,
            tx,
            amount: SUBSCRIPTION_DAILY_COINS,
            type: 'credit',
            reason: 'subscription',
            memo: SUBSCRIPTION_PLAN_ID,
          });

          const lastBoost = doc.get('subscription.lastBoostAt');
          const shouldGrantBoost = !lastBoost || dayjs(lastBoost.toDate()).isBefore(dayjs().subtract(7, 'day'));

          tx.update(doc.ref, {
            coinBalance: newBalance,
            'subscription.lastDailyCreditAt': admin.firestore.FieldValue.serverTimestamp(),
            ...(shouldGrantBoost && {
              'subscription.boostQuota': admin.firestore.FieldValue.increment(SUBSCRIPTION_WEEKLY_BOOST),
              'subscription.lastBoostAt': admin.firestore.FieldValue.serverTimestamp(),
            }),
          });
        });
      }),
    );
  });

export const adminAdjustBalance = functions.https.onCall(async (data, context) => {
  if (!context.auth || !(context.auth.token?.admin === true)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin privileges required');
  }

  const targetUid = data.uid as string;
  const amount = data.amount as number;
  const reason = (data.reason as string) ?? 'adjustment';
  if (!targetUid || !amount) {
    throw new functions.https.HttpsError('invalid-argument', 'uid and amount required');
  }

  await db.runTransaction(async (tx) => {
    const type = amount >= 0 ? 'credit' : 'debit';
    await recordCoinTransaction({
      uid: targetUid,
      tx,
      amount: Math.abs(amount),
      type: type === 'credit' ? 'credit' : 'debit',
      reason: type === 'credit' ? 'bonus' : 'refund',
      memo: reason,
    });
  });

  await db.collection('admin_logs').doc().set({
    adminUid: context.auth.uid,
    uid: targetUid,
    delta: amount,
    reason,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

export const monitorTransactions = functions.firestore
  .document('coin_transactions/{txId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    if (!data) return;

    if (data.type === 'credit' && data.amount > 5000) {
      await flagFraud(data.uid, 'High value credit detected', { txId: snap.id });
    }
  });
