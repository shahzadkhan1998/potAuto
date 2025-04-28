import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';
import '../models/post.dart';

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

  Future<String> transcribeAudio(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      final transcription = await _openAI.audio.createTranscription(
        file: file,
        model: 'whisper-1',
        responseFormat: OpenAIAudioResponseFormat.text,
      );

      return transcription.text;
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  Future<Post> generateLinkedInPost(
    String transcript, {
    PostType type = PostType.post,
  }) async {
    try {
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

      final messageContent = completion.choices.first.message.content;
      if (messageContent == null || messageContent.isEmpty) {
        throw Exception('No content generated');
      }

      final textContent = messageContent
          .whereType<OpenAIChatCompletionChoiceMessageContentItemModel>()
          .where((item) => item.type == 'text')
          .map((item) => item.text)
          .join('\n');

      return _parseResponse(textContent, type);
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
