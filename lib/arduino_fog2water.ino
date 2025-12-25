#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>
#include <ArduinoJson.h>
#include <TelegramCertificate.h>
#include <functional>
#include <math.h>

/* =========================================================
   CONFIGURATION
   ========================================================= */
class Config {
public:
  const String ssid;
  const String password;
  const String botToken;
  const String chatId;

  const float vRef;
  const float tdsFactor;
  const unsigned long pollInterval;

  Config(
    String ssid,
    String password,
    String botToken,
    String chatId,
    float vRef = 3.3,
    float tdsFactor = 0.5,
    unsigned long pollInterval = 1000
  )
    : ssid(ssid),
      password(password),
      botToken(botToken),
      chatId(chatId),
      vRef(vRef),
      tdsFactor(tdsFactor),
      pollInterval(pollInterval) {}
};

/* =========================================================
   WIFI MANAGER
   ========================================================= */
class WiFiManager {
public:
  static void connect(const String& ssid, const String& password) {
    WiFi.begin(ssid.c_str(), password.c_str());
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
    }
  }
};

/* =========================================================
   TDS SENSOR
   ========================================================= */
class TDSSensor {
  int pin;
  float adcResolution;

public:
  TDSSensor(int pin, float adcResolution)
    : pin(pin), adcResolution(adcResolution) {}

  float read(float vRef, float factor) {
    int raw = analogRead(pin);
    float voltage = raw * (vRef / adcResolution);

    float tds =
      (133.42 * pow(voltage, 3)
     - 255.86 * pow(voltage, 2)
     + 857.39 * voltage)
     * factor;

    return tds;
  }
};

/* =========================================================
   TELEGRAM BOT WRAPPER
   ========================================================= */
class TelegramBotWrapper {
  WiFiClientSecure client;
  UniversalTelegramBot bot;
  unsigned long lastPoll = 0;

public:
  TelegramBotWrapper(const String& token)
    : bot(token, client) {
    client.setCACert(TELEGRAM_CERTIFICATE_ROOT);
  }

  void poll(
    unsigned long interval,
    std::function<void(const String&, const String&)> handler
  ) {
    if (millis() - lastPoll < interval) return;

    int count = bot.getUpdates(bot.last_message_received + 1);
    for (int i = 0; i < count; i++) {
      handler(bot.messages[i].text, bot.messages[i].chat_id);
    }
    lastPoll = millis();
  }

  void send(const String& chatId, const String& message) {
    bot.sendMessage(chatId, message, "");
  }
};

/* =========================================================
   GLOBAL OBJECTS
   ========================================================= */
Config config(
  "YOUR_WIFI_NAME",
  "YOUR_WIFI_PASSWORD",
  "YOUR_BOT_TOKEN",
  "YOUR_CHAT_ID"
);

TDSSensor tds(32, 4095.0);
TelegramBotWrapper telegram(config.botToken);

/* =========================================================
   COMMAND HANDLER
   ========================================================= */
   
void handleCommand(const String& text, const String& chatId) {
  if (text == "/start") {
    telegram.send(
      chatId,
      "💧 Water Monitor Online!\nSend /check to read water quality."
    );
  }

  if (text == "/check") {
    float tdsValue = tds.read(config.vRef, config.tdsFactor);

    String message = "🌊 Water Status Report\n";
    message += "PPM Level: " + String(tdsValue, 0) + " ppm\n";

    telegram.send(chatId, message);
  }
}

/* =========================================================
   ARDUINO LIFECYCLE
   ========================================================= */
void setup() {
  Serial.begin(115200);
  WiFiManager::connect(config.ssid, config.password);
}

void loop() {
  telegram.poll(config.pollInterval, handleCommand);
}
