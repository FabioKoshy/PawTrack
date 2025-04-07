import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartMode { byDay, byWeek }

class HeartRateEntry {
  final DateTime timestamp;
  final double bpm;

  HeartRateEntry(this.timestamp, this.bpm);
}


class HeartRateTrendsPage extends StatefulWidget {
  final String petName;
  final List<HeartRateEntry> bpmHistory;

  const HeartRateTrendsPage({
    super.key,
    required this.petName,
    required this.bpmHistory,
  });

  @override
  State<HeartRateTrendsPage> createState() => _HeartRateTrendsPageState();
}

class _HeartRateTrendsPageState extends State<HeartRateTrendsPage> {
  ChartMode _selectedMode = ChartMode.byDay;

  List<double> _getWeeklyAverages(List<double> data) {
    final List<double> weekly = [];
    for (int i = 0; i < data.length; i += 7) {
      final weekSlice = data.sublist(i, i + 7 > data.length ? data.length : i + 7);
      final average = weekSlice.reduce((a, b) => a + b) / weekSlice.length;
      weekly.add(average);
    }
    return weekly;
  }

  List<FlSpot> _generateSpots() {
    final now = DateTime.now();
    final todayEntries = widget.bpmHistory
        .where((entry) =>
    entry.timestamp.year == now.year &&
        entry.timestamp.month == now.month &&
        entry.timestamp.day == now.day)
        .toList();

    final last20 = todayEntries.length <= 20
        ? todayEntries
        : todayEntries.sublist(todayEntries.length - 20);

    return last20.asMap().entries.map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.bpm),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final spots = _generateSpots();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.petName}'s Heart Rate Trends"),
        backgroundColor: primaryColor.withOpacity(0.2),
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [
                _selectedMode == ChartMode.byDay,
                _selectedMode == ChartMode.byWeek,
              ],
              onPressed: (index) {
                setState(() {
                  _selectedMode = ChartMode.values[index];
                });
              },
              borderRadius: BorderRadius.circular(12),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("By Day"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("By Week"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Heart Rate Overview (${_selectedMode == ChartMode.byDay ? "Daily" : "Weekly"})",
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
                        _selectedMode == ChartMode.byDay ? "Time of the day" : "Weeks",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(value.toInt().toString()),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: primaryColor,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  borderData: FlBorderData(
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.inversePrimary),
                      left: BorderSide(color: theme.colorScheme.inversePrimary),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  minY: spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10 : 0,
                  maxY: spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10 : 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
