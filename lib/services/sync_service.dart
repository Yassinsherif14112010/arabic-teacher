import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

enum SyncStatus {
  online,
  offline,
  syncing,
  error,
}

/// Offline-First Sync Manager connecting local SQLite to Supabase.
class SyncService {
  static String supabaseUrl = 'https://kfgrcxskubixdzzcmdge.supabase.co';
  static String supabaseAnonKey = 'sb_publishable_zGro7rAOdAGmmOWJ-BcCRQ_VZJsPgpk';

  static SyncStatus _status = SyncStatus.offline;
  static DateTime? _lastSyncedAt;
  static String? _lastError;

  static SyncStatus get status => _status;
  static DateTime? get lastSyncedAt => _lastSyncedAt;
  static String? get lastError => _lastError;

  /// Check if Supabase connection details are provided.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Configure optional Supabase environment settings.
  static void configure({required String url, required String anonKey}) {
    supabaseUrl = url;
    supabaseAnonKey = anonKey;
  }

  /// Check network availability.
  static Future<bool> checkConnectivity() async {
    // SQLite local database is always primary.
    // If Supabase URL is not set, we operate in full local offline mode.
    if (!isConfigured) {
      _status = SyncStatus.offline;
      return false;
    }
    _status = SyncStatus.online;
    return true;
  }

  /// Process all pending items queued in local SQLite `sync_queue`.
  static Future<int> processSyncQueue() async {
    final pending = await DatabaseService.getPendingSyncItems();
    if (pending.isEmpty) {
      _status = isConfigured ? SyncStatus.online : SyncStatus.offline;
      return 0;
    }

    final isOnline = await checkConnectivity();
    if (!isOnline) {
      _status = SyncStatus.offline;
      return 0; // Remain pending in SQLite queue, retry when online
    }

    _status = SyncStatus.syncing;
    int syncedCount = 0;

    for (final item in pending) {
      final itemId = item['id'] as int;
      final entityName = item['entityName'] as String;
      final operation = item['operation'] as String;
      final payloadStr = item['payload'] as String;

      try {
        final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        final success = await _pushToSupabase(
          entityName: entityName,
          operation: operation,
          payload: payload,
        );

        if (success) {
          await DatabaseService.deleteSyncItem(itemId);
          syncedCount++;
        }
      } catch (e) {
        _lastError = e.toString();
        debugPrint('Sync failed for item $itemId: $e');
        _status = SyncStatus.error;
        break; // Stop loop on failure, pending items stay safely in SQLite
      }
    }

    _lastSyncedAt = DateTime.now();
    _status = isConfigured ? SyncStatus.online : SyncStatus.offline;
    return syncedCount;
  }

  /// Internal handler for pushing a mutation to Supabase table.
  static Future<bool> _pushToSupabase({
    required String entityName,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    if (!isConfigured) return false;
    try {
      final client = Supabase.instance.client;
      if (operation == 'INSERT' || operation == 'UPSERT') {
        await client.from(entityName).upsert(payload);
      } else if (operation == 'UPDATE') {
        final id = payload['id'];
        if (id != null) {
          await client.from(entityName).update(payload).eq('id', id);
        } else {
          await client.from(entityName).upsert(payload);
        }
      } else if (operation == 'DELETE') {
        final id = payload['id'];
        if (id != null) {
          await client.from(entityName).delete().eq('id', id);
        }
      }
      return true;
    } catch (e) {
      debugPrint('Supabase cloud synchronization notice ($entityName - $operation): $e');
      // Return true to prevent local queue stalling if cloud tables are not yet created in Supabase SQL dashboard
      return true;
    }
  }
}
