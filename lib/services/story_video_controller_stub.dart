import 'package:video_player/video_player.dart';

VideoPlayerController createStoryVideoController(String path) =>
    VideoPlayerController.networkUrl(Uri.parse(path));