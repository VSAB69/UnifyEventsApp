import 'package:hive/hive.dart';

part 'pending_checkin.g.dart';

@HiveType(typeId: 2)
class PendingCheckin extends HiveObject {
  @HiveField(0)
  final String qrToken;

  @HiveField(1)
  final DateTime scannedAt;

  @HiveField(2)
  final String? eventId; // Optional, depending on if we have it offline

  @HiveField(3)
  late String status; // pending, success, failed

  @HiveField(4)
  late int retries; // max 3

  PendingCheckin({
    required this.qrToken,
    required this.scannedAt,
    this.eventId,
    this.status = 'pending',
    this.retries = 0,
  });
}
