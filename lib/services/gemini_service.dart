import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class GeminiService {
  final String _apiKey = "";

  Future<Post> generateLinkedInPost(
    String transcript, {
    PostType type = PostType.post,
  }) async {
    try {
      debugPrint('Generating ${type.toString()} using Gemini');

      final prompt = _getSystemPrompt(type) + '\n\nTranscript:\n' + transcript;
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate content: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final generatedText =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (generatedText == null || generatedText.isEmpty) {
        throw Exception('No content generated from Gemini');
      }

      debugPrint('Successfully generated content with Gemini');
      final lines = generatedText.split('\n');
      String title =
          type == PostType.article ? 'LinkedIn Article' : 'LinkedIn Post';
      String postContent = generatedText;
      List<String> hashtags = [];

      if (type == PostType.article && lines.isNotEmpty) {
        // Extract title from first line if it exists
        if (lines.first.startsWith('#')) {
          title = lines.first.replaceAll('#', '').trim();
          postContent = lines.skip(1).join('\n').trim();
        }
      } else if (lines.isNotEmpty) {
        // Extract hashtags from the last line if they exist
        final lastLine = lines.last;
        if (lastLine.contains('#')) {
          hashtags =
              lastLine
                  .split(' ')
                  .where((word) => word.startsWith('#'))
                  .toList();
          postContent = lines.take(lines.length - 1).join('\n').trim();
        }
      }

      return Post(
        title: title,
        content: postContent,
        type: type,
        hashtags: hashtags,
      );
    } catch (e, stack) {
      debugPrint('Error in Gemini content generation: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to generate content: $e');
    }
  }

  String _getSystemPrompt(PostType type) {
    return type == PostType.article
        ? 'You are a professional content writer specializing in LinkedIn articles. Given a transcript extracted from a YouTube video, craft a well-structured LinkedIn article. Start with a compelling title prefixed with #, expand on key insights, and maintain a professional tone throughout.'
        : 'You are a professional social media manager. Using a transcript derived from a YouTube video, create an engaging LinkedIn post. Ensure the content is concise, professional, and ends with relevant hashtags on a new line.';
  }
}
