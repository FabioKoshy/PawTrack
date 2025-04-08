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

  List<FlSpot> _generateWeeklySpots() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final Map<int, List<HeartRateEntry>> dailyEntries = {};

    for (var entry in widget.bpmHistory) {
      if (entry.timestamp.isAfter(sevenDaysAgo)) {
        final daysFromStart = entry.timestamp.difference(sevenDaysAgo).inDays;
        if (daysFromStart >= 0 && daysFromStart < 7) {
          dailyEntries.putIfAbsent(daysFromStart, () => []).add(entry);
        }
      }
    }


    final uniqueDays = dailyEntries.keys.length;
    if (uniqueDays < 7) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait until you have 7 days of data to view weekly trends.'),
            duration: Duration(seconds: 3),
          ),
        );
      });
      return [];
    }


    final List<FlSpot> spots = [];

    dailyEntries.forEach((day, entries) {

      entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (entries.isEmpty) return;


      final int entriesPerSegment = (entries.length / 3).ceil();

      for (int segment = 0; segment < 3; segment++) {
        final startIdx = segment * entriesPerSegment;
        final endIdx = (startIdx + entriesPerSegment) > entries.length
            ? entries.length
            : startIdx + entriesPerSegment;

        if (startIdx >= entries.length) continue;

        final segmentEntries = entries.sublist(startIdx, endIdx);
        final avgBpm = segmentEntries.fold(0.0, (sum, entry) => sum + entry.bpm) / segmentEntries.length;


        final xPos = day.toDouble() + (segment / 3);
        spots.add(FlSpot(xPos, avgBpm));
      }
    });

    return spots;
  }

  List<FlSpot> _generateSpots() {
    if (_selectedMode == ChartMode.byDay) {
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
    } else {
      return _generateWeeklySpots();
    }
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
                        _selectedMode == ChartMode.byDay ? "Time of the day" : "Days",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          _selectedMode == ChartMode.byWeek && value % 1 == 0
                              ? value.toInt().toString()
                              : value.toInt().toString(),
                        ),
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

