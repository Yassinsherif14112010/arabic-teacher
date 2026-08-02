import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/study_group.dart';

void openMonthlyAttendanceReportImpl(
  String monthStr,
  List<Student> students,
  List<Attendance> allRecords,
  List<StudyGroup> groups,
) {
  debugPrint('Attendance report generating on native for $monthStr');
}
