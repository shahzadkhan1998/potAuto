import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/video_data.dart';
import '../services/gemini_service.dart';
import '../services/linkedin_service.dart';

class PostProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final LinkedInService _linkedInService = LinkedInService();

  Post? _generatedPost;
  bool _isGenerating = false;
  bool _isSharing = false;
  String? _error;
  String? _currentOperation;

  Post? get generatedPost => _generatedPost;
  bool get isGenerating => _isGenerating;
  bool get isSharing => _isSharing;
  String? get error => _error;
  String? get currentOperation => _currentOperation;

  Future<void> generatePost(
    VideoData videoData, {
    PostType type = PostType.post,
  }) async {
    if (videoData.transcript == null) {
      debugPrint('Cannot generate post: No transcript available');
      _error = 'No transcript available';
      notifyListeners();
      return;
    }

    try {
      _resetState();
      _setGenerating(true);
      _updateOperation('Generating ${type.toString()}...');

      debugPrint('Starting post generation for video: ${videoData.id}');
      debugPrint('Post type: ${type.toString()}');

      _generatedPost = await _geminiService.generateLinkedInPost(
        videoData.transcript!,
        type: type,
      );

      debugPrint('Successfully generated ${type.toString()}');
      _updateOperation('Content generated successfully');
    } catch (e, stack) {
      debugPrint('Error generating post: $e');
      debugPrint('Stack trace: $stack');
      _error = e.toString();
      _generatedPost = null;
    } finally {
      _setGenerating(false);
    }
    notifyListeners();
  }

  Future<void> shareToLinkedIn() async {
    if (_generatedPost == null) {
      debugPrint('Cannot share: No content available');
      _error = 'No content to share';
      notifyListeners();
      return;
    }

    try {
      _resetState();
      _setSharing(true);
      _updateOperation('Preparing to share on LinkedIn...');

      debugPrint('Starting LinkedIn share process');
      debugPrint('Content type: ${_generatedPost!.type}');

      if (_generatedPost!.type == PostType.article) {
        _updateOperation('Publishing article...');
        await _linkedInService.shareArticle(_generatedPost!);
        debugPrint('Successfully published article on LinkedIn');
      } else {
        _updateOperation('Sharing post...');
        await _linkedInService.sharePost(_generatedPost!);
        debugPrint('Successfully shared post on LinkedIn');
      }

      _updateOperation('Content shared successfully');
    } catch (e, stack) {
      debugPrint('Error sharing to LinkedIn: $e');
      debugPrint('Stack trace: $stack');
      _error = e.toString();
    } finally {
      _setSharing(false);
    }
  }

  void updatePost(Post updatedPost) {
    debugPrint('Updating post content');
    _generatedPost = updatedPost;
    _error = null;
    notifyListeners();
  }

  void _resetState() {
    _error = null;
    _currentOperation = null;
    notifyListeners();
  }

  void _updateOperation(String operation) {
    _currentOperation = operation;
    notifyListeners();
    debugPrint('Operation: $operation');
  }

  void _setGenerating(bool value) {
    _isGenerating = value;
    if (!value) {
      _currentOperation = null;
    }
    notifyListeners();
  }

  void _setSharing(bool value) {
    _isSharing = value;
    if (!value) {
      _currentOperation = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('Disposing PostProvider');
    super.dispose();
  }
}
