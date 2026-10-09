import 'package:zitface_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedAudience = 'CBU Campus';
  Uint8List? _imageBytes;
  bool _isPickingImage = false;

  final List<String> _audienceOptions = [
    'Public',
    'CBU Campus',
    'SICT (Computer Science)',
    'Guild Union',
  ];

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select image: ${error.message}')),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select image: $error')));
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _submitPost() {
    final text = _postController.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    Navigator.pop(context, <String, Object?>{
      'text': text,
      'audience': _selectedAudience,
      'imageBytes': _imageBytes,
    });
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
              // Top Drag Handle & Title Bar
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
                  const Text(
                    'Create Post',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _postController,
                    builder: (context, value, _) {
                      final bool canPost =
                          value.text.trim().isNotEmpty || _imageBytes != null;
                      return ElevatedButton(
                        onPressed: canPost ? _submitPost : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPost
                              ? AppColors.accent
                              : AppColors.textPrimary.withValues(alpha: 0.1),
                          foregroundColor: canPost
                              ? AppColors.onAccent
                              : AppColors.textSecondary,
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
                          'Post',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // User Info & Audience Dropdown Selector
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textPrimary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jackson Nsonga',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _showAudienceSelector(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedAudience,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.textSecondary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Multiline Text Field Input
              TextField(
                controller: _postController,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: "What's happening on campus?",
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
              ),

              if (_imageBytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textSecondary,
                                  size: 40,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imageBytes = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textPrimary,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 10),
              Divider(color: AppColors.textPrimary.withValues(alpha: 0.08)),
              const SizedBox(height: 10),

              // Attachment Action Buttons Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Photo',
                    onTap: _pickImage,
                  ),
                  _buildActionButton(
                    icon: Icons.sell_outlined,
                    label: 'Tag Group',
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.location_on_outlined,
                    label: 'CBU Location',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudienceSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Audience',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ..._audienceOptions.map(
                (option) => ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  trailing: _selectedAudience == option
                      ? const Icon(
                          Icons.check,
                          color: AppColors.textPrimary,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedAudience = option;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
