import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../widgets/app_header.dart';
import '../services/theme_service.dart';
import '../widgets/gradient_app_bar.dart';

class ProfileEditScreen extends StatefulWidget {
  // Removed showInMainLayout as it will always be shown in the main layout
  const ProfileEditScreen({
    super.key, 
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    _nameController.text = userModel.name;
    _emailController.text = userModel.email;
    
    // Load existing profile image if available
    if (userModel.profileImagePath != null && userModel.profileImagePath!.isNotEmpty) {
      _profileImage = File(userModel.profileImagePath!);
    }
  }

  Future<String?> _saveProfileImage(File imageFile) async {
    try {
      // Get the app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      
      // Create a unique filename
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = path.join(appDir.path, fileName);
      
      // Copy the image to the app directory
      await imageFile.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      return null;
    }
  }

  Future<void> _saveUserData() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final dataService = Provider.of<DataService>(context, listen: false);
      
      String? profileImagePath;
      
      // Save profile image if changed
      if (_profileImage != null) {
        profileImagePath = await _saveProfileImage(_profileImage!);
        if (profileImagePath == null) {
          throw Exception('Failed to save profile image');
        }
      }
      
      // Update user data using copyWith and save to storage
      final updatedUser = userModel.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profileImagePath: profileImagePath ?? userModel.profileImagePath,
      );
      
      // Save to data service which will update the UserModel provider
      await dataService.saveUser(updatedUser);
      
      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Return true to indicate changes were made
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          if (_profileImage != null || (Provider.of<UserModel>(context, listen: false).profileImagePath?.isNotEmpty ?? false))
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _profileImage = null;
                  _hasChanges = true;
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;

    return Scaffold(
      appBar: GradientAppBar(
        title: '👤 Edit Profile',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _buildContent(isDarkMode, themeService),
      bottomNavigationBar: _buildSaveButton(themeService),
    );
  }

  Widget _buildContent(bool isDarkMode, ThemeService themeService) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                  
                    // Profile Picture
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: themeService.primary,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? Consumer<UserModel>(
                                    builder: (context, userModel, child) {
                                      if (userModel.profileImagePath != null && userModel.profileImagePath!.isNotEmpty) {
                                        return ClipOval(
                                          child: Image.file(
                                            File(userModel.profileImagePath!),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Text(
                                                userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : 'U',
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }
                                      return Text(
                                        userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: themeService.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                      Text(
                      "Tap to change profile picture",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        fontSize: 14,
                        ),
                      ),
                    
                    const SizedBox(height: 30),
                    
                    // Name TextField
                    TextField(
                        controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                          ),
                      onChanged: (value) {
                        setState(() {
                          _hasChanges = true;
                        });
                        },
                      ),
                      
                    const SizedBox(height: 16),
                      
                    // Email TextField
                    TextField(
                        controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                          ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          _hasChanges = true;
                        });
                        },
                      ),
                      
                    // Add padding at the bottom to ensure content isn't hidden by the button
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
  }

  // Updated Save Button to match Save Reminder
  Widget _buildSaveButton(ThemeService themeService) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Material(
            color: themeService.primary, // Use dynamic theme color
            borderRadius: BorderRadius.circular(16), // Match Save Reminder radius
            child: InkWell(
              borderRadius: BorderRadius.circular(16), // Match Save Reminder radius
              onTap: _hasChanges && !_isLoading ? _saveUserData : null,
              child: Center(
                child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18, // Match Save Reminder text style
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                                ),
                    ),
              ),
            ),
          ),
                ),
              ),
    );
  }
}