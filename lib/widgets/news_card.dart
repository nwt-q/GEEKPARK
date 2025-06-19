import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/news.dart';

class NewsCard extends StatelessWidget {
  final News news;
  final VoidCallback? onTap;
  final bool showFullContent;
  final bool isHorizontal;

  const NewsCard({
    Key? key,
    required this.news,
    this.onTap,
    this.showFullContent = false,
    this.isHorizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图片
            if (news.coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: news.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标签
                  if (news.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: news.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTagColor(tag).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getTagColor(tag),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  if (news.tags.isNotEmpty) const SizedBox(height: 8),

                  // 标题
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: showFullContent ? null : 2,
                    overflow: showFullContent ? null : TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // 摘要
                  if (news.abstract.isNotEmpty)
                    Text(
                      news.abstract,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: showFullContent ? null : 3,
                      overflow: showFullContent ? null : TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // 作者和统计信息
                  Row(
                    children: [
                      // 作者头像
                      if (news.authors.isNotEmpty &&
                          news.authors[0].avatarUrl?.isNotEmpty == true)
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: CachedNetworkImageProvider(
                            news.authors[0].avatarUrl!,
                          ),
                          backgroundColor: Colors.grey[200],
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('Avatar load error: $exception');
                          },
                        )
                      else
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            news.authors.isNotEmpty
                                ? news.authors[0].nickname?.isNotEmpty == true
                                    ? news.authors[0].nickname![0].toUpperCase()
                                    : 'A'
                                : 'A',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      const SizedBox(width: 8),

                      // 作者名称
                      Expanded(
                        child: Text(
                          news.authors.isNotEmpty
                              ? news.authors[0].nickname?.isNotEmpty == true
                                  ? news.authors[0].nickname!
                                  : '匿名作者'
                              : '匿名作者',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 统计信息
                      _buildStatItem(Icons.visibility, news.views),
                      const SizedBox(width: 12),
                      _buildStatItem(
                          Icons.thumb_up, news.likeCount), // 修正为 likeCount
                      const SizedBox(width: 12),
                      _buildStatItem(Icons.comment,
                          news.commentsCount), // 修正为 commentsCount
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 发布时间和阅读时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(news.publishedDate), // 修正为 publishedDate
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (news.readingTime > 0)
                        Text(
                          '${news.readingTime}分钟阅读',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图片
              if (news.coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: CachedNetworkImage(
                      imageUrl: news.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标签
                      if (news.tags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getTagColor(news.tags.first).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getTagColor(news.tags.first)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            news.tags.first,
                            style: TextStyle(
                              fontSize: 9,
                              color: _getTagColor(news.tags.first),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      if (news.tags.isNotEmpty) const SizedBox(height: 6),

                      // 标题
                      Expanded(
                        child: Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 底部信息
                      Row(
                        children: [
                          // 作者头像（安全访问）
                          if (news.authors.isNotEmpty)
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  news.authors[0].avatarUrl?.isNotEmpty == true
                                      ? CachedNetworkImageProvider(
                                          news.authors[0].avatarUrl!)
                                      : null,
                              onBackgroundImageError: (exception, stackTrace) {
                                // 图片加载失败时的处理
                                debugPrint('Avatar load error: $exception');
                              },
                            )
                          else
                            // 没有作者信息时显示默认图标
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.grey[300],
                              child: const Text(
                                'A',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          const SizedBox(width: 6),

                          // 作者名称（安全访问）
                          Expanded(
                            child: Text(
                              news.authors.isNotEmpty
                                  ? news.authors[0].nickname?.isNotEmpty == true
                                      ? news.authors[0].nickname!
                                      : '匿名作者'
                                  : '匿名作者',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 阅读量
                          _buildStatItem(Icons.visibility, news.views,
                              small: true),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // 发布时间
                      Text(
                        _formatDate(news.publishedDate), // 修正为 publishedDate
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count, {bool small = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: small ? 10 : 12,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 2),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: small ? 9 : 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Color _getTagColor(String tag) {
    // 根据标签内容返回不同颜色
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final hash = tag.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MM-dd').format(date);
    } else if (difference.inDays > 0) {
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

// 特殊的热门新闻卡片
class HotNewsCard extends StatelessWidget {
  final News news;
  final VoidCallback? onTap;
  final int index;

  const HotNewsCard({
    Key? key,
    required this.news,
    this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getGradientColor().withOpacity(0.1),
                _getGradientColor().withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图片和排名
              Stack(
                children: [
                  if (news.coverUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: news.coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 排名标识
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRankColor(),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Expanded(
                        child: Text(
                          news.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 统计信息
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: _getGradientColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(news.views),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getGradientColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.thumb_up,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(news.likeCount), // 修正为 likeCount
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(
                                news.publishedDate), // 修正为 publishedDate
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGradientColor() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Color _getRankColor() {
    if (index == 0) return Colors.red;
    if (index == 1) return Colors.orange;
    if (index == 2) return Colors.blue;
    return Colors.grey;
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else {
      return '刚刚';
    }
  }
}
