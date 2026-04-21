// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_ticket.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedTicketAdapter extends TypeAdapter<CachedTicket> {
  @override
  final int typeId = 0;

  @override
  CachedTicket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedTicket(
      participantId: fields[0] as String,
      name: fields[1] as String,
      eventName: fields[2] as String,
      slot: fields[3] as String,
      qrToken: fields[4] as String,
      isCheckedIn: fields[5] as bool,
      cachedAt: fields[6] as DateTime,
      parentEventName: fields[7] as String,
      eventImageKey: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedTicket obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.participantId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.eventName)
      ..writeByte(3)
      ..write(obj.slot)
      ..writeByte(4)
      ..write(obj.qrToken)
      ..writeByte(5)
      ..write(obj.isCheckedIn)
      ..writeByte(6)
      ..write(obj.cachedAt)
      ..writeByte(7)
      ..write(obj.parentEventName)
      ..writeByte(8)
      ..write(obj.eventImageKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedTicketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
