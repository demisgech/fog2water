#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <ArduinoJson.h>
#include <Preferences.h>

//////////////////// DOMAIN MODELS ////////////////////

struct AppConfig {
  String ssid;
  String password;
  int port;
  String deviceName;
};

//////////////////// CONFIG STORAGE ////////////////////

class ConfigRepository {
public:
  AppConfig load() {
    prefs.begin("config", true);
    AppConfig cfg;
    cfg.ssid = prefs.getString("ssid", "");
    cfg.password = prefs.getString("password", "");
    cfg.port = prefs.getInt("port", 80);
    cfg.deviceName = prefs.getString("device", "fog2water");
    prefs.end();
    return cfg;
  }

  void save(const AppConfig& cfg) {
    prefs.begin("config", false);
    prefs.putString("ssid", cfg.ssid);
    prefs.putString("password", cfg.password);
    prefs.putInt("port", cfg.port);
    prefs.putString("device", cfg.deviceName);
    prefs.end();
  }

  bool isConfigured() {
    prefs.begin("config", true);
    String s = prefs.getString("ssid", "");
    prefs.end();
    return s.length() > 0;
  }

private:
  Preferences prefs;
};

//////////////////// SENSOR & SERVICE ////////////////////

class TdsSensor {
public:
  explicit TdsSensor(int pin) : _pin(pin) { pinMode(_pin, INPUT); }
  float readPpm() {
    int raw = analogRead(_pin);
    float voltage = raw * (3.3 / 4095.0);
    // Standard TDS formula
    float ppm = (133.42 * pow(voltage, 3) - 255.86 * pow(voltage, 2) + 857.39 * voltage) * 0.5;
    return ppm < 0 ? 0 : ppm;
  }
private:
  int _pin;
};

class TdsService {
public:
  explicit TdsService(TdsSensor& sensor) : _sensor(sensor) {}
  float ppm() { return _sensor.readPpm(); }
  String quality(float ppm) {
    if (ppm <= 50) return "Excellent";
    if (ppm <= 100) return "Good";
    if (ppm < 150) return "Acceptable";
    if (ppm <= 300) return "Fair";
    return "Poor / Unsafe";
  }
private:
  TdsSensor& _sensor;
};

//////////////////// API CONTROLLER ////////////////////

class ApiController {
public:
  ApiController(WebServer& server, TdsService& tds, ConfigRepository& repo, AppConfig& config)
      : _server(server), _tds(tds), _repo(repo), _config(config) {}

  void routes() {
    // Handle CORS Preflight (Important for Flutter/Web)
    _server.onNotFound([this]() {
      if (_server.method() == HTTP_OPTIONS) {
        _server.sendHeader("Access-Control-Allow-Origin", "*");
        _server.sendHeader("Access-Control-Max-Age", "10000");
        _server.sendHeader("Access-Control-Allow-Methods", "PUT,POST,GET,OPTIONS");
        _server.sendHeader("Access-Control-Allow-Headers", "*");
        _server.send(204);
      } else {
        _server.send(404, "text/plain", "Not Found");
      }
    });

    _server.on("/api/tds", HTTP_GET, [this]() { tds(); });
    _server.on("/api/health", HTTP_GET, [this]() { health(); });
    _server.on("/api/config", HTTP_GET, [this]() { getConfig(); });
    _server.on("/api/config", HTTP_POST, [this]() { setConfig(); });
    _server.on("/api/reboot", HTTP_POST, [this]() { 
        _server.send(200, "application/json", "{\"rebooting\":true}");
        delay(500);
        ESP.restart(); 
    });
  }

private:
  WebServer& _server;
  TdsService& _tds;
  ConfigRepository& _repo;
  AppConfig& _config;

  void send(JsonDocument& doc) {
    String out;
    serializeJson(doc, out);
    _server.sendHeader("Access-Control-Allow-Origin", "*"); // Allow Flutter access
    _server.send(200, "application/json", out);
  }

  void tds() {
    StaticJsonDocument<128> doc;
    float p = _tds.ppm();
    doc["ppm"] = (int)p;
    doc["quality"] = _tds.quality(p);
    send(doc);
  }

  void health() {
    StaticJsonDocument<64> doc;
    doc["status"] = "UP";
    send(doc);
  }

  void getConfig() {
    StaticJsonDocument<256> doc;
    doc["ssid"] = _config.ssid;
    doc["deviceName"] = _config.deviceName;
    doc["port"] = _config.port;
    send(doc);
  }

  void setConfig() {
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, _server.arg("plain"));

    if (error) {
      _server.send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
      return;
    }

    _config.ssid = doc["ssid"].as<String>();
    _config.password = doc["password"].as<String>();
    _config.deviceName = doc["deviceName"] | "fog2water";
    _config.port = doc["port"] | 80;

    _repo.save(_config);
    
    StaticJsonDocument<64> res;
    res["saved"] = true;
    send(res);
  }
};

//////////////////// MAIN ////////////////////

ConfigRepository repo;
AppConfig config;
TdsSensor sensor(32);
TdsService service(sensor);
WebServer server(80);
ApiController api(server, service, repo, config);

void setup() {
  Serial.begin(115200);
  delay(1000); // Give serial time to start
  
  config = repo.load();

  if (repo.isConfigured()) {
    Serial.println("Attempting to connect to: " + config.ssid);
    WiFi.mode(WIFI_STA);
    WiFi.begin(config.ssid.c_str(), config.password.c_str());
    
    int attempts = 0;
    // Wait for 10 seconds (20 * 500ms)
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
      delay(500);
      Serial.print(".");
      attempts++;
    }
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nSTA Mode Connected!");
    Serial.println("IP Address: " + WiFi.localIP().toString());
    MDNS.begin(config.deviceName.c_str());
  } else {
    // FORCE cleanup before starting AP
    Serial.println("\nFailed to connect or not configured. Starting Hotspot...");
    WiFi.disconnect(true); 
    WiFi.mode(WIFI_OFF);
    delay(100);
    
    WiFi.mode(WIFI_AP);
    // You can add a password here if you want: WiFi.softAP("SSID", "PASS")
    bool success = WiFi.softAP("Fog2Water-Setup"); 
    
    if(success) {
      Serial.println("Hotspot 'Fog2Water-Setup' is LIVE");
      Serial.print("AP IP Address: ");
      Serial.println(WiFi.softAPIP());
    } else {
      Serial.println("Hotspot start FAILED!");
    }
  }

  api.routes();
  server.begin();
}

void loop() {
  server.handleClient();
  // Keep mDNS running
  #ifdef ESP32
    // mDNS is handled by the system, no need for MDNS.update()
  #endif
}