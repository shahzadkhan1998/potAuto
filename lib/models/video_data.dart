class VideoData {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String? transcript;

  VideoData({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    this.transcript,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      transcript: json['transcript'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'transcript': transcript,
    };
  }
}
