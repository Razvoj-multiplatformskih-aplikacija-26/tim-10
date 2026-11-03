import '../user.dart';
import 'entry.dart';

/// Who may do what (README, requirement 1). The domain decides, not the screen.
abstract final class AccessPolicy {
  /// R6: the owner's actions on their own entry: save, retry, propose, edit and delete.
  /// An editor never manages users' entries; they only decide on proposals.
  static bool canManage(User user, Entry entry) => user.role == Role.user && entry.owner == user.id;

  /// R6: publishing or rejecting a proposal.
  static bool canDecide(User user) => user.role == Role.editor;

  /// R7: the personal layer is seen only by the owner, never by an editor (README, requirement 6).
  ///
  /// Today the same condition as [canManage], but a separate rule: sharing a collection with a friend would change
  /// one and not the other.
  static bool canViewPersonal(User user, Entry entry) => user.role == Role.user && entry.owner == user.id;
}
