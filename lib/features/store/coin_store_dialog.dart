import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../i18n/i18n.dart';
import '../../models/coin.dart';
import '../../services/coin_service.dart';
import '../../theme/theme.dart';

class CoinStoreDialog extends StatefulWidget {
  const CoinStoreDialog({super.key});

  @override
  State<CoinStoreDialog> createState() => _CoinStoreDialogState();
}

class _CoinStoreDialogState extends State<CoinStoreDialog> {
  String? _selectedPackage;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Future<void> _purchaseBundle(CoinBundle bundle) async {
    final i18n = I18n.of(context);
    final platform = Theme.of(context).platform == TargetPlatform.iOS
        ? 'apple'
        : 'google';

    final purchaseToken = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.card,
          title: Text(
            i18n.t('coin.enter_receipt'),
            style: const TextStyle(color: AppTheme.text),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: i18n.t('coin.receipt_token'),
              labelStyle: const TextStyle(color: AppTheme.sub),
            ),
            style: const TextStyle(color: AppTheme.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                i18n.t('common.cancel'),
                style: const TextStyle(color: AppTheme.sub),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(
                i18n.t('common.confirm'),
                style: const TextStyle(color: AppTheme.pink),
              ),
            ),
          ],
        );
      },
    );

    if (purchaseToken == null || purchaseToken.isEmpty) return;

    setState(() {
      _selectedPackage = bundle.id;
    });

    try {
      final result = await CoinService.verifyAndCredit(
        platform: platform,
        bundleId: bundle.id,
        purchaseToken: purchaseToken,
      );
      if (!mounted) return;
      final coinsText = (result['coins'] ?? bundle.coins).toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${coinsText}코인을 구매했습니다!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('구매 실패: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _selectedPackage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundles = CoinService.getBundles();

    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFC107),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '코인 스토어',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.sub),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '코인으로 프리미엄 기능을 이용하세요',
                style: TextStyle(color: AppTheme.sub),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userStream(),
              builder: (context, snapshot) {
                final balance = snapshot.data?.data()?['coinBalance'] ?? 0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF9E6),
                        const Color(0xFFFFF3E0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFE082),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFFC107),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 보유 코인',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$balance 코인',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ...bundles.map((bundle) {
                      final totalCoins = bundle.coins +
                          (bundle.bonusRate > 0
                              ? (bundle.coins * bundle.bonusRate).toInt()
                              : 0);
                      final isPurchasing = _selectedPackage == bundle.id;
                      final isPopular = bundle.id == 'medium';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isPopular
                                ? const Color(0xFF2196F3)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (bundle.bonusRate > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFFC107),
                                        const Color(0xFFFF9800),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '최고가치',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF9C27B0),
                                          const Color(0xFF2196F3),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${bundle.coins} 코인',
                                              style: const TextStyle(
                                                color: AppTheme.text,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (bundle.bonusRate > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '+${(bundle.bonusRate * 100).toInt()}% 보너스',
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (bundle.bonusRate > 0)
                                          Text(
                                            '총 $totalCoins 코인',
                                            style: const TextStyle(
                                              color: AppTheme.sub,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₩${bundle.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: AppTheme.text,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ElevatedButton(
                                        onPressed: isPurchasing
                                            ? null
                                            : () => _purchaseBundle(bundle),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPopular
                                              ? const Color(0xFF2196F3)
                                              : AppTheme.pink,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(isPurchasing ? '구매중...' : '구매'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF9C27B0),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '코인으로 할 수 있는 것',
                                style: TextStyle(
                                  color: AppTheme.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _FeatureItem('프로필 부스트로 더 많은 사람에게 노출'),
                          _FeatureItem('무제한 좋아요'),
                          _FeatureItem('누가 나를 좋아했는지 확인'),
                          _FeatureItem('슈퍼 라이크로 특별한 관심 표시'),
                          _FeatureItem('매칭 우선권'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

