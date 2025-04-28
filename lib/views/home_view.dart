import 'package:autopost/models/post.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/video_provider.dart';
import '../providers/post_provider.dart';
import '../widgets/video_input.dart';
import '../widgets/post_editor.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube to LinkedIn'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.isAuthenticated) {
                return TextButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  onPressed: () => auth.authenticate(),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                );
              }
              return TextButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () => auth.logout(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (!auth.isAuthenticated) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please login to LinkedIn to continue'),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        auth.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => auth.authenticate(),
                    icon: const Icon(Icons.login),
                    label: const Text('Login with LinkedIn'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: VideoInput(),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<VideoProvider>(
                  builder: (context, video, _) {
                    if (video.videoData == null) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              video.videoData!.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                video.videoData!.thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Consumer<PostProvider>(
                              builder: (context, post, _) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => post.generatePost(
                                              video.videoData!,
                                              type: PostType.post,
                                            ),
                                        icon: const Icon(Icons.post_add),
                                        label: const Text('Post'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            () => post.generatePost(
                                              video.videoData!,
                                              type: PostType.article,
                                            ),
                                        icon: const Icon(Icons.article),
                                        label: const Text('Article'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<PostProvider>(
                  builder: (context, post, _) {
                    if (post.generatedPost == null) {
                      return const SizedBox.shrink();
                    }

                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: PostEditor(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
