import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../widgets/app_header.dart';
import '../services/theme_service.dart';

class ProfileEditScreen extends StatefulWidget {
  // Removed showInMainLayout as it will always be shown in the main layout
  const ProfileEditScreen({
    super.key, 
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _profileImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      
      setState(() {
        _nameController.text = userModel.name;
        _emailController.text = userModel.email ?? '';
        
        // Load profile image if it exists
        final profileImagePath = userModel.profileImagePath;
        if (profileImagePath != null && profileImagePath.isNotEmpty) {
          _profileImage = File(profileImagePath);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final dataService = Provider.of<DataService>(context, listen: false);
      
      String? profileImagePath;
      if (_profileImage != null) {
        // Save the image to app's documents directory for persistence
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await _profileImage!.copy('${appDir.path}/$fileName');
        profileImagePath = savedImage.path;
      }
      
      final updatedUser = userModel.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profileImagePath: profileImagePath ?? userModel.profileImagePath,
      );
      
      await dataService.saveUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving user data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: source);
      
      if (pickedImage == null) return;
      
      setState(() {
        _profileImage = File(pickedImage.path);
        _hasChanges = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
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
          if (_profileImage != null)
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
      appBar: AppHeader(
        title: 'Profile',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        ),
      body: _buildContent(isDarkMode, themeService),
      bottomNavigationBar: _buildSaveButton(), // Use the updated save button
    );
  }

  Widget _buildContent(bool isDarkMode, ThemeService themeService) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          backgroundColor: isDarkMode 
                              ? Colors.grey[800] 
                              : Colors.grey[200],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: isDarkMode 
                                      ? Colors.grey[400] 
                                      : Colors.grey[600],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: themeService.primaryColor,
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
        );
  }

  // Updated Save Button to match Save Reminder
  Widget _buildSaveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Material(
            color: const Color(0xFFFF85A2), // Match Save Reminder color
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