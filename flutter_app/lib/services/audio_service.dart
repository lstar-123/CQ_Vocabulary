import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/tts_repository.dart';

/// Playback state for the shared audio service.
enum AudioPlayState { idle, loading, playing, stopped }

/// Shared audio service — the single entry point for TTS playback.
///
/// Used by Flashcard, Spelling, and Quiz screens. Each screen watches
/// [audioServiceProvider] to react to playback state changes.
class AudioNotifier extends Notifier<AudioPlayState> {
  @override
  AudioPlayState build() {
    ref.onDispose(() {
      _player?.dispose();
      _player = null;
    });
    return AudioPlayState.idle;
  }

  AudioPlayer? _player;
  Uint8List? _cachedBytes;
  String? _currentWord;

  AudioPlayer get _p => _player ??= AudioPlayer();

  /// Fetch TTS audio for [text] and start playback.
  Future<void> play(String text) async {
    // If same word, just replay from cache.
    if (_currentWord == text && _cachedBytes != null) {
      await _p.stop();
      await _p.play(BytesSource(_cachedBytes!));
      state = AudioPlayState.playing;
      return;
    }

    _currentWord = text;
    state = AudioPlayState.loading;

    final repo = TtsRepository();
    try {
      _cachedBytes = await repo.speak(text);
      await _p.stop();
      await _p.play(BytesSource(_cachedBytes!));
      state = AudioPlayState.playing;

      // Listen for completion.
      _p.onPlayerComplete.first.then((_) {
        if (state == AudioPlayState.playing) {
          state = AudioPlayState.stopped;
        }
      });
    } on Exception {
      state = AudioPlayState.stopped;
      rethrow;
    }
  }

  /// Stop playback.
  Future<void> stop() async {
    await _p.stop();
    state = AudioPlayState.stopped;
  }

  /// Replay the last word from cache.
  Future<void> replay() async {
    if (_cachedBytes == null) return;
    state = AudioPlayState.loading;
    await _p.stop();
    await _p.play(BytesSource(_cachedBytes!));
    state = AudioPlayState.playing;
  }

  /// Release the player.
  Future<void> disposePlayer() async {
    await _p.dispose();
    _player = null;
    _cachedBytes = null;
    _currentWord = null;
    state = AudioPlayState.idle;
  }
}

/// Shared audio service provider. All audio goes through this.
final audioServiceProvider =
    NotifierProvider<AudioNotifier, AudioPlayState>(
  AudioNotifier.new,
);
