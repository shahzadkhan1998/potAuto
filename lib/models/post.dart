enum PostType { article, post }

class Post {
  final String title;
  final String content;
  final PostType type;
  final List<String>? hashtags;
  final String? imageUrl;

  Post({
    required this.title,
    required this.content,
    this.type = PostType.post,
    this.hashtags,
    this.imageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'] as String,
      content: json['content'] as String,
      type: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${json['type']}',
        orElse: () => PostType.post,
      ),
      hashtags: (json['hashtags'] as List<dynamic>?)?.cast<String>(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'hashtags': hashtags,
      'imageUrl': imageUrl,
    };
  }
}
