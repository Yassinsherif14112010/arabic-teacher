import '../models/student.dart';
import '../models/attendance.dart';
import '../models/study_group.dart';
import 'attendance_report_stub.dart'
    if (dart.library.html) 'attendance_report_web.dart';

class AttendanceReportService {
  static void openMonthlyReport(
    String monthStr,
    List<Student> students,
    List<Attendance> allRecords,
    List<StudyGroup> groups,
  ) {
    openMonthlyAttendanceReportImpl(monthStr, students, allRecords, groups);
  }
}
