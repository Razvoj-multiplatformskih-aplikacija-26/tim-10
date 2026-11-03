import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  final at = DateTime.utc(2026, 11, 4, 12);

  test('every state of the domain has its own badge', () {
    final badges = {
      badgeStatusOf(Queued(at: at)),
      badgeStatusOf(Analyzing(startedAt: at)),
      badgeStatusOf(AwaitingReview(analyzedAt: at)),
      badgeStatusOf(Saved(at: at)),
      badgeStatusOf(AnalysisFailed(reason: AnalysisFailure.notFood, at: at)),
      badgeStatusOf(PendingApproval(submittedAt: at)),
      badgeStatusOf(Published(by: const UserId('u'), at: at, catalogId: const EntryId('e'))),
      badgeStatusOf(Rejected(by: const UserId('u'), reason: RejectionReason.parse('x').valueOrNull!, at: at)),
    };

    expect(badges, BadgeStatus.values.toSet());
  });

  test('the kind of a card comes from the content', () {
    const recipe = RecipeContent(title: 't', ingredients: [], steps: [], servings: 1);
    const restaurant = RestaurantContent(
      name: 'n',
      location: Location(address: 'a', city: 'c'),
      cuisine: 'k',
      recommendedDishes: [],
    );

    expect(cardKindOf(recipe), EntryCardKind.recipe);
    expect(cardKindOf(restaurant), EntryCardKind.restaurant);
    expect(cardKindOf(null), EntryCardKind.unknown);
  });
}
