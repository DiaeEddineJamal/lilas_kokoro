import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

import '../models/sound_model.dart';
import 'data_service.dart';

class AudioService extends ChangeNotifier {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._internal();
  
  // Audio player for previewing and playing sounds
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Directory for storing custom sounds
  late Directory _soundsDirectory;
  
  // Currently playing sound ID
  String? _currentPlayingId;
  bool _isPlaying = false;
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Private constructor
  AudioService._internal();
  
  // Getters
  bool get isPlaying => _isPlaying;
  String? get currentPlayingId => _currentPlayingId;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Create directory for storing sounds
    await _createSoundsDirectory();
    
    // Set up completion listener
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _currentPlayingId = null;
        notifyListeners();
      }
    });
    
    _isInitialized = true;
    debugPrint('✅ AudioService initialized successfully');
  }
  
  // Create directory for storing sounds
  Future<void> _createSoundsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _soundsDirectory = Directory('${appDir.path}/sounds');
    
    if (!await _soundsDirectory.exists()) {
      await _soundsDirectory.create(recursive: true);
    }
  }
  
  // Play a sound with looping option
  Future<void> playSound(Sound sound, {bool loop = false}) async {
    if (!_isInitialized) await initialize();
    
    // Stop any currently playing sound
    await stopSound();
    
    try {
      // Set up the audio source
      if (sound.isAsset) {
        await _audioPlayer.setAsset(sound.storageUrl);
      } else {
        await _audioPlayer.setFilePath(sound.storageUrl);
      }
      
      // Set looping mode
      if (loop) {
        await _audioPlayer.setLoopMode(LoopMode.one);
      } else {
        await _audioPlayer.setLoopMode(LoopMode.off);
      }
      
      // Play the sound
      await _audioPlayer.play();
      
      // Update state
      _isPlaying = true;
      _currentPlayingId = sound.id;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing sound: $e');
      
      // Try to play a default sound if the original fails
      if (!sound.isDefault) {
        final dataService = DataService();
        final sounds = await dataService.getSounds();
        final defaultSound = sounds.firstWhere(
          (s) => s.isDefault && s.type == sound.type,
          orElse: () => sounds.firstWhere(
            (s) => s.isDefault,
            orElse: () => sounds.first,
          ),
        );
        
        if (defaultSound.id != sound.id) {
          await playSound(defaultSound, loop: loop);
        }
      }
    }
  }
  
  // Stop the current sound
  Future<void> stopSound() async {
    if (!_isInitialized) return;
    
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentPlayingId = null;
    notifyListeners();
  }
  
  // Pause the current sound
  Future<void> pauseSound() async {
    if (!_isInitialized) return;
    
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }
  
  // Resume playing the current sound
  Future<void> resumeSound() async {
    if (!_isInitialized) return;
    
    await _audioPlayer.play();
    _isPlaying = true;
    notifyListeners();
  }
  
  // Pick a sound file from device storage
  Future<Sound?> pickSoundFile({
    required String userId,
    SoundType type = SoundType.alarm,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Make sure we have a path
        if (file.path == null) return null;
        
        // Copy the file to our app directory
        final soundFileName = '${const Uuid().v4()}${path.extension(file.path!)}';
        final destinationPath = '${_soundsDirectory.path}/$soundFileName';
        
        // Copy the file
        await File(file.path!).copy(destinationPath);
        
        // Create a sound object
        final sound = Sound(
          name: file.name,
          storageUrl: destinationPath,
          userId: userId,
          type: type,
          isAsset: false,
          isDefault: false,
        );
        
        // Save the sound
        final dataService = DataService();
        await dataService.addSound(sound);
        
        return sound;
      }
    } catch (e) {
      debugPrint('Error picking sound file: $e');
    }
    
    return null;
  }
  
  // Get all sounds of a specific type
  Future<List<Sound>> getSoundsOfType(SoundType type) async {
    final dataService = DataService();
    final sounds = await dataService.getSounds();
    return sounds.where((s) => s.type == type).toList();
  }
  
  // Delete a custom sound
  Future<bool> deleteSound(String soundId) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Get the sound
      final dataService = DataService();
      final sounds = await dataService.getSounds();
      final sound = sounds.firstWhere(
        (s) => s.id == soundId,
        orElse: () => Sound(
          id: '',
          name: '',
          storageUrl: '',
          userId: '',
        ),
      );
      
      // Can't delete default sounds
      if (sound.isDefault || sound.id.isEmpty) return false;
      
      // Delete the file if it's not an asset
      if (!sound.isAsset) {
        final file = File(sound.storageUrl);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remove from database
      await dataService.deleteSound(soundId);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting sound: $e');
      return false;
    }
  }
  
  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
} 