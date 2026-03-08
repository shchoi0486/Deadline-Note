import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import 'src/app.dart';
import 'src/services/job_link_parser.dart';
import 'src/services/notifications_service.dart';
import 'src/services/share_service.dart';
import 'src/services/storage_service.dart';
import 'src/state/app_state.dart';
import 'src/state/app_state_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ["F826AD408ACD78280C4BF64A87A7D31E"]),
  );

  final notifications = await NotificationsService.create();
  final appState = AppState(
    storage: StorageService(),
    notifications: notifications,
    shareService: ShareService(),
    parser: JobLinkParser(),
  );

  runApp(AppStateScope(notifier: appState, child: const DeadlineNoteApp()));
}
