import 'package:meta/meta.dart';

import 'identifiers.dart';

/// `user` manages their own entries and proposes them for the catalog; `editor` publishes or rejects proposals.
enum Role { user, editor }

@immutable
final class User {
  const User({required this.id, required this.role});

  final UserId id;
  final Role role;

  @override
  bool operator ==(Object other) => other is User && other.id == id && other.role == role;

  @override
  int get hashCode => Object.hash(id, role);

  @override
  String toString() => 'User(${id.value}, ${role.name})';
}
