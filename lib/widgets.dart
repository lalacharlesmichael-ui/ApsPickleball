import 'package:flutter/material.dart';

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

class CountdownTimer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final remaining = end.difference(now);
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
        horizontal: compact ? 8 : 12,
        vertical: compact ? 5 : 8,
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
            size: compact ? 16 : 18,
            color: foreground,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 14,
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
