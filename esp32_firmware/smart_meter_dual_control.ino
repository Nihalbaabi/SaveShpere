/*
 * SMART ENERGY METER - DUAL CONTROL VERSION
 * Supports both Physical Switches AND App Toggle Buttons
 *
 * ┌───────────────────────────────┬──────────────┬────────────────┬────────────────┬────────────────────────────────┐
 * │ Scenario                      │ Physical SW  │ App Toggle     │ Effective State│ Behaviour                      │
 * ├───────────────────────────────┼──────────────┼────────────────┼────────────────┼────────────────────────────────┤
 * │ Initial state                 │ OFF          │ OFF            │ OFF            │ Room is OFF                    │
 * │ Turn ON with Physical         │ ON           │ OFF → Sync ON  │ ON             │ App auto-updates to ON         │
 * │ Turn ON with App              │ OFF          │ ON             │ ON             │ Device turns ON                │
 * │ Both ON                       │ ON           │ ON             │ ON             │ Normal ON state                │
 * │ Turn OFF with Physical        │ OFF          │ ON → Sync OFF  │ OFF            │ App auto-updates to OFF        │
 * │ Turn OFF with App             │ ON           │ OFF            │ OFF            │ Device turns OFF (app wins)    │
 * │ Turn ON again with App        │ OFF          │ ON             │ ON             │ Device turns ON                │
 * │ Turn ON again with Physical   │ ON           │ OFF → Sync ON  │ ON             │ App syncs to ON                │
 * │ Rapid toggle (any side)       │ Changes      │ Changes        │ Last Action Wins│ No flicker, precise sync       │
 * └───────────────────────────────┴──────────────┴────────────────┴────────────────┴────────────────────────────────┘
 *
 * Key rules:
 *   1. effectiveState = appControl  (app toggle is always the master)
 *   2. Physical switch CHANGE (either direction) → syncs its state to /control/
 *      so the app UI reflects the physical press immediately
 *   3. App OFF overrides physical ON  → device turns OFF
 *   4. fetchControlStates() polls /control/ every 1s to pick up app changes
 *   5. COOL-DOWN: After a physical change, the ESP32 ignores cloud updates for
 *      that room for 3 seconds to prevent "latency flicker".
 *
 * Firebase structure:
 *   /live        → ESP32 writes real-time telemetry (overwrite every minute)
 *   /logs/<ts>   → ESP32 writes historical log (every minute)
 *   /control/    → App writes; ESP32 reads + mirrors physical ON/OFF changes
 *     bedroom : bool
 *     lrLight : bool
 *     lrTV    : bool
 *     kitchen : bool
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Preferences.h>

/* ---------------- WIFI ---------------- */
#define WIFI_SSID     "ASIANET-2.4G-247"
#define WIFI_PASSWORD "Fibr@247@"

/* ---------------- FIREBASE ---------------- */
#define FIREBASE_URL  "https://smart-meter-1aff1-default-rtdb.firebaseio.com"

/* ---------------- SWITCH PINS (INPUT_PULLUP → LOW = pressed) ---------------- */
#define SW_BEDROOM  14
#define SW_LR_LIGHT 27
#define SW_LR_TV    26
#define SW_KITCHEN  25

/* ---------------- LED PINS ---------------- */
#define BED_LIGHT_LED 23
#define BED_FAN_LED   22
#define LR_LIGHT_LED  21
#define LR_TV_LED     19
#define KITCHEN_LED   18

/* ---------------- POWER (Watts) ---------------- */
#define P_BEDROOM          102
#define P_LR_LIGHT_TOTAL   25
#define P_LR_ENTERTAINMENT 125
#define P_KITCHEN_TOTAL    900

/* ---------------- INTERVALS ---------------- */
#define SEND_INTERVAL_MS    60000   // 1 minute telemetry
#define SAVE_INTERVAL_MS    60000   // Flash save every 1 minute
#define CONTROL_POLL_MS     1000    // Poll /control/ every 1s (faster response)
#define SYNC_COOLDOWN_MS    3000    // Ignore cloud polls for 3s after physical sync
#define DEBOUNCE_MS         50
#define STABLE_MS           100     // Physical switch must be stable for 100ms

/* ---------------- NTP ---------------- */
const char* ntpServer        = "pool.ntp.org";
const long  gmtOffset_sec    = 19800;   // IST = UTC+5:30
const int   daylightOffset_sec = 0;

/* ---------------- STORAGE ---------------- */
Preferences prefs;

float energyBedroom    = 0;
float energyLivingRoom = 0;
float energyKitchen    = 0;

unsigned long lastTime    = 0;
unsigned long lastSend    = 0;
unsigned long lastSave    = 0;
unsigned long lastControl = 0;

/* App-controlled states (read from Firebase /control/) */
bool appBedroom = false;
bool appLRLight = false;
bool appLRTV    = false;
bool appKitchen = false;

/* Last known stable physical switch states */
bool stablePhysBedroom = false;
bool stablePhysLRLight = false;
bool stablePhysLRTV    = false;
bool stablePhysKitchen = false;

/* Debounce & Sync Latency timers */
unsigned long lastDebounceBed = 0, lastSyncBed = 0;
unsigned long lastDebounceLRL = 0, lastSyncLRL = 0;
unsigned long lastDebounceLRV = 0, lastSyncLRV = 0;
unsigned long lastDebounceKit = 0, lastSyncKit = 0;

bool lastReadingBed = false;
bool lastReadingLRL = false;
bool lastReadingLRV = false;
bool lastReadingKit = false;

/* ================================================================
   WIFI
   ================================================================ */
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.print("Connecting WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }
  if (WiFi.status() == WL_CONNECTED)
    Serial.println("\nWiFi Connected!");
  else
    Serial.println("\nWiFi Failed (will retry)");
}

/* ================================================================
   TIMESTAMP
   ================================================================ */
String getTimeStamp() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "0000-00-00_00-00-00";
  char buffer[25];
  strftime(buffer, sizeof(buffer), "%Y-%m-%d_%H-%M-%S", &timeinfo);
  return String(buffer);
}

/* ================================================================
   STABLE READ (Debounced)
   Returns the current hardware state (LOW = true/ON)
   ================================================================ */
bool getSwitchHardwareState(int pin) {
  return digitalRead(pin) == LOW; // INPUT_PULLUP
}

/* ================================================================
   SAVE ENERGY TO FLASH
   ================================================================ */
void saveEnergy() {
  prefs.putFloat("bed", energyBedroom);
  prefs.putFloat("lr",  energyLivingRoom);
  prefs.putFloat("kit", energyKitchen);
  Serial.println("Energy saved to flash");
}

/* ================================================================
   POLL FIREBASE /control/ → UPDATE appXxx BOOLEANS
   ================================================================ */
void fetchControlStates() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(FIREBASE_URL) + "/control.json";
  http.begin(url);
  int code = http.GET();

  if (code == 200) {
    String payload = http.getString();
    // Payload looks like: {"bedroom":true,"kitchen":false,"lrLight":true,"lrTV":false}
    // Parse with ArduinoJson
    StaticJsonDocument<256> doc;
    DeserializationError err = deserializeJson(doc, payload);
    if (!err) {
      unsigned long now = millis();
      // Only update from cloud if NOT in the 3s cooldown period for that specific room
      if (now - lastSyncBed >= SYNC_COOLDOWN_MS && !doc["bedroom"].isNull()) 
        appBedroom = doc["bedroom"].as<bool>();
        
      if (now - lastSyncLRL >= SYNC_COOLDOWN_MS && !doc["lrLight"].isNull())
        appLRLight = doc["lrLight"].as<bool>();
        
      if (now - lastSyncLRV >= SYNC_COOLDOWN_MS && !doc["lrTV"].isNull())
        appLRTV = doc["lrTV"].as<bool>();
        
      if (now - lastSyncKit >= SYNC_COOLDOWN_MS && !doc["kitchen"].isNull())
        appKitchen = doc["kitchen"].as<bool>();
    }
  } else {
    Serial.println("fetchControlStates HTTP error: " + String(code));
  }
  http.end();
}

/* ================================================================
   SYNC SINGLE PHYSICAL SWITCH STATE TO FIREBASE /control/
   Uses specific key PATCH to avoid overwriting other switches' states
   if the local cache (appXxx) is slightly out of date.
   ================================================================ */
void syncSingleToControl(String key, bool value) {
  if (WiFi.status() != WL_CONNECTED) return;
  
  // Update cooldown timer for this key
  unsigned long now = millis();
  if (key == "bedroom") lastSyncBed = now;
  else if (key == "lrLight") lastSyncLRL = now;
  else if (key == "lrTV")    lastSyncLRV = now;
  else if (key == "kitchen") lastSyncKit = now;

  String json = "{\"" + key + "\":" + (value ? "true" : "false") + "}";

  HTTPClient http;
  String url = String(FIREBASE_URL) + "/control.json";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int code = http.PATCH(json);
  http.end();

  if (code == 200 || code == 204) {
    Serial.println("Sync SUCCESS: " + key + " -> " + String(value));
  } else {
    Serial.println("Sync ERROR: " + key + " (code " + String(code) + ")");
  }
}

/* ================================================================
   SEND TELEMETRY TO FIREBASE (/live and /logs)
   ================================================================ */
void sendToFirebase(int totalW, int bedW, int lrW, int kitW,
                    bool bed, bool lrLight, bool lrTV, bool kit) {
  if (WiFi.status() != WL_CONNECTED) return;

  String timestamp = getTimeStamp();

  float bedKWh   = energyBedroom    / 1000.0;
  float lrKWh    = energyLivingRoom / 1000.0;
  float kitKWh   = energyKitchen    / 1000.0;

  // Build JSON payload (includes switch states so app can read them from /live)
  String json = "{";
  json += "\"timestamp\":\"" + timestamp + "\",";
  json += "\"power\":{";
  json += "\"bedroom\":"    + String(bedW   / 1000.0, 3) + ",";
  json += "\"livingRoom\":" + String(lrW    / 1000.0, 3) + ",";
  json += "\"kitchen\":"    + String(kitW   / 1000.0, 3) + ",";
  json += "\"total\":"      + String(totalW / 1000.0, 3);
  json += "},";
  json += "\"energy\":{";
  json += "\"bedroom\":"    + String(bedKWh,    4) + ",";
  json += "\"livingRoom\":" + String(lrKWh,     4) + ",";
  json += "\"kitchen\":"    + String(kitKWh,    4);
  json += "},";
  // Include effective switch states (physical OR app) for app awareness
  json += "\"switches\":{";
  json += "\"bedroom\":"    + String(bed     ? "true" : "false") + ",";
  json += "\"lrLight\":"    + String(lrLight ? "true" : "false") + ",";
  json += "\"lrTV\":"       + String(lrTV    ? "true" : "false") + ",";
  json += "\"kitchen\":"    + String(kit     ? "true" : "false");
  json += "}";
  json += "}";

  /* --- LIVE (overwrite) --- */
  HTTPClient httpLive;
  String liveURL = String(FIREBASE_URL) + "/live.json";
  httpLive.begin(liveURL);
  httpLive.addHeader("Content-Type", "application/json");
  httpLive.PUT(json);
  httpLive.end();

  /* --- LOG (history, keyed by timestamp) --- */
  HTTPClient httpLog;
  String logURL = String(FIREBASE_URL) + "/logs/" + timestamp + ".json";
  httpLog.begin(logURL);
  httpLog.addHeader("Content-Type", "application/json");
  httpLog.PUT(json);
  httpLog.end();

  Serial.println("Telemetry sent → " + timestamp + " | " + String(totalW) + "W");
}

/* ================================================================
   SETUP
   ================================================================ */
void setup() {
  Serial.begin(115200);

  /* Switch pins */
  pinMode(SW_BEDROOM,  INPUT_PULLUP);
  pinMode(SW_LR_LIGHT, INPUT_PULLUP);
  pinMode(SW_LR_TV,    INPUT_PULLUP);
  pinMode(SW_KITCHEN,  INPUT_PULLUP);

  /* LED pins */
  pinMode(BED_LIGHT_LED, OUTPUT);
  pinMode(BED_FAN_LED,   OUTPUT);
  pinMode(LR_LIGHT_LED,  OUTPUT);
  pinMode(LR_TV_LED,     OUTPUT);
  pinMode(KITCHEN_LED,   OUTPUT);

  /* Restore saved energy from flash */
  prefs.begin("energy", false);
  energyBedroom    = prefs.getFloat("bed", 0);
  energyLivingRoom = prefs.getFloat("lr",  0);
  energyKitchen    = prefs.getFloat("kit", 0);

  connectWiFi();
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  delay(1000);

  /* Read app control states on boot */
  fetchControlStates();

  /* Initial hardware state */
  stablePhysBedroom = getSwitchHardwareState(SW_BEDROOM);
  stablePhysLRLight = getSwitchHardwareState(SW_LR_LIGHT);
  stablePhysLRTV    = getSwitchHardwareState(SW_LR_TV);
  stablePhysKitchen = getSwitchHardwareState(SW_KITCHEN);
  
  lastReadingBed = stablePhysBedroom;
  lastReadingLRL = stablePhysLRLight;
  lastReadingLRV = stablePhysLRTV;
  lastReadingKit = stablePhysKitchen;

  lastTime = lastSend = lastSave = lastControl = millis();
  Serial.println("Boot complete.");
}

/* ================================================================
   LOOP
   ================================================================ */
void loop() {
  /* Keep WiFi alive */
  if (WiFi.status() != WL_CONNECTED) connectWiFi();

  unsigned long now = millis();

  /* ---- 1. POLL /control/ every 2 seconds ---- */
  if (now - lastControl >= CONTROL_POLL_MS) {
    lastControl = now;
    fetchControlStates();
  }

  /* ---- 2. READ & DEBOUNCE PHYSICAL SWITCHES ---- */
  unsigned long currentTime = millis();

  // Bedroom Debounce
  bool currBed = getSwitchHardwareState(SW_BEDROOM);
  if (currBed != lastReadingBed) { lastDebounceBed = currentTime; lastReadingBed = currBed; }
  if ((currentTime - lastDebounceBed) > STABLE_MS) {
    if (currBed != stablePhysBedroom) {
      stablePhysBedroom = currBed;
      appBedroom = stablePhysBedroom; // Physical change syncs TO App
      syncSingleToControl("bedroom", appBedroom);
    }
  }

  // Living Room Light Debounce
  bool currLRL = getSwitchHardwareState(SW_LR_LIGHT);
  if (currLRL != lastReadingLRL) { lastDebounceLRL = currentTime; lastReadingLRL = currLRL; }
  if ((currentTime - lastDebounceLRL) > STABLE_MS) {
    if (currLRL != stablePhysLRLight) {
      stablePhysLRLight = currLRL;
      appLRLight = stablePhysLRLight;
      syncSingleToControl("lrLight", appLRLight);
    }
  }

  // Living Room TV Debounce
  bool currLRV = getSwitchHardwareState(SW_LR_TV);
  if (currLRV != lastReadingLRV) { lastDebounceLRV = currentTime; lastReadingLRV = currLRV; }
  if ((currentTime - lastDebounceLRV) > STABLE_MS) {
    if (currLRV != stablePhysLRTV) {
      stablePhysLRTV = currLRV;
      appLRTV = stablePhysLRTV;
      syncSingleToControl("lrTV", appLRTV);
    }
  }

  // Kitchen Debounce
  bool currKit = getSwitchHardwareState(SW_KITCHEN);
  if (currKit != lastReadingKit) { lastDebounceKit = currentTime; lastReadingKit = currKit; }
  if ((currentTime - lastDebounceKit) > STABLE_MS) {
    if (currKit != stablePhysKitchen) {
      stablePhysKitchen = currKit;
      appKitchen = stablePhysKitchen;
      syncSingleToControl("kitchen", appKitchen);
    }
  }

  /* ---- 4. EFFECTIVE STATE = APP CONTROL (Master Logic) ---- */
  bool effBedroom = appBedroom;
  bool effLRLight = appLRLight;
  bool effLRTV    = appLRTV;
  bool effKitchen = appKitchen;


  /* ---- 5. DRIVE LEDs ---- */
  digitalWrite(BED_LIGHT_LED, effBedroom);
  digitalWrite(BED_FAN_LED,   effBedroom);
  digitalWrite(LR_LIGHT_LED,  effLRLight);
  digitalWrite(LR_TV_LED,     effLRTV);
  digitalWrite(KITCHEN_LED,   effKitchen);

  /* ---- 6. ENERGY ACCUMULATION ---- */
  float hours = (now - lastTime) / 3600000.0;
  lastTime = now;

  int bedPower = effBedroom ? P_BEDROOM          : 0;
  int lrPower  = (effLRLight ? P_LR_LIGHT_TOTAL  : 0) +
                 (effLRTV    ? P_LR_ENTERTAINMENT : 0);
  int kitPower = effKitchen ? P_KITCHEN_TOTAL    : 0;
  int totalPower = bedPower + lrPower + kitPower;

  energyBedroom    += bedPower * hours;
  energyLivingRoom += lrPower  * hours;
  energyKitchen    += kitPower * hours;

  /* ---- 7. SEND TELEMETRY (every 1 minute) ---- */
  if (now - lastSend >= SEND_INTERVAL_MS) {
    lastSend = now;
    sendToFirebase(totalPower, bedPower, lrPower, kitPower,
                   effBedroom, effLRLight, effLRTV, effKitchen);
  }

  /* ---- 8. SAVE ENERGY TO FLASH (every 1 minute) ---- */
  if (now - lastSave >= SAVE_INTERVAL_MS) {
    lastSave = now;
    saveEnergy();
  }

  delay(100);
}
