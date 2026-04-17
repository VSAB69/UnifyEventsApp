class ConstraintModel {
  final String bookingType; // 'single' or 'multiple'
  final bool fixed;
  final int lowerLimit;
  final int upperLimit;

  ConstraintModel({
    required this.bookingType,
    required this.fixed,
    required this.lowerLimit,
    required this.upperLimit,
  });

  factory ConstraintModel.fromJson(Map<String, dynamic> json) {
    return ConstraintModel(
      bookingType: json['booking_type']?.toString().toLowerCase() ?? 'single',
      fixed:
          json['fixed'] == true ||
          json['fixed']?.toString().toLowerCase() == 'true',
      lowerLimit: int.tryParse(json['lower_limit']?.toString() ?? '1') ?? 1,
      upperLimit: int.tryParse(json['upper_limit']?.toString() ?? '1') ?? 1,
    );
  }
}

class SlotModel {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final int? availableParticipants;
  final bool unlimitedParticipants;

  SlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.availableParticipants,
    required this.unlimitedParticipants,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      availableParticipants: json['available_participants'],
      unlimitedParticipants: json['unlimited_participants'] ?? false,
    );
  }
}
