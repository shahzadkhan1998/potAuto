import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
import 'loading_indicator.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({super.key});

  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _hashtagController = TextEditingController();
  late PostType _postType;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final post = context.read<PostProvider>().generatedPost;
    if (post != null) {
      _titleController.text = post.title;
      _contentController.text = post.content;
      _hashtagController.text = post.hashtags?.join(' ') ?? '';
      _postType = post.type;
    } else {
      _postType = PostType.post;
    }
  }

  void _updatePost() {
    final hashtags =
        _hashtagController.text
            .split(' ')
            .where((tag) => tag.isNotEmpty)
            .map((tag) => tag.startsWith('#') ? tag : '#$tag')
            .toList();

    final updatedPost = Post(
      title: _titleController.text,
      content: _contentController.text,
      type: _postType,
      hashtags: hashtags,
    );

    context.read<PostProvider>().updatePost(updatedPost);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, provider, child) {
        if (provider.isGenerating) {
          return const LoadingIndicator(
            progress: 1.0,
            message: 'Generating content...',
          );
        }

        if (provider.isSharing) {
          return const LoadingIndicator(
            progress: 1.0,
            message: 'Sharing to LinkedIn...',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<PostType>(
              segments: const [
                ButtonSegment(
                  value: PostType.post,
                  label: Text('Post'),
                  icon: Icon(Icons.post_add),
                ),
                ButtonSegment(
                  value: PostType.article,
                  label: Text('Article'),
                  icon: Icon(Icons.article),
                ),
              ],
              selected: {_postType},
              onSelectionChanged: (Set<PostType> selected) {
                setState(() {
                  _postType = selected.first;
                  _updatePost();
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updatePost(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
              onChanged: (_) => _updatePost(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hashtagController,
              decoration: const InputDecoration(
                labelText: 'Hashtags',
                hintText: 'Separate with spaces',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _updatePost(),
            ),
            const SizedBox(height: 16),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  provider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ElevatedButton.icon(
              onPressed: provider.shareToLinkedIn,
              icon: const Icon(Icons.share),
              label: const Text('Share to LinkedIn'),
            ),
          ],
        );
      },
    );
  }
}
