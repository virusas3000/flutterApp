import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';

import 'data/hive_data_store.dart';

const bool _isWidgetTest = bool.fromEnvironment('FLUTTER_TEST');
const bool _authDisabled = true;

// Web Apple Sign-In requires a Service ID (clientId) + redirect URI.
// Fill these when you set up Sign in with Apple for Web.
const String _appleWebClientId = '';
const String _appleWebRedirectUri = '';

enum UserRole { serviceProvider, needsService }

/// Shared list for map chips and first-time “service needed” onboarding.
const List<String> kServiceNeedCategories = ['髮型屋'];

/// Listing details collected from service providers before the main map.
class ProviderOffering {
  const ProviderOffering({
    required this.title,
    required this.subtitle,
    required this.priceHkd,
  });

  final String title;
  final String subtitle;
  final int priceHkd;

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'priceHkd': priceHkd,
  };

  factory ProviderOffering.fromJson(Map<String, dynamic> json) {
    return ProviderOffering(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      priceHkd: (json['priceHkd'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProviderListing {
  const ProviderListing({
    required this.serviceDescription,
    required this.priceMin,
    required this.priceMax,
    required this.address,
    required this.backgroundPhotoUrl,
    required this.products,
    required this.latitude,
    required this.longitude,
    this.category = '',
    this.title = '',
    this.serviceTitle = '',
  });

  final String serviceDescription;
  final double priceMin;
  final double priceMax;
  final String address;
  final String backgroundPhotoUrl;
  final List<ProviderOffering> products;
  final double latitude;
  final double longitude;
  final String category;
  final String title;
  final String serviceTitle;

  double get lowestProductPrice {
    if (products.isEmpty) return 0;
    return products
        .map((e) => e.priceHkd.toDouble())
        .reduce((a, b) => a < b ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'serviceDescription': serviceDescription,
    'priceMin': priceMin,
    'priceMax': priceMax,
    'address': address,
    'backgroundPhotoUrl': backgroundPhotoUrl,
    'products': products.map((e) => e.toJson()).toList(),
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'title': title,
    'serviceTitle': serviceTitle,
  };

  factory ProviderListing.fromJson(Map<String, dynamic> m) {
    double d(String key) {
      final v = m[key];
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return ProviderListing(
      serviceDescription: (m['serviceDescription'] ?? '').toString(),
      priceMin: d('priceMin'),
      priceMax: d('priceMax'),
      address: (m['address'] ?? '').toString(),
      backgroundPhotoUrl: (m['backgroundPhotoUrl'] ?? '').toString(),
      products: ((m['products'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ProviderOffering.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      latitude: d('latitude'),
      longitude: d('longitude'),
      category: (m['category'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      serviceTitle: (m['serviceTitle'] ?? '').toString(),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appDataStore.init();
  runApp(const GoServiceApp());
}

/// Shown briefly on cold start before [AppShell]. Skips delay in widget tests.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key, required this.child});

  final Widget child;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _showMain = false;

  @override
  void initState() {
    super.initState();
    final delay = _isWidgetTest
        ? Duration.zero
        : const Duration(milliseconds: 1800);
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _showMain = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showMain ? widget.child : const StartupScreen();
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'InterMatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '本地服務，一按即達',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 56),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoServiceApp extends StatelessWidget {
  const GoServiceApp({super.key});

  static const Color kBrand = Color(0xFF00B4D8);
  static const Color kBrandDark = Color(0xFF0077B6);
  static const Color kBrandLight = Color(0xFFCAF0F8);
  static const Color kAccent = Color(0xFFFF6B35);
  static const Color kBg = Color(0xFFF8F9FA);
  static const Color kSurface = Colors.white;
  static const Color kTextPrimary = Color(0xFF1A1A2E);
  static const Color kTextSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InterMatch',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'Hant'),
      supportedLocales: const [Locale('zh', 'Hant'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrand,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurface,
          foregroundColor: kTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: kTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBrand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurface,
          indicatorColor: kBrandLight,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kBrandDark,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kBrandDark, size: 24);
            }
            return const IconThemeData(color: kTextSecondary, size: 24);
          }),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      home: const StartupGate(child: AppShell()),
    );
  }
}

class ServiceHubApp extends StatelessWidget {
  const ServiceHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoServiceApp();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  UserRole? _role;
  ProviderListing? _providerListing;
  bool _providerLoggedIn = false;
  bool _userLoggedIn = false;
  Map<String, dynamic>? _providerAccount;
  Map<String, dynamic>? _userAccount;
  // Email/password login removed; keep social accounts only.
  int _tabIndex = 0;
  final List<ProviderMarker> _recentlyViewed = [];
  String? _userPrimaryServiceNeed;
  bool _hydrated = false;
  final List<ServiceRequestDraft> _providerRequests = [];
  int _unreadRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final roleIndex = appDataStore.readUserRoleIndex();
    final listingMap = appDataStore.readProviderListingMap();
    final recentNames = appDataStore.readRecentProviderNames();
    final providerAccount = appDataStore.readProviderAccount();
    final userAccount = appDataStore.readUserAccount();
    final providerLoggedIn = appDataStore.readProviderLoggedIn();
    final userLoggedIn = appDataStore.readUserLoggedIn();
    final userPrimaryServiceNeed = appDataStore.readUserPrimaryServiceNeed();

    final resolvedRecent = <ProviderMarker>[];
    for (final name in recentNames) {
      for (final p in DemoData.providers) {
        if (p.providerName == name) {
          resolvedRecent.add(p);
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _hydrated = true;
      _role = roleIndex == null ? null : UserRole.values[roleIndex];
      _providerListing = listingMap == null
          ? null
          : ProviderListing.fromJson(listingMap);
      _providerAccount = providerAccount;
      _userAccount = userAccount;
      _providerLoggedIn = providerLoggedIn;
      _userLoggedIn = userLoggedIn;
      _userPrimaryServiceNeed = userPrimaryServiceNeed;
      _recentlyViewed
        ..clear()
        ..addAll(resolvedRecent);
    });
  }

  void _resetRole() {
    appDataStore.clearSession();
    setState(() {
      _role = null;
      _providerLoggedIn = false;
      _userLoggedIn = false;
      _userPrimaryServiceNeed = null;
      _recentlyViewed.clear();
      _tabIndex = 0;
    });
  }

  Future<void> _onUserPrimaryServiceNeedChosen(String value) async {
    await appDataStore.saveUserPrimaryServiceNeed(value);
    if (!mounted) return;
    setState(() => _userPrimaryServiceNeed = value.trim());
  }

  Future<void> _onUserCategoryChosenFromHome(String value) async {
    await _onUserPrimaryServiceNeedChosen(value);
    if (!mounted) return;
    setState(() => _tabIndex = 0);
  }

  void _onRoleSelected(UserRole role) {
    setState(() => _role = role);
    appDataStore.saveUserRoleIndex(role.index);
    if (role == UserRole.needsService) {
      appDataStore.saveProviderListing(null);
    }
  }

  // Email/password login removed. Keep only social/phone auth.

  Future<bool> _loginWithFacebook({required bool isProvider}) async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) {
        final msg = result.message ?? 'Facebook login cancelled';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        return false;
      }

      final userData = await FacebookAuth.instance.getUserData(
        fields: 'name,email,picture.width(200)',
      );

      final account = <String, dynamic>{
        'provider': 'facebook',
        'facebookUserId': userData['id'],
        'name': userData['name'],
        'email': userData['email'],
        'picture': (userData['picture'] as Map?)?['data'],
      };

      if (isProvider) {
        setState(() {
          _providerAccount = account;
          _providerLoggedIn = true;
        });
        await appDataStore.saveProviderAccount(account);
        await appDataStore.saveProviderLoggedIn(true);
      } else {
        setState(() {
          _userAccount = account;
          _userLoggedIn = true;
        });
        await appDataStore.saveUserAccount(account);
        await appDataStore.saveUserLoggedIn(true);
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Facebook 登入失敗：$e')));
      }
      return false;
    }
  }

  Future<bool> _loginWithApple({required bool isProvider}) async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('目前無法使用 Apple 登入。')));
        }
        return false;
      }

      final credential = kIsWeb
          ? await _getAppleCredentialForWeb()
          : await SignInWithApple.getAppleIDCredential(
              scopes: [
                AppleIDAuthorizationScopes.email,
                AppleIDAuthorizationScopes.fullName,
              ],
            );

      final account = <String, dynamic>{
        'provider': 'apple',
        'userIdentifier': credential.userIdentifier,
        'email': credential.email,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
        'identityToken': credential.identityToken,
      };

      if (isProvider) {
        setState(() {
          _providerAccount = account;
          _providerLoggedIn = true;
        });
        await appDataStore.saveProviderAccount(account);
        await appDataStore.saveProviderLoggedIn(true);
      } else {
        setState(() {
          _userAccount = account;
          _userLoggedIn = true;
        });
        await appDataStore.saveUserAccount(account);
        await appDataStore.saveUserLoggedIn(true);
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Apple 登入失敗：$e')));
      }
      return false;
    }
  }

  Future<AuthorizationCredentialAppleID> _getAppleCredentialForWeb() async {
    if (_appleWebClientId.isEmpty || _appleWebRedirectUri.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Apple web login not configured. Set _appleWebClientId and _appleWebRedirectUri.',
            ),
          ),
        );
      }
      throw StateError('Apple web login not configured');
    }

    return SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: _appleWebClientId,
        redirectUri: Uri.parse(_appleWebRedirectUri),
      ),
    );
  }

  bool _showPostSuccess = false;
  void _onProviderListingSaved(ProviderListing listing) async {
    setState(() {
      _providerListing = listing;
      _showPostSuccess = true;
    });
    appDataStore.saveProviderListing(listing.toJson());
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _showPostSuccess = false;
      _tabIndex = 0;
    });
  }

  List<ProviderMenuItem> _providerMenuItemsFor(
    ProviderMarker provider,
    ProviderListing? listing,
  ) {
    if (listing != null && listing.products.isNotEmpty) {
      return listing.products
          .map(
            (e) => ProviderMenuItem(
              title: e.title,
              subtitle: e.subtitle,
              priceHkd: e.priceHkd,
            ),
          )
          .toList();
    }

    final base = provider.startingPrice.round().clamp(0, 99999);
    int price(int delta) => (base + delta).clamp(0, 99999);

    return [
      ProviderMenuItem(
        title: '${provider.serviceName}（基本）',
        subtitle: '快速安排，按情況收費',
        priceHkd: price(0),
      ),
      ProviderMenuItem(
        title: '${provider.serviceName}（進階）',
        subtitle: '包含額外項目／材料（視乎現場）',
        priceHkd: price(120),
      ),
      ProviderMenuItem(
        title: '${provider.serviceName}（加急）',
        subtitle: '優先處理，時間更彈性',
        priceHkd: price(220),
      ),
    ];
  }

  void _onOpenProvider(ProviderMarker provider) {
    setState(() {
      _recentlyViewed.remove(provider);
      _recentlyViewed.insert(0, provider);
      if (_recentlyViewed.length > 8) {
        _recentlyViewed.removeLast();
      }
    });
    appDataStore.saveRecentProviderNames(
      _recentlyViewed.map((p) => p.providerName).toList(),
    );
  }

  void _onRequestService(ProviderMarker provider) {
    if (!_authDisabled && !_userLoggedIn) {
      _showUserAuth();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailsScreen(
          provider: provider,
          initialServiceType: _userPrimaryServiceNeed,
          initialUserName: (_userAccount?['name'] ?? '').toString(),
          onSubmit: (request) {
            setState(() {
              _providerRequests.insert(0, request);
              _unreadRequestCount++;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '已提交給 ${provider.providerName}：${request.serviceType}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showUserAuth() async {
    if (_authDisabled) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(
          title: '需要一般用戶帳號',
          subtitle: '要求服務前請先登入或註冊',
          onFacebook: () => _loginWithFacebook(isProvider: false),
          onApple: () => _loginWithApple(isProvider: false),
          onGoogle: () async {
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google 登入尚未設定（需要 Firebase/Google 配置）。'),
              ),
            );
            return false;
          },
          onPhone: () async {
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('電話登入尚未設定（需要 SMS OTP 後端）。')),
            );
            return false;
          },
        ),
      ),
    );
  }

  Future<void> _logoutCurrentRole() async {
    final role = _role;
    if (role == null) return;

    final account = role == UserRole.serviceProvider
        ? _providerAccount
        : _userAccount;
    if (account?['provider'] == 'facebook') {
      await FacebookAuth.instance.logOut();
    }

    if (role == UserRole.serviceProvider) {
      setState(() => _providerLoggedIn = false);
      await appDataStore.saveProviderLoggedIn(false);
    } else {
      setState(() => _userLoggedIn = false);
      await appDataStore.saveUserLoggedIn(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hydrated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_authDisabled) {
      // Treat both roles as logged-in while auth is disabled.
      _userLoggedIn = true;
      _providerLoggedIn = true;
    }

    if (_role == null) {
      return RoleSelectionScreen(onRoleSelected: _onRoleSelected);
    }

    if (_role == UserRole.serviceProvider && !_providerLoggedIn) {
      if (_authDisabled) {
        // Treat provider as logged-in when auth is temporarily disabled.
        _providerLoggedIn = true;
      } else {
        return AuthScreen(
          title: '服務提供者帳號',
          subtitle: '管理服務前請先註冊或登入',
          onBack: _resetRole,
          onFacebook: () => _loginWithFacebook(isProvider: true),
          onApple: () => _loginWithApple(isProvider: true),
          onGoogle: () async {
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google 登入尚未設定（需要 Firebase/Google 配置）。'),
              ),
            );
            return false;
          },
          onPhone: () async {
            if (!mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('電話登入尚未設定（需要 SMS OTP 後端）。')),
            );
            return false;
          },
        );
      }
    }

    if (_role == UserRole.serviceProvider && _providerListing == null) {
      if (_showPostSuccess) {
        return const PostSuccessScreen();
      }
      return ProviderSetupScreen(
        onBack: _resetRole,
        onComplete: _onProviderListingSaved,
      );
    }


    if (_role == UserRole.needsService &&
        (_userPrimaryServiceNeed == null || _userPrimaryServiceNeed!.isEmpty)) {
      return FoodPandaHomeScreen(
        onBack: _resetRole,
        onSelectCategory: _onUserCategoryChosenFromHome,
      );
    }

    final pages = [
      MapExploreScreen(
        role: _role!,
        myListing: _providerListing,
        myListingItems: _providerMenuItemsFor(
          ProviderMarker(
            latitude: _providerListing?.latitude ?? 0,
            longitude: _providerListing?.longitude ?? 0,
            eta: '15 min',
            icon: Icons.storefront_rounded,
            color: GoServiceApp.kBrandDark,
            serviceName: ((_providerListing?.category ?? '').trim().isNotEmpty)
                ? _providerListing!.category
                : ((_providerListing?.serviceDescription ?? '').trim().isEmpty)
                ? '你的服務'
                : (_providerListing!.serviceDescription
                      .split('\n')
                      .first
                      .trim()),
            providerName: (_providerListing?.title.isNotEmpty == true
                ? _providerListing!.title
                : (_providerAccount?['name'] ?? '你的店舖').toString()),
            description: _providerListing?.serviceDescription ?? '',
            startingPrice: _providerListing?.lowestProductPrice ?? 0,
            rating: 5,
            address: _providerListing?.address ?? '',
          ),
          _providerListing,
        ),
        myListingProviderName: (_providerListing?.title.isNotEmpty == true
            ? _providerListing!.title
            : (_providerAccount?['name'] ?? '你的店舖').toString()),
        isUserLoggedIn: _userLoggedIn,
        initialSearchQuery: _role == UserRole.needsService
            ? (_userPrimaryServiceNeed ?? '')
            : '',
        nearbyProviders: [
          ...DemoData.providers,
          if (_providerListing != null)
            ProviderMarker(
              latitude: _providerListing!.latitude,
              longitude: _providerListing!.longitude,
              eta: '15 min',
              icon: Icons.storefront_rounded,
              color: GoServiceApp.kBrandDark,
              serviceName: _providerListing!.category.isNotEmpty
                  ? _providerListing!.category
                  : _providerListing!.serviceDescription
                        .split('\n')
                        .first
                        .trim()
                        .isEmpty
                  ? '你的服務'
                  : _providerListing!.serviceDescription
                        .split('\n')
                        .first
                        .trim(),
              providerName: (_providerListing?.title.isNotEmpty == true
                  ? _providerListing!.title
                  : (_providerAccount?['name'] ?? '你的店舖').toString()),
              description: _providerListing!.serviceDescription,
              startingPrice: _providerListing!.lowestProductPrice,
              rating: 5,
              address: _providerListing!.address,
            ),
        ],
        onOpenProvider: _onOpenProvider,
        onRequestService: _onRequestService,
        onRequireUserAuth: _showUserAuth,
      ),
      if (_role == UserRole.serviceProvider)
        ProviderRequestsScreen(
          requests: _providerRequests,
          onClearUnread: () {
            setState(() => _unreadRequestCount = 0);
          },
        ),
      AccountScreen(
        role: _role!,
        providerListing: _providerListing,
        providerProductCount: _providerListing?.products.length ?? 0,
        providerAccount: _providerAccount,
        userAccount: _userAccount,
        onLogout: _logoutCurrentRole,
        onSwitchRole: _resetRole,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: '探索',
          ),
          if (_role == UserRole.serviceProvider)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _unreadRequestCount > 0,
                label: Text('$_unreadRequestCount'),
                child: const Icon(Icons.inbox_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: _unreadRequestCount > 0,
                label: Text('$_unreadRequestCount'),
                child: const Icon(Icons.inbox_rounded),
              ),
              label: '請求',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '帳號',
          ),
        ],
      ),
    );
  }
}

class PostSuccessScreen extends StatelessWidget {
  const PostSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0077B6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 72),
            SizedBox(height: 20),
            Text(
              '發佈成功！',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderSetupScreen extends StatefulWidget {
  const ProviderSetupScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
  });

  final VoidCallback onBack;
  final ValueChanged<ProviderListing> onComplete;

  @override
  State<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends State<ProviderSetupScreen> {
  static const LatLng _defaultPin = LatLng(22.3193, 114.1694);
  static const _stepTitles = ['店舖名稱', '服務類別', '服務詳情', '背景照片', '服務項目'];

  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _serviceTitleController = TextEditingController();
  final _serviceController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedCategory;

  final List<_ProviderOfferingDraft> _offeringDrafts = [
    _ProviderOfferingDraft(),
  ];
  String? _backgroundPhotoPath;
  int _currentStep = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _serviceTitleController.dispose();
    _serviceController.dispose();
    _addressController.dispose();

    for (final draft in _offeringDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_titleController.text.trim().isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('請輸入店舖名稱。')));
          return false;
        }
        return true;
      case 1:
        if (_selectedCategory == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('請選擇服務類別。')));
          return false;
        }
        return true;
      case 2:
        if (_serviceTitleController.text.trim().isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('請輸入服務標題。')));
          return false;
        }
        if (_serviceController.text.trim().isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('請描述你提供的服務內容。')));
          return false;
        }
        if (_addressController.text.trim().isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('請輸入服務地址。')));
          return false;
        }
        return true;
      case 3:
        return true;
      case 4:
        for (final draft in _offeringDrafts) {
          final title = draft.titleController.text.trim();
          final subtitle = draft.subtitleController.text.trim();
          final price = int.tryParse(draft.priceController.text.trim());
          if (title.isEmpty || subtitle.isEmpty || price == null || price < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('請完整填寫所有產品名稱、描述與有效價格。')),
            );
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _submit() {
    if (!_validateCurrentStep()) return;

    final products = <ProviderOffering>[];
    for (final draft in _offeringDrafts) {
      final title = draft.titleController.text.trim();
      final subtitle = draft.subtitleController.text.trim();
      final price = int.tryParse(draft.priceController.text.trim())!;
      products.add(
        ProviderOffering(title: title, subtitle: subtitle, priceHkd: price),
      );
    }

    widget.onComplete(
      ProviderListing(
        serviceDescription: _serviceController.text.trim(),
        serviceTitle: _serviceTitleController.text.trim(),
        priceMin: 0,
        priceMax: 0,
        address: _addressController.text.trim(),
        backgroundPhotoUrl: _backgroundPhotoPath ?? '',
        products: products,
        latitude: _defaultPin.latitude,
        longitude: _defaultPin.longitude,
        category: _selectedCategory ?? '',
        title: _titleController.text.trim(),
      ),
    );
  }

  Future<void> _pickBackgroundPhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1800,
      );
      if (!mounted || file == null) return;
      setState(() => _backgroundPhotoPath = file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('選擇背景照片失敗：$e')));
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: List.generate(_stepTitles.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepBefore = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepBefore < _currentStep
                    ? GoServiceApp.kBrand
                    : const Color(0xFFE5E7EB),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < _currentStep;
          final isCurrent = stepIndex == _currentStep;
          return GestureDetector(
            onTap: stepIndex < _currentStep
                ? () => setState(() => _currentStep = stepIndex)
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isCurrent
                        ? GoServiceApp.kBrand
                        : const Color(0xFFE5E7EB),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _stepTitles[stepIndex],
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted || isCurrent
                        ? GoServiceApp.kBrand
                        : const Color(0xFF9CA3AF),
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '步驟 1：店舖名稱',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '輸入你的店舖名稱，讓客戶認識你。',
              style: TextStyle(color: GoServiceApp.kTextSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '店舖名稱',
                hintText: '例如：剪髮研究所',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '步驟 2：服務類別',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '選擇你提供的服務類別。',
              style: TextStyle(color: GoServiceApp.kTextSecondary),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '服務類別',
                border: OutlineInputBorder(),
              ),
              hint: const Text('請選擇服務類別'),
              isExpanded: true,
              items: kServiceNeedCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '步驟 3：服務詳情',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '輸入服務標題、描述及地址。',
              style: TextStyle(color: GoServiceApp.kTextSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _serviceTitleController,
              decoration: const InputDecoration(
                labelText: '服務標題',
                hintText: '例如：專業剪髮造型',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serviceController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '服務描述',
                hintText: '例如：提供男女剪髮、染燙、造型等一站式服務…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '地址',
                hintText: '例如：尖沙咀廣東道 88 號',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '步驟 4：背景照片',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '上傳店舖背景照片（可選）。',
              style: TextStyle(color: GoServiceApp.kTextSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_backgroundPhotoPath != null &&
                      _backgroundPhotoPath!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isWidgetTest
                          ? Container(
                              height: 160,
                              color: const Color(0xFFECEFF1),
                              alignment: Alignment.center,
                              child: const Text('背景照片預覽'),
                            )
                          : Image.file(
                              File(_backgroundPhotoPath!),
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 160,
                                    color: const Color(0xFFECEFF1),
                                    alignment: Alignment.center,
                                    child: const Text('無法載入已選圖片'),
                                  ),
                            ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickBackgroundPhoto,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _backgroundPhotoPath == null
                                ? '上傳店舖頁背景照片'
                                : '重新選擇背景照片',
                          ),
                        ),
                      ),
                      if (_backgroundPhotoPath != null &&
                          _backgroundPhotoPath!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              setState(() => _backgroundPhotoPath = null),
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: '移除背景照片',
                        ),
                      ],
                    ],
                  ),
                  if (_backgroundPhotoPath == null ||
                      _backgroundPhotoPath!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '建議使用橫向照片，會顯示在服務提供者頁面最上方背景。',
                        style: TextStyle(
                          fontSize: 12,
                          color: GoServiceApp.kTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '步驟 5：服務項目',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '新增你的服務項目與價格。',
              style: TextStyle(color: GoServiceApp.kTextSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('服務項目', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _offeringDrafts.add(_ProviderOfferingDraft());
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新增項目'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_offeringDrafts.length, (index) {
              final draft = _offeringDrafts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '項目 ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (_offeringDrafts.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  final removed = _offeringDrafts.removeAt(
                                    index,
                                  );
                                  removed.dispose();
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: '刪除項目',
                            ),
                        ],
                      ),
                      TextField(
                        controller: draft.titleController,
                        decoration: const InputDecoration(
                          labelText: '產品／服務名稱',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: draft.subtitleController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: '描述',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: draft.priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '價格（HKD）',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _stepTitles.length - 1;
    final isFirstStep = _currentStep == 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isFirstStep ? widget.onBack : _prevStep,
        ),
        title: const Text('你的服務刊登'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildStepIndicator(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildStepContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  if (!isFirstStep)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('上一步'),
                      ),
                    ),
                  if (!isFirstStep) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLastStep ? _submit : _nextStep,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: GoServiceApp.kBrand,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isLastStep ? '儲存' : '下一步'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key, required this.onRoleSelected});

  final ValueChanged<UserRole> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoServiceApp.kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: GoServiceApp.kBrandLight,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'InterMatch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: GoServiceApp.kTextPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '你想如何使用此應用程式？',
                style: TextStyle(
                  fontSize: 16,
                  color: GoServiceApp.kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _RoleCard(
                icon: Icons.search_rounded,
                title: '我需要服務',
                subtitle: '搜尋附近服務供應商並預約',
                color: GoServiceApp.kBrand,
                onTap: () => onRoleSelected(UserRole.needsService),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: '我是服務提供者',
                subtitle: '刊登你的服務，接收客戶需求',
                color: GoServiceApp.kAccent,
                onTap: () => onRoleSelected(UserRole.serviceProvider),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: GoServiceApp.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: GoServiceApp.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderOfferingDraft {
  _ProviderOfferingDraft({
    String title = '',
    String subtitle = '',
    String price = '',
  }) : titleController = TextEditingController(text: title),
       subtitleController = TextEditingController(text: subtitle),
       priceController = TextEditingController(text: price);

  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController priceController;

  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    priceController.dispose();
  }
}

class FoodPandaHomeScreen extends StatefulWidget {
  const FoodPandaHomeScreen({
    super.key,
    required this.onSelectCategory,
    this.onBack,
  });

  final Future<void> Function(String value) onSelectCategory;
  final VoidCallback? onBack;

  @override
  State<FoodPandaHomeScreen> createState() => _FoodPandaHomeScreenState();
}

class _FoodPandaHomeScreenState extends State<FoodPandaHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _go(String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    await widget.onSelectCategory(v);
  }

  static const _categoryIcons = <String, IconData>{
    '髮型屋': Icons.content_cut_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: GoServiceApp.kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.onBack != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: widget.onBack,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const Expanded(
                        child: Text(
                          'InterMatch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '今日想搵咩服務？',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      /* search bar is for typing */
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: GoServiceApp.kTextSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _go,
                              decoration: InputDecoration(
                                hintText: '搜尋髮型屋…',
                                hintStyle: TextStyle(
                                  color: GoServiceApp.kTextSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: GoServiceApp.kBrand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '熱門分類',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GoServiceApp.kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kServiceNeedCategories.length > 8
                    ? 8
                    : kServiceNeedCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final name = kServiceNeedCategories[index];
                  final hue = (index * 40 + 180) % 360;
                  final color = HSLColor.fromAHSL(
                    1,
                    hue.toDouble(),
                    0.55,
                    0.50,
                  ).toColor();
                  return GestureDetector(
                    onTap: () => _go(name),
                    child: SizedBox(
                      width: 76,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: color.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Icon(
                              _categoryIcons[name] ?? Icons.category_rounded,
                              color: color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: GoServiceApp.kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: GoServiceApp.kAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '所有服務',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GoServiceApp.kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final name = kServiceNeedCategories[index];
                final hue = (index * 32) % 360;
                final color = HSLColor.fromAHSL(
                  1,
                  hue.toDouble(),
                  0.50,
                  0.52,
                ).toColor();
                return GestureDetector(
                  onTap: () => _go(name),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Icon(
                              _categoryIcons[name] ?? Icons.category_rounded,
                              color: color,
                              size: 48,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: GoServiceApp.kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '查看附近店家',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GoServiceApp.kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: kServiceNeedCategories.length),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-time prompt for users who need a service: capture the type of service they want.
class UserServiceNeedScreen extends StatefulWidget {
  const UserServiceNeedScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  final Future<void> Function(String value) onComplete;
  final VoidCallback? onBack;

  @override
  State<UserServiceNeedScreen> createState() => _UserServiceNeedScreenState();
}

class _UserServiceNeedScreenState extends State<UserServiceNeedScreen> {
  String? _selectedCategory;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final custom = _customController.text.trim();
    final value = custom.isNotEmpty ? custom : _selectedCategory;
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇或輸入你需要的服務類型')));
      return;
    }
    await widget.onComplete(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '你想找哪類服務？',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '選擇一項常見類型，或於下方自訂。日後仍可在地圖上更改搜尋。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kServiceNeedCategories.map((c) {
                          final selected = _selectedCategory == c;
                          return FilterChip(
                            label: Text(c),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = selected ? null : c;
                                if (!selected) _customController.clear();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _customController,
                        decoration: const InputDecoration(
                          labelText: '其他（自訂）',
                          hintText: '例如：鋼琴調音、寵物美容…',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (_customController.text.isNotEmpty) {
                            setState(() => _selectedCategory = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _continue, child: const Text('繼續')),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.onFacebook,
    this.onApple,
    this.onGoogle,
    this.onPhone,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Future<bool> Function()? onFacebook;
  final Future<bool> Function()? onApple;
  final Future<bool> Function()? onGoogle;
  final Future<bool> Function()? onPhone;
  final VoidCallback? onBack;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class ServiceRequestDraft {
  ServiceRequestDraft({
    required this.serviceType,
    required this.preferredTime,
    required this.contactPhone,
    required this.requesterName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String serviceType;
  final String preferredTime;
  final String contactPhone;
  final String requesterName;
  final DateTime createdAt;
}

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({
    super.key,
    required this.provider,
    this.initialServiceType,
    this.initialUserName,
    required this.onSubmit,
  });

  final ProviderMarker provider;
  final String? initialServiceType;
  final String? initialUserName;
  final ValueChanged<ServiceRequestDraft> onSubmit;

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  late final TextEditingController _serviceTypeController;
  final _preferredTimeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialServiceType ?? widget.provider.serviceName)
        .trim();
    _serviceTypeController = TextEditingController(text: initial);
    final userName = (widget.initialUserName ?? '').trim();
    if (userName.isNotEmpty) {
      _nameController.text = userName;
    }
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _preferredTimeController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final serviceType = _serviceTypeController.text.trim();
    final preferredTime = _preferredTimeController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入你的名稱')));
      return;
    }
    if (serviceType.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入服務類型')));
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入聯絡電話')));
      return;
    }

    widget.onSubmit(
      ServiceRequestDraft(
        serviceType: serviceType,
        preferredTime: preferredTime,
        contactPhone: phone,
        requesterName: name,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickTime() async {
    DateTime selectedTime = DateTime.now();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        padding: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('確定'),
                  onPressed: () {
                    final hh = selectedTime.hour.toString().padLeft(2, '0');
                    final mm = selectedTime.minute.toString().padLeft(2, '0');
                    _preferredTimeController.text = '$hh:$mm';
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (dt) => selectedTime = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return Scaffold(
      appBar: AppBar(title: const Text('填寫服務需求')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.color.withValues(alpha: 0.12),
                  child: Icon(p.icon, color: p.color),
                ),
                title: Text(p.serviceName),
                subtitle: Text(p.providerName),
                trailing: Text(
                  '\$${p.startingPrice.toStringAsFixed(0)} 起',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '你的名稱',
                hintText: '例如：陳先生',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serviceTypeController,
              decoration: const InputDecoration(
                labelText: '服務類型',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _preferredTimeController,
              readOnly: true,
              onTap: _pickTime,
              decoration: InputDecoration(
                labelText: '期望時間',
                hintText: '選擇時間',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_rounded),
                  tooltip: '選擇時間',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '聯絡電話',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: GoServiceApp.kBrand,
                foregroundColor: Colors.white,
              ),
              child: const Text('提交需求'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.subtitle),
              const SizedBox(height: 20),
              if (widget.onApple != null) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final ok = await widget.onApple!.call();
                    if (!mounted) return;
                    if (ok) navigator.maybePop();
                  },
                  icon: const Icon(Icons.apple),
                  label: const Text('使用 Apple 繼續'),
                ),
              ],
              if (widget.onGoogle != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final ok = await widget.onGoogle!.call();
                    if (!mounted) return;
                    if (ok) navigator.maybePop();
                  },
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text('使用 Google 繼續'),
                ),
              ],
              if (widget.onFacebook != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final ok = await widget.onFacebook!.call();
                    if (!mounted) return;
                    if (ok) navigator.maybePop();
                  },
                  icon: const Icon(Icons.facebook),
                  label: const Text('使用 Facebook 繼續'),
                ),
              ],
              if (widget.onPhone != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final ok = await widget.onPhone!.call();
                    if (!mounted) return;
                    if (ok) navigator.maybePop();
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('使用電話登入'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({
    super.key,
    required this.role,
    this.myListing,
    this.myListingItems = const [],
    this.myListingProviderName,
    required this.isUserLoggedIn,
    this.initialSearchQuery = '',
    required this.nearbyProviders,
    required this.onOpenProvider,
    required this.onRequestService,
    required this.onRequireUserAuth,
  });

  final UserRole role;
  final ProviderListing? myListing;
  final List<ProviderMenuItem> myListingItems;
  final String? myListingProviderName;
  final bool isUserLoggedIn;
  final String initialSearchQuery;
  final List<ProviderMarker> nearbyProviders;
  final ValueChanged<ProviderMarker> onOpenProvider;
  final ValueChanged<ProviderMarker> onRequestService;
  final VoidCallback onRequireUserAuth;

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  static const CameraPosition _hongKongCenter = CameraPosition(
    target: LatLng(22.3193, 114.1694),
    zoom: 12,
  );

  GoogleMapController? _mapController;
  LatLng _approxUserLocation = _hongKongCenter.target;
  ProviderMarker? _selectedProvider;

  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSearchQuery.trim();
    _query = initial;
    _searchController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProviders = widget.nearbyProviders.where((provider) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return provider.serviceName.toLowerCase().contains(query) ||
          provider.providerName.toLowerCase().contains(query) ||
          provider.description.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: _isWidgetTest
                ? Container(
                    color: const Color(0xFFECEFF1),
                    alignment: Alignment.center,
                    child: const Text('Google Map Preview'),
                  )
                : GoogleMap(
                    initialCameraPosition: _hongKongCenter,
                    onMapCreated: (c) => _mapController = c,
                    onCameraMove: (pos) => _approxUserLocation = pos.target,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    markers: _buildMarkers(filteredProviders),
                    polylines: const <Polyline>{},
                  ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: '搜尋服務類型',
                            hintStyle: TextStyle(
                              color: GoServiceApp.kTextSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: GoServiceApp.kBrand,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GoServiceApp.kBrand,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: _ServiceCategoryChips(
                    onSelect: (value) {
                      _searchController.text = value;
                      _searchController.selection = TextSelection.collapsed(
                        offset: value.length,
                      );
                      setState(() => _query = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ServiceListSheet(
              role: widget.role,
              providers: filteredProviders,
              onTapProvider: (provider) {
                widget.onOpenProvider(provider);
                _focusAndHighlight(provider);
                _showProviderDetails(context, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<ProviderMarker> providers) {
    final markers = providers
        .map(
          (provider) => Marker(
            markerId: MarkerId(provider.providerName),
            position: LatLng(provider.latitude, provider.longitude),
            icon: _selectedProvider?.providerName == provider.providerName
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  )
                : BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: provider.serviceName,
              snippet: '${provider.providerName} • ${provider.eta}',
              onTap: () {
                widget.onOpenProvider(provider);
                _focusAndHighlight(provider);
              },
            ),
            onTap: () {
              widget.onOpenProvider(provider);
              _focusAndHighlight(provider);
            },
          ),
        )
        .toSet();

    if (widget.role == UserRole.needsService && _selectedProvider != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('approx_user_location'),
          position: _approxUserLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: '你的位置（估算）'),
        ),
      );
    }

    return markers;
  }

  Future<void> _focusAndHighlight(ProviderMarker provider) async {
    setState(() => _selectedProvider = provider);

    if (_isWidgetTest) return;
    final c = _mapController;
    if (c == null) return;

    final store = LatLng(provider.latitude, provider.longitude);

    await c.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: store, zoom: 16.8)),
    );
  }

  void _showProviderDetails(BuildContext context, ProviderMarker provider) {
    widget.onOpenProvider(provider);
    final isMyListing =
        widget.role == UserRole.serviceProvider &&
        widget.myListing != null &&
        provider.latitude == widget.myListing!.latitude &&
        provider.longitude == widget.myListing!.longitude;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderMenuScreen(
          provider: provider,
          customItems: isMyListing ? widget.myListingItems : const [],
          customAddress: isMyListing ? widget.myListing?.address : null,
          customBackgroundPhotoUrl: isMyListing
              ? widget.myListing?.backgroundPhotoUrl
              : null,
          onRequest: () {
            if (widget.role == UserRole.needsService &&
                !widget.isUserLoggedIn) {
              widget.onRequireUserAuth();
              return;
            }
            widget.onRequestService(provider);
          },
        ),
      ),
    );
  }
}

class _ServiceListSheet extends StatelessWidget {
  const _ServiceListSheet({
    required this.role,
    required this.providers,
    required this.onTapProvider,
  });

  final UserRole role;
  final List<ProviderMarker> providers;
  final ValueChanged<ProviderMarker> onTapProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: GoServiceApp.kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(
              children: [
                Text(
                  role == UserRole.needsService ? '附近可用服務' : '地圖上的活躍服務',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: GoServiceApp.kTextPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${providers.length} 個結果',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GoServiceApp.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: providers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: GoServiceApp.kTextSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '沒有符合搜尋條件的服務',
                          style: TextStyle(color: GoServiceApp.kTextSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: providers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = providers[index];
                      return _ProviderCard(
                        provider: p,
                        onTap: () => onTapProvider(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final ProviderMarker provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      provider.color.withValues(alpha: 0.18),
                      provider.color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(provider.icon, color: provider.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: GoServiceApp.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      provider.providerName,
                      style: TextStyle(
                        fontSize: 13,
                        color: GoServiceApp.kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _RatingStars(
                          rating: provider.rating,
                          size: 13,
                          color: const Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: GoServiceApp.kTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: GoServiceApp.kBrandLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            provider.eta,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: GoServiceApp.kBrandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'HK\$${provider.startingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: GoServiceApp.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '起',
                    style: TextStyle(
                      fontSize: 11,
                      color: GoServiceApp.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderMenuItem {
  const ProviderMenuItem({
    required this.title,
    required this.subtitle,
    required this.priceHkd,
  });

  final String title;
  final String subtitle;
  final int priceHkd;
}

class ProviderMenuScreen extends StatelessWidget {
  const ProviderMenuScreen({
    super.key,
    required this.provider,
    this.customItems = const [],
    this.customAddress,
    this.customBackgroundPhotoUrl,
    required this.onRequest,
  });

  final ProviderMarker provider;
  final List<ProviderMenuItem> customItems;
  final String? customAddress;
  final String? customBackgroundPhotoUrl;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final items = customItems.isNotEmpty
        ? customItems
        : <ProviderMenuItem>[
            ProviderMenuItem(
              title: '${p.serviceName}（基本）',
              subtitle: '快速安排，按情況收費',
              priceHkd: p.startingPrice.round().clamp(0, 99999),
            ),
            ProviderMenuItem(
              title: '${p.serviceName}（進階）',
              subtitle: '包含額外項目／材料（視乎現場）',
              priceHkd: (p.startingPrice.round() + 120).clamp(0, 99999),
            ),
            ProviderMenuItem(
              title: '${p.serviceName}（加急）',
              subtitle: '優先處理，時間更彈性',
              priceHkd: (p.startingPrice.round() + 220).clamp(0, 99999),
            ),
          ];
    final bgUrl = (customBackgroundPhotoUrl ?? '').trim();
    final address = (customAddress ?? p.address).trim();
    final isRemoteImage =
        bgUrl.startsWith('http://') || bgUrl.startsWith('https://');

    return Scaffold(
      backgroundColor: GoServiceApp.kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bgUrl.isNotEmpty)
                    isRemoteImage
                        ? Image.network(
                            bgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        p.color,
                                        p.color.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                          )
                        : Image.file(
                            File(bgUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        p.color,
                                        p.color.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                          )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [p.color, p.color.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  Container(
                    color: Colors.black.withValues(
                      alpha: bgUrl.isNotEmpty ? 0.25 : 0,
                    ),
                  ),
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: Icon(
                      p.icon,
                      size: 160,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(p.icon, color: p.color, size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p.providerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.serviceName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RatingStars(
                        rating: p.rating,
                        size: 18,
                        color: const Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: GoServiceApp.kTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      _InfoPill(
                        icon: Icons.schedule_rounded,
                        text: '約 ${p.eta}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: GoServiceApp.kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    text: 'HK\$${p.startingPrice.toStringAsFixed(0)} 起',
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoPill(icon: Icons.place_outlined, text: address),
                  ],
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: p.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '服務項目與價格',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: GoServiceApp.kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onRequest,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: GoServiceApp.kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: GoServiceApp.kTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '價格',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: GoServiceApp.kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: GoServiceApp.kBrandLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'HK\$${item.priceHkd}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: GoServiceApp.kBrandDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: FilledButton(
              onPressed: onRequest,
              child: const Text('要求此服務'),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: GoServiceApp.kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: GoServiceApp.kTextSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: GoServiceApp.kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({
    required this.rating,
    this.size = 16,
    this.color = const Color(0xFFFFC107),
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const maxStars = 5;
    final clamped = rating.clamp(0.0, maxStars.toDouble());
    final full = clamped.floor();
    final fraction = clamped - full;
    final hasHalf = fraction >= 0.25 && fraction < 0.75;
    final extraFull = fraction >= 0.75 ? 1 : 0;
    final filled = (full + extraFull).clamp(0, maxStars);

    final stars = <Widget>[];
    for (var i = 0; i < filled; i++) {
      stars.add(Icon(Icons.star_rounded, size: size, color: color));
    }
    if (hasHalf && stars.length < maxStars) {
      stars.add(Icon(Icons.star_half_rounded, size: size, color: color));
    }
    while (stars.length < maxStars) {
      stars.add(
        Icon(
          Icons.star_outline_rounded,
          size: size,
          color: color.withValues(alpha: 0.55),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({
    super.key,
    required this.requests,
    required this.onClearUnread,
  });

  final List<ServiceRequestDraft> requests;
  final VoidCallback onClearUnread;

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  bool _clearedUnread = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void didUpdateWidget(covariant ProviderRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_clearedUnread) _markRead();
  }

  void _markRead() {
    if (_clearedUnread) return;
    _clearedUnread = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onClearUnread();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('客戶需求')),
      body: widget.requests.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: GoServiceApp.kTextSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暫時沒有客戶需求',
                    style: TextStyle(
                      fontSize: 16,
                      color: GoServiceApp.kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '當有客戶提交服務需求時，會顯示在這裡。',
                    style: TextStyle(
                      fontSize: 13,
                      color: GoServiceApp.kTextSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: widget.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = widget.requests[index];
                final timeAgo = _formatTimeAgo(req.createdAt);
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: GoServiceApp.kBrand.withValues(
                                alpha: 0.12,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: GoServiceApp.kBrand,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    req.requesterName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: GoServiceApp.kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RequestInfoRow(
                          icon: Icons.design_services_outlined,
                          label: '服務類型',
                          value: req.serviceType,
                        ),
                        if (req.preferredTime.isNotEmpty)
                          _RequestInfoRow(
                            icon: Icons.schedule_outlined,
                            label: '期望時間',
                            value: req.preferredTime,
                          ),
                        _RequestInfoRow(
                          icon: Icons.phone_outlined,
                          label: '聯絡電話',
                          value: req.contactPhone,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return '${diff.inDays} 天前';
  }
}

class _RequestInfoRow extends StatelessWidget {
  const _RequestInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GoServiceApp.kTextSecondary),
          const SizedBox(width: 8),
          Text(
            '$label：',
            style: TextStyle(fontSize: 13, color: GoServiceApp.kTextSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    required this.role,
    this.providerListing,
    this.providerProductCount = 0,
    this.providerAccount,
    this.userAccount,
    required this.onLogout,
    required this.onSwitchRole,
  });

  final UserRole role;
  final ProviderListing? providerListing;
  final int providerProductCount;
  final Map<String, dynamic>? providerAccount;
  final Map<String, dynamic>? userAccount;
  final Future<void> Function() onLogout;
  final VoidCallback onSwitchRole;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == UserRole.needsService ? '正在尋找服務' : '服務提供者';
    final account = role == UserRole.serviceProvider
        ? providerAccount
        : userAccount;
    final name = (account?['name'] ?? 'Account').toString();
    final email = (account?['email'] ?? '').toString();

    return Scaffold(
      backgroundColor: GoServiceApp.kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [GoServiceApp.kBrand, GoServiceApp.kBrandDark],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: GoServiceApp.kTextPrimary,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: GoServiceApp.kTextSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GoServiceApp.kBrandLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: GoServiceApp.kBrandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (providerListing != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '你的服務刊登',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: GoServiceApp.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (providerListing!.serviceTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          providerListing!.serviceTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: GoServiceApp.kTextPrimary,
                          ),
                        ),
                      ),
                    Text(
                      providerListing!.serviceDescription,
                      style: TextStyle(color: GoServiceApp.kTextSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'HK\$${providerListing!.lowestProductPrice.toStringAsFixed(0)} 起',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: GoServiceApp.kTextPrimary,
                      ),
                    ),
                    if (providerListing!.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        providerListing!.address,
                        style: TextStyle(color: GoServiceApp.kTextSecondary),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '已新增 $providerProductCount 個服務項目',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: GoServiceApp.kBrandDark,
                      ),
                    ),
                    if (providerListing!.backgroundPhotoUrl
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child:
                              (providerListing!.backgroundPhotoUrl.startsWith(
                                    'http://',
                                  ) ||
                                  providerListing!.backgroundPhotoUrl
                                      .startsWith('https://'))
                              ? Image.network(
                                  providerListing!.backgroundPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: const Color(0xFFECEFF1),
                                        alignment: Alignment.center,
                                        child: const Text('背景照片無法顯示'),
                                      ),
                                )
                              : _isWidgetTest
                              ? Container(
                                  color: const Color(0xFFECEFF1),
                                  alignment: Alignment.center,
                                  child: const Text('背景照片'),
                                )
                              : Image.file(
                                  File(providerListing!.backgroundPhotoUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: const Color(0xFFECEFF1),
                                        alignment: Alignment.center,
                                        child: const Text('背景照片無法顯示'),
                                      ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '已設定服務提供者頁面背景照片',
                        style: TextStyle(
                          fontSize: 12,
                          color: GoServiceApp.kTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _AccountMenuTile(
              icon: Icons.swap_horiz_rounded,
              title: '切換使用身份',
              onTap: onSwitchRole,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('登出'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: GoServiceApp.kTextSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: GoServiceApp.kTextPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: GoServiceApp.kTextSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCategoryChips extends StatelessWidget {
  const _ServiceCategoryChips({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: kServiceNeedCategories.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = kServiceNeedCategories[index];
        return GestureDetector(
          onTap: () => onSelect(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GoServiceApp.kTextPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProviderMarker {
  const ProviderMarker({
    required this.latitude,
    required this.longitude,
    required this.eta,
    required this.icon,
    required this.color,
    required this.serviceName,
    required this.providerName,
    required this.description,
    required this.startingPrice,
    required this.rating,
    this.address = '',
  });

  final double latitude;
  final double longitude;
  final String eta;
  final IconData icon;
  final Color color;
  final String serviceName;
  final String providerName;
  final String description;
  final double startingPrice;
  final double rating;
  final String address;
}

class DemoData {
  static const providers = <ProviderMarker>[
    ProviderMarker(
      latitude: 22.2800,
      longitude: 114.1588,
      eta: '10 min',
      icon: Icons.content_cut_rounded,
      color: Color(0xFF8E24AA),
      serviceName: '髮型屋',
      providerName: '剪髮研究所',
      description: '專業剪髮、染髮、燙髮服務，歡迎預約。',
      startingPrice: 120,
      rating: 4.8,
      address: '銅鑼灣駱克道 88 號',
    ),
    ProviderMarker(
      latitude: 22.3170,
      longitude: 114.1694,
      eta: '15 min',
      icon: Icons.content_cut_rounded,
      color: Color(0xFF5C6BC0),
      serviceName: '髮型屋',
      providerName: 'Style Studio',
      description: '時尚造型、護髮療程，為你打造獨特形象。',
      startingPrice: 150,
      rating: 4.5,
      address: '尖沙咀彌敦道 132 號',
    ),
    ProviderMarker(
      latitude: 22.3360,
      longitude: 114.1870,
      eta: '20 min',
      icon: Icons.content_cut_rounded,
      color: Color(0xFF00897B),
      serviceName: '髮型屋',
      providerName: '靚髮軒',
      description: '男女剪髮、頭皮護理、韓式造型。',
      startingPrice: 100,
      rating: 4.3,
      address: '旺角西洋菜街 56 號',
    ),
  ];
}
