import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import 'loading_indicator.dart';

class VideoInput extends StatefulWidget {
  const VideoInput({super.key});

  @override
  State<VideoInput> createState() => _VideoInputState();
}

class _VideoInputState extends State<VideoInput> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormFieldState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateYouTubeUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a YouTube URL';
    }
    if (!value.contains('youtube.com/') && !value.contains('youtu.be/')) {
      return 'Please enter a valid YouTube URL';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return LoadingIndicator(
            progress: provider.progress,
            message: 'Processing video...',
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              key: _formKey,
              decoration: InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'Paste video URL here',
                errorText: provider.error,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _controller.clear,
                ),
              ),
              validator: _validateYouTubeUrl,
              onFieldSubmitted: (url) {
                if (_formKey.currentState?.validate() ?? false) {
                  provider.processVideo(url);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  provider.processVideo(_controller.text);
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Process Video'),
            ),
          ],
        );
      },
    );
  }
}
