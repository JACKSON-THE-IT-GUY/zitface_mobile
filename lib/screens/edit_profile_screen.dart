import 'package:zitface_mobile/theme/app_theme.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentHandle;
  final String currentSchool;
  final String currentBio;
  final String currentPhotoPath;
  final String currentPhotoData;
  final bool isCreating;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentHandle,
    required this.currentSchool,
    required this.currentBio,
    this.currentPhotoPath = '',
    this.currentPhotoData = '',
    this.isCreating = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _schoolController;
  late TextEditingController _bioController;
  final ImagePicker _imagePicker = ImagePicker();
  late String _photoPath;
  late String _photoData;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _handleController = TextEditingController(text: widget.currentHandle);
    _schoolController = TextEditingController(text: widget.currentSchool);
    _bioController = TextEditingController(text: widget.currentBio);
    _photoPath = widget.currentPhotoPath;
    _photoData = widget.currentPhotoData;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _schoolController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your display name.')),
      );
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'handle': _handleController.text.trim(),
      'school': _schoolController.text.trim(),
      'bio': _bioController.text.trim(),
      'photoPath': _photoPath,
      'photoData': _photoData,
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _photoPath = '';
          _photoData = base64Encode(bytes);
        });
      }
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select profile photo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    widget.isCreating ? 'Create Profile' : 'Edit Profile',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Avatar Edit Box
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _pickPhoto,
                      borderRadius: BorderRadius.circular(48),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                    border: Border.all(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(child: _buildPhotoPreview()),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.onAccent,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _photoData.isEmpty && _photoPath.isEmpty
                                  ? 'Add profile photo'
                                  : 'Change photo',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_photoData.isNotEmpty || _photoPath.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          _photoPath = '';
                          _photoData = '';
                        }),
                        child: const Text('Remove photo'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Input Fields
              _buildInputField(
                label: 'Display Name',
                controller: _nameController,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                label: 'Student Handle',
                controller: _handleController,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                label: 'CBU School / Major',
                controller: _schoolController,
              ),
              const SizedBox(height: 14),
              _buildInputField(
                label: 'Bio',
                controller: _bioController,
                maxLines: 3,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    if (_photoData.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(_photoData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _emptyAvatar(),
        );
      } on FormatException {
        return _emptyAvatar();
      }
    }
    return _emptyAvatar();
  }

  Widget _emptyAvatar() {
    return const Icon(Icons.person, color: AppColors.accent, size: 40);
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }
}
