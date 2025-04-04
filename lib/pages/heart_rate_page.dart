// File: heart_rate_page.dart (Updated for Realtime Database + Trends)

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pawtrack/pages/heart_rate_trends_page.dart';

class HeartRatePage extends StatefulWidget {
  final String petName;

  const HeartRatePage({super.key, required this.petName});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  double currentBPM = 0.0;
  double averageBPM = 0.0;
  double lowBPM = 0.0;
  double highBPM = 0.0;
  bool trackingEnabled = false;
  List<double> bpmHistory = [];

  final db = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    listenToHeartRate();
  }

  void listenToHeartRate() {
    db.child("heartrate").onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          currentBPM = (data['current_bpm'] ?? 0).toDouble();
          lowBPM = (data['stats']?['low_bpm'] ?? 0).toDouble();
          averageBPM = (data['stats']?['avg_bpm'] ?? 0).toDouble();
          highBPM = (data['stats']?['high_bpm'] ?? 0).toDouble();

          if (trackingEnabled) {
            bpmHistory.add(currentBPM);
            if (bpmHistory.length > 50) bpmHistory.removeAt(0);
          }
        });
      }
    });
  }

  void updateTrackingStatus(bool enable) async {
    await db.child("sensor/tracking").set(enable);
    setState(() => trackingEnabled = enable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.petName}'s Heart Rate"),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBPMCard('Current:', currentBPM),
            _buildBPMCard('Low:', lowBPM),
            _buildBPMCard('Average:', averageBPM),
            _buildBPMCard('High:', highBPM),
            const SizedBox(height: 50),
            Row(
              children: [
                _buildTrackingButton('Start Tracking', true),
                const Spacer(),
                _buildTrackingButton('Stop Tracking', false),
              ],
            ),
            const SizedBox(height: 20),
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
                      bpmHistory: bpmHistory,
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

  Widget _buildBPMCard(String label, double bpmValue) {
    return Container(
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
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('${bpmValue.toStringAsFixed(1)} BPM', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTrackingButton(String label, bool start) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      onPressed: () => updateTrackingStatus(start),
      child: Text(label),
    );
  }
}
