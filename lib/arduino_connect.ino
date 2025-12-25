#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>
#include <ArduinoJson.h>


//  WiFi Credentials
const char* ssid = "YOUR_WIFI_NAME";
const char* password = "YOUR_WIFI_PASSWORD";

//  Telegram Bot Credentials
const char* botToken = "YOUR_BOT_TOKEN_HERE";  // Get from BotFather
const char* chatID = "YOUR_CHAT_ID_HERE";      // Get from IDBot

// ================= SENSOR SETTINGS ===============
const int tdsPin = 32;          // The pin you connected (D32)
float vRef = 3.3;               // ESP32 Reference Voltage
float adcResolution = 4095.0;   // ESP32 is 12-bit (0-4095)

// checks every X milliseconds (1000ms = 1 second)
unsigned long botRequestDelay = 1000; 
unsigned long lastTimeBotRan;

WiFiClientSecure client;
UniversalTelegramBot bot(botToken, client);

void setup() {
  Serial.begin(115200);

  // Connect to WiFi
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected!");

  // Secure connection setup for Telegram
  client.setCACert(TELEGRAM_CERTIFICATE_ROOT); 

  // Send a startup message so you know it's working
  bot.sendMessage(chatID, "💧 TDS Water Monitor is Online! Send /check to read water quality.", "");
}

void loop() {
  if (millis() > lastTimeBotRan + botRequestDelay) {
    int numNewMessages = bot.getUpdates(bot.last_message_received + 1);

    while (numNewMessages) {
      handleNewMessages(numNewMessages);
      numNewMessages = bot.getUpdates(bot.last_message_received + 1);
    }
    lastTimeBotRan = millis();
  }
}

// Function to handle incoming Telegram messages
void handleNewMessages(int numNewMessages) {
  for (int i = 0; i < numNewMessages; i++) {
    String chat_id = String(bot.messages[i].chat_id);
    String text = bot.messages[i].text;

    if (text == "/check") {
      float tdsValue = readTDS();
      String quality = getWaterQuality(tdsValue);
      
      String message = "🌊 Water Status Report:\n";
      message += "PPM Level: " + String(tdsValue, 0) + " ppm\n";
      message += "Quality: " + quality + "\n";
      
      bot.sendMessage(chat_id, message, "");
    }
    
    if (text == "/start") {
      String welcome = "Welcome! Type /check to see current water quality.";
      bot.sendMessage(chat_id, welcome, "");
    }
  }
}

// Function to Calculate Water Quality based on your ranges
String getWaterQuality(float tds) {
  if (tds >= 0 && tds <= 50) {
    return "Excellent to Drink ✅";
  } 
  else if (tds > 50 && tds <= 100) {
    return "Good to Drink 👌";
  }
  else if (tds > 100 && tds < 150) {
    // You didn't specify 100-150, but usually this is 'Hard but Acceptable'
    return "Acceptable / Hard Water 😐";
  }
  else if (tds >= 150 && tds <= 300) {
    return "Fair (Filtration Recommended) ⚠️";
  }
  else if (tds > 300 && tds <= 500) {
    return "Poor (Do Not Drink) ❌";
  }
  else {
    return "UNSAFE / HAZARDOUS ☠️";
  }
}

// Function to read the Sensor
float readTDS() {
  int analogValue = analogRead(tdsPin);
  
  // Convert analog reading to Voltage
  float voltage = analogValue * (vRef / adcResolution);
  
  // Simple TDS Formula (Approximation)
  // Usually: TDS = (Voltage * k_value) -> simplified here
  // Adjust this factor (0.5) if you have a calibration buffer solution
  float tdsFactor = 0.5; 
  
  // Convert voltage to TDS value
  // Depending on your specific sensor model, the math varies.
  // This is the standard linear approximation for generic probes.
  float tdsValue = (133.42 * voltage * voltage * voltage - 255.86 * voltage * voltage + 857.39 * voltage) * tdsFactor;
  
  return tdsValue;
}