import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'support/in_memory_entry_repository.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  final now = DateTime.utc(2026, 11, 4, 12);
  const reel = 'https://www.instagram.com/reel/C8xYz12AbC/';
  final reelLink = VideoLink.parse(reel).valueOrNull!;

  /// [count] of Petar's entries, each with one analysis an hour ago.
  List<Entry> analysedToday(int count) => [
    for (var i = 0; i < count; i++)
      Entry(
        id: EntryId('e-$i'),
        owner: petar.id,
        source: FromVideo(link: reelLink),
        status: Saved(at: now),
        createdAt: now,
        analysisRequests: [now.subtract(const Duration(hours: 1))],
      ),
  ];

  SubmitLinkBloc blocWith(InMemoryEntryRepository repository) => SubmitLinkBloc(
    loadMyEntries: LoadMyEntries(entries: repository),
    submitLink: SubmitLink(entries: repository, clock: FixedClock(now)),
    user: petar,
    clock: FixedClock(now),
  );

  group('R1 · SubmitLinkBloc while typing', () {
    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'text that is not a link shows InvalidLink',
      build: () => blocWith(InMemoryEntryRepository()),
      act: (bloc) => bloc.add(const LinkChanged('palačinke sa bananom')),
      expect: () => [const SubmitLinkState(input: 'palačinke sa bananom', linkError: InvalidLink())],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'a YouTube link shows UnsupportedPlatform',
      build: () => blocWith(InMemoryEntryRepository()),
      act: (bloc) => bloc.add(const LinkChanged('https://youtube.com/shorts/aB3dE5fG7hI')),
      expect: () => [isA<SubmitLinkState>().having((s) => s.linkError, 'linkError', const UnsupportedPlatform())],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'an empty field shows no error and cannot be sent',
      build: () => blocWith(InMemoryEntryRepository()),
      seed: () => const SubmitLinkState(input: 'x', linkError: InvalidLink()),
      act: (bloc) => bloc.add(const LinkChanged('  ')),
      expect: () => [
        isA<SubmitLinkState>()
            .having((s) => s.linkError, 'linkError', isNull)
            .having((s) => s.canSubmit, 'canSubmit', isFalse),
      ],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'a valid link is recognised and enables the button',
      build: () => blocWith(InMemoryEntryRepository()),
      act: (bloc) => bloc.add(const LinkChanged(reel)),
      expect: () => [
        isA<SubmitLinkState>().having((s) => s.link, 'link', reelLink).having((s) => s.canSubmit, 'canSubmit', isTrue),
      ],
    );
  });

  group('R2 · SubmitLinkBloc counter', () {
    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'shows how many analyses are left today',
      build: () => blocWith(InMemoryEntryRepository(analysedToday(3))),
      act: (bloc) => bloc.add(const SubmitLinkOpened()),
      expect: () => [const SubmitLinkState(remaining: 17)],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'at the limit says when the next analysis is possible and keeps the button off',
      build: () => blocWith(InMemoryEntryRepository(analysedToday(20))),
      act: (bloc) => bloc
        ..add(const SubmitLinkOpened())
        ..add(const LinkChanged(reel)),
      expect: () => [
        SubmitLinkState(remaining: 0, limitError: DailyLimitReached(availableAt: now.add(const Duration(hours: 23)))),
        isA<SubmitLinkState>().having((s) => s.link, 'link', reelLink).having((s) => s.canSubmit, 'canSubmit', isFalse),
      ],
    );
  });

  group('SubmitLinkBloc · sending', () {
    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'sends the link and reports the new entry',
      build: () => blocWith(InMemoryEntryRepository()),
      seed: () => SubmitLinkState(input: reel, link: reelLink),
      act: (bloc) => bloc.add(const LinkSubmitted()),
      expect: () => [
        SubmitLinkState(input: reel, link: reelLink, isSending: true),
        isA<SubmitLinkState>()
            .having((s) => s.isSending, 'isSending', isFalse)
            .having(
              (s) => s.notice,
              'notice',
              isA<SubmitSucceeded>().having((n) => n.alreadyAnalyzed, 'alreadyAnalyzed', isFalse),
            ),
      ],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'a lost connection keeps the link in the field and reports the failure',
      build: () => blocWith(InMemoryEntryRepository()..failNextCall = true),
      seed: () => SubmitLinkState(input: reel, link: reelLink),
      act: (bloc) => bloc.add(const LinkSubmitted()),
      skip: 1,
      expect: () => [
        isA<SubmitLinkState>()
            .having((s) => s.input, 'input', reel)
            .having((s) => s.notice, 'notice', isA<SubmitFailed>()),
      ],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'a rule the server applies comes back as a rejection',
      build: () => blocWith(
        InMemoryEntryRepository()
          ..nextSubmitResult = Failure(DailyLimitReached(availableAt: now.add(const Duration(hours: 2)))),
      ),
      seed: () => SubmitLinkState(input: reel, link: reelLink),
      act: (bloc) => bloc.add(const LinkSubmitted()),
      skip: 1,
      expect: () => [
        isA<SubmitLinkState>().having(
          (s) => s.notice,
          'notice',
          SubmitRejected(DailyLimitReached(availableAt: now.add(const Duration(hours: 2)))),
        ),
      ],
    );

    blocTest<SubmitLinkBloc, SubmitLinkState>(
      'nothing is sent without a valid link',
      build: () => blocWith(InMemoryEntryRepository()),
      seed: () => const SubmitLinkState(input: 'x', linkError: InvalidLink()),
      act: (bloc) => bloc.add(const LinkSubmitted()),
      expect: () => <SubmitLinkState>[],
    );
  });
}
