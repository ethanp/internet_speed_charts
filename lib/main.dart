import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speed_test_dart/classes/settings.dart';
import 'package:speed_test_dart/speed_test_dart.dart';

import 'model.dart';
import 'my_line_chart.dart';
import 'sqlite.dart';
import 'util.dart';

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
    Settings? settings;
    try {
      settings = await tester.getSettings();
    } catch (e) {
      print('error: ${e.runtimeType} $e');
      setState(() {
        final dataPoint = DataPoint(DateTime.now(), -25, -25);
        dataPoints.add(dataPoint);
        Sqlite().insertDataPoint(dataPoint);
      });
      return;
    }
    final bestServers = await tester.getBestServers(servers: settings.servers);
    final downloadRate = await tester.testDownloadSpeed(
      servers: bestServers,
      simultaneousDownloads: 8,
    );
    final uploadRate = await tester.testUploadSpeed(
      servers: bestServers,
      simultaneousUploads: 8,
    );
    setState(() {
      final dataPoint = DataPoint(DateTime.now(), downloadRate, uploadRate);
      dataPoints.add(dataPoint);
      Sqlite().insertDataPoint(dataPoint);
    });
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
              : MyLineChart(dataPoints),
        ),
        startStopButtons(),
      ]),
    );
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
}
