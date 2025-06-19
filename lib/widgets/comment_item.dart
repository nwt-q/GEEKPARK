import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/comment.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final bool showReplies;
  final int level;

  const CommentItem({
    Key? key,
    required this.comment,
    this.onLike,
    this.onReply,
    this.showReplies = true,
    this.level = 0,
  }) : super(key: key);

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLiked = false;
  int _likeCount = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.comment.likeCount;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isReply = widget.level > 0;
    final maxLevel = 3; // 最大嵌套层级

    return Container(
      margin: EdgeInsets.only(
        left: isReply ? (widget.level * 16.0).clamp(0, maxLevel * 16.0) : 0,
        bottom: 8,
      ),
      child: Card(
        elevation: isReply ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isReply
              ? BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户信息行
              Row(
                children: [
                  // 用户头像
                  CircleAvatar(
                    radius: isReply ? 16 : 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: widget.comment.user.avatarUrl != null &&
                            widget.comment.user.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            widget.comment.user.avatarUrl!)
                        : null,
                    child: widget.comment.user.avatarUrl == null ||
                            widget.comment.user.avatarUrl!.isEmpty
                        ? Text(
                            widget.comment.user.nickname?.isNotEmpty == true
                                ? widget.comment.user.nickname![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: isReply ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 用户名
                            Text(
                              widget.comment.user.nickname?.isNotEmpty == true
                                  ? widget.comment.user.nickname!
                                  : '匿名用户',
                              style: TextStyle(
                                fontSize: isReply ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            // VIP标识
                            if (widget.comment.user.verified)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VIP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                            // 作者标识
                            if (widget.comment.user.isAuthor)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '作者',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // 发布时间和楼层
                        Row(
                          children: [
                            Text(
                              _formatDate(widget.comment.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (widget.comment.floor > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '#${widget.comment.floor}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 更多操作按钮
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'report':
                          _showReportDialog();
                          break;
                        case 'copy':
                          _copyComment();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16),
                            SizedBox(width: 8),
                            Text('复制'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report, size: 16),
                            SizedBox(width: 8),
                            Text('举报'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 评论内容
              Text(
                widget.comment.content,
                style: TextStyle(
                  fontSize: isReply ? 14 : 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // 操作按钮行
              Row(
                children: [
                  // 点赞按钮
                  GestureDetector(
                    onTap: _handleLike,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 16,
                                color:
                                    _isLiked ? Colors.blue : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _likeCount.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _isLiked ? Colors.blue : Colors.grey[600],
                                  fontWeight: _isLiked
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 24),

                  // 回复按钮
                  if (widget.level < maxLevel)
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '回复',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // 展开/收起回复按钮
                  if (widget.comment.replies.isNotEmpty && widget.showReplies)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.comment.replies.length}条回复',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // 回复列表
              if (_isExpanded &&
                  widget.comment.replies.isNotEmpty &&
                  widget.showReplies)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: widget.comment.replies.map((reply) {
                      return CommentItem(
                        comment: reply,
                        onLike: widget.onLike,
                        onReply: widget.onReply,
                        showReplies: widget.level < maxLevel - 1,
                        level: widget.level + 1,
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('举报评论'),
        content: const Text('确定要举报这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('举报已提交'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _copyComment() {
    // 这里可以实现复制到剪贴板的功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('评论已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MM-dd HH:mm').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
    // 添加兜底返回语句，虽然上面的条件已经覆盖了所有情况
    return DateFormat('MM-dd HH:mm').format(date);
  }
}

// 评论排序选择器
class CommentSortSelector extends StatelessWidget {
  final CommentSortType currentSort;
  final ValueChanged<CommentSortType> onSortChanged;

  const CommentSortSelector({
    Key? key,
    required this.currentSort,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            '排序方式：',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CommentSortType.values.map((sort) {
                  final isSelected = sort == currentSort;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        _getSortLabel(sort),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          onSortChanged(sort);
                        }
                      },
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey[200],
                      checkmarkColor: Colors.white,
                      elevation: isSelected ? 2 : 0,
                      pressElevation: 4,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(CommentSortType sort) {
    switch (sort) {
      case CommentSortType.latest:
        return '最新';
      case CommentSortType.oldest:
        return '最早';
      case CommentSortType.hottest:
        return '最热';
      default:
        return '未知'; // 添加默认返回值
    }
  }
}

// 评论输入框
class CommentInput extends StatefulWidget {
  final String? replyToUser;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onSubmit;

  const CommentInput({
    Key? key,
    this.replyToUser,
    this.onCancel,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.replyToUser != null) {
      _controller.text = '@${widget.replyToUser} ';
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      widget.onSubmit?.call(content);
      _controller.clear();
      widget.onCancel?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyToUser != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '回复 @${widget.replyToUser}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: widget.replyToUser != null
                        ? '回复 @${widget.replyToUser}'
                        : '写下你的评论...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSubmitting ? null : _submit,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? Colors.grey : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
