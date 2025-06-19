import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/news.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

class NewsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  
  // 新闻列表状态
  List<News> _newsList = [];
  List<News> _hotWeeklyNews = [];
  List<News> _categoryNews = [];
  List<News> _searchResults = [];
  List<News> _favorites = [];
  List<News> _readHistory = [];
  
  // 当前新闻详情
  News? _currentNews;
  List<Comment> _currentComments = [];
  News? _nextNews;
  List<News> _relatedNews = [];
  
  // 加载状态
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  
  // 分页信息
  int _currentPage = 1;
  int _currentCategoryPage = 1;
  NewsCategory? _currentCategory;
  
  // 网络状态
  bool _isOnline = true;
  
  // Getters
  List<News> get newsList => _newsList;
  List<News> get hotWeeklyNews => _hotWeeklyNews;
  List<News> get categoryNews => _categoryNews;
  List<News> get searchResults => _searchResults;
  List<News> get favorites => _favorites;
  List<News> get readHistory => _readHistory;
  
  News? get currentNews => _currentNews;
  List<Comment> get currentComments => _currentComments;
  News? get nextNews => _nextNews;
  List<News> get relatedNews => _relatedNews;
  
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  
  int get currentPage => _currentPage;
  NewsCategory? get currentCategory => _currentCategory;
  bool get isOnline => _isOnline;

  NewsProvider() {
    _initConnectivity();
    _loadCachedData();
  }

  // 初始化网络连接监听
  void _initConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (!wasOnline && _isOnline) {
        // 从离线恢复到在线，刷新数据
        refreshAllData();
      }
      notifyListeners();
    });
  }

  // 加载缓存数据
  void _loadCachedData() async {
    try {
      _favorites = await _dbService.getFavorites();
      _readHistory = await _dbService.getReadHistory();
      
      if (!_isOnline) {
        _newsList = await _dbService.getCachedNews();
        _hotWeeklyNews = await _dbService.getCachedNews(limit: 7);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('加载缓存数据失败: $e');
    }
  }

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  // 获取一周热门新闻
  Future<void> loadHotWeeklyNews({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    try {
      if (refresh) {
        _setLoading(true);
      }
      
      if (_isOnline) {
        _hotWeeklyNews = await _apiService.getHotWeeklyNews();
        // 缓存到本地
        await _dbService.cacheNewsList(_hotWeeklyNews);
      } else {
        _hotWeeklyNews = await _dbService.getCachedNews(limit: 7);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('加载热门新闻失败: $e');
    }
  }

  // 获取新闻列表
  Future<void> loadNewsList({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _setLoading(true);
      }
      
      if (_isOnline) {
        final response = await _apiService.getNewsList(page: _currentPage);
        
        if (refresh) {
          _newsList = response.news;
        } else {
          _newsList.addAll(response.news);
        }
        
        _hasMore = response.hasMore;
        _currentPage = response.currentPage + 1;
        
        // 缓存到本地
        await _dbService.cacheNewsList(response.news);
      } else {
        if (refresh) {
          _newsList = await _dbService.getCachedNews();
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('加载新闻列表失败: $e');
    }
  }

  // 加载更多新闻
  Future<void> loadMoreNews() async {
    if (_isLoadingMore || !_hasMore || !_isOnline) return;
    
    try {
      _isLoadingMore = true;
      notifyListeners();
      
      final response = await _apiService.getNewsList(page: _currentPage);
      _newsList.addAll(response.news);
      _hasMore = response.hasMore;
      _currentPage = response.currentPage + 1;
      
      // 缓存到本地
      await _dbService.cacheNewsList(response.news);
      
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _setError('加载更多新闻失败: $e');
    }
  }

  // 获取分类新闻
  Future<void> loadCategoryNews(NewsCategory category, {bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    try {
      if (refresh || _currentCategory != category) {
        _currentCategory = category;
        _currentCategoryPage = 1;
        _hasMore = true;
        _setLoading(true);
      }
      
      if (_isOnline) {
        final response = await _apiService.getCategoryNews(
          columnId: category.id,
          page: _currentCategoryPage,
        );
        
        if (refresh || _currentCategory != category) {
          _categoryNews = response.news;
        } else {
          _categoryNews.addAll(response.news);
        }
        
        _hasMore = response.hasMore;
        _currentCategoryPage = response.currentPage + 1;
        
        // 缓存到本地
        await _dbService.cacheNewsList(response.news, categoryId: category.id);
      } else {
        if (refresh || _currentCategory != category) {
          _categoryNews = await _dbService.getCachedNews(categoryId: category.id);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('加载分类新闻失败: $e');
    }
  }

  // 获取新闻详情
  Future<void> loadNewsDetail(int newsId) async {
    try {
      _setLoading(true);
      
      if (_isOnline) {
        _currentNews = await _apiService.getNewsDetail(newsId);
        // 缓存到本地
        await _dbService.cacheNews(_currentNews!);
      } else {
        _currentNews = await _dbService.getCachedNewsById(newsId);
      }
      
      // 添加到阅读历史
      await _dbService.addReadHistory(newsId);
      
      // 加载相关数据
      await Future.wait([
        loadNewsComments(newsId),
        loadNextNews(newsId),
        loadRelatedNews(),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('加载新闻详情失败: $e');
    }
  }

  // 获取新闻评论
  Future<void> loadNewsComments(int newsId) async {
    try {
      if (_isOnline) {
        _currentComments = await _apiService.getNewsComments(newsId);
        // 缓存到本地
        await _dbService.cacheComments(newsId, _currentComments);
      } else {
        _currentComments = await _dbService.getCachedComments(newsId);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('加载评论失败: $e');
    }
  }

  // 获取下一篇新闻
  Future<void> loadNextNews(int newsId) async {
    try {
      if (_isOnline) {
        _nextNews = await _apiService.getNextNews(newsId);
        if (_nextNews != null) {
          await _dbService.cacheNews(_nextNews!);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载下一篇新闻失败: $e');
    }
  }

  // 获取相关新闻
  Future<void> loadRelatedNews() async {
    try {
      if (_isOnline) {
        _relatedNews = await _apiService.getLatestNews(count: 4);
        await _dbService.cacheNewsList(_relatedNews);
      } else {
        _relatedNews = await _dbService.getCachedNews(limit: 4);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载相关新闻失败: $e');
    }
  }

  // 搜索新闻
  Future<void> searchNews(String keyword) async {
    if (keyword.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    try {
      _setLoading(true);
      
      if (_isOnline) {
        _searchResults = await _apiService.searchNews(keyword);
      } else {
        // 离线搜索本地缓存
        final cachedNews = await _dbService.getCachedNews(limit: 100);
        _searchResults = cachedNews.where((news) => 
          news.title.toLowerCase().contains(keyword.toLowerCase()) ||
          news.abstract.toLowerCase().contains(keyword.toLowerCase())
        ).toList();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _setError('搜索失败: $e');
    }
  }

  // 切换收藏状态
  Future<void> toggleFavorite(int newsId) async {
    try {
      final isFavorited = await _dbService.isFavorited(newsId);
      
      if (isFavorited) {
        await _dbService.removeFavorite(newsId);
        _favorites.removeWhere((news) => news.id == newsId);
      } else {
        await _dbService.addFavorite(newsId);
        // 重新加载收藏列表
        _favorites = await _dbService.getFavorites();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('切换收藏状态失败: $e');
    }
  }

  // 检查是否已收藏
  Future<bool> isFavorited(int newsId) async {
    return await _dbService.isFavorited(newsId);
  }

  // 加载收藏列表
  Future<void> loadFavorites() async {
    try {
      _favorites = await _dbService.getFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('加载收藏列表失败: $e');
    }
  }

  // 加载阅读历史
  Future<void> loadReadHistory() async {
    try {
      _readHistory = await _dbService.getReadHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('加载阅读历史失败: $e');
    }
  }

  // 刷新所有数据
  Future<void> refreshAllData() async {
    await Future.wait([
      loadHotWeeklyNews(refresh: true),
      loadNewsList(refresh: true),
    ]);
  }

  // 清理缓存
  Future<void> clearCache() async {
    try {
      await _dbService.clearAllCache();
      if (!_isOnline) {
        _newsList.clear();
        _hotWeeklyNews.clear();
        _categoryNews.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('清理缓存失败: $e');
    }
  }

  // 获取缓存大小
  Future<int> getCacheSize() async {
    return await _dbService.getCacheSize();
  }

  // 清理过期缓存
  Future<void> cleanExpiredCache() async {
    try {
      await _dbService.cleanExpiredCache();
    } catch (e) {
      debugPrint('清理过期缓存失败: $e');
    }
  }
}