import 'package:flutter/material.dart';

enum AddMethodResult { share, manual }

class AddMethodSheet extends StatelessWidget {
  const AddMethodSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('URL링크로 추가'),
              subtitle: const Text('사람인/잡코리아 등에서 링크 공유'),
              onTap: () => Navigator.of(context).pop(AddMethodResult.share),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('직접 추가'),
              subtitle: const Text('공유할 수 없는 공고일 때 빠르게 입력'),
              onTap: () => Navigator.of(context).pop(AddMethodResult.manual),
            ),
          ],
        ),
      ),
    );
  }
}

