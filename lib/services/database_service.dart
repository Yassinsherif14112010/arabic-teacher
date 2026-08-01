import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/grade.dart';
import '../models/fee_setting.dart';

/// Offline-first SQLite database service.
/// No network dependency — all data is persisted locally.
class DatabaseService {
  static Database? _db;
  static const int _version = 4;
  static const String _dbName = 'arabic_teacher_v2.db';

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    String path;
    if (kIsWeb) {
      path = inMemoryDatabasePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _dbName);
    }
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add fee_settings table if upgrading from v1
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fee_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          academicYear TEXT NOT NULL,
          grade TEXT NOT NULL,
          feeAmount TEXT NOT NULL,
          UNIQUE(academicYear, grade)
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add sync_queue table for offline-first Supabase sync
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entityName TEXT NOT NULL,
          operation TEXT NOT NULL,
          entityId TEXT NOT NULL,
          payload TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auth_audit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          eventType TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        parentPhone TEXT,
        barcodeNumber TEXT NOT NULL UNIQUE,
        grade TEXT,
        groupId INTEGER,
        feePaid INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE study_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        grade TEXT NOT NULL,
        schedule TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        attendanceDate TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        UNIQUE(studentId, attendanceDate)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        amount TEXT NOT NULL,
        paymentDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL DEFAULT 'cash',
        month TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        examType TEXT NOT NULL,
        score TEXT NOT NULL,
        maxScore TEXT NOT NULL DEFAULT '100',
        examDate TEXT NOT NULL,
        subject TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fee_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        academicYear TEXT NOT NULL,
        grade TEXT NOT NULL,
        feeAmount TEXT NOT NULL,
        UNIQUE(academicYear, grade)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entityName TEXT NOT NULL,
        operation TEXT NOT NULL,
        entityId TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE auth_audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventType TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // ─── Students ────────────────────────────────────────────────────────────

  static Future<List<Student>> getStudents() async {
    final db = await database;
    final rows = await db.query('students', orderBy: 'name ASC');
    return rows.map(Student.fromMap).toList();
  }

  static Future<Student?> getStudentByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'students',
      where: 'barcodeNumber = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return rows.isNotEmpty ? Student.fromMap(rows.first) : null;
  }

  static Future<int> insertStudent(Student student) async {
    final db = await database;
    return db.insert('students', student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateStudent(Student student) async {
    final db = await database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  static Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Study Groups ─────────────────────────────────────────────────────────

  static Future<List<StudyGroup>> getGroups() async {
    final db = await database;
    final rows = await db.query('study_groups', orderBy: 'grade ASC, name ASC');
    return rows.map(StudyGroup.fromMap).toList();
  }

  static Future<int> insertGroup(StudyGroup group) async {
    final db = await database;
    return db.insert('study_groups', group.toMap());
  }

  static Future<void> updateGroup(StudyGroup group) async {
    final db = await database;
    await db.update(
      'study_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  static Future<void> deleteGroup(int id) async {
    final db = await database;
    await db.delete('study_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  static Future<List<Attendance>> getAttendanceForDate(String date) async {
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'attendanceDate = ?',
      whereArgs: [date],
    );
    return rows.map(Attendance.fromMap).toList();
  }

  static Future<List<Attendance>> getAllAttendance() async {
    final db = await database;
    final rows =
        await db.query('attendance', orderBy: 'attendanceDate DESC');
    return rows.map(Attendance.fromMap).toList();
  }

  /// Upsert: insert or replace attendance for a student on a given date.
  static Future<void> upsertAttendance(Attendance record) async {
    final db = await database;
    await db.insert(
      'attendance',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  static Future<List<Payment>> getPayments() async {
    final db = await database;
    final rows =
        await db.query('payments', orderBy: 'paymentDate DESC');
    return rows.map(Payment.fromMap).toList();
  }

  static Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return db.insert('payments', payment.toMap());
  }

  static Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Grades ───────────────────────────────────────────────────────────────

  static Future<List<Grade>> getGradesForStudent(int studentId) async {
    final db = await database;
    final rows = await db.query(
      'grades',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'examDate DESC',
    );
    return rows.map(Grade.fromMap).toList();
  }

  static Future<List<Grade>> getAllGrades() async {
    final db = await database;
    final rows = await db.query('grades', orderBy: 'examDate DESC');
    return rows.map(Grade.fromMap).toList();
  }

  static Future<int> insertGrade(Grade grade) async {
    final db = await database;
    return db.insert('grades', grade.toMap());
  }

  static Future<void> deleteGrade(int id) async {
    final db = await database;
    await db.delete('grades', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Fee Settings ─────────────────────────────────────────────────────────

  static Future<List<FeeSetting>> getFeeSettings() async {
    final db = await database;
    final rows = await db.query('fee_settings',
        orderBy: 'academicYear DESC, grade ASC');
    return rows.map(FeeSetting.fromMap).toList();
  }

  static Future<void> upsertFeeSetting(FeeSetting setting) async {
    final db = await database;
    await db.insert(
      'fee_settings',
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteFeeSetting(int id) async {
    final db = await database;
    await db.delete('fee_settings', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Sync Queue ───────────────────────────────────────────────────────────

  static Future<int> enqueueSyncItem({
    required String entityName,
    required String operation,
    required String entityId,
    required String payload,
  }) async {
    final db = await database;
    return db.insert('sync_queue', {
      'entityName': entityName,
      'operation': operation,
      'entityId': entityId,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  static Future<void> deleteSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  // ─── Auth Audit Logs ──────────────────────────────────────────────────────

  static Future<int> logAuthEvent({
    required String eventType,
    required String message,
  }) async {
    final db = await database;
    return db.insert('auth_audit_logs', {
      'eventType': eventType,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getAuthLogs({int limit = 50}) async {
    final db = await database;
    return db.query(
      'auth_audit_logs',
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  /// Wipe all data (useful for testing / reset).
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('students');
    await db.delete('study_groups');
    await db.delete('attendance');
    await db.delete('payments');
    await db.delete('grades');
    await db.delete('fee_settings');
    await db.delete('sync_queue');
    await db.delete('auth_audit_logs');
  }

  /// Close the database (used in tests).
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
