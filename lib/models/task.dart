class Task {
  final int? id;
  final int categoryId;
  final String title;
  final int index;
  final bool status;
  final DateTime? reminder;

  Task({
    this.id,
    required this.categoryId,
    required this.title,
    this.index = 0,
    this.status = false,
    this.reminder,
  });

  Task copyWith({
    int? id,
    int? categoryId,
    String? title,
    int? index,
    bool? status,
    DateTime? reminder,
  }) {
    return Task(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      index: index ?? this.index,
      status: status ?? this.status,
      reminder: reminder ?? this.reminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'index': index,
      'status': status ? 1 : 0,
      'reminder': reminder?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      title: map['title'] as String,
      index: map['index'] as int? ?? 0,
      status: (map['status'] as int) == 1,
      reminder: map['reminder'] != null
          ? DateTime.parse(map['reminder'] as String)
          : null,
    );
  }
}
