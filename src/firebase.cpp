#include "firebase.h"
#include <WiFi.h>

// Define global variables declared in firebase.h
String wifiSsid = "";
String wifiPassword = "";
String wifiUsername = "";
String firebaseToken = "";
String userId = "";

bool wifiConnected = false;
bool firebaseConnected = false;
unsigned long lastWiFiCheckTime = 0;

int BPM = 0;  // Define the global BPM variable

Firebase_ESP_Client firebase;
FirebaseAuth auth;
FirebaseConfig config;

bool trackingEnabled = false;
WiFiMode currentWiFiMode = UNKNOWN_WIFI;

// Time variables
const char* ntpServer = "pool.ntp.org";
const long gmtOffset_sec = -5 * 3600;  // Eastern Time (UTC-5)
const int daylightOffset_sec = 3600;

// Battery monitoring variables
unsigned long lastBatteryReadTime = 0;
int batteryPercentage = 0;
float batteryVoltage = 0.0;

// Function to setup Firebase
void setupFirebase(String firebaseToken, String userId) {
    Serial.println("Connecting to Firebase realtime database...");
    config.api_key = API_KEY;
    config.database_url = FIREBASE_HOST;
    auth.token.uid = userId.c_str();
    config.signer.tokens.legacy_token = firebaseToken.c_str();
    Firebase.begin(&config, &auth);
    int retry = 0;
    while (!Firebase.ready() && retry < 10) {
        Serial.print("Waiting for Firebase to be ready... Attempt ");
        Serial.println(retry + 1);
        delay(1000);
        retry++;
    }
    if (Firebase.ready()) {
        Serial.println("Successfully initialized Firebase with custom token.");
        firebaseConnected = true;
    } else {
        Serial.println("Failed to initialize Firebase.");
        firebaseConnected = false;
    }
    Firebase.reconnectWiFi(true);
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    Serial.println("Firebase initialized with Firebase-ESP-Client library.");
}

// Function to check tracking status
void checkTrackingStatus(String userId) {
    String path = "/users/";
    path.concat(userId);
    path.concat("/trackingEnabled");
    FirebaseData fbdo;
    if (Firebase.RTDB.getBool(&fbdo, path.c_str())) {
        trackingEnabled = fbdo.to<bool>();
        Serial.print("Tracking status: ");
        Serial.println(trackingEnabled ? "Enabled" : "Disabled");
    } else {
        Serial.println("Failed to check tracking status: Unknown error");
    }
}

// Function to send current heart rate to Firebase
void sendCurrentHeartRateToFirebase(int bpm, String userId) {
    String path = "/users/";
    path.concat(userId);
    path.concat("/heartRate/current");
    FirebaseJson json;
    json.add("bpm", bpm);
    json.add("timestamp", getTime());
    FirebaseData fbdo;
    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
        Serial.println("Current heart rate sent to Firebase successfully.");
    } else {
        Serial.println("Failed to send current heart rate: Unknown error");
    }
}

// Function to send heart rate stats to Firebase
void sendStatsToFirebase(int low, int avg, int high, String userId) {
    String path = "/users/";
    path.concat(userId);
    path.concat("/heartRate/stats");
    FirebaseJson json;
    json.add("low", low);
    json.add("average", avg);
    json.add("high", high);
    json.add("timestamp", getTime());
    FirebaseData fbdo;
    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
        Serial.println("Heart rate stats sent to Firebase successfully.");
    } else {
        Serial.println("Failed to send heart rate stats: Unknown error");
    }
}

// Function to send GPS data to Firebase
void sendToFirebase(double lat, double lng, double alt, int satellites, double hdop, String timestamp, String userId) {
    String path = "/users/";
    path.concat(userId);
    path.concat("/location");
    FirebaseJson json;
    json.add("latitude", String(lat, 6));
    json.add("longitude", String(lng, 6));
    json.add("altitude", String(alt, 2));
    json.add("satellites", satellites);
    json.add("hdop", String(hdop, 2));
    json.add("timestamp", timestamp);
    FirebaseData fbdo;
    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
        Serial.println("GPS data sent to Firebase successfully.");
    } else {
        Serial.println("Failed to send GPS data: Unknown error");
    }
}

// Function to send battery data to Firebase
void sendBatteryToFirebase(float voltage, int percentage, String userId) {
    String path = "/users/";
    path.concat(userId);
    path.concat("/battery");
    FirebaseJson json;
    json.add("voltage", String(voltage, 2));
    json.add("percentage", percentage);
    json.add("timestamp", getTime());
    FirebaseData fbdo;
    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {
        Serial.println("Battery data sent to Firebase successfully.");
    } else {
        Serial.println("Failed to send battery data: Unknown error");
    }
}

// Function to get current time as string
String getTime() {
    struct tm timeinfo;
    char buffer[30];
    if (!getLocalTime(&timeinfo)) {
        Serial.println("Failed to obtain time");
        return "Unknown";
    }
    strftime(buffer, sizeof(buffer), "%Y-%m-%d %H:%M:%S", &timeinfo);
    return String(buffer);
}

// Function to scan Wi-Fi networks
void scanWiFiNetworks() {
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    delay(100);
    Serial.println("Scanning for Wi-Fi networks...");
    int n = WiFi.scanNetworks();
    Serial.print(n);
    Serial.println(" networks found:");
    for (int i = 0; i < n; i++) {
        Serial.print(i + 1);
        Serial.print(": ");
        Serial.print(WiFi.SSID(i).c_str());
        Serial.print(" (RSSI: ");
        Serial.print(WiFi.RSSI(i));
        Serial.println(" dBm)");
        if (WiFi.SSID(i) == "iRent @ 2121 St Mathieu") {
            currentWiFiMode = HOME_WIFI;
        } else if (WiFi.SSID(i).indexOf("eduroam") != -1) {
            currentWiFiMode = SCHOOL_WIFI;
        }
    }
    if (currentWiFiMode == UNKNOWN_WIFI) {
        Serial.println("No known Wi-Fi networks found.");
    }
}

// Function to connect to Wi-Fi (simplified to WPA2-Personal)
void connectToWiFi(const char* ssid, const char* password, const char* username) {
    Serial.println("Connecting to Wi-Fi...");
    WiFi.disconnect(true);
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password); // Simplified to WPA2-Personal
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println();
        Serial.println("WiFi connected!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        wifiConnected = true;
    } else {
        Serial.println();
        Serial.println("Failed to connect to WiFi.");
        wifiConnected = false;
    }
}

// Function to check Wi-Fi connection
void checkWiFiConnection() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi connection lost. Attempting to reconnect...");
        if (wifiSsid.length() > 0 && wifiPassword.length() > 0) {
            connectToWiFi(wifiSsid.c_str(), wifiPassword.c_str(), wifiUsername.length() > 0 ? wifiUsername.c_str() : nullptr);
        }
    } else {
        wifiConnected = true;
    }
}

// Function to display Wi-Fi status
void displayWiFiStatus() {
    Serial.println("Checking WiFi status...");
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("WiFi Connected");
    } else {
        Serial.println("WiFi Disconnected");
    }
}

// Function to print local time
void printLocalTime() {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        Serial.println("Failed to obtain time");
        return;
    }
    char buffer[30];
    strftime(buffer, sizeof(buffer), "Current time: %Y-%m-%d %H:%M:%S", &timeinfo);
    Serial.println(buffer);
}

// Function to update battery status
void updateBatteryStatus(String userId) {
    uint16_t adcRaw = analogRead(BATTERY_PIN);
    float voltage = ((adcRaw / 4095.0) * 3.3 * VOLTAGE_DIVIDER_RATIO) * ADC_CORRECTION_FACTOR;
    batteryVoltage = voltage;
    float percentage = ((voltage - MIN_BATTERY_VOLTAGE) / (MAX_BATTERY_VOLTAGE - MIN_BATTERY_VOLTAGE)) * 100.0;
    percentage = constrain(percentage, 0, 100);
    batteryPercentage = (int)percentage;
    Serial.print("🔋 Battery: ADC=");
    Serial.print(adcRaw);
    Serial.print(", Voltage=");
    Serial.print(voltage, 2);
    Serial.print("V, Percentage=");
    Serial.print(batteryPercentage);
    Serial.println("%");
    if (firebaseConnected) {
        sendBatteryToFirebase(voltage, batteryPercentage, userId);
    }
}