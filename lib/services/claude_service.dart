import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';
import '../models/post.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  late final OpenAI _openAI;

  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in environment variables');
    }
    OpenAI.apiKey = apiKey;
    _openAI = OpenAI.instance;
  }

  Future<String> transcribeAudio(String base64Audio) async {
    try {
      final transcription = await _openAI.audio.createTranscription(
        file: File.fromRawPath(base64Decode(base64Audio)),
        model: 'whisper-base-en-us',
        responseFormat: OpenAIAudioResponseFormat.text,
      );

      return transcription.text;
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  Future<Post> generateLinkedInPost(
    List<OpenAIChatCompletionChoiceMessageContentItemModel> messages, {
    PostType type = PostType.post,
  }) async {
    try {
      // Extract text content from messages
      final transcript =
          messages
              .where((msg) => msg.type == 'text')
              .map((msg) => msg.text)
              .join('\n')
              .trim();

      final prompt = _createPrompt(transcript, type);

      final completion = await _openAI.chat.create(
        model: 'gpt-4-turbo-preview',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      if (completion.choices.isEmpty) {
        throw Exception('No content generated from OpenAI');
      }

      final responseContent =
          completion.choices.first.message.content
              ?.where((content) => content.type == 'text')
              .map((content) => content.text)
              .join('\n')
              .trim();

      if (responseContent == null || responseContent.isEmpty) {
        throw Exception('No text content in response');
      }

      return _parseResponse(responseContent, type);
    } catch (e) {
      throw Exception('Content generation failed: $e');
    }
  }

  String _createPrompt(String transcript, PostType type) {
    if (type == PostType.article) {
      return '''
Create a LinkedIn article based on this transcript. Include:
1. An engaging title
2. Well-structured content with headers
3. Key takeaways
4. Relevant hashtags

Transcript:
$transcript
''';
    }

    return '''
Create a concise LinkedIn post based on this transcript. Include:
1. An attention-grabbing opening line
2. Key insights
3. A call to action
4. 3-5 relevant hashtags

Transcript:
$transcript
''';
  }

  Post _parseResponse(String response, PostType type) {
    final lines = response.split('\n');
    String title = '';
    String content = '';
    List<String> hashtags = [];

    if (type == PostType.article) {
      // Extract title from first line
      title = lines.first.replaceAll('#', '').trim();
      content = lines.skip(1).join('\n').trim();
    } else {
      content = response;
      // Extract hashtags from the last line
      final lastLine = lines.last;
      if (lastLine.contains('#')) {
        hashtags =
            lastLine.split(' ').where((word) => word.startsWith('#')).toList();
        content = lines.take(lines.length - 1).join('\n').trim();
      }
    }

    return Post(title: title, content: content, type: type, hashtags: hashtags);
  }
}

class ClaudeService {
  final String _baseUrl = 'https://api.anthropic.com/v1';
  String? _apiKey;

  ClaudeService() {
    _apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (_apiKey == null) {
      debugPrint(
        'WARNING: ANTHROPIC_API_KEY not found in environment variables',
      );
    }
  }

  Future<Post> generateLinkedInPost(
    String transcript, {
    PostType type = PostType.post,
  }) async {
    try {
      if (_apiKey == null) {
        throw Exception('Anthropic API key not configured');
      }

      debugPrint('Generating ${type.toString()} using Claude');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey!,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': 'claude-3-opus-20240229',
              'messages': [
                {'role': 'system', 'content': _getSystemPrompt(type)},
                {'role': 'user', 'content': transcript},
              ],
              'max_tokens': type == PostType.article ? 2000 : 500,
              'temperature': 0.7,
            }),
          )
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              debugPrint('Claude API request timed out');
              throw Exception('Request timed out. Please try again.');
            },
          );

      if (response.statusCode != 200) {
        debugPrint('Claude API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception(
          'Failed to generate content: ${_parseErrorMessage(response.body)}',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;

      debugPrint('Successfully generated content with Claude');
      return Post(title: '', content: content, type: type);
    } catch (e, stack) {
      debugPrint('Error in Claude content generation: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to generate content: $e');
    }
  }

  String _getSystemPrompt(PostType type) {
    return type == PostType.article
        ? 'You are a professional content writer specializing in LinkedIn articles. Convert the given transcript into a well-structured LinkedIn article. Maintain key insights and professional tone while expanding on important points.'
        : 'You are a social media expert specializing in LinkedIn content. Convert the given transcript into an engaging LinkedIn post. Keep it concise and professional while maintaining the key message.';
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['error']?['message'] ?? 'Unknown error occurred';
    } catch (e) {
      return 'Failed to parse error message';
    }
  }
}
