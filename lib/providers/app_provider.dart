import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/grade.dart';
import '../models/fee_setting.dart';
import '../services/database_service.dart';

/// Central state provider for the entire app.
/// All data is loaded from and persisted to the local SQLite database.
class AppProvider extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────
  List<Student> _students = [];
  List<StudyGroup> _groups = [];
  List<Attendance> _todayAttendance = [];
  List<Payment> _payments = [];
  List<Grade> _grades = [];
  List<FeeSetting> _feeSettings = [];

  bool _loading = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Student> get students => List.unmodifiable(_students);
  List<StudyGroup> get groups => List.unmodifiable(_groups);
  List<Attendance> get todayAttendance => List.unmodifiable(_todayAttendance);
  List<Payment> get payments => List.unmodifiable(_payments);
  List<Grade> get grades => List.unmodifiable(_grades);
  List<FeeSetting> get feeSettings => List.unmodifiable(_feeSettings);
  bool get loading => _loading;
  String? get error => _error;

  String get todayDateString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ─── Dashboard stats ──────────────────────────────────────────────────────
  int get totalStudents => _students.length;
  int get activeStudents =>
      _students.where((s) => s.status == 'active').length;
  int get presentToday =>
      _todayAttendance.where((a) => a.status == AttendanceStatus.present).length;
  int get lateToday =>
      _todayAttendance.where((a) => a.status == AttendanceStatus.late).length;
  int get paidStudents => _students.where((s) => s.feePaid).length;

  int get attendanceRate {
    if (_students.isEmpty) return 0;
    return ((presentToday / _students.length) * 100).round();
  }

  // ─── Load all data ────────────────────────────────────────────────────────
  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _students = await DatabaseService.getStudents();
      _groups = await DatabaseService.getGroups();
      _todayAttendance =
          await DatabaseService.getAttendanceForDate(todayDateString);
      _payments = await DatabaseService.getPayments();
      _grades = await DatabaseService.getAllGrades();
      _feeSettings = await DatabaseService.getFeeSettings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Students ─────────────────────────────────────────────────────────────

  Future<void> addStudent(Student student) async {
    await DatabaseService.insertStudent(student);
    _students = await DatabaseService.getStudents();
    notifyListeners();
  }

  Future<void> updateStudent(Student student) async {
    await DatabaseService.updateStudent(student);
    _students = await DatabaseService.getStudents();
    notifyListeners();
  }

  Future<void> deleteStudent(int id) async {
    await DatabaseService.deleteStudent(id);
    _students = await DatabaseService.getStudents();
    notifyListeners();
  }

  Student? findStudentByBarcode(String barcode) {
    try {
      return _students.firstWhere((s) => s.barcodeNumber == barcode);
    } catch (_) {
      return null;
    }
  }

  /// Generate a unique barcode number (6-digit numeric string).
  String generateBarcode() {
    final rng = Random();
    String code;
    do {
      code = (100000 + rng.nextInt(900000)).toString();
    } while (_students.any((s) => s.barcodeNumber == code));
    return code;
  }

  // ─── Study Groups ─────────────────────────────────────────────────────────

  Future<void> addGroup(StudyGroup group) async {
    await DatabaseService.insertGroup(group);
    _groups = await DatabaseService.getGroups();
    notifyListeners();
  }

  Future<void> updateGroup(StudyGroup group) async {
    await DatabaseService.updateGroup(group);
    _groups = await DatabaseService.getGroups();
    notifyListeners();
  }

  Future<void> deleteGroup(int id) async {
    await DatabaseService.deleteGroup(id);
    _groups = await DatabaseService.getGroups();
    notifyListeners();
  }

  List<StudyGroup> groupsForGrade(String grade) =>
      _groups.where((g) => g.grade == grade).toList();

  // ─── Attendance ───────────────────────────────────────────────────────────

  Future<void> recordAttendance({
    required int studentId,
    required String date,
    required AttendanceStatus status,
    String? notes,
  }) async {
    final record = Attendance(
      studentId: studentId,
      attendanceDate: date,
      status: status,
      notes: notes,
    );
    await DatabaseService.upsertAttendance(record);
    // Refresh today's attendance if the date matches
    if (date == todayDateString) {
      _todayAttendance =
          await DatabaseService.getAttendanceForDate(todayDateString);
    }
    notifyListeners();
  }

  Future<List<Attendance>> getAttendanceForDate(String date) async {
    return DatabaseService.getAttendanceForDate(date);
  }

  AttendanceStatus? getStudentStatusForDate(
      int studentId, List<Attendance> records) {
    try {
      return records.firstWhere((a) => a.studentId == studentId).status;
    } catch (_) {
      return null;
    }
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  Future<void> addPayment(Payment payment) async {
    await DatabaseService.insertPayment(payment);
    _payments = await DatabaseService.getPayments();
    notifyListeners();
  }

  Future<void> deletePayment(int id) async {
    await DatabaseService.deletePayment(id);
    _payments = await DatabaseService.getPayments();
    notifyListeners();
  }

  // ─── Grades ───────────────────────────────────────────────────────────────

  Future<List<Grade>> getGradesForStudent(int studentId) async {
    return DatabaseService.getGradesForStudent(studentId);
  }

  Future<void> addGrade(Grade grade) async {
    await DatabaseService.insertGrade(grade);
    _grades = await DatabaseService.getAllGrades();
    notifyListeners();
  }

  Future<void> deleteGrade(int id) async {
    await DatabaseService.deleteGrade(id);
    _grades = await DatabaseService.getAllGrades();
    notifyListeners();
  }

  // ─── Fee Settings ─────────────────────────────────────────────────────────

  Future<void> upsertFeeSetting(FeeSetting setting) async {
    await DatabaseService.upsertFeeSetting(setting);
    _feeSettings = await DatabaseService.getFeeSettings();
    notifyListeners();
  }

  Future<void> deleteFeeSetting(int id) async {
    await DatabaseService.deleteFeeSetting(id);
    _feeSettings = await DatabaseService.getFeeSettings();
    notifyListeners();
  }
}
