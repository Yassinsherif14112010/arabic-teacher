import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:arabic_teacher_flutter/services/database_service.dart';
import 'package:arabic_teacher_flutter/services/sync_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SyncService.supabaseUrl = '';
    SyncService.supabaseAnonKey = '';
  });

  tearDown(() async {
    await DatabaseService.clearAll();
    await DatabaseService.close();
  });

  group('SyncService & sync_queue tests', () {
    test('Initial sync status is offline when unconfigured', () async {
      expect(SyncService.status, SyncStatus.offline);
      expect(SyncService.isConfigured, isFalse);
    });

    test('enqueueSyncItem saves items into SQLite queue', () async {
      await DatabaseService.enqueueSyncItem(
        entityName: 'students',
        operation: 'INSERT',
        entityId: '1',
        payload: '{"name": "أحمد"}',
      );

      final items = await DatabaseService.getPendingSyncItems();
      expect(items.length, 1);
      expect(items.first['entityName'], 'students');
      expect(items.first['operation'], 'INSERT');
      expect(items.first['entityId'], '1');
    });

    test('deleteSyncItem removes item from SQLite queue', () async {
      final id = await DatabaseService.enqueueSyncItem(
        entityName: 'payments',
        operation: 'INSERT',
        entityId: '10',
        payload: '{"amount": "500"}',
      );

      var items = await DatabaseService.getPendingSyncItems();
      expect(items.length, 1);

      await DatabaseService.deleteSyncItem(id);
      items = await DatabaseService.getPendingSyncItems();
      expect(items, isEmpty);
    });

    test('processSyncQueue when offline retains queue items in SQLite', () async {
      await DatabaseService.enqueueSyncItem(
        entityName: 'grades',
        operation: 'INSERT',
        entityId: '5',
        payload: '{"score": "95"}',
      );

      // Processing when offline should retain items safely in SQLite
      final processed = await SyncService.processSyncQueue();
      expect(processed, 0);

      final pending = await DatabaseService.getPendingSyncItems();
      expect(pending.length, 1);
    });

    test('processSyncQueue when configured drains items successfully', () async {
      SyncService.configure(
        url: 'https://xyz.supabase.co',
        anonKey: 'eyDummyKey',
      );

      await DatabaseService.enqueueSyncItem(
        entityName: 'attendance',
        operation: 'UPSERT',
        entityId: '1_2025-01-01',
        payload: '{"status": "present"}',
      );

      final processed = await SyncService.processSyncQueue();
      expect(processed, 1);

      final pending = await DatabaseService.getPendingSyncItems();
      expect(pending, isEmpty);
    });
  });
}
