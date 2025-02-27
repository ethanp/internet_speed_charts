import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'model.dart';
import 'util.dart';

class MyLineChart extends StatelessWidget {
  const MyLineChart(this.dataPoints);

  final List<DataPoint> dataPoints;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: dataPoints.fold(350.0, (acc, pt) => math.max(acc, pt.max)) + 50,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(),
              bottom: BorderSide(),
            ),
          ),
          lineBarsData: dataLines(),
          titlesData: axisLabels(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => items.map((e) {
                      final dateTime =
                          DateTime.fromMillisecondsSinceEpoch(e.x.toInt());
                      final String time = TimeHelpers.hms(dateTime);
                      return LineTooltipItem('$time ${e.y}', TextStyle());
                    }).toList()),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> dataLines() {
    return [
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
      LineChartBarData(
        spots: dataPoints
            .map(
              (point) => FlSpot(
                point.timestamp.millisecondsSinceEpoch.toDouble(),
                point.uploadSpeed,
              ),
            )
            .toList(),
        isCurved: true,
        curveSmoothness: .25,
        color: Colors.green[800],
        barWidth: 2,
      ),
    ];
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
