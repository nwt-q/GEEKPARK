import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/news.dart';
import '../models/comment.dart';

class ApiService {
  static const String baseUrl = 'https://mainssl.geekpark.net/api';
  late final Dio _dio;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'GeekPark News App',
        'Accept': 'application/json',
      },
    ));

    // 添加错误处理拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        String errorMessage = '网络请求失败';
        
        if (error.type == DioExceptionType.connectionTimeout) {
          errorMessage = '连接超时，请检查网络连接';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          errorMessage = '响应超时，请稍后重试';
        } else if (error.type == DioExceptionType.connectionError) {
          errorMessage = '网络连接错误，请检查网络设置';
        } else if (error.response?.statusCode == 404) {
          errorMessage = '请求的资源不存在';
        } else if (error.response?.statusCode == 500) {
          errorMessage = '服务器内部错误';
        }
        
        print('API请求错误: $errorMessage - ${error.message}');
        handler.next(error);
      },
    ));

    // 添加日志拦截器（仅在调试模式下）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => print(obj),
      ));
    }
  }

  // 获取一周最新文章
  Future<List<News>> getHotWeeklyNews({int count = 7}) async {
    try {
      final response = await _dio.get('/v1/posts/hot_in_week?per=$count');
      final List<dynamic> data = response.data['posts'] ?? [];
      return data.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('获取一周热门新闻失败: $e');
    }
  }

  // 获取新闻列表
  Future<NewsListResponse> getNewsList({int page = 1}) async {
    try {
      final response = await _dio.get('/v2?page=$page');
      final data = response.data;

      final List<dynamic> homepagePosts = data['homepage_posts'] ?? [];
      final newsList = homepagePosts.map((item) {
        final postData = item['post'] ?? item;
        return News.fromJson(postData);
      }).toList();

      return NewsListResponse(
        news: newsList,
        currentPage: data['current_page'] ?? page,
        totalPages: data['last_page'] ?? 1,
        hasMore: (data['current_page'] ?? page) < (data['last_page'] ?? 1),
      );
    } catch (e) {
      throw ApiException('获取新闻列表失败: $e');
    }
  }

  // 获取分类新闻列表
  Future<NewsListResponse> getCategoryNews({
    required int columnId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/v1/columns/$columnId?page=$page');
      final data = response.data;

      final List<dynamic> posts = data['column']?['posts'] ?? data['posts'] ?? [];
      final newsList = posts.map((json) => News.fromJson(json)).toList();

      return NewsListResponse(
        news: newsList,
        currentPage: data['current_page'] ?? page,
        totalPages: data['last_page'] ?? 1,
        hasMore: (data['current_page'] ?? page) < (data['last_page'] ?? 1),
      );
    } catch (e) {
      throw ApiException('获取分类新闻失败: $e');
    }
  }

  // 获取新闻详情
  Future<News> getNewsDetail(int newsId) async {
    try {
      final response = await _dio.get('/v1/posts/$newsId');
      return News.fromJson(response.data['post']);
    } catch (e) {
      throw ApiException('获取新闻详情失败: $e');
    }
  }

  // 获取新闻评论
  Future<List<Comment>> getNewsComments(int newsId, {int page = 1}) async {
    try {
      final response = await _dio.get('/v1/posts/$newsId/comments?page=$page');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('获取新闻评论失败: $e');
    }
  }

  // 获取下一篇文章
  Future<News?> getNextNews(int newsId) async {
    try {
      final response = await _dio.get('/v1/posts/$newsId/next');
      if (response.data['data'] != null) {
        return News.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw ApiException('获取下一篇文章失败: $e');
    }
  }

  // 获取最新文章
  Future<List<News>> getLatestNews({int count = 4}) async {
    try {
      final response = await _dio.get('/v1/posts?per=$count');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('获取最新文章失败: $e');
    }
  }

  // 搜索新闻
  Future<List<News>> searchNews(String keyword, {int page = 1}) async {
    try {
      final response = await _dio.get('/v1/search', queryParameters: {
        'q': keyword,
        'page': page,
      });
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => News.fromJson(json)).toList();
    } catch (e) {
      throw ApiException('搜索新闻失败: $e');
    }
  }
}

// 新闻列表响应模型
class NewsListResponse {
  final List<News> news;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  NewsListResponse({
    required this.news,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });
}

// API异常类
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

// 网络状态枚举
enum NetworkStatus {
  loading,
  success,
  error,
  empty,
}
