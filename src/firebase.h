#ifndef FIREBASE_H
#define FIREBASE_H

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <String.h>

// Declare global variables as extern
extern String wifiSsid;
extern String wifiPassword;
extern String wifiUsername;
extern String firebaseToken;
extern String userId;

extern bool wifiConnected;
extern bool firebaseConnected;
extern unsigned long lastWiFiCheckTime;

extern int BPM;  // Declare BPM as extern

// Firebase configuration
#define FIREBASE_HOST "pawtrack-1-default-rtdb.firebaseio.com"
#define API_KEY "AIzaSyDXG85MllBHAlkUcqSZoEAFu5J2OSuFCsc"

// Battery monitoring pin and constants
#define BATTERY_PIN 34
#define VOLTAGE_DIVIDER_RATIO 2.0
#define ADC_CORRECTION_FACTOR 1.0
#define MIN_BATTERY_VOLTAGE 3.0
#define MAX_BATTERY_VOLTAGE 4.2

// Wi-Fi mode enum
enum WiFiMode {
    UNKNOWN_WIFI,
    HOME_WIFI,
    SCHOOL_WIFI
};

// Declare functions
void setupFirebase(String firebaseToken, String userId);
void checkTrackingStatus(String userId);
void sendCurrentHeartRateToFirebase(int bpm, String userId);
void sendStatsToFirebase(int low, int avg, int high, String userId);
void sendToFirebase(double lat, double lng, double alt, int satellites, double hdop, String timestamp, String userId);
void sendBatteryToFirebase(float voltage, int percentage, String userId);
String getTime();
void scanWiFiNetworks();
void connectToWiFi(const char* ssid, const char* password, const char* username);
void checkWiFiConnection();
void displayWiFiStatus();
void printLocalTime();
void updateBatteryStatus(String userId);

#endif // FIREBASE_H