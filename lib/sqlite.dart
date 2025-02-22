import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'model.dart';

class Sqlite {
  static final String tableName = 'data_points';
  static final String columnId = 'id';
  static final String columnTimestamp = 'timestamp';
  static final String columnDownload = 'download_speed';
  static final String columnUpload = 'upload_speed';

  // Some kind of Singleton pattern I guess.
  static final Sqlite _instance = Sqlite._internal();

  Sqlite._internal();

  factory Sqlite() => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'speed_test.db');
      _database = await openDatabase(path, version: 1, onCreate: createTables);
    }
    return _database!;
  }

  Future<void> createTables(Database db, int version) async {
    print('sqlite: creating table');
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTimestamp INTEGER NOT NULL,
        $columnDownload REAL NOT NULL,
        $columnUpload REAL NOT NULL
      )
    ''');
  }

  Future<List<DataPoint>> getAllDataPoints() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    print('sqlite: loaded ${maps.length} data points');
    return List.generate(maps.length, (i) {
      return DataPoint.fromMap(maps[i]);
    });
  }

  Future<int> insertDataPoint(DataPoint dataPoint) async {
    print('sqlite: saving datapoint ${dataPoint.toMap()}');
    final db = await database;
    return await db.insert(
      tableName,
      dataPoint.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
