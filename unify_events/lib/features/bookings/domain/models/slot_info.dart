class SlotInfo {
  final String? date;
  final String? startTime;
  final String? endTime;
  final bool unlimited;

  SlotInfo({
    this.date,
    this.startTime,
    this.endTime,
    required this.unlimited,
  });

  factory SlotInfo.fromJson(Map<String, dynamic> json) {
    return SlotInfo(
      date: json['date']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      unlimited: json['unlimited'] == true || json['unlimited'] == 'true',
    );
  }

  static SlotInfo? tryParse(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return SlotInfo.fromJson(data);
    }
    return null;
  }
}

String formatTimeHHMM(String? timeRaw) {
  if (timeRaw == null || timeRaw.isEmpty) return '';
  num? hOverride;
  num? mOverride;
  
  final parts = timeRaw.split(':');
  if (parts.isNotEmpty) hOverride = num.tryParse(parts[0]);
  if (parts.length > 1) mOverride = num.tryParse(parts[1]);

  if (hOverride == null || mOverride == null) return timeRaw;
  
  final isPM = hOverride >= 12;
  final hr12 = hOverride % 12 == 0 ? 12 : hOverride % 12;
  final minStr = mOverride.toInt().toString().padLeft(2, '0');
  
  return '$hr12:$minStr ${isPM ? 'PM' : 'AM'}';
}
