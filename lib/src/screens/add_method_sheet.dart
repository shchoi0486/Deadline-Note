import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

enum AddMethodResult { share, manual }

class AddMethodSheet extends StatelessWidget {
  const AddMethodSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.addMethodLink),
              subtitle: Text(l10n.addMethodLinkDesc),
              onTap: () => Navigator.of(context).pop(AddMethodResult.share),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.addMethodManual),
              subtitle: Text(l10n.addMethodManualDesc),
              onTap: () => Navigator.of(context).pop(AddMethodResult.manual),
            ),
          ],
        ),
      ),
    );
  }
}

