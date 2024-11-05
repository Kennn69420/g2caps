import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  String time;

  @HiveField(3)
  String date;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  bool hasReminder;

  Task({
    required this.title,
    this.description = '',
    this.time = '',
    this.date = '',
    this.isCompleted = false,
    this.hasReminder = false,
  });
}
