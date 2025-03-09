import 'package:flutter/material.dart';
import 'package:pawtrack/pages/HeartRateTrendsPage.dart';

class HeartRatePage extends StatefulWidget {
  final String petName;

  const HeartRatePage({super.key, required this.petName});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  double currentBPM = 75.0;
  double averageBPM = 70.0;
  double lowBPM = 30.0;
  double highBPM = 90.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.petName}'s Heart Rate"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Reference style
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${currentBPM.toStringAsFixed(1)} BPM', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Low:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${lowBPM.toStringAsFixed(1)} BPM', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Average:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${averageBPM.toStringAsFixed(1)} BPM', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('High:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${highBPM.toStringAsFixed(1)} BPM', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 50), // Reduced space to fit the new button
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Add functionality for "Start Tracking" button
                  },
                  child: const Text("Start Tracking"),
                ),
                const Spacer(), // Pushes the next widget to the right
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Add functionality for "Stop Tracking" button
                  },
                  child: const Text("Stop Tracking"),
                ),
              ],
            ),
            const SizedBox(height: 20), // Space between the two buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeartRateTrendsPage(
                      petName: widget.petName,
                      currentBPM: currentBPM,
                      lowBPM: lowBPM,
                      averageBPM: averageBPM,
                      highBPM: highBPM,
                    ),
                  ),
                );
              },
              child: const Text("Trends"),
            ),
          ],
        ),
      ),
    );
  }
}