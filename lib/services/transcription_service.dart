import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TranscriptionService {
  final String? _apiKey = dotenv.env['ASSEMBLY_API_KEY'];
  final String _baseUrl = 'https://api.assemblyai.com/v2';

  Future<String> transcribeAudio(String audioFilePath) async {
    try {
      if (_apiKey == null) {
        throw Exception('AssemblyAI API key not configured');
      }

      debugPrint('Starting audio transcription for file: $audioFilePath');

      final file = File(audioFilePath);
      if (!await file.exists()) {
        debugPrint('Audio file not found: $audioFilePath');
        throw Exception('Audio file not found');
      }

      debugPrint('Reading audio file...');
      final bytes = await file.readAsBytes();

      // Upload the audio file
      debugPrint('Uploading audio file...');
      final uploadResponse = await http.post(
        Uri.parse('$_baseUrl/upload'),
        headers: {'authorization': _apiKey},
        body: bytes,
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload audio file');
      }

      final uploadUrl = jsonDecode(uploadResponse.body)['upload_url'];

      // Start transcription
      debugPrint('Starting transcription...');
      final transcriptResponse = await http.post(
        Uri.parse('$_baseUrl/transcript'),
        headers: {'authorization': _apiKey, 'content-type': 'application/json'},
        body: jsonEncode({'audio_url': uploadUrl, 'language_code': 'en'}),
      );

      if (transcriptResponse.statusCode != 200) {
        throw Exception('Failed to start transcription');
      }

      final transcriptId = jsonDecode(transcriptResponse.body)['id'];

      // Poll for completion
      while (true) {
        await Future.delayed(const Duration(seconds: 3));

        final pollingResponse = await http.get(
          Uri.parse('$_baseUrl/transcript/$transcriptId'),
          headers: {'authorization': _apiKey},
        );

        if (pollingResponse.statusCode != 200) {
          throw Exception('Failed to get transcription status');
        }

        final pollingResult = jsonDecode(pollingResponse.body);
        if (pollingResult['status'] == 'completed') {
          return pollingResult['text'];
        } else if (pollingResult['status'] == 'error') {
          throw Exception('Transcription failed: ${pollingResult['error']}');
        }
      }
    } catch (e, stack) {
      debugPrint('Error in transcribeAudio: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  void dispose() {
    debugPrint('Disposing TranscriptionService');
  }
}
