import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/sound_model.dart';
import 'local_storage_service.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();
  
  final LocalStorageService _storage = LocalStorageService();
  
  // Get all sounds
  Future<List<Sound>> getSounds() async {
    return await _storage.getSounds();
  }
  
  // Add a new sound
  Future<Sound?> addSound(String name, String userId) async {
    try {
      // Pick a sound file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      final file = File(result.files.first.path!);
      final fileName = path.basename(file.path);
      
      // Create sounds directory if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${appDir.path}/alarm_sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }
      
      // Copy file to app directory
      final savedPath = '${soundsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await file.copy(savedPath);
      
      // Create sound model
      final sound = Sound(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        storageUrl: savedPath,
        userId: userId,
        createdAt: DateTime.now(),
      );
      
      // Save to storage
      final sounds = await _storage.getSounds();
      sounds.add(sound);
      await _storage.saveSounds(sounds);
      
      return sound;
    } catch (e) {
      debugPrint('❌ Error adding sound: $e');
      return null;
    }
  }
  
  // Delete a sound
  Future<bool> deleteSound(String soundId) async {
    try {
      final sounds = await _storage.getSounds();
      final soundIndex = sounds.indexWhere((s) => s.id == soundId);
      
      if (soundIndex >= 0) {
        final sound = sounds[soundIndex];
        
        // Delete the file
        final file = File(sound.storageUrl);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Remove from list
        sounds.removeAt(soundIndex);
        await _storage.saveSounds(sounds);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting sound: $e');
      return false;
    }
  }
  
  // Get default sounds
  Future<List<Sound>> getDefaultSounds(String userId) async {
    final defaultSounds = [
      Sound(
        id: 'default_1',
        name: 'Gentle Chime',
        storageUrl: 'assets/sounds/gentle_chime.mp3',
        userId: userId,
        createdAt: DateTime.now(),
      ),
      Sound(
        id: 'default_2',
        name: 'Morning Birds',
        storageUrl: 'assets/sounds/morning_birds.mp3',
        userId: userId,
        createdAt: DateTime.now(),
      ),
      Sound(
        id: 'default_3',
        name: 'Soft Bell',
        storageUrl: 'assets/sounds/soft_bell.mp3',
        userId: userId,
        createdAt: DateTime.now(),
      ),
    ];
    
    return defaultSounds;
  }
}