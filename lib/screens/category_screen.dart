import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/news_provider.dart';
import '../models/news.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  final NewsCategory category;

  const CategoryScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  late NewsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<NewsProvider>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _loadData() {
    _provider.loadCategoryNews(widget.category, refresh: true);
  }

  void _onRefresh() async {
    try {
      await _provider.loadCategoryNews(widget.category, refresh: true);
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  void _onLoading() async {
    try {
      await _provider.loadCategoryNews(widget.category);

      if (_provider.hasMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: _getCategoryColor(),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.category.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCategoryColor(),
                        _getCategoryColor().withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          _getCategoryIcon(),
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _getCategoryIcon(),
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getCategoryDescription(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Consumer<NewsProvider>(
                  builder: (context, provider, child) {
                    return IconButton(
                      icon: Icon(
                        provider.isOnline ? Icons.wifi : Icons.wifi_off,
                        color:
                            provider.isOnline ? Colors.white : Colors.red[300],
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.isOnline ? '网络连接正常' : '当前离线模式',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: Consumer<NewsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.categoryNews.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.errorMessage != null &&
                provider.categoryNews.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCategoryColor(),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            if (provider.categoryNews.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无${widget.category.title}新闻',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCategoryColor(),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('刷新'),
                    ),
                  ],
                ),
              );
            }

            return SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: provider.hasMore,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              header: WaterDropHeader(
                waterDropColor: _getCategoryColor(),
              ),
              footer: CustomFooter(
                builder: (BuildContext context, LoadStatus? mode) {
                  // 初始化 body 变量
                  Widget body = const Text("上拉加载更多");

                  if (mode == LoadStatus.idle) {
                    body = const Text("上拉加载更多");
                  } else if (mode == LoadStatus.loading) {
                    body = Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_getCategoryColor()),
                      ),
                    );
                  } else if (mode == LoadStatus.failed) {
                    body = const Text("加载失败！点击重试！");
                  } else if (mode == LoadStatus.canLoading) {
                    body = const Text("松手,加载更多!");
                  } else {
                    body = const Text("没有更多数据了!");
                  }

                  return SizedBox(
                    height: 55.0,
                    child: Center(child: body),
                  );
                },
              ),
              child: CustomScrollView(
                slivers: [
                  // 统计信息
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor().withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            '文章数量',
                            '${provider.categoryNews.length}',
                            Icons.article,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: _getCategoryColor().withOpacity(0.3),
                          ),
                          _buildStatColumn(
                            '总阅读量',
                            _formatNumber(
                                _getTotalViews(provider.categoryNews)),
                            Icons.visibility,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: _getCategoryColor().withOpacity(0.3),
                          ),
                          _buildStatColumn(
                            '网络状态',
                            provider.isOnline ? '在线' : '离线',
                            provider.isOnline ? Icons.wifi : Icons.wifi_off,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 新闻列表
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final news = provider.categoryNews[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            index == 0 ? 0 : 8,
                            16,
                            index == provider.categoryNews.length - 1 ? 16 : 8,
                          ),
                          child: NewsCard(
                            news: news,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewsDetailScreen(
                                    newsId: news.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: provider.categoryNews.length,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null) {
            return FloatingActionButton(
              onPressed: _loadData,
              backgroundColor: _getCategoryColor(),
              child: const Icon(Icons.refresh, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: _getCategoryColor(),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getCategoryColor(),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (widget.category) {
      case NewsCategory.comprehensive:
        return Colors.blue;
      case NewsCategory.aiWave:
        return Colors.purple;
      case NewsCategory.newCar:
        return Colors.green;
      case NewsCategory.financial:
        return Colors.orange;
      case NewsCategory.ceoInterview:
        return Colors.red;
      case NewsCategory.geekInsight:
        return Colors.teal;
      case NewsCategory.heartTech:
        return Colors.pink;
      case NewsCategory.industry:
        return Colors.indigo;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.category) {
      case NewsCategory.comprehensive:
        return Icons.dashboard;
      case NewsCategory.aiWave:
        return Icons.psychology;
      case NewsCategory.newCar:
        return Icons.directions_car;
      case NewsCategory.financial:
        return Icons.trending_up;
      case NewsCategory.ceoInterview:
        return Icons.person;
      case NewsCategory.geekInsight:
        return Icons.lightbulb;
      case NewsCategory.heartTech:
        return Icons.favorite;
      case NewsCategory.industry:
        return Icons.business;
    }
  }

  String _getCategoryDescription() {
    switch (widget.category) {
      case NewsCategory.comprehensive:
        return '全面覆盖科技行业的综合性报道，为您带来最新的科技资讯';
      case NewsCategory.aiWave:
        return '深度观察人工智能发展趋势，解读AI技术的最新突破';
      case NewsCategory.newCar:
        return '关注新能源汽车行业动态，探索智能出行的未来';
      case NewsCategory.financial:
        return '专业解读科技公司财报，分析行业发展趋势';
      case NewsCategory.ceoInterview:
        return '深度对话科技行业领袖，分享创业心得与行业洞察';
      case NewsCategory.geekInsight:
        return '独家深度特稿，为您提供独特的科技行业视角';
      case NewsCategory.heartTech:
        return '关注科技与人文的结合，探索技术的温度';
      case NewsCategory.industry:
        return '及时报道科技行业资讯，把握行业发展脉搏';
    }
  }

  int _getTotalViews(List<News> newsList) {
    return newsList.fold(0, (sum, news) => sum + news.views);
  }

  String _formatNumber(int number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
