import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const petar = User(id: UserId('u-petar'), role: Role.user);
  const stefan = User(id: UserId('u-stefan'), role: Role.user);
  const editor = User(id: UserId('u-editor'), role: Role.editor);

  final at = DateTime.utc(2026, 11, 3, 12);
  final petarsEntry = Entry(
    id: const EntryId('e-1'),
    owner: petar.id,
    source: const Manual(),
    status: PendingApproval(submittedAt: at),
    createdAt: at,
    personal: const PersonalLayer(note: 'Bilo je preslano.'),
  );

  group('R6 · AccessPolicy', () {
    test('the owner manages their own entry', () {
      expect(AccessPolicy.canManage(petar, petarsEntry), isTrue);
    });

    test('another user cannot manage it', () {
      expect(AccessPolicy.canManage(stefan, petarsEntry), isFalse);
    });

    test('an editor cannot manage a user\'s entry', () {
      expect(AccessPolicy.canManage(editor, petarsEntry), isFalse);
    });

    test('only an editor decides on proposals', () {
      expect(AccessPolicy.canDecide(editor), isTrue);
      expect(AccessPolicy.canDecide(petar), isFalse);
    });
  });

  group('R7 · personal layer', () {
    test('the owner sees their personal layer', () {
      expect(AccessPolicy.canViewPersonal(petar, petarsEntry), isTrue);
    });

    test('another user does not', () {
      expect(AccessPolicy.canViewPersonal(stefan, petarsEntry), isFalse);
    });

    test('an editor does not, even while deciding on that very entry', () {
      expect(AccessPolicy.canDecide(editor), isTrue);
      expect(AccessPolicy.canViewPersonal(editor, petarsEntry), isFalse);
    });
  });
}
