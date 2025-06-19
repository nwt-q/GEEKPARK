import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import '../providers/news_provider.dart';
import '../models/news.dart';
import '../models/comment.dart';
import '../widgets/comment_item.dart';
import '../widgets/news_card.dart';

class NewsDetailScreen extends StatefulWidget {
  final int newsId;

  const NewsDetailScreen({Key? key, required this.newsId}) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadData();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 200;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
  }

  void _loadData() {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    provider.loadNewsDetail(widget.newsId);
  }

  void _checkFavoriteStatus() async {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    final favorited = await provider.isFavorited(widget.newsId);
    setState(() {
      _isFavorited = favorited;
    });
  }

  void _toggleFavorite() async {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    await provider.toggleFavorite(widget.newsId);
    setState(() {
      _isFavorited = !_isFavorited;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorited ? '已添加到收藏' : '已取消收藏'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareNews() {
    final provider = Provider.of<NewsProvider>(context, listen: false);
    final news = provider.currentNews;
    if (news != null) {
      // 这里可以集成分享功能
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享功能待实现'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentNews == null) {
            return const Scaffold(
              appBar: null,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null && provider.currentNews == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('新闻详情'),
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              body: Center(
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
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            );
          }

          final news = provider.currentNews;
          if (news == null) {
            return const Scaffold(
              body: Center(child: Text('新闻不存在')),
            );
          }

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 300,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  title: _showAppBarTitle
                      ? Text(
                          news.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorited ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareNews,
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: news.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 64,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (news.tags.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  children: news.tags.take(3).map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                news.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[600],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue[600],
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.article, size: 20),
                          const SizedBox(width: 4),
                          const Text('正文'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.comment, size: 20),
                          const SizedBox(width: 4),
                          Text('评论 (${provider.currentComments.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildContentTab(news, provider),
                      _buildCommentsTab(provider),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentTab(News news, NewsProvider provider) {
    print("[1]");
    print(news.content);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文章信息
          _buildArticleInfo(news),
          const SizedBox(height: 24),

          // 文章摘要
          if (news.abstract.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                news.abstract,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[800],
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 文章内容

          if (news.content != null && news.content!.isNotEmpty)
            Html(
              data: news.content!,
              style: {
                "body": Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight.number(1.6),
                  color: Colors.black87,
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight.number(1.6),
                  margin: Margins.only(bottom: 16),
                  padding: HtmlPaddings.zero,
                  textAlign: TextAlign.left,
                ),
                "p[style*='text-align: left']": Style(
                  textAlign: TextAlign.left,
                ),
                "p[style*='text-align: center']": Style(
                  textAlign: TextAlign.center,
                ),
                "p[style*='text-align: right']": Style(
                  textAlign: TextAlign.right,
                ),
                "span": Style(
                  fontSize: FontSize(16),
                ),
                "span[style*='font-weight: bold']": Style(
                  fontWeight: FontWeight.bold,
                ),
                "h1, h2, h3, h4, h5, h6": Style(
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24, bottom: 16),
                ),
                "img": Style(
                  width: Width(double.infinity),
                  margin: Margins.only(top: 16, bottom: 16),
                ),
                "blockquote": Style(
                  backgroundColor: Colors.grey[100],
                  padding: HtmlPaddings.all(16),
                  margin: Margins.only(top: 16, bottom: 16),
                  border: Border(
                    left: BorderSide(color: Colors.grey[400]!, width: 4),
                  ),
                ),
              },
              extensions: [
                TagExtension(
                  tagsToExtend: {"p"},
                  builder: (extensionContext) {
                    final element = extensionContext.element;
                    final style = element?.attributes['style'] ?? '';
                    TextAlign? textAlign;
                    if (style.contains('text-align: left')) {
                      textAlign = TextAlign.left;
                    } else if (style.contains('text-align: center')) {
                      textAlign = TextAlign.center;
                    } else if (style.contains('text-align: right')) {
                      textAlign = TextAlign.right;
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        element?.text ?? '',
                        textAlign: textAlign ?? TextAlign.left,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          else
            const Text(
              '暂无正文内容',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

          const SizedBox(height: 32),

          // 下一篇文章
          if (provider.nextNews != null) ...[
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '下一篇',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            NewsCard(
              news: provider.nextNews!,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetailScreen(
                      newsId: provider.nextNews!.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          // 相关文章
          if (provider.relatedNews.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '相关推荐',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...provider.relatedNews.map((relatedNews) {
              return NewsCard(
                news: relatedNews,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(
                        newsId: relatedNews.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],

          const SizedBox(height: 80), // 底部间距
        ],
      ),
    );
  }

  Widget _buildArticleInfo(News news) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 作者和时间信息
        Row(
          children: [
            if (news.authors.isNotEmpty && news.authors.first.avatarUrl != null)
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(
                  news.authors.first.avatarUrl!,
                ),
                onBackgroundImageError: (exception, stackTrace) {},
                child: news.authors.first.avatarUrl == null
                    ? Text(
                        news.mainAuthor.isNotEmpty ? news.mainAuthor[0] : 'A')
                    : null,
              )
            else
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  news.mainAuthor.isNotEmpty ? news.mainAuthor[0] : 'A',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.mainAuthor,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('yyyy年MM月dd日 HH:mm').format(news.publishedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 统计信息
        Row(
          children: [
            _buildStatItem(Icons.visibility, '${news.views}', '阅读'),
            const SizedBox(width: 24),
            _buildStatItem(Icons.thumb_up_outlined, '${news.likeCount}', '点赞'),
            const SizedBox(width: 24),
            _buildStatItem(
                Icons.comment_outlined, '${news.commentsCount}', '评论'),
            const SizedBox(width: 24),
            _buildStatItem(Icons.access_time, '${news.readingTime}分钟', '阅读时长'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  Widget _buildCommentsTab(NewsProvider provider) {
    if (provider.currentComments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无评论',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.currentComments.length,
      itemBuilder: (context, index) {
        final comment = provider.currentComments[index];
        return CommentItem(
          comment: comment,
          onReply: () {
            // 使用闭包捕获 comment 变量
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('回复 ${comment.content.substring(0, 10)}...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          onLike: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('点赞 ${comment.content.substring(0, 10)}...'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
