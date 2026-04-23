import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({
    super.key,
    required this.onCategoryTap,
    required this.onProviderTap,
  });

  final void Function(String category) onCategoryTap;
  final void Function(String providerName) onProviderTap;

  static const _categories = [
    {'name': '叫車', 'emoji': '🚗', 'color': Color(0xFF3B82F6)},
    {'name': '外賣', 'emoji': '🍔', 'color': Color(0xFFEF4444)},
    {'name': '雜貨配送', 'emoji': '🛒', 'color': Color(0xFF22C55E)},
    {'name': '家居服務', 'emoji': '🏠', 'color': Color(0xFF6366F1)},
    {'name': '美容水療', 'emoji': '💅', 'color': Color(0xFFEC4899)},
    {'name': '包裹速遞', 'emoji': '📦', 'color': Color(0xFFA855F7)},
    {'name': '維修師傅', 'emoji': '🔧', 'color': Color(0xFFEAB308)},
    {'name': '醫療保健', 'emoji': '⚕️', 'color': Color(0xFF14B8A6)},
  ];

  static const _providers = [
    {
      'name': 'Premium Rides',
      'category': '叫車',
      'rating': 4.9,
      'reviews': 1250,
      'price': 'HK\$12 起',
    },
    {
      'name': "Chef's Kitchen",
      'category': '外賣',
      'rating': 4.8,
      'reviews': 890,
      'price': 'HK\$25 起',
    },
    {
      'name': 'Fresh Grocers',
      'category': '雜貨配送',
      'rating': 4.7,
      'reviews': 2100,
      'price': 'HK\$8 起',
    },
    {
      'name': 'Sparkle Clean',
      'category': '家居服務',
      'rating': 4.9,
      'reviews': 456,
      'price': 'HK\$45 起',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 12,
                16,
                16,
              ),
              child: const Text(
                '服務',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          // Categories
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '類別',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _CategoryCard(
                        name: cat['name'] as String,
                        emoji: cat['emoji'] as String,
                        color: cat['color'] as Color,
                        onTap: () => onCategoryTap(cat['name'] as String),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Popular Providers
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '熱門',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onCategoryTap(''),
                        child: const Text(
                          '查看全部',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_providers.map(
                    (provider) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProviderCard(
                        name: provider['name'] as String,
                        category: provider['category'] as String,
                        rating: provider['rating'] as double,
                        reviews: provider['reviews'] as int,
                        price: provider['price'] as String,
                        onTap: () => onProviderTap(provider['name'] as String),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  final String name;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ),
            Text(
              name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.onTap,
  });

  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('⭐️', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviews)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}
