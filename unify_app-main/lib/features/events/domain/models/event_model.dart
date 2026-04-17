class EventModel {
  final int id;
  final int? parentEventId;
  final String title;
  final String description;
  final String? bannerImage;
  final num? price;
  final String? date;

  EventModel({
    required this.id,
    this.parentEventId,
    required this.title,
    required this.description,
    this.bannerImage,
    this.price,
    this.date,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      parentEventId: int.tryParse(json['parent_event']?.toString() ?? ''),
      title:
          json['title']?.toString() ??
          json['name']?.toString() ??
          'Unknown Event',
      description: json['description']?.toString() ?? '',
      bannerImage:
          json['image_key']?.toString() ??
          json['banner_image']?.toString() ??
          json['image']?.toString(),
      price: num.tryParse(
        json['price']?.toString() ?? json['fee']?.toString() ?? '',
      ),
      date: json['date']?.toString() ?? json['start_time']?.toString(),
    );
  }
}
