import 'package:hive/hive.dart';

part 'cached_participant.g.dart';

@HiveType(typeId: 1)
class CachedParticipant extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String eventId;

  @HiveField(3)
  final String eventName;

  @HiveField(4)
  final String qrToken;

  @HiveField(5)
  late bool isCheckedIn;

  CachedParticipant({
    required this.id,
    required this.name,
    required this.eventId,
    required this.eventName,
    required this.qrToken,
    required this.isCheckedIn,
  });
}
