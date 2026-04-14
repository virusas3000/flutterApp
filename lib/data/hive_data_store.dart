import 'package:hive_flutter/hive_flutter.dart';

import 'app_data_store.dart';

/// Hive-backed store (embedded NoSQL). Not SQLite.
final AppDataStore appDataStore = HiveDataStore();

class HiveDataStore implements AppDataStore {
  static const _boxName = 'goservice';
  static const _keyRole = 'user_role_index';
  static const _keyListing = 'provider_listing';
  static const _keyRecent = 'recent_provider_names';
  static const _keyProviderAccount = 'provider_account';
  static const _keyUserAccount = 'user_account';
  static const _keyProviderAccounts = 'provider_accounts';
  static const _keyUserAccounts = 'user_accounts';
  static const _keyProviderLoggedIn = 'provider_logged_in';
  static const _keyUserLoggedIn = 'user_logged_in';
  static const _keyUserPrimaryServiceNeed = 'user_primary_service_need';

  Box<dynamic>? _box;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  Box<dynamic> get _requireBox {
    final b = _box;
    if (b == null) {
      throw StateError('HiveDataStore.init() was not called');
    }
    return b;
  }

  @override
  bool get isReady => _box != null;

  @override
  Future<void> saveUserRoleIndex(int? roleIndex) async {
    if (_box == null) return;
    if (roleIndex == null) {
      await _requireBox.delete(_keyRole);
    } else {
      await _requireBox.put(_keyRole, roleIndex);
    }
  }

  @override
  int? readUserRoleIndex() {
    if (_box == null) return null;
    final v = _requireBox.get(_keyRole);
    if (v == null) return null;
    return v as int;
  }

  @override
  Future<void> saveProviderListing(Map<String, dynamic>? json) async {
    if (_box == null) return;
    if (json == null) {
      await _requireBox.delete(_keyListing);
    } else {
      await _requireBox.put(_keyListing, json);
    }
  }

  @override
  Map<String, dynamic>? readProviderListingMap() {
    if (_box == null) return null;
    final v = _requireBox.get(_keyListing);
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }

  @override
  Future<void> saveRecentProviderNames(List<String> names) async {
    if (_box == null) return;
    await _requireBox.put(_keyRecent, names);
  }

  @override
  List<String> readRecentProviderNames() {
    if (_box == null) return [];
    final v = _requireBox.get(_keyRecent);
    if (v == null) return [];
    return (v as List).map((e) => e.toString()).toList();
  }

  @override
  Future<void> saveProviderAccount(Map<String, dynamic>? account) async {
    if (_box == null) return;
    if (account == null) {
      await _requireBox.delete(_keyProviderAccount);
    } else {
      await _requireBox.put(_keyProviderAccount, account);
    }
  }

  @override
  Map<String, dynamic>? readProviderAccount() {
    if (_box == null) return null;
    final v = _requireBox.get(_keyProviderAccount);
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }

  @override
  Future<void> saveUserAccount(Map<String, dynamic>? account) async {
    if (_box == null) return;
    if (account == null) {
      await _requireBox.delete(_keyUserAccount);
    } else {
      await _requireBox.put(_keyUserAccount, account);
    }
  }

  @override
  Map<String, dynamic>? readUserAccount() {
    if (_box == null) return null;
    final v = _requireBox.get(_keyUserAccount);
    if (v == null) return null;
    return Map<String, dynamic>.from(v as Map);
  }

  @override
  Future<void> saveProviderAccounts(
    Map<String, dynamic> accountsByEmail,
  ) async {
    if (_box == null) return;
    await _requireBox.put(_keyProviderAccounts, accountsByEmail);
  }

  @override
  Map<String, dynamic> readProviderAccounts() {
    if (_box == null) return {};
    final v = _requireBox.get(_keyProviderAccounts);
    if (v == null) return {};
    return Map<String, dynamic>.from(v as Map);
  }

  @override
  Future<void> saveUserAccounts(Map<String, dynamic> accountsByEmail) async {
    if (_box == null) return;
    await _requireBox.put(_keyUserAccounts, accountsByEmail);
  }

  @override
  Map<String, dynamic> readUserAccounts() {
    if (_box == null) return {};
    final v = _requireBox.get(_keyUserAccounts);
    if (v == null) return {};
    return Map<String, dynamic>.from(v as Map);
  }

  @override
  Future<void> saveProviderLoggedIn(bool value) async {
    if (_box == null) return;
    await _requireBox.put(_keyProviderLoggedIn, value);
  }

  @override
  bool readProviderLoggedIn() {
    if (_box == null) return false;
    return (_requireBox.get(_keyProviderLoggedIn) as bool?) ?? false;
  }

  @override
  Future<void> saveUserLoggedIn(bool value) async {
    if (_box == null) return;
    await _requireBox.put(_keyUserLoggedIn, value);
  }

  @override
  bool readUserLoggedIn() {
    if (_box == null) return false;
    return (_requireBox.get(_keyUserLoggedIn) as bool?) ?? false;
  }

  @override
  Future<void> saveUserPrimaryServiceNeed(String? value) async {
    if (_box == null) return;
    if (value == null || value.trim().isEmpty) {
      await _requireBox.delete(_keyUserPrimaryServiceNeed);
    } else {
      await _requireBox.put(_keyUserPrimaryServiceNeed, value.trim());
    }
  }

  @override
  String? readUserPrimaryServiceNeed() {
    if (_box == null) return null;
    final v = _requireBox.get(_keyUserPrimaryServiceNeed);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  Future<void> clearSession() async {
    if (_box == null) return;
    await _requireBox.delete(_keyRole);
    await _requireBox.delete(_keyListing);
    await _requireBox.delete(_keyRecent);
    await _requireBox.delete(_keyUserPrimaryServiceNeed);
    await _requireBox.put(_keyProviderLoggedIn, false);
    await _requireBox.put(_keyUserLoggedIn, false);
  }
}
