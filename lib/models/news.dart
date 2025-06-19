class News {
  final int id;
  final String title;
  final String abstract;
  final String? content;
  final String coverUrl;
  final int publishedTimestamp;
  final String postType;
  final List<String> tags;
  final List<String> imgList;
  final int views;
  final int readingTime;
  final int likeCount;
  final int commentsCount;
  final List<Author> authors;
  final NewsColumn? column;
  final Map<String, dynamic>? extra;

  News({
    required this.id,
    required this.title,
    required this.abstract,
    this.content,
    required this.coverUrl,
    required this.publishedTimestamp,
    required this.postType,
    required this.tags,
    required this.imgList,
    required this.views,
    required this.readingTime,
    required this.likeCount,
    required this.commentsCount,
    required this.authors,
    this.column,
    this.extra,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      abstract: json['abstract'] ?? '',
      content: json['content'],
      coverUrl: json['cover_url'] ?? '',
      publishedTimestamp: json['published_timestamp'] ?? 0,
      postType: json['post_type'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      imgList: List<String>.from(json['img_list'] ?? []),
      views: json['views'] ?? 0,
      readingTime: json['reading_time'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      authors: (json['authors'] as List<dynamic>? ?? [])
          .map((author) => Author.fromJson(author))
          .toList(),
      column: json['column'] != null ? NewsColumn.fromJson(json['column']) : null,
      extra: json['extra'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'abstract': abstract,
      'content': content,
      'cover_url': coverUrl,
      'published_timestamp': publishedTimestamp,
      'post_type': postType,
      'tags': tags,
      'img_list': imgList,
      'views': views,
      'reading_time': readingTime,
      'like_count': likeCount,
      'comments_count': commentsCount,
      'authors': authors.map((author) => author.toJson()).toList(),
      'column': column?.toJson(),
      'extra': extra,
    };
  }

  // 格式化发布时间
  DateTime get publishedDate => DateTime.fromMillisecondsSinceEpoch(publishedTimestamp * 1000);
  
  // 获取主要作者
  String get mainAuthor => authors.isNotEmpty ? authors.first.nickname : '未知作者';
  
  // 获取标签字符串
  String get tagsString => tags.join(' · ');
}

class Author {
  final String id;
  final String? email;
  final String nickname;
  final String? mobile;
  final String? avatarUrl;
  final String? realname;
  final List<String> roles;
  final bool wechatEnabled;
  final bool weiboEnabled;
  final String? bio;
  final bool banned;

  Author({
    required this.id,
    this.email,
    required this.nickname,
    this.mobile,
    this.avatarUrl,
    this.realname,
    required this.roles,
    required this.wechatEnabled,
    required this.weiboEnabled,
    this.bio,
    required this.banned,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? '',
      email: json['email'],
      nickname: json['nickname'] ?? '',
      mobile: json['mobile'],
      avatarUrl: json['avatar_url'],
      realname: json['realname'],
      roles: List<String>.from(json['roles'] ?? []),
      wechatEnabled: json['wechat_enabled'] ?? false,
      weiboEnabled: json['weibo_enabled'] ?? false,
      bio: json['bio'],
      banned: json['banned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'mobile': mobile,
      'avatar_url': avatarUrl,
      'realname': realname,
      'roles': roles,
      'wechat_enabled': wechatEnabled,
      'weibo_enabled': weiboEnabled,
      'bio': bio,
      'banned': banned,
    };
  }
}

class NewsColumn {
  final int id;
  final String title;
  final String description;
  final bool columnVisible;
  final String? bannerUrl;

  NewsColumn({
    required this.id,
    required this.title,
    required this.description,
    required this.columnVisible,
    this.bannerUrl,
  });

  factory NewsColumn.fromJson(Map<String, dynamic> json) {
    return NewsColumn(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      columnVisible: json['column_visible'] ?? true,
      bannerUrl: json['banner_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'column_visible': columnVisible,
      'banner_url': bannerUrl,
    };
  }
}

// 新闻分类枚举
enum NewsCategory {
  comprehensive(179, '综合报道'),
  aiWave(304, 'AI新浪潮观察'),
  newCar(305, '新造车观察'),
  financial(271, '财报解读'),
  ceoInterview(308, '底稿对话CEO系列'),
  geekInsight(306, 'Geek Insight 特稿系列'),
  heartTech(307, '心科技'),
  industry(2, '行业资讯');

  const NewsCategory(this.id, this.title);
  
  final int id;
  final String title;
  
  static NewsCategory? fromId(int id) {
    for (NewsCategory category in NewsCategory.values) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}