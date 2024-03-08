// task.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';


part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final DateTime dueDate;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.dueDate,
  }) : this.id = id ?? Uuid().v4();
}