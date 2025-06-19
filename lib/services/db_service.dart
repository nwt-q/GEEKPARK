import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/news.dart';
import '../models/comment.dart';

class DatabaseService {
  static const String _databaseName = 'geekpark_news.db';
  static const int _databaseVersion = 1;

  // 表名
  static const String _newsTable = 'news';
  static const String _commentsTable = 'comments';
  static const String _readHistoryTable = 'read_history';
  static const String _favoritesTable = 'favorites';

  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    print('数据库路径: ${_database!.path}');
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Web平台使用sqflite_common_ffi_web
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        _databaseName,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      // 移动端使用sqflite
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建新闻表
    await db.execute('''
      CREATE TABLE $_newsTable (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        abstract TEXT,
        content TEXT,
        cover_url TEXT,
        published_timestamp INTEGER,
        post_type TEXT,
        tags TEXT,
        img_list TEXT,
        views INTEGER,
        reading_time INTEGER,
        like_count INTEGER,
        comments_count INTEGER,
        authors TEXT,
        column_data TEXT,
        extra TEXT,
        cached_at INTEGER,
        category_id INTEGER
      )
    ''');

    // 创建评论表
    await db.execute('''
      CREATE TABLE $_commentsTable (
        id INTEGER PRIMARY KEY,
        news_id INTEGER,
        content TEXT NOT NULL,
        created_timestamp INTEGER,
        updated_timestamp INTEGER,
        like_count INTEGER,
        floor INTEGER,
        reply_count INTEGER,
        liked INTEGER,
        user_data TEXT,
        replies TEXT,
        parent_comment TEXT,
        cached_at INTEGER,
        FOREIGN KEY (news_id) REFERENCES $_newsTable (id)
      )
    ''');

    // 创建阅读历史表
    await db.execute('''
      CREATE TABLE $_readHistoryTable (
        id INTEGER PRIMARY KEY,
        news_id INTEGER,
        read_at INTEGER,
        read_progress REAL DEFAULT 0.0,
        FOREIGN KEY (news_id) REFERENCES $_newsTable (id)
      )
    ''');

    // 创建收藏表
    await db.execute('''
      CREATE TABLE $_favoritesTable (
        id INTEGER PRIMARY KEY,
        news_id INTEGER,
        favorited_at INTEGER,
        FOREIGN KEY (news_id) REFERENCES $_newsTable (id)
      )
    ''');

    // 创建索引
    await db.execute(
        'CREATE INDEX idx_news_published ON $_newsTable (published_timestamp)');
    await db
        .execute('CREATE INDEX idx_news_category ON $_newsTable (category_id)');
    await db
        .execute('CREATE INDEX idx_comments_news ON $_commentsTable (news_id)');
    await db.execute(
        'CREATE INDEX idx_read_history_news ON $_readHistoryTable (news_id)');
    await db.execute(
        'CREATE INDEX idx_favorites_news ON $_favoritesTable (news_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
  }

  // 缓存新闻
  Future<void> cacheNews(News news, {int? categoryId}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _newsTable,
      {
        'id': news.id,
        'title': news.title,
        'abstract': news.abstract,
        'content': news.content,
        'cover_url': news.coverUrl,
        'published_timestamp': news.publishedTimestamp,
        'post_type': news.postType,
        'tags': jsonEncode(news.tags),
        'img_list': jsonEncode(news.imgList),
        'views': news.views,
        'reading_time': news.readingTime,
        'like_count': news.likeCount,
        'comments_count': news.commentsCount,
        'authors': jsonEncode(news.authors.map((a) => a.toJson()).toList()),
        'column_data':
            news.column != null ? jsonEncode(news.column!.toJson()) : null,
        'extra': news.extra != null ? jsonEncode(news.extra!) : null,
        'cached_at': now,
        'category_id': categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 批量缓存新闻
  Future<void> cacheNewsList(List<News> newsList, {int? categoryId}) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final news in newsList) {
      batch.insert(
        _newsTable,
        {
          'id': news.id,
          'title': news.title,
          'abstract': news.abstract,
          'content': news.content,
          'cover_url': news.coverUrl,
          'published_timestamp': news.publishedTimestamp,
          'post_type': news.postType,
          'tags': jsonEncode(news.tags),
          'img_list': jsonEncode(news.imgList),
          'views': news.views,
          'reading_time': news.readingTime,
          'like_count': news.likeCount,
          'comments_count': news.commentsCount,
          'authors': jsonEncode(news.authors.map((a) => a.toJson()).toList()),
          'column_data':
              news.column != null ? jsonEncode(news.column!.toJson()) : null,
          'extra': news.extra != null ? jsonEncode(news.extra!) : null,
          'cached_at': now,
          'category_id': categoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // 获取缓存的新闻列表
  Future<List<News>> getCachedNews(
      {int? categoryId, int limit = 20, int offset = 0}) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      whereClause = 'WHERE category_id = ?';
      whereArgs.add(categoryId);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $_newsTable 
      $whereClause
      ORDER BY published_timestamp DESC 
      LIMIT $limit OFFSET $offset
    ''', whereArgs);

    return maps.map((map) => _newsFromMap(map)).toList();
  }

  // 获取单个缓存新闻
  Future<News?> getCachedNewsById(int newsId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _newsTable,
      where: 'id = ?',
      whereArgs: [newsId],
    );

    if (maps.isNotEmpty) {
      return _newsFromMap(maps.first);
    }
    return null;
  }

  // 缓存评论
  Future<void> cacheComments(int newsId, List<Comment> comments) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 先删除旧评论
    batch.delete(_commentsTable, where: 'news_id = ?', whereArgs: [newsId]);

    // 插入新评论
    for (final comment in comments) {
      batch.insert(
        _commentsTable,
        {
          'id': comment.id,
          'news_id': newsId,
          'content': comment.content,
          'created_timestamp': comment.createdTimestamp,
          'updated_timestamp': comment.updatedTimestamp,
          'like_count': comment.likeCount,
          'floor': comment.floor ?? 1,
          'reply_count': comment.replyCount,
          'liked': comment.liked ? 1 : 0,
          'user_data': jsonEncode(comment.user.toJson()),
          'replies':
              jsonEncode(comment.replies.map((r) => r.toJson()).toList()),
          'parent_comment': comment.parentComment != null
              ? jsonEncode(comment.parentComment!.toJson())
              : null,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // 获取缓存的评论
  Future<List<Comment>> getCachedComments(int newsId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _commentsTable,
      where: 'news_id = ?',
      whereArgs: [newsId],
      orderBy: 'created_timestamp DESC',
    );

    return maps.map((map) => _commentFromMap(map)).toList();
  }

  // 添加阅读历史
  Future<void> addReadHistory(int newsId, {double progress = 0.0}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _readHistoryTable,
      {
        'news_id': newsId,
        'read_at': now,
        'read_progress': progress,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 获取阅读历史
  Future<List<News>> getReadHistory({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT n.*, h.read_at, h.read_progress 
      FROM $_newsTable n 
      INNER JOIN $_readHistoryTable h ON n.id = h.news_id 
      ORDER BY h.read_at DESC 
      LIMIT $limit
    ''');

    return maps.map((map) => _newsFromMap(map)).toList();
  }

  // 添加收藏
  Future<void> addFavorite(int newsId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _favoritesTable,
      {
        'news_id': newsId,
        'favorited_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // 移除收藏
  Future<void> removeFavorite(int newsId) async {
    final db = await database;
    await db.delete(
      _favoritesTable,
      where: 'news_id = ?',
      whereArgs: [newsId],
    );
  }

  // 检查是否已收藏
  Future<bool> isFavorited(int newsId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _favoritesTable,
      where: 'news_id = ?',
      whereArgs: [newsId],
    );
    return maps.isNotEmpty;
  }

  // 获取收藏列表
  Future<List<News>> getFavorites({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT n.*, f.favorited_at 
      FROM $_newsTable n 
      INNER JOIN $_favoritesTable f ON n.id = f.news_id 
      ORDER BY f.favorited_at DESC 
      LIMIT $limit
    ''');

    return maps.map((map) => _newsFromMap(map)).toList();
  }

  // 清理过期缓存
  Future<void> cleanExpiredCache({int daysToKeep = 7}) async {
    final db = await database;
    final expiredTime = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;

    await db.delete(
      _newsTable,
      where: 'cached_at < ?',
      whereArgs: [expiredTime],
    );

    await db.delete(
      _commentsTable,
      where: 'cached_at < ?',
      whereArgs: [expiredTime],
    );
  }

  // 获取缓存大小
  Future<int> getCacheSize() async {
    final db = await database;
    final newsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_newsTable')) ??
        0;
    final commentsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_commentsTable')) ??
        0;
    return newsCount + commentsCount;
  }

  // 清空所有缓存
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete(_newsTable);
    await db.delete(_commentsTable);
  }

  // 辅助方法：从Map转换为News对象
  News _newsFromMap(Map<String, dynamic> map) {
    return News(
      id: map['id'],
      title: map['title'],
      abstract: map['abstract'] ?? '',
      content: map['content'],
      coverUrl: map['cover_url'] ?? '',
      publishedTimestamp: map['published_timestamp'],
      postType: map['post_type'] ?? '',
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      imgList: List<String>.from(jsonDecode(map['img_list'] ?? '[]')),
      views: map['views'] ?? 0,
      readingTime: map['reading_time'] ?? 0,
      likeCount: map['like_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      authors: (jsonDecode(map['authors'] ?? '[]') as List)
          .map((json) => Author.fromJson(json))
          .toList(),
      column: map['column_data'] != null
          ? NewsColumn.fromJson(jsonDecode(map['column_data']))
          : null,
      extra: map['extra'] != null ? jsonDecode(map['extra']) : null,
    );
  }

  // 辅助方法：从Map转换为Comment对象
  Comment _commentFromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      content: map['content'],
      createdTimestamp: map['created_timestamp'],
      updatedTimestamp: map['updated_timestamp'],
      likeCount: map['like_count'] ?? 0,
      replyCount: map['reply_count'] ?? 0,
      floor: map['floor'] ?? 0,
      liked: map['liked'] == 1,
      user: CommentUser.fromJson(jsonDecode(map['user_data'])),
      replies: (jsonDecode(map['replies'] ?? '[]') as List)
          .map((json) => Comment.fromJson(json))
          .toList(),
      parentComment: map['parent_comment'] != null
          ? Comment.fromJson(jsonDecode(map['parent_comment']))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_timestamp'] * 1000),
    );
  }
}
