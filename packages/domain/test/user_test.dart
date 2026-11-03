import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Identifiers', () {
    test('two ids with the same value are equal', () {
      expect(EntryId('e-1'), EntryId('e-1'));
      expect(EntryId('e-1'), isNot(EntryId('e-2')));
    });
  });

  group('User', () {
    test('users with the same id and role are equal', () {
      expect(User(id: UserId('u-1'), role: Role.user), User(id: UserId('u-1'), role: Role.user));
    });

    test('users with the same id but a different role are not equal', () {
      expect(User(id: UserId('u-1'), role: Role.user), isNot(User(id: UserId('u-1'), role: Role.editor)));
    });

    test('there are exactly two roles: user and editor', () {
      expect(Role.values, [Role.user, Role.editor]);
    });
  });
}
