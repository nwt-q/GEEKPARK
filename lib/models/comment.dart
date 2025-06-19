class Comment {
  final int id;
  final String content;
  final int createdTimestamp;
  final int updatedTimestamp;
  final int likeCount;
  final int replyCount;
  final bool liked;
  final CommentUser user;
  final List<Comment> replies;
  final Comment? parentComment;
  final DateTime createdAt; // 添加 DateTime 类型属性
  final int floor; // 声明为 final 但未初始化

  Comment({
    required this.id,
    required this.content,
    required this.createdTimestamp,
    required this.updatedTimestamp,
    required this.likeCount,
    required this.replyCount,
    required this.liked,
    required this.user,
    required this.replies,
    this.parentComment,
    required this.createdAt, // 更新构造函数
    required this.floor, // 确保有这个属性
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final timestamp = json['created_timestamp'] ?? 0;
    return Comment(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      createdTimestamp: json['created_timestamp'] ?? 0,
      updatedTimestamp: json['updated_timestamp'] ?? 0,
      floor: json['floor'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      liked: json['liked'] ?? false,
      user: CommentUser.fromJson(json['user'] ?? {}),
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((reply) => Comment.fromJson(reply))
          .toList(),
      parentComment: json['parent_comment'] != null
          ? Comment.fromJson(json['parent_comment'])
          : null,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000), // 从时间戳转换
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_timestamp': createdTimestamp,
      'updated_timestamp': updatedTimestamp,
      'like_count': likeCount,
      'floor': floor,
      'reply_count': replyCount,
      'liked': liked,
      'user': user.toJson(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'parent_comment': parentComment?.toJson(),
    };
  }

  // 格式化创建时间
  DateTime get createdDate =>
      DateTime.fromMillisecondsSinceEpoch(createdTimestamp * 1000);

  // 格式化更新时间
  DateTime get updatedDate =>
      DateTime.fromMillisecondsSinceEpoch(updatedTimestamp * 1000);

  // 获取相对时间描述
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

class CommentUser {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final bool isAuthor;
  final bool verified;
  final List<String> badges;

  CommentUser({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    required this.isAuthor,
    required this.verified,
    required this.badges,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      verified: json['verified'] ?? false,
      isAuthor: json['is_author'] ?? false, // 从 JSON 解析
      badges: List<String>.from(json['badges'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'bio': bio,
      'verified': verified,
      'is_author': isAuthor,
      'badges': badges,
    };
  }
}

// 评论排序方式
enum CommentSortType {
  latest('latest', '最新'),
  hottest('hottest', '最热'),
  oldest('oldest', '最早');

  const CommentSortType(this.value, this.title);

  final String value;
  final String title;
}
