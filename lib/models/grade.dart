/// Exam type options.
enum ExamType { daily, monthly, final_ }

extension ExamTypeExt on ExamType {
  String get value {
    switch (this) {
      case ExamType.daily:
        return 'daily';
      case ExamType.monthly:
        return 'monthly';
      case ExamType.final_:
        return 'final';
    }
  }

  String get label {
    switch (this) {
      case ExamType.daily:
        return 'يومي';
      case ExamType.monthly:
        return 'شهري';
      case ExamType.final_:
        return 'نهائي';
    }
  }

  static ExamType fromString(String s) {
    switch (s) {
      case 'monthly':
        return ExamType.monthly;
      case 'final':
        return ExamType.final_;
      default:
        return ExamType.daily;
    }
  }
}

/// A grade/exam record for a student.
class Grade {
  final int? id;
  final int studentId;
  final ExamType examType;
  final double score;
  final double maxScore;
  final String examDate; // ISO date string
  final String? subject;
  final String? notes;

  const Grade({
    this.id,
    required this.studentId,
    required this.examType,
    required this.score,
    this.maxScore = 100,
    required this.examDate,
    this.subject,
    this.notes,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
  bool get isPassing => percentage >= 50;

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'] != null ? (map['id'] as num).toInt() : null,
      studentId: (map['studentId'] as num).toInt(),
      examType: ExamTypeExt.fromString((map['examType'] ?? '').toString()),
      score: double.tryParse((map['score'] ?? '0').toString()) ?? 0.0,
      maxScore: double.tryParse((map['maxScore'] ?? '100').toString()) ?? 100.0,
      examDate: (map['examDate'] ?? '').toString(),
      subject: map['subject'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'examType': examType.value,
      'score': score.toString(),
      'maxScore': maxScore.toString(),
      'examDate': examDate,
      'subject': subject,
      'notes': notes,
    };
  }
}
