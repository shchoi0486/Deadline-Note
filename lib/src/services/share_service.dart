import 'dart:async';

import 'package:share_handler/share_handler.dart';

class ShareService {
  StreamSubscription<dynamic>? _subscription;

  Stream<String> onSharedText() async* {
    final controller = StreamController<String>.broadcast();
    _subscription = ShareHandler.instance.sharedMediaStream.listen((media) {
      final subject = media.conversationIdentifier?.trim();
      final content = media.content?.trim();
      final text = [subject, content].where((s) => s != null && s.isNotEmpty).join('\n');
      
      if (text.isEmpty) return;
      controller.add(text);
    });
    yield* controller.stream;
  }

  Future<String?> getInitialSharedText() async {
    final media = await ShareHandler.instance.getInitialSharedMedia();
    await ShareHandler.instance.resetInitialSharedMedia();
    
    final subject = media?.conversationIdentifier?.trim();
    final content = media?.content?.trim();
    final text = [subject, content].where((s) => s != null && s.isNotEmpty).join('\n');
    
    if (text.isEmpty) return null;
    return text;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
