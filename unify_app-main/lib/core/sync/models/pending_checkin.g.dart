// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_checkin.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingCheckinAdapter extends TypeAdapter<PendingCheckin> {
  @override
  final int typeId = 2;

  @override
  PendingCheckin read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingCheckin(
      qrToken: fields[0] as String,
      scannedAt: fields[1] as DateTime,
      eventId: fields[2] as String?,
      status: fields[3] as String,
      retries: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PendingCheckin obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.qrToken)
      ..writeByte(1)
      ..write(obj.scannedAt)
      ..writeByte(2)
      ..write(obj.eventId)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.retries);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingCheckinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
