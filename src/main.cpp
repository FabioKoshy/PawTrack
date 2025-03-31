#include <TinyGPS++.h>
#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <SPI.h>
#include "firebase.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <CST816S.h>
#include <config/CST816S_pin_config.h>
#include <lvgl.h>
#include "paw_heart_image.h"
#if LV_USE_TFT_ESPI
#include <TFT_eSPI.h>
#endif


// GPS Pins
#define RXD2 16
#define TXD2 17
#define GPS_BAUD 9600
#define PPS_PIN 18  // GPIO pin to monitor PPS signal

// Heart Rate Sensor Pin
#define SENSOR_PIN 15

#define TFT_HOR_RES   240
#define TFT_VER_RES   240
#define TFT_ROTATION  LV_DISPLAY_ROTATION_0
#define DRAW_BUF_SIZE (TFT_HOR_RES * TFT_VER_RES / 10 * (LV_COLOR_DEPTH / 8))
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define DATA_CHAR_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Heart Rate Constants
const int sampleInterval = 2;
const long printInterval = 1000; // Heart rate every 1 second
const long gpsPrintInterval = 1000; // GPS every 1 second
const long minuteInterval = 60000; // Stats every 60 seconds
const int maxSamples = 60;
const int minBPM = 160;
const int maxBPM = 300;
const int filterSize = 10;
const long minIBI = 200;
const int ibiWindow = 5;
const int peakAmplitudeMin = 100;

// WiFi reconnection interval (5 minutes)
#define WIFI_CHECK_INTERVAL 300000

// GPS Objects
TinyGPSPlus gps;
HardwareSerial gpsSerial(2);
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define DATA_CHAR_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"

uint32_t draw_buf[DRAW_BUF_SIZE / 4];
CST816S touch(TOUCH_SDA, TOUCH_SCL, TOUCH_RST, TOUCH_IRQ);

BLEServer* pServer = NULL;
BLECharacteristic* pDataCharacteristic = NULL;
bool deviceConnected = false;

class MySecurityCallbacks : public BLESecurityCallbacks {
    uint32_t onPassKeyRequest() { 
        Serial.println("Passkey requested. Returning 123456 (not used with Just Works)");
        return 123456; 
    }
    void onPassKeyNotify(uint32_t pass_key) {
        Serial.print("Passkey Notify: ");
        Serial.println(pass_key);
    }
    bool onConfirmPIN(uint32_t pass_key) { 
        Serial.print("Confirm PIN: ");
        Serial.println(pass_key);
        return true; 
    }
    bool onSecurityRequest() { 
        Serial.println("Security Request received");
        return true; 
    }
    void onAuthenticationComplete(esp_ble_auth_cmpl_t auth) {
        if (auth.success) {
            Serial.println("Authentication successful. Devices are bonded.");
        } else {
            Serial.print("Authentication failed. Failure reason code: ");
            Serial.println(auth.fail_reason);
        }
    }
};

static uint32_t my_tick(void) {
    return millis();
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println("Android phone connected via BLE.");
    }

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println("Android phone disconnected. Starting advertising again...");
        BLEDevice::startAdvertising();
        Serial.println("Advertising restarted.");
    }
};

// Structure to hold satellite information
struct SatelliteInfo {
    uint8_t prn;  // Pseudo-Random Noise code (satellite ID)
    uint8_t snr;  // Signal-to-Noise Ratio (dBHz)
    bool valid;   // Whether the data is valid
};

#define MAX_SATELLITES 32  // Maximum number of satellites to track
SatelliteInfo satellitesInView[MAX_SATELLITES];
uint8_t numSatellitesInView = 0;

// Variables for PPS interrupt
volatile unsigned long lastPpsTime = 0;
volatile bool ppsTriggered = false;

// Heart Rate Variables
int bpmSamples[maxSamples];
int sampleCount = 0;
long lastPrintTime = 0;
long lastGpsPrintTime = 0;
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

// WiFi Variables
unsigned long lastWiFiCheckTime = 0;

// Function Declarations (Heart Rate)
int applyFilter(int rawValue);
void updateThreshold(int filteredValue);
void detectBeat(int ecgValue);
void updateIBIBuffer(long ibi);
int getAverageBPM();
void printBPM(long currentTime);
void calculateStats();
void checkWiFiConnection();
void displayWiFiStatus();

// Function Declarations (GPS)
void sendUBX(uint8_t *MSG, uint8_t len);
void forceColdStart();
void enableGLONASS();
void setUpdateRate();
void setNavigationMode();
void configurePPS();
void parseGSVSentence(String sentence);
void IRAM_ATTR ppsInterrupt();
String getGpsTimestamp();

// PPS interrupt handler
void IRAM_ATTR ppsInterrupt() {
    lastPpsTime = micros();
    ppsTriggered = true;
}

// Send UBX command to NEO-7M
void sendUBX(uint8_t *MSG, uint8_t len) {
    for (int i = 0; i < len; i++) {
        gpsSerial.write(MSG[i]);
    }
    gpsSerial.flush();
}

// Force a cold start to clear old data
void forceColdStart() {
    uint8_t ubxCfgRst[] = {
        0xB5, 0x62, 0x06, 0x04, 0x04, 0x00,
        0xFF, 0xFF,
        0x02,
        0x00,
        0x00, 0x00
    };
    uint8_t ck_a = 0, ck_b = 0;
    for (int i = 2; i < (sizeof(ubxCfgRst) - 2); i++) {
        ck_a = ck_a + ubxCfgRst[i];
        ck_b = ck_b + ck_a;
    }
    ubxCfgRst[sizeof(ubxCfgRst) - 2] = ck_a;
    ubxCfgRst[sizeof(ubxCfgRst) - 1] = ck_b;
    sendUBX(ubxCfgRst, sizeof(ubxCfgRst));
    Serial.println("Forced a cold start on NEO-7M");
}

// Enable GLONASS for better satellite detection
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

// Set GPS update rate to 1 Hz
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

// Set navigation mode to Portable, with lower min elevation angle
void setNavigationMode() {
    uint8_t ubxCfgNav5[] = {
        0xB5, 0x62, 0x06, 0x24, 0x24, 0x00,
        0xFF, 0xFF,
        0x01,
        0x03,
        0x00, 0x00, 0x00, 0x00,
        0x05, 0x00, 0x00, 0x00,
        0x05,
        0x00,
        0xFA, 0x00,
        0xFA, 0x00,
        0x00,
        0x05,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00
    };
    uint8_t ck_a = 0, ck_b = 0;
    for (int i = 2; i < (sizeof(ubxCfgNav5) - 2); i++) {
        ck_a = ck_a + ubxCfgNav5[i];
        ck_b = ck_b + ck_a;
    }
    ubxCfgNav5[sizeof(ubxCfgNav5) - 2] = ck_a;
    ubxCfgNav5[sizeof(ubxCfgNav5) - 1] = ck_b;
    sendUBX(ubxCfgNav5, sizeof(ubxCfgNav5));
    Serial.println("Set navigation mode to Portable");
}

// Configure PPS pulse width to 50ms
void configurePPS() {
    uint8_t ubxCfgTp5[] = {
        0xB5, 0x62, 0x06, 0x31, 0x20, 0x00,
        0x00,
        0x00,
        0x00, 0x00,
        0x32, 0x00,
        0x00, 0x00,
        0x40, 0x42, 0x0F, 0x00,
        0x20, 0xA1, 0x07, 0x00,
        0x01,
        0x00,
        0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00
    };
    uint8_t ck_a = 0, ck_b = 0;
    for (int i = 2; i < (sizeof(ubxCfgTp5) - 2); i++) {
        ck_a = ck_a + ubxCfgTp5[i];
        ck_b = ck_b + ck_a;
    }
    ubxCfgTp5[sizeof(ubxCfgTp5) - 2] = ck_a;
    ubxCfgTp5[sizeof(ubxCfgTp5) - 1] = ck_b;
    sendUBX(ubxCfgTp5, sizeof(ubxCfgTp5));
    Serial.println("Configured PPS pulse width to 50ms");
}

// Parse $GPGSV and $GLGSV sentences to extract satellite info
void parseGSVSentence(String sentence) {
    int commaIndex = 0;
    String fields[20];
    int fieldCount = 0;

    int checksumIndex = sentence.indexOf('*');
    if (checksumIndex != -1) {
        sentence = sentence.substring(0, checksumIndex);
    }

    while (commaIndex != -1 && fieldCount < 20) {
        commaIndex = sentence.indexOf(',');
        if (commaIndex != -1) {
            fields[fieldCount] = sentence.substring(0, commaIndex);
            sentence = sentence.substring(commaIndex + 1);
            fieldCount++;
        } else {
            fields[fieldCount] = sentence;
            fieldCount++;
        }
    }

    if (fields[0] != "$GPGSV" && fields[0] != "$GLGSV") {
        return;
    }

    int totalSatellites = fields[3].toInt();
    int messageNumber = fields[1].toInt();
    int totalMessages = fields[2].toInt();

    if (messageNumber == 1) {
        numSatellitesInView = 0;
    }

    for (int i = 0; i < 4; i++) {
        int fieldIndex = 4 + i * 4;
        if (fieldIndex + 3 >= fieldCount || fields[fieldIndex].length() == 0) {
            break;
        }

        uint8_t prn = fields[fieldIndex].toInt();
        uint8_t snr = fields[fieldIndex + 3].toInt();

        if (numSatellitesInView < MAX_SATELLITES) {
            satellitesInView[numSatellitesInView].prn = prn;
            satellitesInView[numSatellitesInView].snr = snr;
            satellitesInView[numSatellitesInView].valid = true;
            numSatellitesInView++;
        }
    }
}

// Get GPS timestamp in ISO 8601 format (e.g., "2025-03-21T15:40:00Z")
String getGpsTimestamp() {
    if (gps.date.isValid() && gps.time.isValid()) {
        char timestamp[21];
        snprintf(timestamp, sizeof(timestamp), "%04d-%02d-%02dT%02d:%02d:%02dZ",
                 gps.date.year(), gps.date.month(), gps.date.day(),
                 gps.time.hour(), gps.time.minute(), gps.time.second());
        return String(timestamp);
    } else {
        return "1970-01-01T00:00:00Z"; // Default timestamp if GPS time is invalid
    }
}


#if LV_USE_LOG != 0
void my_print(lv_log_level_t level, const char * buf)
{
    LV_UNUSED(level);
    Serial.println(buf);
    Serial.flush();
}
#endif
/*Read the touchpad*/
void my_touchpad_read(lv_indev_t * indev, lv_indev_data_t * data)
{
    bool touched = touch.available();
    if(!touched) {
        data->state = LV_INDEV_STATE_RELEASED;
    } else {
        data->state = LV_INDEV_STATE_PRESSED;
        data->point.x = touch.data.x;
        data->point.y = touch.data.y;
        Serial.print("Data x ");
        Serial.println(touch.data.x);
        Serial.print("Data y ");
        Serial.println(touch.data.y);
    }
}


void setup() {
    Serial.begin(115200);

// === LVGL Display + Touch Setup ===
touch.begin();
lv_init();
lv_tick_set_cb(my_tick);  // use millis()


lv_display_t * disp;
#if LV_USE_TFT_ESPI
disp = lv_tft_espi_create(TFT_HOR_RES, TFT_VER_RES, draw_buf, sizeof(draw_buf));
lv_display_set_rotation(disp, TFT_ROTATION);
#else
disp = lv_display_create(TFT_HOR_RES, TFT_VER_RES);
lv_display_set_flush_cb(disp, my_disp_flush);
lv_display_set_buffers(disp, draw_buf, NULL, sizeof(draw_buf), LV_DISPLAY_RENDER_MODE_PARTIAL);
#endif

lv_indev_t * indev = lv_indev_create();
lv_indev_set_type(indev, LV_INDEV_TYPE_POINTER);
lv_indev_set_read_cb(indev, my_touchpad_read);

lv_obj_t * screen = lv_screen_active();
lv_obj_set_style_bg_color(screen, lv_color_hex(0x000000), 0);
lv_obj_t * img = lv_img_create(screen);
lv_img_set_src(img, &paw_heart_dark_logo);
lv_img_set_zoom(img, 200);  // 256 = 100%, 200 = ~78%
lv_obj_center(img);
Serial.println("LVGL display setup complete.");

    while (!Serial);

    pinMode(PPS_PIN, INPUT);
    attachInterrupt(digitalPinToInterrupt(PPS_PIN), ppsInterrupt, RISING);
    Serial.print("PPS interrupt initialized on GPIO ");
    Serial.println(PPS_PIN);
    
    gpsSerial.begin(GPS_BAUD, SERIAL_8N1, RXD2, TXD2);
    Serial.println("Serial 2 started at 9600 baud rate");

    pinMode(SENSOR_PIN, INPUT);

    for (int i = 0; i < filterSize; i++) {
        filterBuffer[i] = 0;
    }
    for (int i = 0; i < ibiWindow; i++) {
        ibiBuffer[i] = 0;
    }

    setupFirebase();
    displayWiFiStatus();

    //forceColdStart(); //useless as we r in montreal
    enableGLONASS();
    setUpdateRate();
    setNavigationMode();
    configurePPS();

    Serial.println("🔄 Pet tracker initialized.");

    // Initialize BLE
    BLEDevice::init("ESP32_PetTracker");
    BLEDevice::setEncryptionLevel(ESP_BLE_SEC_ENCRYPT);
    BLEDevice::setSecurityCallbacks(new MySecurityCallbacks());

    BLESecurity *pSecurity = new BLESecurity();
    pSecurity->setAuthenticationMode(ESP_LE_AUTH_BOND);
    pSecurity->setCapability(ESP_IO_CAP_NONE);
    pSecurity->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);

    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);
    pDataCharacteristic = pService->createCharacteristic(
                            DATA_CHAR_UUID,
                            BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
                          );
    pDataCharacteristic->addDescriptor(new BLE2902());
    pDataCharacteristic->setCallbacks(new BLECharacteristicCallbacks());

    pService->start();

    // Configure advertising with device name
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true); // Include device name in scan response
    pAdvertising->setMinPreferred(0x06); // Minimum connection interval
    pAdvertising->setMaxPreferred(0x12); // Maximum connection interval

    // Explicitly set advertising data to include the device name
    BLEAdvertisementData advertisementData;
    advertisementData.setName("ESP32_PetTracker"); // Set the name in the advertising packet
    advertisementData.setFlags(0x04); // BR/EDR Not Supported (BLE only)
    pAdvertising->setAdvertisementData(advertisementData);

    // Start advertising
    BLEDevice::startAdvertising();
    Serial.println("BLE started. Connect to ESP32_PetTracker.");

    lastWiFiCheckTime = millis();
    delay(1000);
}

void loop() {
    static long previousMillis = 0;
    long currentMillis = millis();
    static bool newGpsData = false;
    static String nmeaSentence = "";
    static bool ppsActive = false;
    static unsigned long lastUpdate = 0;

    if (ppsTriggered) {
        Serial.print("\nPPS pulse detected at ");
        Serial.print(lastPpsTime);
        Serial.println(" microseconds");
        ppsTriggered = false;
        ppsActive = true;
    }

    while (gpsSerial.available() > 0) {
        char c = gpsSerial.read();
        nmeaSentence += c;

        if (gps.encode(c)) {
            newGpsData = true;
        }

        if (c == '\n') {
            nmeaSentence.trim();
            if (nmeaSentence.startsWith("$GPGSV") || nmeaSentence.startsWith("$GLGSV")) {
                parseGSVSentence(nmeaSentence);
            }
            nmeaSentence = "";
        }
    }

    static unsigned long lastPpsTimeCheck = 0;
    if (ppsActive && (currentMillis - lastPpsTimeCheck >= 1500)) {
        if ((micros() - lastPpsTime) > 1500000) {
            Serial.println("\nPPS signal lost - GPS fix lost!");
            ppsActive = false;
        }
        lastPpsTimeCheck = currentMillis;
    }

    if (newGpsData && (currentMillis - lastGpsPrintTime >= gpsPrintInterval)) {
        Serial.println("\n=== GPS DATA ===");
        Serial.print("Satellites in Use: ");
        Serial.print(gps.satellites.value());
        Serial.print(" | Fix: ");
        Serial.print(gps.location.isValid() ? "Yes" : "No");
        if (gps.location.isValid()) {
            Serial.print(" | LAT: ");
            Serial.print(gps.location.lat(), 6);
            Serial.print(" | LONG: ");
            Serial.print(gps.location.lng(), 6);
            Serial.print(" | ALT: ");
            Serial.print(gps.altitude.meters());
        }
        Serial.println();

        if (gps.hdop.isValid()) {
            Serial.print("HDOP: ");
            Serial.println(gps.hdop.hdop(), 2);
        }

        if (gps.date.isValid() && gps.time.isValid()) {
            Serial.print("Timestamp: ");
            Serial.println(getGpsTimestamp());
        }

        Serial.print("Satellites in View: ");
        Serial.println(numSatellitesInView);
        for (int i = 0; i < numSatellitesInView; i++) {
            if (satellitesInView[i].valid) {
                Serial.print("  Satellite ");
                Serial.print(i + 1);
                Serial.print(": PRN ");
                Serial.print(satellitesInView[i].prn);
                Serial.print(", SNR ");
                Serial.println(satellitesInView[i].snr);
            }
        }
        Serial.println("===============");
        lastGpsPrintTime = currentMillis;
        newGpsData = false;
    }

    if (currentMillis - previousMillis >= sampleInterval) {
        int ecgValue = analogRead(SENSOR_PIN);
        int filteredValue = applyFilter(ecgValue);
        updateThreshold(filteredValue);
        detectBeat(filteredValue);
        previousMillis = currentMillis;
    }

    if (currentMillis - lastWiFiCheckTime >= WIFI_CHECK_INTERVAL) {
        checkWiFiConnection();
        lastWiFiCheckTime = currentMillis;
    }

    if (currentMillis - lastPrintTime >= printInterval) {
        printBPM(currentMillis);
        sendCurrentHeartRateToFirebase(BPM);
        lastPrintTime = currentMillis;

        if (gps.location.isValid() && (currentMillis - lastUpdate >= 5000)) {
            String timestamp = getGpsTimestamp();
            sendToFirebase(
                gps.location.lat(),
                gps.location.lng(),
                gps.altitude.meters(),
                gps.satellites.value(),
                gps.hdop.isValid() ? gps.hdop.hdop() : 0.0,
                timestamp
            );
            lastUpdate = currentMillis;
        }
    }

    if (!isCalibrating && currentMillis - lastMinuteTime >= minuteInterval) {
        calculateStats();
        lastMinuteTime = currentMillis;
    }

    // Send BLE data to the connected phone (counter value)
    static unsigned long lastDataUpdate = 0;
    static int counter = 0;
    if (deviceConnected && millis() - lastDataUpdate >= 1000) {
        BLE2902* p2902 = (BLE2902*)pDataCharacteristic->getDescriptorByUUID(BLEUUID((uint16_t)0x2902));
        bool notificationsEnabled = p2902 && p2902->getNotifications();
        if (notificationsEnabled) {
            String counterStr = String(counter);
            pDataCharacteristic->setValue(counterStr.c_str());
            pDataCharacteristic->notify();
            Serial.print("Sent counter: ");
            Serial.println(counter);
            counter++;
        } else {
            Serial.println("Notifications not enabled for data characteristic.");
        }
        lastDataUpdate = millis();
    }

    // Periodically check advertising status
    static unsigned long lastAdvertisingCheck = 0;
    if (millis() - lastAdvertisingCheck >= 10000) { // Check every 10 seconds
        if (!deviceConnected) {
            Serial.println("Device not connected. Ensuring advertising is active...");
            BLEDevice::startAdvertising();
            Serial.println("Advertising restarted.");
        }
        lastAdvertisingCheck = millis();
    }

lv_timer_handler();  // Let LVGL GUI update
delay(5);

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

void updateIBIBuffer(long ibi) {
    ibiBuffer[ibiIndex] = ibi;
    ibiIndex = (ibiIndex + 1) % ibiWindow;
    if (ibiCount < ibiWindow) ibiCount++;
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
            Serial.print(">");
            Serial.print("BPM:");
            Serial.print(avgBPM);
            Serial.println();
            BPM = avgBPM;
            if (sampleCount < maxSamples) {
                bpmSamples[sampleCount] = avgBPM;
                sampleCount++;
            }
        } else {
            Serial.print(">");
            Serial.print("BPM:");
            Serial.print(0);
            Serial.println();
            BPM = 0;
        }
    } else {
        Serial.print(">");
        Serial.print("BPM:");
        Serial.print(0);
        Serial.println();
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
    Serial.println("--- Minute Stats ---");
    Serial.print("Low BPM: ");
    Serial.println(minBPMStat);
    Serial.print("Avg BPM: ");
    Serial.println(avgBPMStat, 1);
    Serial.print("High BPM: ");
    Serial.println(maxBPMStat);
    Serial.print("Samples: ");
    Serial.println(sampleCount);
    Serial.println("--------------------");
    Serial.println("======================");

    sendStatsToFirebase(minBPMStat, (int)avgBPMStat, maxBPMStat);

    sampleCount = 0;
}

void checkWiFiConnection() {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("⚠️ WiFi connection lost. Attempting to reconnect...");
        autoConnectWiFi();
        displayWiFiStatus();
    } else {
        Serial.println("✅ WiFi connection check: Connected");
    }
}

void displayWiFiStatus() {
    Serial.println("📡 Checking WiFi status...");
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("✅ WiFi Connected");
    } else {
        Serial.println("❌ WiFi Disconnected");
    }
}
