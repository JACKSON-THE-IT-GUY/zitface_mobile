import 'package:video_player/video_player.dart';

import 'story_video_controller_stub.dart'
    if (dart.library.io) 'story_video_controller_io.dart'
    if (dart.library.html) 'story_video_controller_web.dart' as platform;

VideoPlayerController createStoryVideoController(String path) =>
    platform.createStoryVideoController(path);