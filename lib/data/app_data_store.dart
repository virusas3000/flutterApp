/// Persists app session data using a **NoSQL / key-value** backend (Hive).
/// This project does not use SQLite.
abstract class AppDataStore {
  Future<void> init();

  bool get isReady;

  Future<void> saveUserRoleIndex(int? roleIndex);

  int? readUserRoleIndex();

  Future<void> saveProviderListing(Map<String, dynamic>? json);

  Map<String, dynamic>? readProviderListingMap();

  Future<void> saveRecentProviderNames(List<String> names);

  List<String> readRecentProviderNames();

  Future<void> saveProviderAccount(Map<String, dynamic>? account);

  Map<String, dynamic>? readProviderAccount();

  Future<void> saveUserAccount(Map<String, dynamic>? account);

  Map<String, dynamic>? readUserAccount();

  Future<void> saveProviderAccounts(Map<String, dynamic> accountsByEmail);

  Map<String, dynamic> readProviderAccounts();

  Future<void> saveUserAccounts(Map<String, dynamic> accountsByEmail);

  Map<String, dynamic> readUserAccounts();

  Future<void> saveProviderLoggedIn(bool value);

  bool readProviderLoggedIn();

  Future<void> saveUserLoggedIn(bool value);

  bool readUserLoggedIn();

  /// Primary service type for users who need a service (first-time onboarding).
  /// `null` or empty means they have not completed the service-need prompt.
  Future<void> saveUserPrimaryServiceNeed(String? value);

  String? readUserPrimaryServiceNeed();

  Future<void> clearSession();
}
