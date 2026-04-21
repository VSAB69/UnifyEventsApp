// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_participant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedParticipantAdapter extends TypeAdapter<CachedParticipant> {
  @override
  final int typeId = 1;

  @override
  CachedParticipant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedParticipant(
      id: fields[0] as String,
      name: fields[1] as String,
      eventId: fields[2] as String,
      eventName: fields[3] as String,
      qrToken: fields[4] as String,
      isCheckedIn: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedParticipant obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.eventId)
      ..writeByte(3)
      ..write(obj.eventName)
      ..writeByte(4)
      ..write(obj.qrToken)
      ..writeByte(5)
      ..write(obj.isCheckedIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedParticipantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
