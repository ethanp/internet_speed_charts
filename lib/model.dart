import 'dart:math' as math;

import 'sqlite.dart';

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
