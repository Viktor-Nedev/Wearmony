import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/page_body.dart';

/// Read-only page opened from a tokenized vendor link.
class VendorScreen extends StatelessWidget {
  const VendorScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vendorTitle)),
      body: PageBody(children: [Text(l10n.vendorReadOnly)]),
    );
  }
}
