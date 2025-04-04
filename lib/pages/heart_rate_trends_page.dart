import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HeartRateTrendsPage extends StatelessWidget {
  final String petName;
  final List<double> bpmHistory;

  const HeartRateTrendsPage({
    super.key,
    required this.petName,
    required this.bpmHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("$petName's Heart Rate Trends"),
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Heart Rate Overview",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        "Heart Rate (BPM)",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        "Time",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      sideTitles: const SideTitles(showTitles: true),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: bpmHistory
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                          .toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                  borderData: FlBorderData(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.inversePrimary),
                      left: BorderSide(color: theme.colorScheme.inversePrimary),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                  ),
                  minY: bpmHistory.isNotEmpty ? bpmHistory.reduce((a, b) => a < b ? a : b) - 10 : 0,
                  maxY: bpmHistory.isNotEmpty ? bpmHistory.reduce((a, b) => a > b ? a : b) + 10 : 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}