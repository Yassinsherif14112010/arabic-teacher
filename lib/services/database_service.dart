import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/grade.dart';
import '../models/fee_setting.dart';

/// Pure fast LocalStorage database engine specifically optimized for Flutter Web.
/// Bypasses WebAssembly worker complications and guarantees instant 0-latency saves.
class _WebDb {
  static final Map<String, List<Map<String, dynamic>>> _tables = {
    'students': [],
    'study_groups': [],
    'attendance': [],
    'payments': [],
    'grades': [],
    'fee_settings': [],
    'sync_queue': [],
    'auth_audit_logs': [],
  };
  static bool _initialized = false;
  static int _idCounter = 1;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dumpStr = prefs.getString('web_db_storage_v4');
      if (dumpStr != null) {
        final Map<String, dynamic> data = jsonDecode(dumpStr);
        for (final k in _tables.keys) {
          if (data.containsKey(k) && data[k] is List) {
            final list = (data[k] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _tables[k] = list;
            for (final row in list) {
              final id = (row['id'] as num?)?.toInt() ?? 0;
              if (id >= _idCounter) _idCounter = id + 1;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('WebDb init notice: $e');
    }
    _initialized = true;
  }

  static Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_db_storage_v4', jsonEncode(_tables));
    } catch (e) {
      debugPrint('WebDb save notice: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> query(String table) async {
    await init();
    return List<Map<String, dynamic>>.from(_tables[table] ?? []);
  }

  static Future<int> insert(String table, Map<String, dynamic> row,
      {String? uniqueKey}) async {
    await init();
    final map = Map<String, dynamic>.from(row);
    if (map['id'] == null) {
      map['id'] = _idCounter++;
    } else {
      final id = (map['id'] as num).toInt();
      if (id >= _idCounter) _idCounter = id + 1;
      _tables[table] =
          (_tables[table] ?? []).where((r) => r['id'] != id).toList();
    }
    if (uniqueKey != null && map[uniqueKey] != null) {
      _tables[table] = (_tables[table] ?? [])
          .where((r) => r[uniqueKey] != map[uniqueKey])
          .toList();
    }
    _tables[table]!.add(map);
    await save();
    return (map['id'] as num).toInt();
  }

  static Future<void> update(String table, Map<String, dynamic> row) async {
    await init();
    final id = row['id'];
    if (id == null) return;
    final list = _tables[table] ?? [];
    final idx = list.indexWhere((r) => r['id'] == id);
    if (idx >= 0) {
      list[idx] = Map<String, dynamic>.from(row);
    } else {
      list.add(Map<String, dynamic>.from(row));
    }
    await save();
  }

  static Future<void> delete(String table, int id) async {
    await init();
    _tables[table] =
        (_tables[table] ?? []).where((r) => r['id'] != id).toList();
    await save();
  }

  static Future<void> clear(String? table) async {
    await init();
    if (table != null) {
      _tables[table] = [];
    } else {
      for (final k in _tables.keys) {
        _tables[k] = [];
      }
    }
    await save();
  }
}

/// Offline-first Database service.
/// Uses native SQLite on Desktop/Mobile and ultra-fast WebDb on Flutter Web.
class DatabaseService {
  static Database? _db;
  static const int _version = 4;
  static const String _dbName = 'arabic_teacher_v2.db';

  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database query directly invoked on Web');
    }
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Backup is automatically handled by _WebDb on web targets.
  static Future<void> saveWebBackup() async {
    if (kIsWeb) await _WebDb.save();
  }

  /// Helper to upsert pulled cloud records directly into local storage.
  static Future<void> upsertFromCloud(String table, Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _WebDb.insert(table, row);
      return;
    }
    try {
      final db = await database;
      await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('upsertFromCloud notice on $table: $e');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fee_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          academicYear TEXT NOT NULL,
          grade TEXT NOT NULL,
          feeAmount REAL NOT NULL,
          UNIQUE(academicYear, grade)
        )
      ''');
    }
    if (oldVersion < 3) {
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
        feeAmount REAL NOT NULL,
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
    if (kIsWeb) {
      final rows = await _WebDb.query('students');
      rows.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      return rows.map(Student.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query('students', orderBy: 'name ASC');
    return rows.map(Student.fromMap).toList();
  }

  static Future<Student?> getStudentByBarcode(String barcode) async {
    if (kIsWeb) {
      final rows = await _WebDb.query('students');
      final match = rows.where((r) => r['barcodeNumber'] == barcode);
      return match.isNotEmpty ? Student.fromMap(match.first) : null;
    }
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
    if (kIsWeb) {
      return _WebDb.insert('students', student.toMap(), uniqueKey: 'barcodeNumber');
    }
    final db = await database;
    final id = await db.insert('students', student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<void> updateStudent(Student student) async {
    if (kIsWeb) {
      await _WebDb.update('students', student.toMap());
      return;
    }
    final db = await database;
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  static Future<void> deleteStudent(int id) async {
    if (kIsWeb) {
      await _WebDb.delete('students', id);
      _WebDb._tables['attendance'] = (_WebDb._tables['attendance'] ?? []).where((r) => r['studentId'] != id).toList();
      _WebDb._tables['payments'] = (_WebDb._tables['payments'] ?? []).where((r) => r['studentId'] != id).toList();
      _WebDb._tables['grades'] = (_WebDb._tables['grades'] ?? []).where((r) => r['studentId'] != id).toList();
      await _WebDb.save();
      return;
    }
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
    await db.delete('attendance', where: 'studentId = ?', whereArgs: [id]);
    await db.delete('payments', where: 'studentId = ?', whereArgs: [id]);
    await db.delete('grades', where: 'studentId = ?', whereArgs: [id]);
  }

  // ─── Study Groups ─────────────────────────────────────────────────────────

  static Future<List<StudyGroup>> getGroups() async {
    if (kIsWeb) {
      final rows = await _WebDb.query('study_groups');
      rows.sort((a, b) {
        final gComp = (a['grade'] ?? '').toString().compareTo((b['grade'] ?? '').toString());
        if (gComp != 0) return gComp;
        return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
      });
      return rows.map(StudyGroup.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query('study_groups', orderBy: 'grade ASC, name ASC');
    return rows.map(StudyGroup.fromMap).toList();
  }

  static Future<int> insertGroup(StudyGroup group) async {
    if (kIsWeb) {
      return _WebDb.insert('study_groups', group.toMap());
    }
    final db = await database;
    final id = await db.insert('study_groups', group.toMap());
    return id;
  }

  static Future<void> updateGroup(StudyGroup group) async {
    if (kIsWeb) {
      await _WebDb.update('study_groups', group.toMap());
      return;
    }
    final db = await database;
    await db.update(
      'study_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  static Future<void> deleteGroup(int id) async {
    if (kIsWeb) {
      await _WebDb.delete('study_groups', id);
      return;
    }
    final db = await database;
    await db.delete('study_groups', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Attendance ───────────────────────────────────────────────────────────

  static Future<List<Attendance>> getAttendanceForDate(String date) async {
    if (kIsWeb) {
      final rows = await _WebDb.query('attendance');
      return rows.where((r) => r['attendanceDate'] == date).map(Attendance.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query(
      'attendance',
      where: 'attendanceDate = ?',
      whereArgs: [date],
    );
    return rows.map(Attendance.fromMap).toList();
  }

  static Future<List<Attendance>> getAllAttendance() async {
    if (kIsWeb) {
      final rows = await _WebDb.query('attendance');
      rows.sort((a, b) => (b['attendanceDate'] ?? '').toString().compareTo((a['attendanceDate'] ?? '').toString()));
      return rows.map(Attendance.fromMap).toList();
    }
    final db = await database;
    final rows =
        await db.query('attendance', orderBy: 'attendanceDate DESC');
    return rows.map(Attendance.fromMap).toList();
  }

  /// Upsert: insert or replace attendance for a student on a given date.
  static Future<void> upsertAttendance(Attendance record) async {
    if (kIsWeb) {
      await _WebDb.init();
      _WebDb._tables['attendance']!.removeWhere((r) =>
          r['studentId'] == record.studentId && r['attendanceDate'] == record.attendanceDate);
      await _WebDb.insert('attendance', record.toMap());
      return;
    }
    final db = await database;
    await db.insert(
      'attendance',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  static Future<List<Payment>> getPayments() async {
    if (kIsWeb) {
      final rows = await _WebDb.query('payments');
      rows.sort((a, b) => (b['paymentDate'] ?? '').toString().compareTo((a['paymentDate'] ?? '').toString()));
      return rows.map(Payment.fromMap).toList();
    }
    final db = await database;
    final rows =
        await db.query('payments', orderBy: 'paymentDate DESC');
    return rows.map(Payment.fromMap).toList();
  }

  static Future<int> insertPayment(Payment payment) async {
    if (kIsWeb) {
      return _WebDb.insert('payments', payment.toMap());
    }
    final db = await database;
    final id = await db.insert('payments', payment.toMap());
    return id;
  }

  static Future<void> deletePayment(int id) async {
    if (kIsWeb) {
      await _WebDb.delete('payments', id);
      return;
    }
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Grades ───────────────────────────────────────────────────────────────

  static Future<List<Grade>> getGradesForStudent(int studentId) async {
    if (kIsWeb) {
      final rows = await _WebDb.query('grades');
      final matched = rows.where((r) => r['studentId'] == studentId).toList();
      matched.sort((a, b) => (b['examDate'] ?? '').toString().compareTo((a['examDate'] ?? '').toString()));
      return matched.map(Grade.fromMap).toList();
    }
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
    if (kIsWeb) {
      final rows = await _WebDb.query('grades');
      rows.sort((a, b) => (b['examDate'] ?? '').toString().compareTo((a['examDate'] ?? '').toString()));
      return rows.map(Grade.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query('grades', orderBy: 'examDate DESC');
    return rows.map(Grade.fromMap).toList();
  }

  static Future<int> insertGrade(Grade grade) async {
    if (kIsWeb) {
      return _WebDb.insert('grades', grade.toMap());
    }
    final db = await database;
    final id = await db.insert('grades', grade.toMap());
    return id;
  }

  static Future<void> deleteGrade(int id) async {
    if (kIsWeb) {
      await _WebDb.delete('grades', id);
      return;
    }
    final db = await database;
    await db.delete('grades', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Fee Settings ─────────────────────────────────────────────────────────

  static Future<List<FeeSetting>> getFeeSettings() async {
    if (kIsWeb) {
      final rows = await _WebDb.query('fee_settings');
      rows.sort((a, b) => (b['academicYear'] ?? '').toString().compareTo((a['academicYear'] ?? '').toString()));
      return rows.map(FeeSetting.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query('fee_settings',
        orderBy: 'academicYear DESC, grade ASC');
    return rows.map(FeeSetting.fromMap).toList();
  }

  static Future<void> upsertFeeSetting(FeeSetting setting) async {
    if (kIsWeb) {
      await _WebDb.init();
      _WebDb._tables['fee_settings']!.removeWhere((r) =>
          r['academicYear'] == setting.academicYear && r['grade'] == setting.grade);
      await _WebDb.insert('fee_settings', setting.toMap());
      return;
    }
    final db = await database;
    await db.insert(
      'fee_settings',
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteFeeSetting(int id) async {
    if (kIsWeb) {
      await _WebDb.delete('fee_settings', id);
      return;
    }
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
    if (kIsWeb) {
      return _WebDb.insert('sync_queue', {
        'entityName': entityName,
        'operation': operation,
        'entityId': entityId,
        'payload': payload,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
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
    if (kIsWeb) {
      final rows = await _WebDb.query('sync_queue');
      rows.sort((a, b) => ((a['id'] as num?) ?? 0).compareTo((b['id'] as num?) ?? 0));
      return rows;
    }
    final db = await database;
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  static Future<void> deleteSyncItem(int id) async {
    if (kIsWeb) {
      await _WebDb.delete('sync_queue', id);
      return;
    }
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearSyncQueue() async {
    if (kIsWeb) {
      await _WebDb.clear('sync_queue');
      return;
    }
    final db = await database;
    await db.delete('sync_queue');
  }

  // ─── Auth Audit Logs ──────────────────────────────────────────────────────

  static Future<int> logAuthEvent({
    required String eventType,
    required String message,
  }) async {
    if (kIsWeb) {
      return _WebDb.insert('auth_audit_logs', {
        'eventType': eventType,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    final db = await database;
    return db.insert('auth_audit_logs', {
      'eventType': eventType,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getAuthLogs({int limit = 50}) async {
    if (kIsWeb) {
      final rows = await _WebDb.query('auth_audit_logs');
      rows.sort((a, b) => ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0));
      return rows.take(limit).toList();
    }
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
    if (kIsWeb) {
      await _WebDb.clear(null);
      return;
    }
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
    if (kIsWeb) return;
    await _db?.close();
    _db = null;
  }
}
