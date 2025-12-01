class CoinBundle {
  final String id;
  final String title;
  final int coins;
  final int price;
  final String currency;
  final double bonusRate;

  const CoinBundle({
    required this.id,
    required this.title,
    required this.coins,
    required this.price,
    required this.currency,
    this.bonusRate = 0.0,
  });

  factory CoinBundle.fromMap(Map<String, dynamic> map) {
    return CoinBundle(
      id: map['bundleId'] as String,
      title: map['title'] as String? ?? '',
      coins: (map['coins'] as num).toInt(),
      price: (map['price'] as num).toInt(),
      currency: map['currency'] as String? ?? 'KRW',
      bonusRate: (map['bonusRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CoinTransaction {
  final String id;
  final String type;
  final int amount;
  final int balanceAfter;
  final String reason;
  final DateTime createdAt;
  final String? memo;

  CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.reason,
    required this.createdAt,
    this.memo,
  });

  factory CoinTransaction.fromMap(String id, Map<String, dynamic> map) {
    return CoinTransaction(
      id: id,
      type: map['type'] as String? ?? 'debit',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (map['balanceAfter'] as num?)?.toInt() ?? 0,
      reason: map['reason'] as String? ?? '',
      createdAt:
          (map['createdAt'] as DateTime?) ??
          ((map['createdAt'] as dynamic)?.toDate() as DateTime? ??
              DateTime.now()),
      memo: map['memo'] as String?,
    );
  }
}

class CoinActionLog {
  final String id;
  final String type;
  final int cost;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  CoinActionLog({
    required this.id,
    required this.type,
    required this.cost,
    required this.status,
    required this.createdAt,
    required this.payload,
  });

  factory CoinActionLog.fromMap(String id, Map<String, dynamic> map) {
    return CoinActionLog(
      id: id,
      type: map['type'] as String? ?? '',
      cost: (map['cost'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'success',
      createdAt:
          (map['createdAt'] as DateTime?) ??
          ((map['createdAt'] as dynamic)?.toDate() as DateTime? ??
              DateTime.now()),
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
    );
  }
}
