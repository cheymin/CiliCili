import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/video.dart';
import '../utils/theme.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: video.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(Icons.play_circle_outline,
                            color: cs.onSurfaceVariant.withOpacity(0.3),
                            size: 48),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.broken_image,
                          color: cs.onSurfaceVariant.withOpacity(0.3)),
                    ),
                  ),
                ),
                if (video.duration != null && video.duration! > 0)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTheme.formatDuration(video.duration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.title ?? '无标题',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (showViews) ...[
            const SizedBox(height: 4),
            Text(
              '${video.upName ?? "未知UP"} · ${AppTheme.formatCount(video.view ?? 0)}播放',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
