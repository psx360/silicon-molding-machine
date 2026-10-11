import 'package:flutter_test/flutter_test.dart';
import 'package:silicon_control/machine.dart';

void main() {
  test('Hold, release and endpoints keep cups independent', () {
    final machine = Machine();
    machine.hold('A', 1);
    machine.advance(1);
    expect(machine.angleA, 30);
    expect(machine.angleB, 0);
    machine.release('A');
    machine.advance(1);
    expect(machine.angleA, 30);
    machine.hold('A', 1);
    machine.advance(10);
    expect(machine.angleA, 90);
    machine.hold('A', -1);
    machine.advance(10);
    expect(machine.angleA, 0);
    machine.dispose();
  });
  test('Stop freezes cups and mixer', () {
    final machine = Machine();
    machine.hold('B', 1);
    machine.toggleMixer();
    machine.advance(.25);
    final angle = machine.angleB;
    final phase = machine.mixerPhase;
    machine.stop();
    machine.advance(1);
    expect(machine.angleB, angle);
    expect(machine.mixerPhase, phase);
    expect(machine.mixing, false);
    machine.dispose();
  });
}
