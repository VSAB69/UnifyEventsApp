import 'package:hive/hive.dart';

part 'cached_ticket.g.dart';

@HiveType(typeId: 0)
class CachedTicket extends HiveObject {
  @HiveField(0)
  final String participantId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String eventName;

  @HiveField(3)
  final String slot;

  @HiveField(4)
  final String qrToken;

  @HiveField(5)
  late bool isCheckedIn;

  @HiveField(6)
  final DateTime cachedAt;

  @HiveField(7)
  final String parentEventName;
  
  @HiveField(8)
  final String? eventImageKey;

  CachedTicket({
    required this.participantId,
    required this.name,
    required this.eventName,
    required this.slot,
    required this.qrToken,
    required this.isCheckedIn,
    required this.cachedAt,
    this.parentEventName = '',
    this.eventImageKey,
  });
}
