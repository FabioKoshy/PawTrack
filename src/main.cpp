#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TinyGPSPlus.h>
#include <WiFi.h>
#include "firebase.h"
#include "time.h"

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// GPS and PPS pins
#define RXD2 16
#define TXD2 17
#define PPS_PIN 18

// Heart Rate Sensor Pin
#define SENSOR_PIN 15

// BLE variables
BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
BLEAdvertising* pAdvertising = nullptr;
bool deviceConnected = false;
bool wifiCredentialsReceived = false;
bool blePairingInProgress = true;

// GPS variables
TinyGPSPlus gps;
volatile unsigned long ppsCount = 0;

// Heart Rate Variables
const int sampleInterval = 2;
const long printInterval = 1000;
const long minuteInterval = 60000;
const int maxSamples = 60;
const int minBPM = 160;
const int maxBPM = 300;
const int filterSize = 10;
const long minIBI = 200;
const int ibiWindow = 5;
const int peakAmplitudeMin = 100;

int bpmSamples[maxSamples];
int sampleCount = 0;
long lastPrintTime = 0;
long lastMinuteTime = 0;
long lastBeatTime = 0;
int threshold = 800;
bool beatDetected = false;
int filterBuffer[filterSize];
int filterIndex = 0;
long filterSum = 0;
long ibiBuffer[ibiWindow];
int ibiIndex = 0;
int ibiCount = 0;
bool isCalibrating = true;

// BLE callback classes
class MyServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      blePairingInProgress = false;
      Serial.println("Bluetooth pairing success!");
      
      // Delay to stabilize the connection
      delay(500);
      pAdvertising->stop();
      
      // Send an initial notification to confirm connection
      if (pCharacteristic != nullptr) {
        pCharacteristic->setValue("connected:true");
        pCharacteristic->notify();
      }
    }
  
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE disconnected. Waiting before deciding to restart advertising...");
      
      // Add a longer delay to allow the app to handle the disconnection
      delay(5000); // Increased delay to 5 seconds
      
      // Only restart advertising if we haven't progressed to Wi-Fi or Firebase connection
      if (!wifiConnected && !firebaseConnected) {
        blePairingInProgress = true;
        Serial.println("Restarting BLE advertising...");
        pAdvertising->start();
      } else {
        Serial.println("Not restarting advertising as Wi-Fi or Firebase is connected.");
      }
    }
};

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    String bleData = value.c_str();

    if (bleData.length() > 0) {
      Serial.println("=== Received BLE Data ===");
      Serial.print("Raw BLE value: ");
      Serial.println(bleData);

      int ssidStart = bleData.indexOf("SSID:") + 5;
      int ssidEnd = bleData.indexOf(",", ssidStart);
      wifiSsid = bleData.substring(ssidStart, ssidEnd);

      int pwdStart = bleData.indexOf("PWD:") + 4;
      int pwdEnd = bleData.indexOf(",", pwdStart);
      wifiPassword = bleData.substring(pwdStart, pwdEnd);

      int userStart = bleData.indexOf("USER:") + 5;
      int userEnd = bleData.indexOf(",", userStart);
      wifiUsername = bleData.substring(userStart, userEnd);

      int tokenStart = bleData.indexOf("TOKEN:") + 6;
      int tokenEnd = bleData.length();
      firebaseToken = bleData.substring(tokenStart, tokenEnd);

      if (wifiUsername.length() > 0) {
        userId = wifiUsername;
      } else {
        userId = "default_user";
      }

      Serial.println("Parsed Wi-Fi Credentials:");
      Serial.print("Wi-Fi SSID: "); Serial.println(wifiSsid);
      Serial.print("Wi-Fi Password: "); Serial.println(wifiPassword);
      Serial.print("Wi-Fi Username: "); Serial.println(wifiUsername.length() > 0 ? wifiUsername : "Not provided");
      Serial.print("Firebase Token: "); Serial.println(firebaseToken);
      Serial.print("User ID: "); Serial.println(userId);
      Serial.println("========================");

      wifiCredentialsReceived = true;
    } else {
      Serial.println("Received empty BLE data.");
    }
  }
};

// PPS interrupt handler
void IRAM_ATTR ppsInterrupt() {
  ppsCount++;
}

// Heart Rate Functions
int applyFilter(int rawValue) {
  filterSum -= filterBuffer[filterIndex];
  filterBuffer[filterIndex] = rawValue;
  filterSum += rawValue;
  filterIndex = (filterIndex + 1) % filterSize;
  return filterSum / filterSize;
}

void updateThreshold(int filteredValue) {
  static long sumForAvg = 0;
  static int countForAvg = 0;
  static const int avgWindow = 2000;

  sumForAvg += filteredValue;
  countForAvg++;
  if (countForAvg >= avgWindow) {
    int signalAvg = sumForAvg / avgWindow;
    threshold = signalAvg + 200;
    sumForAvg = 0;
    countForAvg = 0;
  }
}

void updateIBIBuffer(long ibi) {
  ibiBuffer[ibiIndex] = ibi;
  ibiIndex = (ibiIndex + 1) % ibiWindow;
  if (ibiCount < ibiWindow) ibiCount++;
}

void detectBeat(int ecgValue) {
  static int lastValue = 0;
  if (ecgValue > threshold && lastValue <= threshold && !beatDetected) {
    long currentTime = millis();
    long ibi = currentTime - lastBeatTime;
    int amplitude = ecgValue - (threshold - 200);
    if (lastBeatTime != 0 && ibi >= minIBI && amplitude >= peakAmplitudeMin) {
      int bpm = 60000 / ibi;
      if (bpm >= minBPM && bpm <= maxBPM) {
        updateIBIBuffer(ibi);
        if (isCalibrating) {
          isCalibrating = false;
          Serial.println("Calibration complete. Starting BPM output...");
          lastMinuteTime = millis();
        }
      }
    }
    lastBeatTime = currentTime;
    beatDetected = true;
  }
  if (ecgValue <= threshold && beatDetected) {
    beatDetected = false;
  }
  lastValue = ecgValue;
}

int getAverageBPM() {
  if (ibiCount == 0) return 0;
  long sumIBI = 0;
  for (int i = 0; i < ibiCount; i++) {
    sumIBI += ibiBuffer[i];
  }
  long avgIBI = sumIBI / ibiCount;
  return 60000 / avgIBI;
}

void printBPM(long currentTime) {
  Serial.println("=== HEART RATE DATA ===");
  if (!isCalibrating) {
    int avgBPM = getAverageBPM();
    if (avgBPM >= minBPM && avgBPM <= maxBPM && ibiCount > 0) {
      Serial.print("BPM: "); Serial.println(avgBPM);
      BPM = avgBPM;
      if (sampleCount < maxSamples) {
        bpmSamples[sampleCount] = avgBPM;
        sampleCount++;
      }
    } else {
      Serial.println("BPM: 0");
      BPM = 0;
    }
  } else {
    Serial.println("BPM: 0 (Calibrating)");
  }
  Serial.println("======================");
}

void calculateStats() {
  if (sampleCount == 0) {
    Serial.println("No valid samples collected");
    return;
  }
  int minBPMStat = bpmSamples[0];
  int maxBPMStat = bpmSamples[0];
  long sumBPMStat = 0;
  for (int i = 0; i < sampleCount; i++) {
    if (bpmSamples[i] < minBPMStat) minBPMStat = bpmSamples[i];
    if (bpmSamples[i] > maxBPMStat) maxBPMStat = bpmSamples[i];
    sumBPMStat += bpmSamples[i];
  }
  float avgBPMStat = (float)sumBPMStat / sampleCount;
  Serial.println("=== HEART RATE STATS ===");
  Serial.print("Low BPM: "); Serial.println(minBPMStat);
  Serial.print("Avg BPM: "); Serial.println(avgBPMStat, 1);
  Serial.print("High BPM: "); Serial.println(maxBPMStat);
  Serial.print("Samples: "); Serial.println(sampleCount);
  Serial.println("======================");
  if (firebaseConnected) {
    sendStatsToFirebase(minBPMStat, avgBPMStat, maxBPMStat, userId);
  }
  sampleCount = 0;
}

// GPS Functions
void sendUBX(uint8_t *MSG, uint8_t len) {
  for (int i = 0; i < len; i++) {
    Serial2.write(MSG[i]);
  }
  Serial2.flush();
}

void enableGLONASS() {
  uint8_t ubxCfgGnss[] = {
    0xB5, 0x62, 0x06, 0x3E, 0x2C, 0x00, 0x00, 0x20, 0x05, 0x00,
    0x01, 0x08, 0x10, 0x00, 0x01, 0x00, 0x00, 0x01,
    0x02, 0x08, 0x10, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x03, 0x08, 0x10, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x05, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x01,
    0x06, 0x08, 0x0E, 0x00, 0x01, 0x00, 0x00, 0x01,
    0x00, 0x00
  };
  uint8_t ck_a = 0, ck_b = 0;
  for (int i = 2; i < (sizeof(ubxCfgGnss) - 2); i++) {
    ck_a = ck_a + ubxCfgGnss[i];
    ck_b = ck_b + ck_a;
  }
  ubxCfgGnss[sizeof(ubxCfgGnss) - 2] = ck_a;
  ubxCfgGnss[sizeof(ubxCfgGnss) - 1] = ck_b;
  sendUBX(ubxCfgGnss, sizeof(ubxCfgGnss));
  Serial.println("Enabled GLONASS support on NEO-7M");
}

void setUpdateRate() {
  uint8_t ubxCfgRate[] = {
    0xB5, 0x62, 0x06, 0x08, 0x06, 0x00, 0xE8, 0x03,
    0x01, 0x00, 0x01, 0x00, 0x00, 0x00
  };
  uint8_t ck_a = 0, ck_b = 0;
  for (int i = 2; i < (sizeof(ubxCfgRate) - 2); i++) {
    ck_a = ck_a + ubxCfgRate[i];
    ck_b = ck_b + ck_a;
  }
  ubxCfgRate[sizeof(ubxCfgRate) - 2] = ck_a;
  ubxCfgRate[sizeof(ubxCfgRate) - 1] = ck_b;
  sendUBX(ubxCfgRate, sizeof(ubxCfgRate));
  Serial.println("Set GPS update rate to 1 Hz");
}

void setup() {
  Serial.begin(115200);
  Serial.println("Device starting...");

  // Initialize BLE
  BLEDevice::init("ESP32_PawTrack");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService* pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());
  pService->start();

  pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("BLE advertising started with name: ESP32_PawTrack");

  // Scan Wi-Fi networks
  scanWiFiNetworks();

  // Initialize GPS
  Serial2.begin(9600, SERIAL_8N1, RXD2, TXD2);
  pinMode(PPS_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(PPS_PIN), ppsInterrupt, RISING);
  enableGLONASS();
  setUpdateRate();

  // Initialize heart rate sensor
  pinMode(SENSOR_PIN, INPUT);
}

void loop() {
  if (blePairingInProgress) {
    Serial.println("Bluetooth pairing configuring");
    delay(1000);
    if (!deviceConnected) {
      // Keep advertising until connected
    }
    return; // Wait until BLE pairing is successful
  }

  // After BLE pairing success, wait for Wi-Fi credentials
  if (wifiCredentialsReceived && WiFi.status() != WL_CONNECTED) {
    connectToWiFi(wifiSsid.c_str(), wifiPassword.c_str(), wifiUsername.length() > 0 ? wifiUsername.c_str() : nullptr);
    wifiCredentialsReceived = false;
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("Wi-Fi connection failed. Please try again.");
      return; // Wait for user to retry
    }
  }

  // Once Wi-Fi is connected, attempt Firebase connection
  if (WiFi.status() == WL_CONNECTED && !firebaseConnected) {
    Serial.println("Connecting to Firebase...");
    setupFirebase(firebaseToken, userId);
    if (!firebaseConnected) {
      Serial.println("Firebase connection failed. Retrying...");
      delay(5000); // Retry after delay
      return;
    }
    Serial.println("Firebase Connected!");
  }

  // Main operation loop after all connections are established
  if (firebaseConnected) {
    while (Serial2.available() > 0) {
      if (gps.encode(Serial2.read())) {
        if (gps.satellites.isValid()) {
          int satellites = gps.satellites.value();
          char satelliteData[32];
          snprintf(satelliteData, sizeof(satelliteData), "satellites:%d", satellites);
          if (deviceConnected) {
            pCharacteristic->setValue(satelliteData);
            pCharacteristic->notify();
          }
          Serial.print("Satellites: ");
          Serial.println(satellites);
        }

        if (gps.location.isValid()) {
          double lat = gps.location.lat();
          double lng = gps.location.lng();
          double alt = gps.altitude.isValid() ? gps.altitude.meters() : 0.0;
          int satellites = gps.satellites.isValid() ? gps.satellites.value() : 0;
          double hdop = gps.hdop.isValid() ? gps.hdop.hdop() : 0.0;
          String timestamp = getTime();
          sendToFirebase(lat, lng, alt, satellites, hdop, timestamp, userId);
        }
      }
    }

    long currentTime = millis();
    int rawValue = analogRead(SENSOR_PIN);
    int filteredValue = applyFilter(rawValue);
    updateThreshold(filteredValue);
    detectBeat(filteredValue);

    if (currentTime - lastPrintTime >= printInterval) {
      printBPM(currentTime);
      lastPrintTime = currentTime;
    }

    if (currentTime - lastMinuteTime >= minuteInterval) {
      calculateStats();
      lastMinuteTime = currentTime;
    }
  }

  delay(sampleInterval);
}