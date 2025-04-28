import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/video_data.dart';

class YoutubeService {
  final _yt = YoutubeExplode();

  Future<VideoData> getVideoInfo(String url) async {
    try {
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        debugPrint('Invalid YouTube URL: $url');
        throw Exception('Invalid YouTube URL');
      }

      debugPrint('Fetching video info for ID: $videoId');
      final video = await _yt.videos.get(videoId);
      return VideoData(
        id: video.id.value,
        title: video.title,
        description: video.description,
        thumbnailUrl: video.thumbnails.highResUrl,
      );
    } on VideoUnavailableException catch (e) {
      debugPrint('Video unavailable: ${e.message}');
      throw Exception('Video is unavailable or private');
    } catch (e, stack) {
      debugPrint('Failed to fetch video info: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to fetch video info: $e');
    }
  }

  Future<String> getTranscript(String videoId) async {
    try {
      debugPrint('Attempting to get transcript for video: $videoId');

      // First try to get closed captions
      final manifest = await _yt.videos.closedCaptions.getManifest(videoId);
      if (manifest.tracks.isNotEmpty) {
        debugPrint('Found ${manifest.tracks.length} caption tracks');

        // Prefer English captions if available
        final track = manifest.tracks.firstWhere(
          (track) => track.language.code == 'en',
          orElse: () => manifest.tracks.first,
        );

        debugPrint('Using caption track: ${track.language.code}');
        final closedCaptions = await _yt.videos.closedCaptions.get(track);

        final transcript = closedCaptions.captions
            .map((caption) => caption.text)
            .join(' ');

        return transcript;
      }

      debugPrint('No captions found, falling back to audio download');
      return await downloadAudio(videoId);
    } catch (e, stack) {
      if (e.toString().toLowerCase().contains('caption') ||
          e.toString().toLowerCase().contains('track')) {
        debugPrint('Captions not available, falling back to audio download');
        return await downloadAudio(videoId);
      }
      debugPrint('Failed to get transcript: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to get transcript: $e');
    }
  }

  Future<String> downloadAudio(String videoId) async {
    try {
      debugPrint('Starting audio download for video: $videoId');
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$videoId.mp3';

      if (await File(filePath).exists()) {
        debugPrint('Using cached audio file: $filePath');
        return filePath;
      }

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      debugPrint('Selected audio stream: ${audioStream.bitrate}bps');

      final file = File(filePath);
      final fileStream = file.openWrite();

      await _yt.videos.streamsClient.get(audioStream).pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      debugPrint('Audio downloaded successfully to: $filePath');
      return filePath;
    } catch (e, stack) {
      debugPrint('Failed to download audio: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to download audio: $e');
    }
  }

  String? _extractVideoId(String url) {
    try {
      return VideoId.parseVideoId(url);
    } catch (e) {
      debugPrint('Failed to extract video ID from URL: $url');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}
