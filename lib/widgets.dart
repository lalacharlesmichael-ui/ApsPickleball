import 'dart:async';

import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'models.dart';
import 'theme.dart';
import 'utils.dart';

const appLogoAsset = 'assets/brand/aps-pickle-zone-logo.png';
const appIconAsset = 'assets/brand/aps-pickle-zone-icon.png';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: scheme.onSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(appIconAsset, fit: BoxFit.cover),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text(
            'Aps Pickle Zone',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.brandText(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.adaptiveSurfaceColor(context, color),
      child: Padding(padding: padding, child: child),
    );
  }
}

class BackgroundSlideshow extends StatefulWidget {
  const BackgroundSlideshow({
    super.key,
    required this.imageUrls,
    required this.child,
    this.slideDuration = const Duration(seconds: 7),
    this.fadeDuration = const Duration(milliseconds: 850),
  });

  final List<String> imageUrls;
  final Widget child;
  final Duration slideDuration;
  final Duration fadeDuration;

  @override
  State<BackgroundSlideshow> createState() => _BackgroundSlideshowState();
}

class _BackgroundSlideshowState extends State<BackgroundSlideshow> {
  Timer? _timer;
  int _index = 0;

  List<String> get _urls {
    final seen = <String>{};
    return [
      for (final rawUrl in widget.imageUrls)
        if (rawUrl.trim().isNotEmpty && seen.add(rawUrl.trim())) rawUrl.trim(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheVisibleImages();
  }

  @override
  void didUpdateWidget(covariant BackgroundSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameUrls(oldWidget.imageUrls, widget.imageUrls)) {
      _index = 0;
      _syncTimer();
      _precacheVisibleImages();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (_urls.length < 2) return;
    _timer = Timer.periodic(widget.slideDuration, (_) {
      final urls = _urls;
      if (!mounted || urls.length < 2) return;
      setState(() => _index = (_index + 1) % urls.length);
      _precacheVisibleImages();
    });
  }

  void _precacheVisibleImages() {
    final urls = _urls;
    if (urls.isEmpty) return;
    final safeIndex = _index.clamp(0, urls.length - 1).toInt();
    unawaited(precacheImage(NetworkImage(urls[safeIndex]), context));
    if (urls.length > 1) {
      unawaited(
        precacheImage(
          NetworkImage(urls[(safeIndex + 1) % urls.length]),
          context,
        ),
      );
    }
  }

  bool _sameUrls(List<String> previous, List<String> next) {
    final left = previous
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty);
    final right = next.map((url) => url.trim()).where((url) => url.isNotEmpty);
    final leftList = left.toList();
    final rightList = right.toList();
    if (leftList.length != rightList.length) return false;
    for (var i = 0; i < leftList.length; i++) {
      if (leftList[i] != rightList[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    if (urls.isEmpty) return widget.child;
    final safeIndex = _index.clamp(0, urls.length - 1).toInt();
    final url = urls[safeIndex];
    final overlayAlpha = AppTheme.isDark(context) ? 152 : 104;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: widget.fadeDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Image.network(
              url,
              key: ValueKey(url),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withAlpha(overlayAlpha)),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 22,
    this.showBorder = false,
  });

  final Profile profile;
  final double radius;
  final bool showBorder;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Future<String?>? _signedUrl;
  String? _imagePath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImageUrl();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.profileImageUrl != widget.profile.profileImageUrl ||
        oldWidget.profile.id != widget.profile.id) {
      _syncImageUrl();
    }
  }

  void _syncImageUrl() {
    final path = widget.profile.profileImageUrl;
    if (path == _imagePath) return;
    _imagePath = path;
    _signedUrl = path == null || path.isEmpty
        ? Future<String?>.value()
        : AppScope.of(context).signedProfileImageUrl(widget.profile);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.iconTileBackground(context),
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(120),
                width: 2,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<String?>(
        future: _signedUrl,
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url == null || url.isEmpty) return _initials(context);
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initials(context),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Stack(
                alignment: Alignment.center,
                children: [
                  _initials(context),
                  SizedBox(
                    width: widget.radius * .7,
                    height: widget.radius * .7,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _initials(BuildContext context) {
    return Center(
      child: Text(
        initials(widget.profile.fullName),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.iconTileForeground(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accent = AppColors.green600,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tintAlpha = AppTheme.isDark(context) ? 46 : 26;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withAlpha(tintAlpha),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusBadge.booking(BookingStatus status) {
    return StatusBadge(
      label: statusLabel(status),
      color: _bookingColor(status),
    );
  }

  factory StatusBadge.payment(PaymentStatus status) {
    return StatusBadge(
      label: statusLabel(status),
      color: _paymentColor(status),
    );
  }

  factory StatusBadge.court(CourtStatus status) {
    return StatusBadge(label: statusLabel(status), color: _courtColor(status));
  }

  @override
  Widget build(BuildContext context) {
    final tintAlpha = AppTheme.isDark(context) ? 46 : 28;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(tintAlpha),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Color _bookingColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.amber;
      case BookingStatus.approved:
        return AppColors.blue;
      case BookingStatus.active:
        return AppColors.green600;
      case BookingStatus.completed:
        return AppColors.green800;
      case BookingStatus.declined:
      case BookingStatus.cancelled:
        return AppColors.red;
    }
  }

  static Color _paymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return AppColors.amber;
      case PaymentStatus.verified:
        return AppColors.green600;
      case PaymentStatus.rejected:
        return AppColors.red;
    }
  }

  static Color _courtColor(CourtStatus status) {
    switch (status) {
      case CourtStatus.available:
        return AppColors.green600;
      case CourtStatus.maintenance:
        return AppColors.amber;
      case CourtStatus.inactive:
        return AppColors.gray;
    }
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return AppCard(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.green600, size: 44),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 16), action],
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBanner extends StatelessWidget {
  const MessageBanner({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.red : AppColors.green600;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.end,
    required this.now,
    this.compact = false,
  });

  final DateTime end;
  final DateTime now;
  final bool compact;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = widget.now;
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end || oldWidget.now != widget.now) {
      _now = widget.now;
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (!widget.end.isAfter(_now)) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = manilaNow;
      setState(() => _now = next);
      if (!widget.end.isAfter(next)) {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.end.difference(_now);
    final finished = !remaining.isNegative && remaining > Duration.zero
        ? false
        : true;
    final text = finished ? 'Finished' : durationText(remaining);
    final colorScheme = Theme.of(context).colorScheme;
    final background = finished
        ? colorScheme.errorContainer
        : AppTheme.successContainer(context);
    final foreground = finished
        ? colorScheme.onErrorContainer
        : AppTheme.successOnContainer(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 12,
        vertical: widget.compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            finished ? Icons.timer_off_rounded : Icons.timer_rounded,
            size: widget.compact ? 16 : 18,
            color: foreground,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: widget.compact ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minItemWidth).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class BookingTile extends StatelessWidget {
  const BookingTile({
    super.key,
    required this.booking,
    required this.now,
    this.onTap,
    this.showCustomer = false,
  });

  final Booking booking;
  final DateTime now;
  final VoidCallback? onTap;
  final bool showCustomer;

  @override
  Widget build(BuildContext context) {
    final customer = booking.customer?.fullName ?? 'Customer';
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 14,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.iconTileBackground(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.sports_tennis_rounded,
            color: AppTheme.iconTileForeground(context),
          ),
        ),
        title: Text(
          '${booking.bookingReference} · ${booking.court?.courtName ?? 'Court'}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                '${formatDateLong(booking.bookingDate)} · ${bookingTimeRange(booking)}',
              ),
              if (showCustomer) Text(customer),
              Text(currency(booking.totalAmount)),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge.booking(booking.status),
            if (booking.status == BookingStatus.active)
              CountdownTimer(end: booking.localEnd, now: now, compact: true),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class CourtVisual extends StatelessWidget {
  const CourtVisual({super.key, this.height = 210});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CourtPainter()),
    );
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.green600;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, paint);

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final inset = Rect.fromLTWH(18, 18, size.width - 36, size.height - 36);
    canvas.drawRect(inset, line);
    canvas.drawLine(
      Offset(size.width / 2, 18),
      Offset(size.width / 2, size.height - 18),
      line,
    );
    canvas.drawLine(
      Offset(18, size.height / 2),
      Offset(size.width - 18, size.height / 2),
      line,
    );
    canvas.drawLine(
      Offset(size.width / 2 - 56, 18),
      Offset(size.width / 2 - 56, size.height - 18),
      line,
    );
    canvas.drawLine(
      Offset(size.width / 2 + 56, 18),
      Offset(size.width / 2 + 56, size.height - 18),
      line,
    );

    final paddlePaint = Paint()..color = AppColors.amber;
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .22),
      16,
      paddlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .78),
      16,
      paddlePaint,
    );
    final handle = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .18 + 10, size.height * .22 + 10),
      Offset(size.width * .18 + 26, size.height * .22 + 28),
      handle,
    );
    canvas.drawLine(
      Offset(size.width * .82 - 10, size.height * .78 - 10),
      Offset(size.width * .82 - 26, size.height * .78 - 28),
      handle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
