import 'package:flutter/material.dart';

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
  bool _showFlashPromo = true;
  int _tabIndex = 0;

  static const _foodpandaPink = Color(0xFFD70F64);

  Future<void> _go(String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    await widget.onSelectCategory(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header & Banner
              SliverToBoxAdapter(
                child: Container(
                  color: _foodpandaPink,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location & Heart
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '46 軒尼詩道',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '香港',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      GestureDetector(
                        onTap: () => _go('搜尋'),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.black87),
                              const SizedBox(width: 12),
                              Text(
                                '搜尋餐廳及生活百貨',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Promo Banner Text
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '再次訂購生活百貨\n輸入TRYUSAGAIN\n即減高達\$60',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () => _go('優惠'),
                                  child: const Row(
                                    children: [
                                      Text(
                                        '立即掃貨',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Placeholder Emoji
                          Container(
                            width: 100,
                            height: 100,
                            alignment: Alignment.center,
                            child: const Text(
                              '🥩🥛🛒',
                              style: TextStyle(fontSize: 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Row 1
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopCategory(
                        '優惠',
                        '％',
                        const Color(0xFFF43F5E),
                        (v) => _go('優惠'),
                      ),
                      _buildTopCategory(
                        '一人餐',
                        '🍱',
                        Colors.blueGrey,
                        (v) => _go('美食'),
                      ),
                      _buildTopCategory(
                        '外賣自取',
                        '🛍️',
                        const Color(0xFFF472B6),
                        (v) => _go('外賣'),
                      ),
                      _buildTopCategory(
                        'pandamart',
                        '🛒',
                        const Color(0xFFD70F64),
                        (v) => _go('生活百貨'),
                      ),
                      _buildTopCategory(
                        '惠康',
                        'W',
                        const Color(0xFFE11D48),
                        (v) => _go('生活百貨'),
                        isText: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Divider(
                  color: Color(0xFFF2F2F7),
                  thickness: 1,
                  height: 1,
                ),
              ),

              // Cuisines Row 2
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildCuisineCategory('咖啡', '☕', (v) => _go('外賣')),
                        _buildCuisineCategory('漢堡', '🍔', (v) => _go('外賣')),
                        _buildCuisineCategory('快餐', '🍟', (v) => _go('外賣')),
                        _buildCuisineCategory('美式', '🌭', (v) => _go('外賣')),
                        _buildCuisineCategory('珍珠奶茶', '🧋', (v) => _go('外賣')),
                        _buildCuisineCategory('健康', '🥗', (v) => _go('外賣')),
                        _buildCuisineCategory('甜品', '🍰', (v) => _go('外賣')),
                      ],
                    ),
                  ),
                ),
              ),

              // Featured Series
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 0, 160),
                sliver: SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPromoCard(
                          title: '精選餐廳\n低至8折*',
                          bgColor: const Color(0xFFE91E63),
                          emoji: '🍲',
                        ),
                        _buildPromoCard(
                          title: 'foodpanda\n獨家\n呢度先有得嗌！',
                          bgColor: const Color(0xFFFFE4E1),
                          textColor: Colors.black87,
                          emoji: '🐼',
                          hasBadge: true,
                        ),
                        _buildPromoCard(
                          title: '生鮮食品\n極速送達',
                          bgColor: const Color(0xFFD70F64),
                          emoji: '🛒',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Promo
          if (_showFlashPromo)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '最多慳25%',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '快閃優惠：限時折扣',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _foodpandaPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _foodpandaPink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '35 : 01',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showFlashPromo = false),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Bottom Nav
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: _foodpandaPink);
                }
                return const IconThemeData(color: Colors.grey);
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: _foodpandaPink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  );
                }
                return const TextStyle(color: Colors.grey, fontSize: 12);
              }),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) {
              setState(() => _tabIndex = i);
              if (i == 4) {
                // Go to Account? Since it's a stand-alone view, we can just close back to the app shell
                // or fire `onBack` if we just want to bypass this home view.
                if (widget.onBack != null) widget.onBack!();
              } else if (i == 1) {
                _go('生活百貨'); // Just triggering the parent Flow
              }
            },
            backgroundColor: Colors.white,
            indicatorColor: Colors.transparent,
            height: 60,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.restaurant_rounded),
                label: '美食',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_rounded),
                label: '生活百貨',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: '搜尋'),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                label: '購物車',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: '帳戶',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCategory(
    String label,
    String emojiOrText,
    Color color,
    void Function(String) go, {
    bool isText = false,
  }) {
    return GestureDetector(
      onTap: () => go(label),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isText ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: isText
                ? Text(
                    emojiOrText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(emojiOrText, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineCategory(
    String label,
    String emoji,
    void Function(String) go,
  ) {
    return GestureDetector(
      onTap: () => go(label),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard({
    required String title,
    required Color bgColor,
    Color textColor = Colors.white,
    required String emoji,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: () => _go('優惠'),
      child: Container(
        width: 140,
        height: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
            if (hasBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD70F64),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            Positioned(
              bottom: -10,
              right: -10,
              child: Text(emoji, style: const TextStyle(fontSize: 80)),
            ),
          ],
        ),
      ),
    );
  }
}
