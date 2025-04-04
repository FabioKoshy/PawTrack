import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pawtrack/pages/heart_rate_trends_page.dart';

class HeartRatePage extends StatefulWidget {
  final String petName;
  final String petId;

  const HeartRatePage({
    super.key,
    required this.petName,
    required this.petId,
  });

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  double currentBPM = 0.0;
  double averageBPM = 0.0;
  double lowBPM = 0.0;
  double highBPM = 0.0;
  bool trackingEnabled = false;
  bool isLoading = true;
  bool isSnackBarVisible = false;
  List<double> bpmHistory = [];

  // Threshold values with defaults
  int minThreshold = 60;
  int maxThreshold = 140;
  bool isThresholdLoading = false;

  final db = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
    listenToHeartRate();
    _loadThresholds();
  }

  void _loadThresholds() {
    final thresholdRef = db.child("settings/${widget.petId}/heartRate/thresholds");
    thresholdRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          minThreshold = data['min'] ?? 60;
          maxThreshold = data['max'] ?? 140;
        });
        debugPrint("Loaded thresholds: Min: $minThreshold, Max: $maxThreshold");
      }
    }, onError: (error) {
      debugPrint("Error loading thresholds: $error");
    });
  }

  Future<void> _saveThresholds() async {
    setState(() {
      isThresholdLoading = true;
    });

    try {
      await db.child("settings/${widget.petId}/heartRate/thresholds").set({
        'min': minThreshold,
        'max': maxThreshold,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Heart rate thresholds saved"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving thresholds: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isThresholdLoading = false;
      });
    }
  }

  void _checkTrackingStatus() {
    db.child("sensor/tracking").onValue.listen((event) {
      final data = event.snapshot.value;
      setState(() {
        trackingEnabled = data == true;
        isLoading = false;
      });
      debugPrint("Tracking status retrieved: $trackingEnabled");
    }, onError: (error) {
      debugPrint("Error retrieving tracking status: $error");
      setState(() {
        isLoading = false;
      });
    });
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

          if (trackingEnabled && currentBPM > 0) {
            bpmHistory.add(currentBPM);
            debugPrint("Added to bpmHistory: $currentBPM, size: ${bpmHistory.length}");
            if (bpmHistory.length > 50) bpmHistory.removeAt(0);

            // Check thresholds and update status
            _checkHeartRateAgainstThresholds(currentBPM);
          }
        });
      }
    });
  }

  void _checkHeartRateAgainstThresholds(double heartRate) {
    String status = "normal";

    if (heartRate < minThreshold) {
      status = "tooLow";
    } else if (heartRate > maxThreshold) {
      status = "tooHigh";
    }

    // Update status in Firebase
    db.child("petStatus/${widget.petId}/heartRate/status").set(status);
  }

  Future<void> updateTrackingStatus(bool enable) async {
    setState(() {
      isLoading = true;
      isSnackBarVisible = true;
    });

    try {
      await db.child("sensor/tracking").set(enable);
      setState(() {
        trackingEnabled = enable;
        // Clear history when stopping tracking
        if (!enable) {
          bpmHistory.clear();
          // Reset status to normal when tracking stops
          db.child("petStatus/${widget.petId}/heartRate/status").set("normal");
        }
      });

      if (mounted) {
        // Show SnackBar and set a timer to mark it as hidden
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(enable
                ? "Starting heart rate tracking..."
                : "Stopping heart rate tracking..."),
            backgroundColor: enable ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        )
            .closed
            .then((_) {
          // When SnackBar is dismissed, update the flag
          if (mounted) {
            setState(() {
              isSnackBarVisible = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating tracking status: $e"),
            backgroundColor: Colors.red,
          ),
        ).closed.then((_) {
          if (mounted) {
            setState(() {
              isSnackBarVisible = false;
            });
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          // Note: We don't reset isSnackBarVisible here because we want it to stay true
          // until the SnackBar is dismissed
        });
      }
    }
  }

  void _showThresholdInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Heart Rate Thresholds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The minimum and maximum values must be at least 80 BPM apart.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'It is recommended to consult a veterinarian or do some online research to determine the ideal heart rate range for your pet.',
            ),
            const SizedBox(height: 15),
            const Text(
              'Current settings:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Minimum: $minThreshold BPM'),
            Text('Maximum: $maxThreshold BPM'),
            const SizedBox(height: 10),
            Text(
              'Maximum limit: ${(highBPM + 80).toInt()} BPM (based on highest reading)',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
    );
  }

  void _adjustThreshold(bool isMin, bool isIncrement) {
    // Calculate the maximum allowed value for the maximum threshold
    int maxAllowedThreshold = (highBPM + 80).toInt();

    if (isMin) {
      if (isIncrement) {
        // Increasing min, check if it would get too close to max
        if (maxThreshold - (minThreshold + 1) < 80) {
          _isLongPressing = false; // Stop continuous adjustment
          _showThresholdConstraintDialog();
          return;
        }
        setState(() => minThreshold++);
      } else {
        // Decreasing min, don't allow below 0
        setState(() => minThreshold = minThreshold > 0 ? minThreshold - 1 : 0);
      }
    } else {
      if (isIncrement) {
        // Increasing max, don't allow above maxAllowedThreshold
        setState(() => maxThreshold = maxThreshold < maxAllowedThreshold ? maxThreshold + 1 : maxAllowedThreshold);
      } else {
        // Decreasing max, check if it would get too close to min
        if ((maxThreshold - 1) - minThreshold < 80) {
          _isLongPressing = false; // Stop continuous adjustment
          _showThresholdConstraintDialog();
          return;
        }
        setState(() => maxThreshold--);
      }
    }
  }

  // For continuous adjustment (long press)
  void _startContinuousAdjustment(bool isMin, bool isIncrement) {
    const initialDelay = Duration(milliseconds: 500);

    Future.delayed(initialDelay, () {
      _continuousAdjustment(isMin, isIncrement);
    });
  }

  void _continuousAdjustment(bool isMin, bool isIncrement) {
    if (!_isLongPressing) return;

    _adjustThreshold(isMin, isIncrement);

    Future.delayed(const Duration(milliseconds: 100), () {
      _continuousAdjustment(isMin, isIncrement);
    });
  }

  bool _isLongPressing = false;

  void _showThresholdConstraintDialog() {
    // Stop continuous adjustment immediately
    _isLongPressing = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Threshold Constraint'),
        content: const Text(
          'The minimum and maximum heart rate thresholds must be at least 80 BPM apart to avoid false alerts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.petName}'s Heart Rate"),
        backgroundColor: primaryColor.withOpacity(0.2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBPMCard('Current:', currentBPM, trackingEnabled),
            _buildBPMCard('Low:', lowBPM, trackingEnabled),
            _buildBPMCard('Average:', averageBPM, trackingEnabled),
            _buildBPMCard('High:', highBPM, trackingEnabled),
            const SizedBox(height: 30),
            // Threshold Controls
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: primaryColor.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Heart Rate Thresholds',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: primaryColor),
                          onPressed: _showThresholdInfoDialog,
                          tooltip: 'Threshold Information',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Minimum',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onLongPress: () {
                                      _isLongPressing = true;
                                      _startContinuousAdjustment(true, false);
                                    },
                                    onLongPressEnd: (_) {
                                      _isLongPressing = false;
                                    },
                                    child: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.orange),
                                      onPressed: () => _adjustThreshold(true, false),
                                    ),
                                  ),
                                  Text(
                                    '$minThreshold BPM',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  GestureDetector(
                                    onLongPress: () {
                                      _isLongPressing = true;
                                      _startContinuousAdjustment(true, true);
                                    },
                                    onLongPressEnd: (_) {
                                      _isLongPressing = false;
                                    },
                                    child: IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.green),
                                      onPressed: () => _adjustThreshold(true, true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Maximum',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onLongPress: () {
                                      _isLongPressing = true;
                                      _startContinuousAdjustment(false, false);
                                    },
                                    onLongPressEnd: (_) {
                                      _isLongPressing = false;
                                    },
                                    child: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.orange),
                                      onPressed: () => _adjustThreshold(false, false),
                                    ),
                                  ),
                                  Text(
                                    '$maxThreshold BPM',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  GestureDetector(
                                    onLongPress: () {
                                      _isLongPressing = true;
                                      _startContinuousAdjustment(false, true);
                                    },
                                    onLongPressEnd: (_) {
                                      _isLongPressing = false;
                                    },
                                    child: IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.green),
                                      onPressed: () => _adjustThreshold(false, true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isThresholdLoading ? null : _saveThresholds,
                        child: isThresholdLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Save Thresholds'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _buildTrackingButton(
                  'Start Tracking',
                  true,
                  trackingEnabled || isLoading,
                ),
                const Spacer(),
                _buildTrackingButton(
                  'Stop Tracking',
                  false,
                  !trackingEnabled || isLoading,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                debugPrint("Navigating to HeartRateTrendsPage with ${bpmHistory.length} data points");

                // If no data, provide sample data
                List<double> dataToUse = bpmHistory;
                if (dataToUse.isEmpty) {
                  debugPrint("BPM history is empty, using sample data");
                  dataToUse = [75.0, 78.0, 80.0, 82.0, 79.0, 77.0];
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeartRateTrendsPage(
                      petName: widget.petName,
                      bpmHistory: dataToUse,
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

  Widget _buildBPMCard(String label, double bpmValue, bool isTrackingEnabled) {
    // Determine if the current value is outside thresholds (for current BPM only)
    Color valueColor = Theme.of(context).colorScheme.primary;
    bool isOutsideThreshold = false;

    if (label == 'Current:' && isTrackingEnabled && bpmValue > 0) {
      if (bpmValue < minThreshold) {
        valueColor = Colors.blue; // Too low
        isOutsideThreshold = true;
      } else if (bpmValue > maxThreshold) {
        valueColor = Colors.red; // Too high
        isOutsideThreshold = true;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: isTrackingEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            width: 2
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTrackingEnabled ? null : Colors.grey,
              )
          ),
          Text(
              isTrackingEnabled
                  ? '${bpmValue.toStringAsFixed(1)} BPM'
                  : 'N/A',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isOutsideThreshold ? FontWeight.bold : FontWeight.normal,
                color: isTrackingEnabled
                    ? (bpmValue > 0 ? valueColor : Colors.grey)
                    : Colors.grey,
              )
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingButton(String label, bool start, bool disabled) {
    // Modify the disabled condition to include isSnackBarVisible
    bool isDisabled = disabled || isSnackBarVisible;
    final buttonColor = start ? Colors.green : Colors.orange;
    final disabledColor = buttonColor.withOpacity(0.3);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: disabledColor,
        disabledForegroundColor: Colors.white70,
      ),
      onPressed: isDisabled ? null : () => updateTrackingStatus(start),
      child: Text(label),
    );
  }
}