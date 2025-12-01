import * as admin from 'firebase-admin';
import dayjs from 'dayjs';

const db = admin.firestore();

type Transaction = admin.firestore.Transaction;

type CoinReason =
  | 'purchase'
  | 'bonus'
  | 'subscription'
  | 'swipe'
  | 'swipe_extra'
  | 'special_like'
  | 'super_like'
  | 'boost'
  | 'priority'
  | 'refund';

interface RecordCoinOptions {
  uid: string;
  tx: Transaction;
  amount: number;
  type: 'credit' | 'debit';
  reason: CoinReason;
  memo?: string;
}

export async function recordCoinTransaction({
  uid,
  tx,
  amount,
  type,
  reason,
  memo,
}: RecordCoinOptions): Promise<number> {
  const userRef = db.collection('users').doc(uid);
  const userSnap = await tx.get(userRef);
  const current = (userSnap.get('coinBalance') as number) ?? 0;

  const newBalance = type === 'credit' ? current + amount : current - amount;
  if (newBalance < 0) {
    throw new Error('Insufficient balance');
  }

  tx.update(userRef, { coinBalance: newBalance });

  const txRef = db.collection('coin_transactions').doc();
  tx.set(txRef, {
    uid,
    type,
    amount,
    balanceAfter: newBalance,
    reason,
    memo: memo ?? null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return newBalance;
}

export async function appendActionLog(
  tx: Transaction,
  uid: string,
  actionType: string,
  cost: number,
  status: 'success' | 'failed',
  payload: Record<string, unknown>,
) {
  const actionRef = db.collection('actions').doc();
  tx.set(actionRef, {
    uid,
    type: actionType,
    cost,
    status,
    payload,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function flagFraud(uid: string, reason: string, meta?: Record<string, unknown>) {
  const ref = db.collection('admin_logs').doc();
  await ref.set({
    uid,
    action: 'fraud_flag',
    reason,
    meta: meta ?? {},
    createdAt: dayjs().toISOString(),
  });
}
