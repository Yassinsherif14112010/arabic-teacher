/// A study group (مجموعة دراسية) for a specific grade.
class StudyGroup {
  final int? id;
  final String name;
  final String grade;
  final String? schedule;
  final String? description;

  const StudyGroup({
    this.id,
    required this.name,
    required this.grade,
    this.schedule,
    this.description,
  });

  factory StudyGroup.fromMap(Map<String, dynamic> map) {
    return StudyGroup(
      id: map['id'] as int?,
      name: map['name'] as String,
      grade: map['grade'] as String,
      schedule: map['schedule'] as String?,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'grade': grade,
      'schedule': schedule,
      'description': description,
    };
  }

  StudyGroup copyWith({
    int? id,
    String? name,
    String? grade,
    String? schedule,
    String? description,
  }) {
    return StudyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      schedule: schedule ?? this.schedule,
      description: description ?? this.description,
    );
  }
}
