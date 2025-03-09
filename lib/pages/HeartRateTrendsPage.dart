import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HeartRateTrendsPage extends StatelessWidget {
  final String petName;
  final double currentBPM;
  final double lowBPM;
  final double averageBPM;
  final double highBPM;

  const HeartRateTrendsPage({
    super.key,
    required this.petName,
    required this.currentBPM,
    required this.lowBPM,
    required this.averageBPM,
    required this.highBPM,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$petName's Heart Rate Trends"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Heart Rate Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Heart Rate (BPM)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Time",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),

                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(1, lowBPM), // Low BPM
                        FlSpot(2, averageBPM), // Average BPM
                        FlSpot(3, currentBPM), // Current BPM
                        FlSpot(4, highBPM), // High BPM
                      ],
                      isCurved: false,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  borderData: FlBorderData(
                    border: const Border(
                      bottom: BorderSide(color: Colors.black),
                      left: BorderSide(color: Colors.black),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true, // Ensures vertical grid lines cover the graph
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey, // Set grid line color
                        strokeWidth: 1,     // Line thickness
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey, // Same color for vertical lines
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
