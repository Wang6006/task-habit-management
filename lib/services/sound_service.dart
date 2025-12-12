import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playCompletionSound() async {
    try {
      await _player.stop();
      
      await _player.play(AssetSource('sounds/complete_sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }
}