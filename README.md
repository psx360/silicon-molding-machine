# Silicon Molding Machine

Repository contains two projects:

- `android-app` - Android BLE control application.
- `esp32-device` - PlatformIO Arduino firmware for an ESP32 BLE motor controller.

The shared BLE protocol is text-based:

- `PING` - request current device status.
- `RUN:<speed>:<reverse>:<revolutions>` - rotate the motor.
- `STOP` - stop rotation immediately.

The ESP32 exposes service UUID `6c8b5a90-7d2c-4c5e-98df-24a16d8a1001`,
write characteristic UUID `6c8b5a91-7d2c-4c5e-98df-24a16d8a1001`, and status
characteristic UUID `6c8b5a92-7d2c-4c5e-98df-24a16d8a1001`.
