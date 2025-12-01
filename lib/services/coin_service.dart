import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/coin.dart';

class CoinService {
  CoinService._();

  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const _bundles = <CoinBundle>[
    CoinBundle(
      id: 'small',
      title: '100 코인',
      coins: 100,
      price: 1000,
      currency: 'KRW',
      bonusRate: 0.2,
    ),
    CoinBundle(
      id: 'medium',
      title: '500 코인',
      coins: 500,
      price: 4500,
      currency: 'KRW',
      bonusRate: 0.2,
    ),
    CoinBundle(
      id: 'large',
      title: '1200 코인',
      coins: 1200,
      price: 9000,
      currency: 'KRW',
      bonusRate: 0.2,
    ),
  ];

  static List<CoinBundle> getBundles() => _bundles;

  static Future<Map<String, dynamic>> verifyAndCredit({
    required String platform,
    required String bundleId,
    required String purchaseToken,
    String? receiptData,
  }) async {
    final callable = _functions.httpsCallable('verifyAndCreditPurchase');
    final response = await callable.call({
      'platform': platform,
      'bundleId': bundleId,
      'purchaseToken': purchaseToken,
      if (receiptData != null) 'receiptData': receiptData,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Future<void> spendCoins({
    required String actionType,
    Map<String, dynamic>? metadata,
  }) async {
    final callable = _functions.httpsCallable('spendCoins');
    await callable.call({
      'actionType': actionType,
      if (metadata != null) 'metadata': metadata,
    });
  }

  static Future<void> claimDailyReward({
    required String rewardType,
    int? coins,
  }) async {
    final callable = _functions.httpsCallable('claimDailyReward');
    await callable.call({
      'rewardType': rewardType,
      if (coins != null) 'coins': coins,
    });
  }

  static Future<Map<String, dynamic>> getUserCoinData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data() ?? {};
  }
}
