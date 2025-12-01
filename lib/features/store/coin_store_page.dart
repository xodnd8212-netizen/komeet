import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../i18n/i18n.dart';
import '../../models/coin.dart';
import '../../services/coin_service.dart';
import '../../theme/theme.dart';

class CoinStorePage extends StatefulWidget {
  const CoinStorePage({super.key});

  @override
  State<CoinStorePage> createState() => _CoinStorePageState();
}

class _CoinStorePageState extends State<CoinStorePage> {
  bool _isProcessing = false;

  String _format(I18n i18n, String key, Map<String, String> params) {
    var text = i18n.t(key);
    params.forEach((placeholder, value) {
      text = text.replaceAll('{$placeholder}', value);
    });
    return text;
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

    setState(() => _isProcessing = true);
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
          content: Text(
            _format(i18n, 'coin.purchase_success', {'coins': coinsText}),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('${i18n.t('coin.purchase_failed')}\n$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _spendCoins(String actionType) async {
    final i18n = I18n.of(context);
    setState(() => _isProcessing = true);
    try {
      await CoinService.spendCoins(actionType: actionType);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(i18n.t('coin.spend_success'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('${i18n.t('coin.spend_failed')}\n$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final bundles = CoinService.getBundles();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.text,
        title: Text(
          i18n.t('coin.store_title'),
          style: const TextStyle(color: AppTheme.text),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isProcessing,
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _userStream(),
                  builder: (context, snapshot) {
                    final balance = snapshot.data?.data()?['coinBalance'] ?? 0;
                    final freeSwipes =
                        snapshot.data?.data()?['freeSwipeCount'] ?? 0;
                    return Card(
                      color: AppTheme.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i18n.t('coin.balance_title'),
                              style: const TextStyle(color: AppTheme.sub),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$balance',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.text,
                              ),
                            ),
                            if (freeSwipes != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _format(i18n, 'coin.free_swipes', {
                                    'count': '$freeSwipes',
                                  }),
                                  style: const TextStyle(color: AppTheme.sub),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  i18n.t('coin.bundle_section'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 12),
                for (final bundle in bundles) ...[
                  Card(
                    color: AppTheme.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bundle.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _format(i18n, 'coin.bundle_detail', {
                                    'coins': bundle.coins.toString(),
                                    'price': bundle.price.toString(),
                                  }),
                                  style: const TextStyle(color: AppTheme.sub),
                                ),
                                if (bundle.bonusRate > 0)
                                  Text(
                                    _format(i18n, 'coin.bundle_bonus', {
                                      'bonus':
                                          '${(bundle.bonusRate * 100).toInt()}%',
                                    }),
                                    style: const TextStyle(
                                      color: AppTheme.pink,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _purchaseBundle(bundle),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text(i18n.t('coin.purchase_button')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                Text(
                  i18n.t('coin.spend_section'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 12),
                _SpendTile(
                  title: i18n.t('coin.action.swipe_extra'),
                  cost: 5,
                  onTap: () => _spendCoins('swipe_extra'),
                ),
                _SpendTile(
                  title: i18n.t('coin.action.special_like'),
                  cost: 10,
                  onTap: () => _spendCoins('special_like'),
                ),
                _SpendTile(
                  title: i18n.t('coin.action.super_like'),
                  cost: 50,
                  onTap: () => _spendCoins('super_like'),
                ),
                _SpendTile(
                  title: i18n.t('coin.action.boost'),
                  cost: 200,
                  onTap: () => _spendCoins('boost'),
                ),
                _SpendTile(
                  title: i18n.t('coin.action.priority'),
                  cost: 150,
                  onTap: () => _spendCoins('priority'),
                ),
                const SizedBox(height: 24),
                Text(
                  i18n.t('coin.info_title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.t('coin.info_desc'),
                  style: const TextStyle(color: AppTheme.sub),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isProcessing
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : null,
    );
  }
}

class _SpendTile extends StatelessWidget {
  final String title;
  final int cost;
  final VoidCallback onTap;

  const _SpendTile({
    required this.title,
    required this.cost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    return Card(
      color: AppTheme.card,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppTheme.text)),
        subtitle: Text(
          i18n.t('coin.cost_label').replaceAll('{coins}', cost.toString()),
          style: const TextStyle(color: AppTheme.sub),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.sub,
        ),
        onTap: onTap,
      ),
    );
  }
}
