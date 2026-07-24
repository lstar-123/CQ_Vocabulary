import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_memorization/services/audio_service.dart';

/// Tests for AudioService state transitions.
void main() {
  test('AudioService provider initialises in idle state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(audioServiceProvider);
    expect(state, AudioPlayState.idle);
  });

  test('AudioPlayState enum values', () {
    expect(AudioPlayState.idle.index, 0);
    expect(AudioPlayState.loading.index, 1);
    expect(AudioPlayState.playing.index, 2);
    expect(AudioPlayState.stopped.index, 3);
  });
}
