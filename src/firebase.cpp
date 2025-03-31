#include "firebase.h"
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <esp_wpa2.h>

// Firebase Objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Define shared variables
int BPM = 0;
int lowBPM = 0, highBPM = 0, sumBPM = 0, bpmCount = 0;
int bpmReadings[30] = {0};
int readingIndex = 0;
bool trackingEnabled = false;

// Current WiFi Mode
WiFiMode currentWiFiMode = UNKNOWN_WIFI;

// Function to connect to School WiFi (WPA2-Enterprise)
void connectToSchoolWiFi() {
    Serial.println("🔄 Attempting to connect to School WPA2-Enterprise WiFi...");
    
    WiFi.disconnect(true);
    WiFi.mode(WIFI_STA);
    
    esp_wifi_sta_wpa2_ent_set_identity((uint8_t *)SCHOOL_WIFI_USER, strlen(SCHOOL_WIFI_USER));
    esp_wifi_sta_wpa2_ent_set_username((uint8_t *)SCHOOL_WIFI_USER, strlen(SCHOOL_WIFI_USER));
    esp_wifi_sta_wpa2_ent_set_password((uint8_t *)SCHOOL_WIFI_PASSWORD, strlen(SCHOOL_WIFI_PASSWORD));
    esp_wifi_sta_wpa2_ent_enable();
    
    WiFi.begin(SCHOOL_WIFI_SSID);
    Serial.print("Connecting to School WiFi: ");
    Serial.println(SCHOOL_WIFI_SSID);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 15) {
        Serial.print(".");
        delay(1000);
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        currentWiFiMode = SCHOOL_WIFI;
        Serial.println("\n✅ Connected to School WiFi!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\n❌ Failed to connect to School WiFi.");
    }
}

// Function to connect to Home WiFi (WPA2-Personal)
void connectToHomeWiFi() {
    Serial.println("🔄 Attempting to connect to Home WiFi...");
    
    WiFi.disconnect(true);
    WiFi.mode(WIFI_STA);
    
    esp_wifi_sta_wpa2_ent_disable();
    
    WiFi.begin(HOME_WIFI_SSID, HOME_WIFI_PASSWORD);
    Serial.print("Connecting to Home WiFi: ");
    Serial.println(HOME_WIFI_SSID);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 15) {
        Serial.print(".");
        delay(1000);
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        currentWiFiMode = HOME_WIFI;
        Serial.println("\n✅ Connected to Home WiFi!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("\n❌ Failed to connect to Home WiFi.");
    }
}

// Function to automatically connect to the available WiFi network
void autoConnectWiFi() {
    WiFi.disconnect(true);
    WiFi.mode(WIFI_STA);
    
    Serial.println("🔎 Scanning for available networks...");
    int networkCount = WiFi.scanNetworks();
    
    if (networkCount == 0) {
        Serial.println("No networks found!");
        return;
    }
    
    bool homeNetworkFound = false;
    bool schoolNetworkFound = false;
    
    for (int i = 0; i < networkCount; i++) {
        String ssid = WiFi.SSID(i);
        Serial.print("Found network: ");
        Serial.println(ssid);
        
        if (ssid.equals(HOME_WIFI_SSID)) {
            homeNetworkFound = true;
        } else if (ssid.equals(SCHOOL_WIFI_SSID)) {
            schoolNetworkFound = true;
        }
    }
    
    WiFi.scanDelete();
    
    if (homeNetworkFound) {
        connectToHomeWiFi();
    }
    
    if (WiFi.status() != WL_CONNECTED && schoolNetworkFound) {
        connectToSchoolWiFi();
    }
    
    if (WiFi.status() != WL_CONNECTED && homeNetworkFound) {
        connectToHomeWiFi();
    }
    
    if (WiFi.status() != WL_CONNECTED) {
        currentWiFiMode = UNKNOWN_WIFI;
        Serial.println("❌ Failed to connect to any known WiFi network.");
    }
}

// Function to initialize Firebase
void setupFirebase() {
    Serial.println(" Initializing network connection...");

    autoConnectWiFi();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println(" WiFi is connected. Setting up Firebase...");
        config.api_key = FIREBASE_API_KEY;
        config.database_url = FIREBASE_PROJECT_URL;
        auth.user.email = USER_EMAIL;
        auth.user.password = USER_PASSWORD;

        Serial.println(" Calling Firebase.begin...");
        Firebase.begin(&config, &auth);
        Serial.println(" Firebase.begin called. Setting reconnectWiFi...");
        Firebase.reconnectWiFi(true);

        int retry = 0;
        while (!Firebase.ready() && retry < 10) {
            char buffer[64];
            sprintf(buffer, " Waiting for Firebase to be ready... Attempt %d", retry + 1);
            Serial.println(buffer);
            delay(1000);
            retry++;
        }

        if (Firebase.ready()) {
            Serial.println(" Connected to Firebase!");
        } else {
            char buffer[64];
            sprintf(buffer, " Firebase connection failed after %d retries.", retry);
            Serial.println(buffer);
            char errorBuffer[128];
            sprintf(errorBuffer, " Firebase error: %s", fbdo.errorReason().c_str());
            Serial.println(errorBuffer);
        }
    } else {
        Serial.println(" No WiFi connection. Cannot connect to Firebase.");
    }
}

// Function to check tracking status from Firebase
void checkTrackingStatus() {
    if (Firebase.getBool(fbdo, "/sensor/tracking")) {
        trackingEnabled = fbdo.boolData();
        Serial.printf("Tracking status: %s\n", trackingEnabled ? "ON" : "OFF");
    } else {
        Serial.printf("❌ Failed to get tracking status: %s\n", fbdo.errorReason().c_str());
    }
}

// Function to send current BPM to Firebase
void sendCurrentHeartRateToFirebase(int bpm) {
    if (Firebase.ready()) {
    if (Firebase.setInt(fbdo, "/heartrate/current_bpm", bpm)) {
        Serial.printf("✅ Current BPM Updated: %d\n", bpm);
    } else {
        Serial.printf("❌ Failed to update BPM: %s\n", fbdo.errorReason().c_str());
    }
} else {
    Serial.println("⚠️ Firebase not ready, skipping BPM update.");
}

}

// Function to send stats to Firebase every 60s
void sendStatsToFirebase(int low, int avg, int high) {
    if (Firebase.ready()) {
    bool ok = Firebase.setInt(fbdo, "/heartrate/stats/low_bpm", low) &&
              Firebase.setInt(fbdo, "/heartrate/stats/high_bpm", high) &&
              Firebase.setInt(fbdo, "/heartrate/stats/avg_bpm", avg);
    if (ok) {
        Serial.printf("📊 Stats Updated - Low: %d, Avg: %d, High: %d\n", low, avg, high);
    } else {
        Serial.printf("❌ Failed to update stats: %s\n", fbdo.errorReason().c_str());
    }
} else {
    Serial.println("⚠️ Firebase not ready, skipping stats update.");
}
}

// Send GPS data to Firebase Realtime Database
void sendToFirebase(double lat, double lng, double alt, int satellites, double hdop, String timestamp) {
    if (Firebase.ready()) {
    bool gpsOk =
        Firebase.setDouble(fbdo, "/gpslocation/stats/latitude", lat) &&
        Firebase.setDouble(fbdo, "/gpslocation/stats/longitude", lng) &&
        Firebase.setDouble(fbdo, "/gpslocation/stats/altitude", alt) &&
        Firebase.setInt(fbdo, "/gpslocation/stats/satellites", satellites) &&
        Firebase.setDouble(fbdo, "/gpslocation/stats/hdop", hdop) &&
        Firebase.setString(fbdo, "/gpslocation/stats/timestamp", timestamp);

    if (gpsOk) {
        Serial.println("✅ Firebase: Location update successful");
    } else {
        Serial.printf("❌ Firebase GPS update failed: %s\n", fbdo.errorReason().c_str());
    }
} else {
    Serial.println("⚠️ Firebase not ready, skipping GPS update.");
}
}