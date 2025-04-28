import 'package:flutter/foundation.dart';
import '../models/video_data.dart';
import '../services/youtube_service.dart';

class VideoProvider with ChangeNotifier {
  final YoutubeService _youtubeService = YoutubeService();

  VideoData? _videoData;
  bool _isLoading = false;
  String? _error;
  double _progress = 0.0;
  String? _currentOperation;

  VideoData? get videoData => _videoData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get progress => _progress;
  String? get currentOperation => _currentOperation;

  Future<void> processVideo(String url) async {
    try {
      _setLoading(true);
      _resetState();

      debugPrint('Starting video processing for URL: $url');
      _updateProgress('Fetching video information...', 0.0);

      // Get video info
      _videoData = await _youtubeService.getVideoInfo(url);
      _updateProgress('Retrieved video information', 0.3);

      debugPrint('Getting transcript for video: ${_videoData!.id}');
      _updateProgress('Getting transcript...', 0.4);

      // Get transcript (either from captions or audio)
      final transcript = await _youtubeService.getTranscript(_videoData!.id);
      _updateProgress('Retrieved transcript', 0.9);

      debugPrint('Updating video data with transcript');
      _videoData = VideoData(
        id: _videoData!.id,
        title: _videoData!.title,
        description: _videoData!.description,
        thumbnailUrl: _videoData!.thumbnailUrl,
        transcript: transcript,
      );
      _updateProgress('Processing complete', 1.0);

      debugPrint('Video processing completed successfully');
    } catch (e, stack) {
      debugPrint('Error processing video: $e');
      debugPrint('Stack trace: $stack');
      _error = e.toString();
      _videoData = null;
    } finally {
      _setLoading(false);
    }
  }

  void _resetState() {
    _error = null;
    _progress = 0.0;
    _currentOperation = null;
    notifyListeners();
  }

  void _updateProgress(String operation, double progress) {
    _currentOperation = operation;
    _progress = progress;
    notifyListeners();
    debugPrint('Progress ($progress): $operation');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (!value) {
      _currentOperation = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('Disposing VideoProvider');
    _youtubeService.dispose();
    super.dispose();
  }
}
