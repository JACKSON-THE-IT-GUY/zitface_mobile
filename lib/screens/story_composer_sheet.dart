import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../services/story_video_controller.dart';
import '../theme/app_theme.dart';

class StoryComposerSheet extends StatefulWidget {
  const StoryComposerSheet({super.key});

  @override
  State<StoryComposerSheet> createState() => _StoryComposerSheetState();
}

class _StoryComposerSheetState extends State<StoryComposerSheet> {
  static const _maxStoryBytes = 52428800;
  static const _maxVideoDuration = Duration(seconds: 60);

  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _captionController = TextEditingController();
  String _mediaType = 'image';
  String _visibility = 'friends';
  Uint8List? _mediaBytes;
  String? _contentType;
  int? _durationSeconds;
  VideoPlayerController? _videoController;
  Uint8List? _audioBytes;
  String? _audioContentType;
  String? _audioName;
  bool _audioRightsConfirmed = false;
  bool _isPicking = false;
  String? _errorMessage;
  bool _isMuted = true;

  @override
  void dispose() {
    _videoController?.dispose();
    unawaited(_audioPlayer.dispose());
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;

      final extension = (file.extension ?? '').toLowerCase();
      final contentType = switch (extension) {
        'mp3' => 'audio/mpeg',
        'm4a' => 'audio/mp4',
        'aac' => 'audio/aac',
        'wav' => 'audio/wav',
        'ogg' => 'audio/ogg',
        _ => null,
      };
      final bytes = file.bytes;
      if (contentType == null || bytes == null || bytes.isEmpty) {
        throw const FormatException('Choose a supported audio file.');
      }
      if (bytes.lengthInBytes > 10485760) {
        throw const FormatException('Soundtracks must be 10 MB or smaller.');
      }

      final path = file.path;
      final sourceUri = path == null
          ? Uri.dataFromBytes(bytes, mimeType: contentType)
          : kIsWeb
          ? Uri.parse(path)
          : Uri.file(path);
      await _audioPlayer.setAudioSource(
        AudioSource.uri(sourceUri),
      );
      if (!mounted) return;
      setState(() {
        _audioBytes = bytes;
        _audioContentType = contentType;
        _audioName = file.name;
        _audioRightsConfirmed = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    }
  }

  Future<void> _toggleAudioPreview() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      unawaited(_audioPlayer.play());
    }
    if (mounted) setState(() {});
  }

  String? _contentTypeFor(XFile file, String mediaType) {
    final extension = file.name.split('.').last.toLowerCase();
    final detected = file.mimeType ?? switch ((mediaType, extension)) {
      ('image', 'jpg' || 'jpeg') => 'image/jpeg',
      ('image', 'png') => 'image/png',
      ('image', 'webp') => 'image/webp',
      ('video', 'mp4') => 'video/mp4',
      ('video', 'mov') => 'video/quicktime',
      _ => null,
    };
    final allowed = mediaType == 'image'
        ? const {'image/jpeg', 'image/png', 'image/webp'}
        : const {'video/mp4', 'video/quicktime'};
    return allowed.contains(detected) ? detected : null;
  }

  Future<void> _pickMedia() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });
    VideoPlayerController? nextVideoController;
    try {
      final file = _mediaType == 'image'
          ? await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 88,
            )
          : await _picker.pickVideo(
              source: ImageSource.gallery,
              maxDuration: _maxVideoDuration,
            );
      if (file == null) return;

      final contentType = _contentTypeFor(file, _mediaType);
      if (contentType == null) {
        throw FormatException(
          _mediaType == 'image'
              ? 'Choose a JPEG, PNG, or WebP photo.'
              : 'Choose an MP4 or MOV video.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.lengthInBytes > _maxStoryBytes) {
        throw const FormatException('Story media must be 50 MB or smaller.');
      }

      int? durationSeconds;
      if (_mediaType == 'video') {
        nextVideoController = createStoryVideoController(file.path);
        await nextVideoController.initialize();
        if (nextVideoController.value.duration > _maxVideoDuration) {
          throw const FormatException('Story videos must be 60 seconds or less.');
        }
        durationSeconds = (nextVideoController.value.duration.inMilliseconds / 1000)
            .ceil();
        await nextVideoController.setLooping(true);
        await nextVideoController.setVolume(0);
      }

      if (!mounted) {
        await nextVideoController?.dispose();
        return;
      }
      await _videoController?.dispose();
      setState(() {
        _mediaBytes = bytes;
        _contentType = contentType;
        _durationSeconds = durationSeconds;
        _videoController = nextVideoController;
      });
      nextVideoController = null;
    } on Exception catch (error) {
      await nextVideoController?.dispose();
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _selectMediaType(String mediaType) {
    if (_mediaType == mediaType) return;
    _videoController?.dispose();
    setState(() {
      _mediaType = mediaType;
      _mediaBytes = null;
      _contentType = null;
      _durationSeconds = null;
      _videoController = null;
      _errorMessage = null;
    });
  }

  Future<void> _toggleVideo() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    final controller = _videoController;
    if (controller == null) return;
    _isMuted = !_isMuted;
    await controller.setVolume(_isMuted ? 0 : 1);
    if (mounted) setState(() {});
  }

  void _submit() {
    final bytes = _mediaBytes;
    final contentType = _contentType;
    if (bytes == null || contentType == null) return;
    Navigator.pop(context, <String, Object?>{
      'mediaBytes': bytes,
      'mediaType': _mediaType,
      'contentType': contentType,
      'durationSeconds': _durationSeconds,
      'caption': _captionController.text.trim(),
      'visibility': _visibility,
      'audioBytes': _audioBytes,
      'audioContentType': _audioContentType,
      'audioRightsConfirmed': _audioRightsConfirmed,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Close story composer',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Expanded(
                    child: Text(
                      'Create story',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share story',
                    onPressed: !_canShare ? null : _submit,
                    icon: Icon(
                      Icons.send,
                      color: _mediaBytes == null
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'image',
                    icon: Icon(Icons.photo_outlined),
                    label: Text('Photo'),
                  ),
                  ButtonSegment(
                    value: 'video',
                    icon: Icon(Icons.videocam_outlined),
                    label: Text('Video'),
                  ),
                ],
                selected: {_mediaType},
                onSelectionChanged: (selection) =>
                    _selectMediaType(selection.first),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _mediaBytes == null
                    ? Center(
                        child: _isPicking
                            ? const CircularProgressIndicator()
                            : OutlinedButton.icon(
                                onPressed: _pickMedia,
                                icon: Icon(
                                  _mediaType == 'image'
                                      ? Icons.photo_library_outlined
                                      : Icons.video_library_outlined,
                                ),
                                label: Text(
                                  _mediaType == 'image'
                                      ? 'Choose photo'
                                      : 'Choose video (up to 60 seconds)',
                                ),
                              ),
                      )
                    : _mediaType == 'image'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _mediaBytes!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      )
                    : _buildVideoPreview(theme),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _captionController,
                maxLength: 240,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add a caption',
                  counterText: '',
                  prefixIcon: Icon(Icons.short_text),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _audioBytes == null ? Icons.music_note : Icons.audiotrack,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _audioName ?? 'Add your own soundtrack',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _audioBytes == null
                    ? IconButton(
                        tooltip: 'Choose soundtrack',
                        onPressed: _pickAudio,
                        icon: const Icon(Icons.add),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: _audioPlayer.playing
                                ? 'Pause soundtrack preview'
                                : 'Preview soundtrack',
                            onPressed: _toggleAudioPreview,
                            icon: Icon(
                              _audioPlayer.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove soundtrack',
                            onPressed: () async {
                              await _audioPlayer.stop();
                              if (!mounted) return;
                              setState(() {
                                _audioBytes = null;
                                _audioContentType = null;
                                _audioName = null;
                                _audioRightsConfirmed = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
              ),
              if (_audioBytes != null)
                CheckboxListTile(
                  value: _audioRightsConfirmed,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I have the rights to use this audio.',
                    maxLines: 2,
                  ),
                  onChanged: (value) => setState(
                    () => _audioRightsConfirmed = value ?? false,
                  ),
                ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'friends',
                    icon: Icon(Icons.people_outline),
                    label: Text('Friends'),
                  ),
                  ButtonSegment(
                    value: 'public',
                    icon: Icon(Icons.public),
                    label: Text('Public'),
                  ),
                ],
                selected: {_visibility},
                onSelectionChanged: (selection) =>
                    setState(() => _visibility = selection.first),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: !_canShare ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(
                    _isPicking
                        ? 'Preparing...'
                        : 'Share for 24 hours',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canShare =>
      _mediaBytes != null &&
      !_isPicking &&
      (_audioBytes == null || _audioRightsConfirmed);

  Widget _buildVideoPreview(ThemeData theme) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            IconButton.filledTonal(
              tooltip: controller.value.isPlaying ? 'Pause preview' : 'Play preview',
              onPressed: _toggleVideo,
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: IconButton.filledTonal(
                tooltip: _isMuted ? 'Unmute preview' : 'Mute preview',
                onPressed: _toggleMute,
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
