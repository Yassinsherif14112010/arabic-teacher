import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/grade.dart';
import '../models/fee_setting.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

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
  int _pendingSyncCount = 0;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Student> get students => List.unmodifiable(_students);
  List<StudyGroup> get groups => List.unmodifiable(_groups);
  List<Attendance> get todayAttendance => List.unmodifiable(_todayAttendance);
  List<Payment> get payments => List.unmodifiable(_payments);
  List<Grade> get grades => List.unmodifiable(_grades);
  List<FeeSetting> get feeSettings => List.unmodifiable(_feeSettings);
  bool get loading => _loading;
  String? get error => _error;
  int get pendingSyncCount => _pendingSyncCount;
  SyncStatus get syncStatus => SyncService.status;

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

  // ─── Sync Operations ──────────────────────────────────────────────────────

  Future<void> _refreshPendingSyncCount() async {
    final pending = await DatabaseService.getPendingSyncItems();
    _pendingSyncCount = pending.length;
    notifyListeners();
  }

  Future<void> syncNow() async {
    await SyncService.processSyncQueue();
    await _refreshPendingSyncCount();
  }

  Future<void> _enqueueSync(String entityName, String operation,
      String entityId, Map<String, dynamic> payload) async {
    await DatabaseService.enqueueSyncItem(
      entityName: entityName,
      operation: operation,
      entityId: entityId,
      payload: jsonEncode(payload),
    );
    await _refreshPendingSyncCount();
    // Fire-and-forget background sync if online
    SyncService.processSyncQueue().then((_) => _refreshPendingSyncCount());
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
      await _refreshPendingSyncCount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Students ─────────────────────────────────────────────────────────────

  Future<void> addStudent(Student student) async {
    final id = await DatabaseService.insertStudent(student);
    _students = await DatabaseService.getStudents();
    await _enqueueSync('students', 'INSERT', id.toString(), student.toMap());
    notifyListeners();
  }

  Future<void> updateStudent(Student student) async {
    await DatabaseService.updateStudent(student);
    _students = await DatabaseService.getStudents();
    await _enqueueSync(
        'students', 'UPDATE', (student.id ?? 0).toString(), student.toMap());
    notifyListeners();
  }

  Future<void> deleteStudent(int id) async {
    await DatabaseService.deleteStudent(id);
    _students = await DatabaseService.getStudents();
    await _enqueueSync('students', 'DELETE', id.toString(), {'id': id});
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
    final id = await DatabaseService.insertGroup(group);
    _groups = await DatabaseService.getGroups();
    await _enqueueSync('study_groups', 'INSERT', id.toString(), group.toMap());
    notifyListeners();
  }

  Future<void> updateGroup(StudyGroup group) async {
    await DatabaseService.updateGroup(group);
    _groups = await DatabaseService.getGroups();
    await _enqueueSync(
        'study_groups', 'UPDATE', (group.id ?? 0).toString(), group.toMap());
    notifyListeners();
  }

  Future<void> deleteGroup(int id) async {
    await DatabaseService.deleteGroup(id);
    _groups = await DatabaseService.getGroups();
    await _enqueueSync('study_groups', 'DELETE', id.toString(), {'id': id});
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
    await _enqueueSync(
        'attendance', 'UPSERT', '${studentId}_$date', record.toMap());
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
    final id = await DatabaseService.insertPayment(payment);
    _payments = await DatabaseService.getPayments();
    await _enqueueSync('payments', 'INSERT', id.toString(), payment.toMap());
    notifyListeners();
  }

  Future<void> deletePayment(int id) async {
    await DatabaseService.deletePayment(id);
    _payments = await DatabaseService.getPayments();
    await _enqueueSync('payments', 'DELETE', id.toString(), {'id': id});
    notifyListeners();
  }

  // ─── Grades ───────────────────────────────────────────────────────────────

  Future<List<Grade>> getGradesForStudent(int studentId) async {
    return DatabaseService.getGradesForStudent(studentId);
  }

  Future<void> addGrade(Grade grade) async {
    final id = await DatabaseService.insertGrade(grade);
    _grades = await DatabaseService.getAllGrades();
    await _enqueueSync('grades', 'INSERT', id.toString(), grade.toMap());
    notifyListeners();
  }

  Future<void> deleteGrade(int id) async {
    await DatabaseService.deleteGrade(id);
    _grades = await DatabaseService.getAllGrades();
    await _enqueueSync('grades', 'DELETE', id.toString(), {'id': id});
    notifyListeners();
  }

  // ─── Fee Settings ─────────────────────────────────────────────────────────

  Future<void> upsertFeeSetting(FeeSetting setting) async {
    await DatabaseService.upsertFeeSetting(setting);
    _feeSettings = await DatabaseService.getFeeSettings();
    await _enqueueSync('fee_settings', 'UPSERT',
        '${setting.academicYear}_${setting.grade}', setting.toMap());
    notifyListeners();
  }

  Future<void> deleteFeeSetting(int id) async {
    await DatabaseService.deleteFeeSetting(id);
    _feeSettings = await DatabaseService.getFeeSettings();
    await _enqueueSync('fee_settings', 'DELETE', id.toString(), {'id': id});
    notifyListeners();
  }
}
