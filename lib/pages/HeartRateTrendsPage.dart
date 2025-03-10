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
    // Determine if dark mode is active
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("$petName's Heart Rate Trends"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Consistent with other pages
      ),
      backgroundColor: Theme.of(context).colorScheme.surface, // White (light) or Black (dark)
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Heart Rate Overview",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16), // Added spacing for better layout
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        "Heart Rate (BPM)",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true, // Show BPM values on Y-axis
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        "Time",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      sideTitles: const SideTitles(showTitles: false), // Hide X-axis labels for simplicity
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(1, lowBPM),    // Low BPM
                        FlSpot(2, averageBPM), // Average BPM
                        FlSpot(3, currentBPM), // Current BPM
                        FlSpot(4, highBPM),   // High BPM
                      ],
                      isCurved: true, // Smoother line for better visuals
                      color: Theme.of(context).colorScheme.primary, // Pink.shade300
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Subtle fill
                      ),
                    ),
                  ],
                  borderData: FlBorderData(
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
                      left: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.secondary, // Grey.shade400 (light) or Grey.shade700 (dark)
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.secondary,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  minY: lowBPM - 10, // Add padding below lowest value
                  maxY: highBPM + 10, // Add padding above highest value
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
