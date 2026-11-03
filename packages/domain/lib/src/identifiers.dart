// Each id is its own type, so the compiler rejects a UserId where an EntryId is expected.
// At runtime an extension type is just its String, so equality is plain String equality.

extension type const EntryId(String value) {}

extension type const UserId(String value) {}

extension type const CollectionId(String value) {}

/// An item in the curated food database (linked to USDA FoodData Central).
extension type const FoodId(String value) {}
