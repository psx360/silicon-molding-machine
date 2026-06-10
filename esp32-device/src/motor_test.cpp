#include <Arduino.h>

static const uint8_t STEP_PIN = 6;
static const uint8_t DIR_PIN = 7;
static const uint8_t EN_PIN = 8;

static const uint16_t STEPS_PER_REVOLUTION = 600;
static const unsigned long STEP_INTERVAL_MICROS = 2000;
static const unsigned int STEP_PULSE_MICROS = 5;
static const unsigned long PAUSE_BETWEEN_DIRECTIONS_MS = 1000;

void waitForSerial() {
  Serial.begin(115200);
  unsigned long started = millis();
  while (!Serial && millis() - started < 2000) {
    delay(10);
  }
}

void stepMotor(uint16_t steps, bool reverse) {
  Serial.println(reverse ? "Test: one revolution reverse" : "Test: one revolution forward");
  Serial.flush();

  digitalWrite(DIR_PIN, reverse ? HIGH : LOW);
  // digitalWrite(EN_PIN, LOW);
  delay(50);

  for (uint16_t i = 0; i < steps; i++) {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(STEP_PULSE_MICROS);
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(STEP_INTERVAL_MICROS);
  }

  // digitalWrite(EN_PIN, HIGH);
}

void setup() {
  waitForSerial();
  Serial.println("Motor test started...");
  Serial.flush();

  pinMode(STEP_PIN, OUTPUT);
  pinMode(DIR_PIN, OUTPUT);
  pinMode(EN_PIN, OUTPUT);

  digitalWrite(STEP_PIN, LOW);
  digitalWrite(DIR_PIN, LOW);
  digitalWrite(EN_PIN, LOW);
}

void loop() {
  stepMotor(STEPS_PER_REVOLUTION, false);
  delay(PAUSE_BETWEEN_DIRECTIONS_MS);
  stepMotor(STEPS_PER_REVOLUTION, true);
  delay(PAUSE_BETWEEN_DIRECTIONS_MS);
}
