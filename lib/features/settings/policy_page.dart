import 'package:flutter/material.dart';

import '../../constants/policies.dart';
import '../../i18n/i18n.dart';
import '../../theme/theme.dart';

class PolicyPage extends StatelessWidget {
  final String policyId;

  const PolicyPage({super.key, required this.policyId});

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final doc = findPolicyById(policyId);

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Policy'),
          backgroundColor: AppTheme.bg,
        ),
        backgroundColor: AppTheme.bg,
        body: const Center(
          child: Text(
            '정책 문서를 찾을 수 없습니다.',
            style: TextStyle(color: AppTheme.sub),
          ),
        ),
      );
    }

    final title = doc.title(i18n.locale);
    final body = doc.body(i18n.locale);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: AppTheme.text,
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.text),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: SelectableText(
            body,
            style: const TextStyle(
              color: AppTheme.text,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

