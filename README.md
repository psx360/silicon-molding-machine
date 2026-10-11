# Silicon Molding Machine

Repository contains two projects:

- `android-app` - Android BLE control application.
- `esp32-device` - PlatformIO Arduino firmware for an ESP32 BLE motor controller.

Version 2 is being developed in `control-app`: a shared Flutter Windows/Android
application with an animated three-motor machine diagram. The initial application
is a simulation and does not send commands to the existing single-motor firmware.
See `control-app/README.md` for launch instructions and `AGENTS.md` for requirements.
For automatic local Windows setup, building and launching with Codex, follow
`WINDOWS_HANDOFF.md` and the PowerShell scripts in `scripts/`.

The shared BLE protocol is text-based:

- `PING` - request current device status.
- `RUN:<speed>:<reverse>:<revolutions>` - rotate the motor.
- `STOP` - stop rotation immediately.

The ESP32 exposes service UUID `6c8b5a90-7d2c-4c5e-98df-24a16d8a1001`,
write characteristic UUID `6c8b5a91-7d2c-4c5e-98df-24a16d8a1001`, and status
characteristic UUID `6c8b5a92-7d2c-4c5e-98df-24a16d8a1001`.
