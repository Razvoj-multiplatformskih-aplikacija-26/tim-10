import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('R1 · VideoLink', () {
    VideoLink valid(String input) => VideoLink.parse(input).valueOrNull!;

    group('accepts', () {
      test('an Instagram reel', () {
        final link = valid('https://www.instagram.com/reel/C8xYz12AbC/');

        expect(link.platform, VideoPlatform.instagram);
        expect(link.videoId, 'C8xYz12AbC');
        expect(link.isShortLink, isFalse);
      });

      test('the /reels/ and /p/ forms as the same video', () {
        final reel = valid('https://www.instagram.com/reel/C8xYz12AbC/');

        expect(valid('https://www.instagram.com/reels/C8xYz12AbC/'), reel);
        expect(valid('https://www.instagram.com/p/C8xYz12AbC/'), reel);
      });

      test('a TikTok video and keeps its 19-digit id exactly', () {
        final link = valid('https://www.tiktok.com/@kuvarica/video/7301234567890123456');

        expect(link.platform, VideoPlatform.tiktok);
        expect(link.videoId, '7301234567890123456');
      });

      test('a short TikTok link as a short link', () {
        final link = valid('https://vm.tiktok.com/ZMabc123/');

        expect(link.platform, VideoPlatform.tiktok);
        expect(link.videoId, 'ZMabc123');
        expect(link.isShortLink, isTrue);
        expect(valid('https://vt.tiktok.com/ZMabc123/'), link);
      });
    });

    group('gives the same link for the same video', () {
      test('without www., without https:// and with tracking parameters', () {
        final canonical = valid('https://www.instagram.com/reel/C8xYz12AbC/');

        expect(valid('instagram.com/reel/C8xYz12AbC?igsh=MWQ1ZGUxMzBkMA=='), canonical);
        expect(valid('http://m.instagram.com/reel/C8xYz12AbC'), canonical);
        expect(valid('  https://WWW.INSTAGRAM.COM/reel/C8xYz12AbC  '), canonical);
      });

      test('for TikTok regardless of the user name and parameters', () {
        expect(
          valid('https://www.tiktok.com/@kuvarica/video/7301234567890123456?is_from_webapp=1'),
          valid('tiktok.com/@drugi_nalog/video/7301234567890123456'),
        );
      });

      test('but not for different videos', () {
        expect(valid('instagram.com/reel/C8xYz12AbC'), isNot(valid('instagram.com/reel/C8xYz12AbD')));
      });
    });

    group('rejects text that is not a link', () {
      for (final input in ['', '   ', 'pasta carbonara', 'instagram', 'mailto:kuvar@example.com']) {
        test('"$input"', () => expect(VideoLink.parse(input), const Failure<VideoLink>(InvalidLink())));
      }
    });

    group('rejects a link from another platform', () {
      for (final input in ['https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://example.com/reel/C8xYz12AbC']) {
        test(input, () => expect(VideoLink.parse(input), const Failure<VideoLink>(UnsupportedPlatform())));
      }
    });

    group('rejects an Instagram or TikTok link that is not a video', () {
      for (final input in [
        'https://www.instagram.com/',
        'https://www.instagram.com/kuvarica/',
        'https://www.instagram.com/reel/',
        'https://www.tiktok.com/@kuvarica',
        'https://www.tiktok.com/@kuvarica/video/abc',
        'https://vm.tiktok.com/',
      ]) {
        test(input, () => expect(VideoLink.parse(input), const Failure<VideoLink>(NotAVideoLink())));
      }
    });
  });
}
