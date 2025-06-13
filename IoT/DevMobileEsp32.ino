#include <WiFi.h>
#include <HTTPClient.h>
#include "DHT.h"

// Altere com o nome e senha da sua rede
const char* ssid = "SUA_REDE_WIFI";
const char* password = "SUA_SENHA_WIFI";

// Altere com o IP do seu backend
const char* serverName = "http://IP_DO_SEU_BACKEND:5000/sensor-data";

#define DHTPIN 15     // Pino GPIO onde o pino de dados do DHT22 está conectado
#define DHTTYPE DHT22   // DHT 22

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  delay(1000);

  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Conectando ao WiFi..");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Conectado!");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    // Lê a temperatura e umidade
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    // Verifica se ambos foram lidos corretamente
    // Se não, tenta novamente.
    if (isnan(humidity) || isnan(temperature)) {
      Serial.println("ERRO: Falha ao ler temperatura do DHT!");
      delay(2000);
      return;
    }

    Serial.printf("Temperatura: %.2f °C, Umidade: %.2f %%\n", temperature, humidity);

    // Prepara o payload JSON
    String jsonPayload = "{\"temperature\": " + String(temperature, 2) + ", \"humidity\": " + String(humidity, 2) + "}";

    HTTPClient http;
    http.begin(serverName);
    http.addHeader("Content-Type", "application/json");

    int httpResponseCode = http.POST(jsonPayload);

    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.printf("Código de resposta HTTP: %d\n", httpResponseCode);
      Serial.println("Resposta do servidor: " + response);
    } else {
      Serial.printf("ERRO: Falha ao enviar HTTP POST: %d\n", httpResponseCode);
    }
    http.end();
  } else {
    Serial.println("WiFi Desconectado");
  }

  delay(10000); // Envia nova leitura a cada 10 segundos
}
