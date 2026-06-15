import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _storage = FlutterSecureStorage();
  Database? _db;

  Database get db {
    final value = _db;
    if (value == null) throw StateError('Database is not open');
    return value;
  }

  Future<void> open() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final key = await _databaseKey();
    _db = await openDatabase(
      p.join(dir.path, 'deepu_logger.db'),
      password: key,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedAdmin(db);
      },
    );
  }

  Future<String> _databaseKey() async {
    const name = 'deepu_logger_db_key';
    final existing = await _storage.read(key: name);
    if (existing != null) return existing;
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final value = base64UrlEncode(bytes);
    await _storage.write(key: name, value: value);
    return value;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  pin_hash TEXT,
  role TEXT NOT NULL,
  status TEXT NOT NULL,
  device_id TEXT NOT NULL,
  biometric_enabled INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE access_requests (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  reason TEXT,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  reviewed_at TEXT,
  reviewed_by TEXT
)''');
    await db.execute('''
CREATE TABLE stock_registers (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date TEXT NOT NULL,
  month_label TEXT NOT NULL,
  item_name TEXT NOT NULL,
  particulars TEXT NOT NULL,
  opening_qty REAL NOT NULL,
  opening_rate REAL NOT NULL,
  opening_amount REAL NOT NULL,
  receipt_qty REAL NOT NULL,
  receipt_rate REAL NOT NULL,
  receipt_amount REAL NOT NULL,
  total_qty REAL NOT NULL,
  total_rate REAL NOT NULL,
  total_amount REAL NOT NULL,
  issue_qty REAL NOT NULL,
  issue_rate REAL NOT NULL,
  issue_amount REAL NOT NULL,
  closing_qty REAL NOT NULL,
  closing_amount REAL NOT NULL,
  low_stock_threshold REAL NOT NULL DEFAULT 0,
  remarks TEXT,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE audit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  action TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT,
  metadata TEXT,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  method TEXT NOT NULL,
  path TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0
)''');
    await db.execute(
      'CREATE INDEX idx_stock_user_date ON stock_registers(user_id, entry_date)',
    );
    await db.execute(
      'CREATE INDEX idx_stock_item ON stock_registers(item_name)',
    );
  }

  Future<void> _seedAdmin(Database db) async {
    const adminEmail = String.fromEnvironment('DEEPU_ADMIN_EMAIL');
    const adminPassword = String.fromEnvironment('DEEPU_ADMIN_PASSWORD');
    if (adminEmail.isEmpty || adminPassword.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': 'admin-default',
      'email': adminEmail.trim().toLowerCase(),
      'name': 'DeepuLogger Admin',
      'password_hash': PasswordHasher.hash(adminPassword),
      'pin_hash': PasswordHasher.hash('123456'),
      'role': 'admin',
      'status': 'active',
      'device_id': 'seeded-device',
      'biometric_enabled': 0,
      'created_at': now,
      'updated_at': now,
    });
  }
}
