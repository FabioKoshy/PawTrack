#ifndef FIREBASE_H
#define FIREBASE_H

#include <WiFi.h>
#include <FirebaseESP32.h>

// WiFi Mode Enum
enum WiFiMode {
    HOME_WIFI,
    SCHOOL_WIFI,
    UNKNOWN_WIFI
};

// Firebase Objects
extern FirebaseData fbdo;
extern FirebaseAuth auth;
extern FirebaseConfig config;

// Shared Variables (Avoid Multiple Definitions)
extern int BPM;
extern int lowBPM, highBPM, sumBPM, bpmCount;
extern int bpmReadings[30];
extern int readingIndex;
extern bool trackingEnabled;

// Current WiFi Mode
extern WiFiMode currentWiFiMode;

// School Wi-Fi Credentials (WPA2-Enterprise for Concordia University)
#define SCHOOL_WIFI_SSID "ConcordiaUniversity"
#define SCHOOL_WIFI_USER "wa_jiach"
#define SCHOOL_WIFI_PASSWORD "Ljw010621!"

// // Home Wi-Fi Credentials (WPA2-Personal)
// #define HOME_WIFI_SSID "iRent @ 2121 St Mathieu"
// #define HOME_WIFI_PASSWORD "onaimecaici"

// Home Wi-Fi 2 Credentials (WPA2-Personal)
#define HOME_WIFI_SSID "Panda400"
#define HOME_WIFI_PASSWORD "5145958688"

// Firebase Credentials
#define FIREBASE_API_KEY "AIzaSyDXG85MllBHAlkUcqSZoEAFu5J2OSuFCsc"
#define FIREBASE_PROJECT_URL "pawtrack-1-default-rtdb.firebaseio.com"
#define USER_EMAIL "phoenixfabio7@gmail.com"
#define USER_PASSWORD "123456789"

// Function Declarations
void setupFirebase();
void autoConnectWiFi();
void connectToSchoolWiFi();
void connectToHomeWiFi();
void checkTrackingStatus();
void sendCurrentHeartRateToFirebase(int bpm);
void sendStatsToFirebase(int low, int avg, int high);
void sendToFirebase(double lat, double lng, double alt, int satellites, double hdop, String timestamp); // Added timestamp parameter

#endif