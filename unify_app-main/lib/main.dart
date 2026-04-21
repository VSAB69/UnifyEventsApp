import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

import 'shared/widgets/cyber_grid_background.dart';

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/bookings/data/models/cached_ticket.dart';
import 'features/events/data/models/cached_participant.dart';
import 'core/sync/models/pending_checkin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Handle Encryption Key
  final secureStorage = SecureStorageService();
  String? keyStr = await secureStorage.getHiveKey();
  late List<int> encryptionKeyAsUint8List;
  if (keyStr == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.saveHiveKey(base64UrlEncode(key));
    encryptionKeyAsUint8List = key;
  } else {
    encryptionKeyAsUint8List = base64Url.decode(keyStr);
  }

  final cipher = HiveAesCipher(encryptionKeyAsUint8List);

  // Register Adapters
  Hive.registerAdapter(CachedTicketAdapter());
  Hive.registerAdapter(CachedParticipantAdapter());
  Hive.registerAdapter(PendingCheckinAdapter());

  // Open Boxes
  await Hive.openBox<CachedTicket>('tickets', encryptionCipher: cipher);
  await Hive.openBox<CachedParticipant>('participants', encryptionCipher: cipher);
  await Hive.openBox<PendingCheckin>('checkin_queue', encryptionCipher: cipher);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F0C29),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        builder: (context, child) {
          return Container(
            color: const Color(0xFF0F0C29),
            child: CyberGridBackground(child: child ?? const SizedBox()),
          );
        },
      ),
    );
  }
}
