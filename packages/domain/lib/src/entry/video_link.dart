import 'package:meta/meta.dart';

import '../errors.dart';
import '../result.dart';

enum VideoPlatform { instagram, tiktok }

/// R1: a link to one Instagram or TikTok video, reduced to its canonical form (platform + video id).
///
/// Two links to the same video (with or without `www.`, with or without tracking parameters) give equal
/// [VideoLink]s. R4 ("the same video is analysed only once") relies on that.
@immutable
final class VideoLink {
  const VideoLink._({required this.platform, required this.videoId, this.isShortLink = false});

  final VideoPlatform platform;

  /// Kept as text: TikTok ids are longer than 2^53, the largest exact integer on the web.
  final String videoId;

  /// A short TikTok link (`vm.tiktok.com/<code>`): [videoId] holds the code. Only the server can resolve it to the
  /// real video id (KT2), so on the client R4 cannot match a short link with a full one.
  final bool isShortLink;

  static final _whitespace = RegExp(r'\s');
  static final _instagramId = RegExp(r'^[A-Za-z0-9_-]+$');
  static final _tiktokId = RegExp(r'^\d+$');
  static final _shortCode = RegExp(r'^[A-Za-z0-9]+$');

  static Result<VideoLink> parse(String input) {
    final text = input.trim();
    if (text.isEmpty || _whitespace.hasMatch(text)) return const Failure(InvalidLink());

    // People often paste a link without `https://`. Only then is it added: `mailto:...` already has a scheme.
    final asTyped = Uri.tryParse(text);
    final uri = asTyped != null && asTyped.hasScheme ? asTyped : Uri.tryParse('https://$text');
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')) || !uri.host.contains('.')) {
      return const Failure(InvalidLink());
    }

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
    final path = [
      for (final segment in uri.pathSegments)
        if (segment.isNotEmpty) segment,
    ];
    return switch (host) {
      'instagram.com' => _instagram(path),
      'tiktok.com' => _tiktok(path),
      'vm.tiktok.com' || 'vt.tiktok.com' => _tiktokShort(path),
      _ => const Failure(UnsupportedPlatform()),
    };
  }

  /// `instagram.com/reel/<id>`, `/reels/<id>` or `/p/<id>`.
  static Result<VideoLink> _instagram(List<String> path) {
    if (path.length < 2 || !const {'reel', 'reels', 'p'}.contains(path[0]) || !_instagramId.hasMatch(path[1])) {
      return const Failure(NotAVideoLink());
    }
    return Success(VideoLink._(platform: VideoPlatform.instagram, videoId: path[1]));
  }

  /// `tiktok.com/@<user>/video/<digits>`. The user name is not part of the identity of the video.
  static Result<VideoLink> _tiktok(List<String> path) {
    if (path.length < 3 || !path[0].startsWith('@') || path[1] != 'video' || !_tiktokId.hasMatch(path[2])) {
      return const Failure(NotAVideoLink());
    }
    return Success(VideoLink._(platform: VideoPlatform.tiktok, videoId: path[2]));
  }

  /// `vm.tiktok.com/<code>` or `vt.tiktok.com/<code>`.
  static Result<VideoLink> _tiktokShort(List<String> path) {
    if (path.length != 1 || !_shortCode.hasMatch(path[0])) return const Failure(NotAVideoLink());
    return Success(VideoLink._(platform: VideoPlatform.tiktok, videoId: path[0], isShortLink: true));
  }

  @override
  bool operator ==(Object other) =>
      other is VideoLink && other.platform == platform && other.videoId == videoId && other.isShortLink == isShortLink;

  @override
  int get hashCode => Object.hash(platform, videoId, isShortLink);

  @override
  String toString() => 'VideoLink(${platform.name}, $videoId${isShortLink ? ', short' : ''})';
}
