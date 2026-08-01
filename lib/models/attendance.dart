/// Attendance status values.
enum AttendanceStatus { present, absent, late }

extension AttendanceStatusExt on AttendanceStatus {
  String get value {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
    }
  }

  static AttendanceStatus fromString(String s) {
    switch (s) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.absent;
    }
  }
}

/// A single attendance record for one student on one date.
class Attendance {
  final int? id;
  final int studentId;
  final String attendanceDate; // ISO date string yyyy-MM-dd
  final AttendanceStatus status;
  final String? notes;

  const Attendance({
    this.id,
    required this.studentId,
    required this.attendanceDate,
    required this.status,
    this.notes,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] != null ? (map['id'] as num).toInt() : null,
      studentId: (map['studentId'] as num).toInt(),
      attendanceDate: (map['attendanceDate'] ?? '').toString(),
      status: AttendanceStatusExt.fromString(map['status']?.toString() ?? 'absent'),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'attendanceDate': attendanceDate,
      'status': status.value,
      'notes': notes,
    };
  }

  Attendance copyWith({
    int? id,
    int? studentId,
    String? attendanceDate,
    AttendanceStatus? status,
    String? notes,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
