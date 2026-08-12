import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/video.dart';
import '../utils/theme.dart';
import '../utils/style.dart';

/// 视频卡片（垂直布局），视觉参考 PiliPlus VideoCardV：
/// Card 包裹、16:10 封面带时长角标、标题两行、底部 UP 名 + 播放量。
class VideoCard extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;
  final bool showViews;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.showViews = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: cs.surfaceContainerLow,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: Style.mdRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: Style.mdRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: Style.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: video.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(Icons.play_circle_outline,
                            color: cs.onSurfaceVariant.withOpacity(0.3),
                            size: 40),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.broken_image,
                          color: cs.onSurfaceVariant.withOpacity(0.3)),
                    ),
                  ),
                  if (video.duration != null && video.duration! > 0)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppTheme.formatDuration(video.duration!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title ?? '无标题',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                  ),
                  if (showViews) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            video.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                        Icon(Icons.play_arrow_outlined,
                            size: 13, color: cs.onSurfaceVariant),
                        Text(
                          AppTheme.formatCount(video.view ?? 0),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
