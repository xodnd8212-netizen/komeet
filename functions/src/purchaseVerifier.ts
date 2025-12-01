import axios from 'axios';
import { google } from 'googleapis';
import * as admin from 'firebase-admin';

import { COIN_BUNDLES, FIRST_PURCHASE_BONUS_RATE, Platform } from './config';

const appStoreEndpoint = 'https://api.storekit.itunes.apple.com/inApps/v1/subscriptions';

interface VerifyRequest {
  uid: string;
  platform: Platform;
  bundleId: string;
  purchaseToken: string;
  receiptData?: string;
}

interface VerifyResult {
  success: boolean;
  coins: number;
  price: number;
  currency: string;
  bonusCoins: number;
  purchaseId: string;
  existingPurchase?: admin.firestore.DocumentData | null;
}

export async function verifyPurchase(input: VerifyRequest): Promise<VerifyResult> {
  const bundle = COIN_BUNDLES[input.bundleId];
  if (!bundle) {
    throw new Error('INVALID_BUNDLE');
  }

  switch (input.platform) {
    case 'apple':
      await verifyAppleReceipt(input.receiptData ?? '', bundle);
      break;
    case 'google':
      await verifyGooglePurchase(input.purchaseToken, bundle);
      break;
    case 'web':
      await verifyWebPurchase(input.purchaseToken, bundle);
      break;
    default:
      throw new Error('UNSUPPORTED_PLATFORM');
  }

  const bonus = Math.round(bundle.coins * (bundle.bonusRate ?? FIRST_PURCHASE_BONUS_RATE));
  return {
    success: true,
    coins: bundle.coins,
    price: bundle.price,
    currency: bundle.currency,
    bonusCoins: bonus,
    purchaseId: input.purchaseToken,
  };
}

async function verifyAppleReceipt(receiptData: string, bundle: { bundleId: string }) {
  if (!receiptData) {
    throw new Error('MISSING_RECEIPT');
  }
  // TODO: Integrate App Store Server API. Placeholder request for documentation purposes.
  try {
    await axios.post(appStoreEndpoint, { receiptData });
  } catch (error) {
    throw new Error('APPLE_VALIDATION_FAILED');
  }
}

async function verifyGooglePurchase(purchaseToken: string, bundle: { bundleId: string }) {
  if (!purchaseToken) {
    throw new Error('MISSING_TOKEN');
  }
  // TODO: Integrate with Google Play Developer API purchases.products API.
  try {
    const auth = new google.auth.JWT({
      // credentials are expected to be stored in environment variables or Secret Manager
      email: process.env.GOOGLE_CLIENT_EMAIL,
      key: (process.env.GOOGLE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    const androidPublisher = google.androidpublisher({ version: 'v3', auth });
    await androidPublisher.purchases.products.get({
      packageName: process.env.GOOGLE_PACKAGE_NAME ?? '',
      productId: bundle.bundleId,
      token: purchaseToken,
    });
  } catch (error) {
    throw new Error('GOOGLE_VALIDATION_FAILED');
  }
}

async function verifyWebPurchase(sessionId: string, bundle: { bundleId: string }) {
  if (!sessionId) {
    throw new Error('MISSING_SESSION');
  }
  // TODO: Verify Stripe/PayPal session via webhook or REST API.
  // This placeholder assumes webhook already validated and stored sessionId.
  return;
}
