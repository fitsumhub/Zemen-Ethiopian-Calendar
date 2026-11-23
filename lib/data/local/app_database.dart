import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/event_entity.dart';

class AppDatabase {
  static const String databaseName = 'ethiocal_database.db';
  static const int databaseVersion = 1;
  static const String tableName = 'events';

  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._();

  static AppDatabase get instance => _instance ??= AppDatabase._();

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            ethiopianYear INTEGER NOT NULL,
            ethiopianMonth INTEGER NOT NULL,
            ethiopianDay INTEGER NOT NULL,
            gregorianYear INTEGER NOT NULL,
            gregorianMonth INTEGER NOT NULL,
            gregorianDay INTEGER NOT NULL,
            hour INTEGER NOT NULL,
            minute INTEGER NOT NULL,
            isAllDay INTEGER NOT NULL,
            recurrence TEXT NOT NULL,
            reminderMinutesBefore INTEGER NOT NULL,
            colorHex TEXT NOT NULL,
            isCompleted INTEGER NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<EventEntity>> getAllEvents() async {
    final db = await database;
    final maps = await db.query(
      tableName,
      orderBy: 'gregorianYear ASC, gregorianMonth ASC, gregorianDay ASC, hour ASC, minute ASC',
    );
    return maps.map((m) => EventEntity.fromMap(m)).toList();
  }

  Future<List<EventEntity>> getEventsForEthiopianMonth(int year, int month) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'ethiopianYear = ? AND ethiopianMonth = ?',
      whereArgs: [year, month],
      orderBy: 'ethiopianDay ASC, hour ASC',
    );
    return maps.map((m) => EventEntity.fromMap(m)).toList();
  }

  Future<List<EventEntity>> getEventsForEthiopianDay(int year, int month, int day) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'ethiopianYear = ? AND ethiopianMonth = ? AND ethiopianDay = ?',
      whereArgs: [year, month, day],
      orderBy: 'hour ASC, minute ASC',
    );
    return maps.map((m) => EventEntity.fromMap(m)).toList();
  }

  Future<List<EventEntity>> searchEvents(String query) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'gregorianYear DESC',
    );
    return maps.map((m) => EventEntity.fromMap(m)).toList();
  }

  Future<EventEntity?> getEventById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EventEntity.fromMap(maps.first);
  }

  Future<int> insertEvent(EventEntity event) async {
    final db = await database;
    return await db.insert(
      tableName,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateEvent(EventEntity event) async {
    final db = await database;
    return await db.update(
      tableName,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(EventEntity event) async {
    return deleteEventById(event.id);
  }

  Future<int> deleteEventById(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
