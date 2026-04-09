import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class SoundboardScreen extends StatefulWidget {
  const SoundboardScreen({super.key});

  @override
  State<SoundboardScreen> createState() => _SoundboardScreenState();
}

class _SoundboardScreenState extends State<SoundboardScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AutoPlayAudioPlayer _audioPlayer = AutoPlayAudioPlayer();

  bool _isRecording = false;
  String? _tempPath;
  List<String?> _buttonPaths = List.filled(6, null);

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/temp_record.wav';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _tempPath = null;
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _tempPath = path;
        }
      });
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  Future<void> _onButtonPress(int index) async {
    if (_tempPath != null) {
      // Save it to this button
      final dir = await getApplicationDocumentsDirectory();
      final newPath = '${dir.path}/sound_$index.wav';

      final file = File(_tempPath!);
      await file.copy(newPath);

      setState(() {
        _buttonPaths[index] = newPath;
        _tempPath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sound saved to Button ${index + 1}')),
        );
      }
    } else {
      // Play existing sound
      final path = _buttonPaths[index];
      if (path != null) {
        await _audioPlayer.play(DeviceFileSource(path));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No sound recorded for Button ${index + 1} yet.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soundboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isRecording
                  ? 'Recording...'
                  : (_tempPath != null
                        ? 'Select a button below to save the recording!'
                        : 'Press Record to start.'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isRecording ? null : _startRecording,
                icon: const Icon(Icons.mic),
                label: const Text('Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                final hasSound = _buttonPaths[index] != null;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tempPath != null
                        ? Colors.orange
                        : (hasSound ? Colors.green : Colors.grey.shade400),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _onButtonPress(index),
                  child: Text(
                    _tempPath != null
                        ? 'Save to Button ${index + 1}'
                        : 'Button ${index + 1}',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Simple wrapper for AudioPlayer
class AutoPlayAudioPlayer extends AudioPlayer {
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    await stop(); // stop any currently playing sounds
    await super.play(
      source,
      volume: volume,
      balance: balance,
      ctx: ctx,
      position: position,
      mode: mode,
    );
  }
}
