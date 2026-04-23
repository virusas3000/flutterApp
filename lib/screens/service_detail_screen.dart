import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({
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
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  String? _selectedTimeSlot;
  bool _showBookingConfirm = false;
  bool _isFav = false;

  late final List<ProviderMenuItem> _items;
  late final String _address;
  late final String _bgUrl;

  static const _timeSlots = [
    '今天 14:00-17:00',
    '明天 09:00-12:00',
    '後天 13:00-16:00',
  ];

  static const _features = [
    '深度清潔全部房間',
    '環保友善產品',
    '專業設備器材',
    '滿意度保證',
    '投保及擔保',
    '彈性時間安排',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _items = widget.customItems.isNotEmpty
        ? widget.customItems
        : [
            ProviderMenuItem(
              title: '${p.serviceName}（基本）',
              subtitle: '快速安排，按情況收費',
              priceHkd: p.startingPrice.round().clamp(0, 99999),
            ),
            ProviderMenuItem(
              title: '${p.serviceName}（進階）',
              subtitle: '包含額外項目／材料',
              priceHkd: (p.startingPrice.round() + 120).clamp(0, 99999),
            ),
            ProviderMenuItem(
              title: '${p.serviceName}（加急）',
              subtitle: '優先處理，時間更彈性',
              priceHkd: (p.startingPrice.round() + 220).clamp(0, 99999),
            ),
          ];
    _bgUrl = (widget.customBackgroundPhotoUrl ?? '').trim();
    _address = (widget.customAddress ?? p.address).trim();
  }

  int get _reviewCount =>
      50 + (widget.provider.providerName.hashCode.abs() % 400);
  int get _yearsExp => 1 + (widget.provider.providerName.hashCode.abs() % 8);

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final isRemoteImage =
        _bgUrl.startsWith('http://') || _bgUrl.startsWith('https://');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sticky Header ──
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                elevation: 0,
                leading: _CircleBackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
                actions: [
                  _CircleActionButton(icon: Icons.share_outlined, onTap: () {}),
                  _CircleActionButton(
                    icon: _isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFav ? const Color(0xFFEF4444) : null,
                    onTap: () => setState(() => _isFav = !_isFav),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // ── Gallery ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildGallery(p, isRemoteImage),
                  ),
                ),
              ),

              // ── Service Info ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.serviceName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: GoServiceApp.kTextPrimary,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'HK\$${p.startingPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                Text(
                                  '每次服務',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: GoServiceApp.kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.description.split('\n').first.length > 20
                                ? p.description
                                      .split('\n')
                                      .first
                                      .substring(0, 20)
                                : (p.description.split('\n').first.isEmpty
                                      ? '服務'
                                      : p.description.split('\n').first),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Provider Info Card ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              _buildProviderAvatar(p),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            p.providerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: GoServiceApp.kTextPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 18,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFC107),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          p.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          ' ($_reviewCount)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: GoServiceApp.kTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.workspace_premium_rounded,
                                          size: 16,
                                          color: Color(0xFF6366F1),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$_yearsExp 年經驗',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: GoServiceApp.kTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Message button
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(21),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_address.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 16,
                                color: GoServiceApp.kTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: GoServiceApp.kTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),

                        // ── Quick Info ──
                        Row(
                          children: [
                            Expanded(
                              child: _QuickInfoTile(
                                icon: Icons.access_time_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                bgColor: const Color(0xFFEFF6FF),
                                label: '時長',
                                value: '3-4 小時',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickInfoTile(
                                icon: Icons.calendar_today_rounded,
                                iconColor: const Color(0xFF22C55E),
                                bgColor: const Color(0xFFF0FDF4),
                                label: '可預約',
                                value: '今天',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Description ──
                        const Text(
                          '關於此服務',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GoServiceApp.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.description.isNotEmpty
                              ? p.description
                              : '專業的服務，注重每一個細節。使用優質環保產品，提供高品質服務與滿意保證。',
                          style: TextStyle(
                            fontSize: 15,
                            color: GoServiceApp.kTextSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Features ──
                        const Text(
                          '服務包含',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GoServiceApp.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 0,
                          runSpacing: 8,
                          children: _features
                              .map(
                                (f) => SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width - 40) /
                                      2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          f,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Service Items & Prices ──
                        Row(
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
                            const Text(
                              '服務項目與價格',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: GoServiceApp.kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ServiceItemCard(item: item),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Available Time Slots ──
                        const Text(
                          '可預約時段',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GoServiceApp.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._timeSlots.map(
                          (slot) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedTimeSlot = slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _selectedTimeSlot == slot
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  color: _selectedTimeSlot == slot
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.05)
                                      : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        slot,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (_selectedTimeSlot == slot)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Reviews ──
                        Row(
                          children: [
                            const Text(
                              '評價',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: GoServiceApp.kTextPrimary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                '查看全部',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ReviewCard(
                          name: '陳先生',
                          rating: 5,
                          comment: '服務非常好！專業又仔細，我的家從來沒有這麼乾淨過。',
                          date: '2 天前',
                        ),
                        const SizedBox(height: 10),
                        _ReviewCard(
                          name: '李小姐',
                          rating: 5,
                          comment: '非常滿意，下次一定會再預約！',
                          date: '1 週前',
                        ),

                        // Space for bottom bar
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Action Bar ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedTimeSlot != null
                          ? () => setState(() => _showBookingConfirm = true)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        disabledBackgroundColor: const Color(
                          0xFF6366F1,
                        ).withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _selectedTimeSlot != null ? '立即預約' : '請選擇時段',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Booking Confirmation Bottom Sheet ──
          if (_showBookingConfirm) _buildBookingSheet(p),
        ],
      ),
    );
  }

  // ── Gallery ──
  Widget _buildGallery(ProviderMarker p, bool isRemoteImage) {
    if (_bgUrl.isNotEmpty) {
      return SizedBox(
        height: 200,
        child: isRemoteImage
            ? Image.network(
                _bgUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, _) => _galleryPlaceholder(p),
              )
            : Image.file(
                File(_bgUrl),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, _) => _galleryPlaceholder(p),
              ),
      );
    }
    return _galleryPlaceholder(p);
  }

  Widget _galleryPlaceholder(ProviderMarker p) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _GalleryCell(icon: p.icon, color: p.color),
          _GalleryCell(
            icon: Icons.cleaning_services_rounded,
            color: const Color(0xFF6366F1),
          ),
          _GalleryCell(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF8B5CF6),
          ),
          _GalleryCell(icon: Icons.spa_rounded, color: const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  // ── Provider avatar ──
  Widget _buildProviderAvatar(ProviderMarker p) {
    if (p.logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          File(p.logoUrl),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, _) => _avatarFallback(p),
        ),
      );
    }
    return _avatarFallback(p);
  }

  Widget _avatarFallback(ProviderMarker p) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          p.providerName.isNotEmpty ? p.providerName[0] : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Booking confirmation sheet ──
  Widget _buildBookingSheet(ProviderMarker p) {
    return GestureDetector(
      onTap: () => setState(() => _showBookingConfirm = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // absorb taps
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Check icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 32,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '確認預約',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: GoServiceApp.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '請確認您的預約詳情',
                      style: TextStyle(
                        fontSize: 15,
                        color: GoServiceApp.kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Booking details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _BookingRow(label: '服務', value: p.serviceName),
                          const SizedBox(height: 10),
                          _BookingRow(label: '供應商', value: p.providerName),
                          const SizedBox(height: 10),
                          _BookingRow(
                            label: '時間',
                            value: _selectedTimeSlot ?? '',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '總計',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: GoServiceApp.kTextSecondary,
                                ),
                              ),
                              Text(
                                'HK\$${p.startingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _showBookingConfirm = false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '取消',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() => _showBookingConfirm = false);
                              widget.onRequest();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '確認預約',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _QuickInfoTile extends StatelessWidget {
  const _QuickInfoTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: GoServiceApp.kTextSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _GalleryCell extends StatelessWidget {
  const _GalleryCell({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }
}

class _ServiceItemCard extends StatelessWidget {
  const _ServiceItemCard({required this.item});
  final ProviderMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
  });

  final String name;
  final int rating;
  final String comment;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        rating,
                        (_) => const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: GoServiceApp.kTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: GoServiceApp.kTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: GoServiceApp.kTextSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
