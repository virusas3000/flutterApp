import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';

class BrowseServicesScreen extends StatefulWidget {
  const BrowseServicesScreen({
    super.key,
    required this.providers,
    required this.onOpenProvider,
    required this.onRequestService,
    this.initialSearchQuery = '',
  });

  final List<ProviderMarker> providers;
  final ValueChanged<ProviderMarker> onOpenProvider;
  final ValueChanged<ProviderMarker> onRequestService;
  final String initialSearchQuery;

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

class _BrowseServicesScreenState extends State<BrowseServicesScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  String? _selectedCategory;
  bool _showFilters = false;
  String _sortBy = '距離';
  double? _minRating;

  static const _categories = [
    '全部',
    '叫車',
    '外賣',
    '家居服務',
    '美容水療',
    '維修師傅',
    '醫療保健',
    '寵物護理',
  ];

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

  List<ProviderMarker> get _filteredProviders {
    var result = widget.providers.where((p) {
      final q = _query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          p.serviceName.toLowerCase().contains(q) ||
          p.providerName.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategory == null || p.serviceName == _selectedCategory;
      final matchesRating = _minRating == null || p.rating >= _minRating!;
      return matchesQuery && matchesCategory && matchesRating;
    }).toList();
    if (_sortBy == '評分') {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      result.sort((a, b) => a.providerName.compareTo(b.providerName));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProviders;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '瀏覽服務',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: GoServiceApp.kTextPrimary,
                            ),
                          ),
                        ),
                        _HeaderIconButton(
                          icon: Icons.filter_list_rounded,
                          filled: true,
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: '搜尋服務或供應商...',
                          hintStyle: TextStyle(
                            color: GoServiceApp.kTextSecondary.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 15,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF8E8E93),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isActive =
                            (cat == '全部' && _selectedCategory == null) ||
                            _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = cat == '全部' ? null : cat;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: Column(
              children: [
                // Result count & sort
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} 個附近服務',
                        style: TextStyle(
                          fontSize: 14,
                          color: GoServiceApp.kTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sortBy = _sortBy == '距離' ? '評分' : '距離';
                          });
                        },
                        child: Text(
                          '排序：$_sortBy',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Service list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: GoServiceApp.kTextSecondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '沒有符合條件的服務',
                                style: TextStyle(
                                  color: GoServiceApp.kTextSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final provider = filtered[index];
                            return _ServiceCard(
                              provider: provider,
                              index: index,
                              onTap: () {
                                widget.onOpenProvider(provider);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Filter Bottom Sheet ──
      bottomSheet: _showFilters
          ? _FilterSheet(
              onClose: () => setState(() => _showFilters = false),
              initialMinRating: _minRating,
              onApply: (minRating) => setState(() {
                _minRating = minRating;
                _showFilters = false;
              }),
            )
          : null,
    );
  }
}

// ── Service Card (matches Figma BrowseServices card) ──
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.provider,
    required this.index,
    required this.onTap,
  });

  final ProviderMarker provider;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                _buildAvatar(),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider.serviceName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: GoServiceApp.kTextPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'HK\$${provider.startingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Provider name
                      Text(
                        provider.providerName,
                        style: TextStyle(
                          fontSize: 14,
                          color: GoServiceApp.kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating & distance
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC107),
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            provider.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: GoServiceApp.kTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${_estimatedReviews(provider)})',
                            style: TextStyle(
                              fontSize: 13,
                              color: GoServiceApp.kTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: GoServiceApp.kTextSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${_estimatedDistance(provider)} km',
                            style: TextStyle(
                              fontSize: 13,
                              color: GoServiceApp.kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Availability
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF22C55E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '現在可用',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (provider.logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(provider.logoUrl),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, _) => _buildIconFallback(),
        ),
      );
    }
    return _buildIconFallback();
  }

  Widget _buildIconFallback() {
    final initials = provider.providerName.isNotEmpty
        ? provider.providerName[0].toUpperCase()
        : provider.serviceName.isNotEmpty
        ? provider.serviceName[0].toUpperCase()
        : '?';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            provider.color.withValues(alpha: 0.85),
            provider.color.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  int _estimatedReviews(ProviderMarker p) {
    // Deterministic pseudo-count based on provider name hash
    return 50 + (p.providerName.hashCode.abs() % 400);
  }

  String _estimatedDistance(ProviderMarker p) {
    final d = 0.3 + (p.providerName.hashCode.abs() % 50) / 10.0;
    return d.toStringAsFixed(1);
  }
}

// ── Header Icon Button ──
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF6366F1) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled ? Colors.white : GoServiceApp.kTextPrimary,
        ),
      ),
    );
  }
}

// ── Filter Sheet ──
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.onClose,
    required this.onApply,
    this.initialMinRating,
  });

  final VoidCallback onClose;
  final void Function(double? minRating) onApply;
  final double? initialMinRating;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _minRating = widget.initialMinRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & close
              Row(
                children: [
                  const Text(
                    '篩選條件',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: GoServiceApp.kTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close_rounded, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Min Rating
              const Text(
                '最低評分',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [4.0, 4.5, 5.0].map((rating) {
                  final isSelected = _minRating == rating;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _minRating = isSelected ? null : rating;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFFFC107),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rating+',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : GoServiceApp.kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onApply(_minRating),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '套用篩選',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
