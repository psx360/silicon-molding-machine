#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

static const char *DEVICE_NAME = "Silicon Molding Machine";
static const char *SERVICE_UUID = "6c8b5a90-7d2c-4c5e-98df-24a16d8a1001";
static const char *WRITE_UUID = "6c8b5a91-7d2c-4c5e-98df-24a16d8a1001";
static const char *STATUS_UUID = "6c8b5a92-7d2c-4c5e-98df-24a16d8a1001";

static const uint8_t STEP_PIN = 6;
static const uint8_t DIR_PIN = 7;
static const uint8_t EN_PIN = 8;
static const uint16_t STEPS_PER_REVOLUTION = 1600;

BLECharacteristic *statusCharacteristic = nullptr;

volatile bool running = false;
volatile long stepsRemaining = 0;
unsigned long lastStepMicros = 0;
unsigned long stepIntervalMicros = 2000;

void publishStatus(const char *state) {
  if (statusCharacteristic == nullptr) {
    return;
  }

  statusCharacteristic->setValue(state);
  statusCharacteristic->notify();
}

void stopMotor() {
  running = false;
  stepsRemaining = 0;
  publishStatus("STATUS:STOPPED");
}

void startMotor(int rpm, bool reverse, float revolutions) {
  rpm = constrain(rpm, 1, 500);
  revolutions = constrain(revolutions, 0.01f, 1000.0f);

  const unsigned long stepsPerMinute = static_cast<unsigned long>(rpm) * STEPS_PER_REVOLUTION;
  stepIntervalMicros = max(200UL, 60000000UL / stepsPerMinute);
  stepsRemaining = max(1L, lroundf(revolutions * STEPS_PER_REVOLUTION));
  digitalWrite(DIR_PIN, reverse ? HIGH : LOW);
  running = true;
  lastStepMicros = micros();
  publishStatus("STATUS:RUNNING");
}

void handleCommand(String command) {
  command.trim();

  if (command == "PING") {
    publishStatus(running ? "STATUS:RUNNING" : "STATUS:READY");
    return;
  }

  if (command == "STOP") {
    stopMotor();
    return;
  }

  if (command.startsWith("RUN:")) {
    int first = command.indexOf(':');
    int second = command.indexOf(':', first + 1);
    int third = command.indexOf(':', second + 1);
    if (first < 0 || second < 0 || third < 0) {
      publishStatus("STATUS:BAD_COMMAND");
      return;
    }

    int rpm = command.substring(first + 1, second).toInt();
    bool reverse = command.substring(second + 1, third).toInt() != 0;
    float revolutions = command.substring(third + 1).toFloat();
    startMotor(rpm, reverse, revolutions);
    return;
  }

  publishStatus("STATUS:UNKNOWN_COMMAND");
}

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    String command = characteristic->getValue().c_str();
    handleCommand(command);
  }
};

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *) override {
    publishStatus("STATUS:READY");
  }

  void onDisconnect(BLEServer *server) override {
    stopMotor();
    server->startAdvertising();
  }
};

void setup() {
  Serial.begin(115200);
  unsigned long serialWaitStarted = millis();
  while (!Serial && millis() - serialWaitStarted < 2000) {
    delay(10);
  }
  Serial.println("Started...");
  Serial.flush();

  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);
  digitalWrite(STEP_PIN, LOW);
  digitalWrite(DIR_PIN, LOW);
  digitalWrite(EN_PIN, LOW);

  BLEDevice::init(DEVICE_NAME);
  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());

  BLEService *service = server->createService(SERVICE_UUID);

  BLECharacteristic *writeCharacteristic = service->createCharacteristic(
      WRITE_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  writeCharacteristic->setCallbacks(new CommandCallbacks());

  statusCharacteristic = service->createCharacteristic(
      STATUS_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  statusCharacteristic->setValue("STATUS:READY");

  service->start();
  server->getAdvertising()->addServiceUUID(SERVICE_UUID);
  server->getAdvertising()->start();
}

void loop() {
  if (!running) {
    delay(10);
    return;
  }

  const unsigned long now = micros();
  if (now - lastStepMicros >= stepIntervalMicros) {
    lastStepMicros = now;
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(5);
    digitalWrite(STEP_PIN, LOW);
    stepsRemaining--;

    if (stepsRemaining <= 0) {
      stopMotor();
    }
  }
}
