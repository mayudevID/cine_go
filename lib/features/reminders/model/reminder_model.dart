class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.scheduledAt,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'scheduledAt': scheduledAt.toIso8601String(),
  };

  factory ReminderModel.fromJson(Map<String, Object?> json) => ReminderModel(
    id: json['id']! as String,
    title: json['title']! as String,
    scheduledAt: DateTime.parse(json['scheduledAt']! as String),
  );
}
