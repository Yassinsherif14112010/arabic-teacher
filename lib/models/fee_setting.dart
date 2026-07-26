/// Fee setting for a specific grade and academic year.
class FeeSetting {
  final int? id;
  final String academicYear;
  final String grade;
  final double feeAmount;

  const FeeSetting({
    this.id,
    required this.academicYear,
    required this.grade,
    required this.feeAmount,
  });

  factory FeeSetting.fromMap(Map<String, dynamic> map) {
    return FeeSetting(
      id: map['id'] as int?,
      academicYear: map['academicYear'] as String,
      grade: map['grade'] as String,
      feeAmount: double.tryParse(map['feeAmount'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'academicYear': academicYear,
      'grade': grade,
      'feeAmount': feeAmount.toString(),
    };
  }
}
