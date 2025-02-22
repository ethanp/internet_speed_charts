import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:sqflite/sqflite.dart';

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
    print('sqlite: saving datapoint');
    final db = await database;
    return await db.insert(
      tableName,
      dataPoint.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dataPoints = await dbHelper.getAllDataPoints();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bandwidth Monitor',
      debugShowCheckedModeBanner: false,
      home: BandwidthMonitor(),
    );
  }
}

// Initialize database and load existing data
final dbHelper = Sqlite();
List<DataPoint> dataPoints = [];

class DataPoint {
  final DateTime timestamp;
  final double downloadSpeed;
  final double uploadSpeed;

  DataPoint(this.timestamp, this.downloadSpeed, this.uploadSpeed);

  // Convert DataPoint to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      Sqlite.columnTimestamp: timestamp.millisecondsSinceEpoch,
      Sqlite.columnDownload: downloadSpeed,
      Sqlite.columnUpload: uploadSpeed,
    };
  }

  // Create DataPoint from a database row
  factory DataPoint.fromMap(Map<String, dynamic> map) {
    return DataPoint(
      DateTime.fromMillisecondsSinceEpoch(map[Sqlite.columnTimestamp]),
      map[Sqlite.columnDownload],
      map[Sqlite.columnUpload],
    );
  }

  double get max => math.max(downloadSpeed, uploadSpeed);
}

class BandwidthMonitor extends StatefulWidget {
  @override
  State<BandwidthMonitor> createState() => _BandwidthMonitorState();
}

class _BandwidthMonitorState extends State<BandwidthMonitor> {
  Timer? _timer;
  bool isTesting = false;

  Future<void> performSpeedTest() async {
    print('${TimeHelpers.mdyHms(DateTime.now())} performing speed test');
    final tester = SpeedTestDart();
    final settings = await tester.getSettings();
    final bestServers = await tester.getBestServers(servers: settings.servers);
    final downloadRate = await tester.testDownloadSpeed(servers: bestServers);
    final uploadRate = await tester.testUploadSpeed(servers: bestServers);
    setState(() {
      final dataPoint = DataPoint(DateTime.now(), downloadRate, uploadRate);
      dataPoints.add(dataPoint);
      Sqlite().insertDataPoint(dataPoint);
    });
    // Store results with timestamp for plotting
  }

  @override
  void dispose() {
    print('cancelling test timer (dispose)');
    _timer?.cancel();
    super.dispose();
  }

  void startTesting() {
    if (isTesting) return;
    setState(() => isTesting = true);
    _timer = Timer.periodic(Duration(seconds: 15), (_) => performSpeedTest());
    // Perform an initial test immediately
    performSpeedTest();
  }

  void stopTesting() {
    if (!isTesting) return;
    print('canceling timer (stop testing)');
    _timer?.cancel();
    setState(() => isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bandwidth Monitor')),
      body: Column(children: [
        Expanded(
          child: dataPoints.isEmpty
              ? Center(child: Text('No data available. Start the test.'))
              : lineChart(),
        ),
        startStopButtons(),
      ]),
    );
  }

  Widget appBody() {
    return Column(children: [
      Expanded(
        child: dataPoints.isEmpty
            ? Center(child: Text('No data available. Start the test.'))
            : lineChart(),
      ),
      startStopButtons(),
    ]);
  }

  Widget startStopButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: isTesting ? stopTesting : startTesting,
        child: Text('${isTesting ? 'Stop' : 'Start'} Testing'),
      ),
    );
  }

  Widget lineChart() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: dataPoints.fold(350.0, (acc, pt) => math.max(acc, pt.max)) + 50,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
              show: true,
              border: Border(left: BorderSide(), bottom: BorderSide())),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints
                  .map(
                    (point) => FlSpot(
                      point.timestamp.millisecondsSinceEpoch.toDouble(),
                      point.downloadSpeed,
                    ),
                  )
                  .toList(),
              isCurved: true,
              curveSmoothness: .25,
              color: Colors.blue,
              barWidth: 2,
            ),
            // Similar for upload speed
          ],
          titlesData: axisLabels(),
        ),
      ),
    );
  }

  FlTitlesData axisLabels() {
    return FlTitlesData(
      topTitles: noTitles(),
      rightTitles: noTitles(),
      bottomTitles: AxisTitles(
        axisNameSize: 22,
        axisNameWidget: Text('Time'),
        sideTitles: SideTitles(
          minIncluded: false,
          maxIncluded: false,
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              meta: meta,
              angle: .7,
              space: 4,
              child: Text(
                TimeHelpers.mdyHms(
                    DateTime.fromMillisecondsSinceEpoch(value.toInt())),
                style: TextStyle(color: Colors.black, fontSize: 10),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        axisNameSize: 22,
        axisNameWidget: Text('Mbps'),
        sideTitles: SideTitles(
          minIncluded: false,
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              meta: meta,
              space: 0,
              child: Text(
                meta.formattedValue,
                style: TextStyle(color: Colors.black, fontSize: 10),
              ),
            );
          },
        ),
      ),
    );
  }

  AxisTitles noTitles() {
    return AxisTitles(sideTitles: SideTitles(showTitles: false));
  }
}

class TimeHelpers {
  static final mdy = DateFormat('MM/dd/yy').format;
  static final hms = DateFormat('h:mm:ssa').format;
  static final mdyHms = DateFormat('MM/dd/yy h:mm:ssa').format;
}
