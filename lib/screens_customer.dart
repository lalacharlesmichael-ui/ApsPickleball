import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_scope.dart';
import 'app_store.dart';
import 'models.dart';
import 'print_helper.dart';
import 'theme.dart';
import 'utils.dart';
import 'widgets.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({
    super.key,
    required this.onBookPressed,
    required this.onBookingsPressed,
    required this.onNotificationsPressed,
  });

  final VoidCallback onBookPressed;
  final VoidCallback onBookingsPressed;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final profile = store.currentProfile;
    final active = store.currentActiveBooking;
    final upcoming = store.upcomingBookings.firstOrNull;
    final summary = store.bookingStatusSummary(store.myBookings);
    final topPlayers = store.playerOfWeek().take(3).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageHeader(
          title:
              'Welcome${profile == null ? '' : ', ${profile.fullName.split(' ').first}'}',
          subtitle: 'Asia/Manila time: ${formatDateTime(store.now)}',
          action: FilledButton.icon(
            onPressed: onBookPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Book a Court'),
          ),
        ),
        if (active != null) ...[
          AppCard(
            color: AppColors.green50,
            child: Row(
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: AppColors.green700,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current rental',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${active.court?.courtName ?? 'Court'} · ${bookingTimeRange(active)}',
                      ),
                    ],
                  ),
                ),
                CountdownTimer(end: active.localEnd, now: store.now),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ResponsiveGrid(
          children: [
            StatCard(
              title: 'Upcoming',
              value: upcoming?.court?.courtName ?? 'None',
              icon: Icons.event_available_rounded,
            ),
            StatCard(
              title: 'Pending',
              value: '${summary[BookingStatus.pending] ?? 0}',
              icon: Icons.pending_actions_rounded,
              accent: AppColors.amber,
            ),
            StatCard(
              title: 'Completed',
              value: '${summary[BookingStatus.completed] ?? 0}',
              icon: Icons.check_circle_outline_rounded,
              accent: AppColors.green800,
            ),
            StatCard(
              title: 'Available Today',
              value: '${store.availableCourtCount}/3',
              icon: Icons.sports_tennis_rounded,
              accent: AppColors.blue,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;
            final left = Column(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle(
                        title: 'Upcoming booking',
                        icon: Icons.calendar_today_rounded,
                        action: TextButton(
                          onPressed: onBookingsPressed,
                          child: const Text('View all'),
                        ),
                      ),
                      if (upcoming == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('No upcoming reservation yet.'),
                        )
                      else
                        BookingTile(
                          booking: upcoming,
                          now: store.now,
                          onTap: () => openBookingDetails(context, upcoming),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle(
                        title: 'Recent notifications',
                        icon: Icons.notifications_none_rounded,
                        action: TextButton(
                          onPressed: onNotificationsPressed,
                          child: const Text('Open'),
                        ),
                      ),
                      if (store.notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('No notifications yet.'),
                        )
                      else
                        ...store.notifications
                            .take(4)
                            .map(
                              (notification) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  notification.isRead
                                      ? Icons.mark_email_read_outlined
                                      : Icons.mark_email_unread_outlined,
                                  color: AppColors.green600,
                                ),
                                title: Text(notification.title),
                                subtitle: Text(notification.message),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            );
            final right = Column(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _CardTitle(
                        title: 'Player of the Week',
                        icon: Icons.emoji_events_outlined,
                      ),
                      const SizedBox(height: 8),
                      if (topPlayers.isEmpty)
                        const Text(
                          'Rankings appear after completed rentals this week.',
                        )
                      else
                        ...topPlayers.map(
                          (player) => PlayerRankingTile(player: player),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const AppCard(child: CourtVisual(height: 190)),
              ],
            );

            if (!wide) {
              return Column(
                children: [left, const SizedBox(height: 12), right],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class BookCourtPage extends StatefulWidget {
  const BookCourtPage({super.key});

  @override
  State<BookCourtPage> createState() => _BookCourtPageState();
}

class _BookCourtPageState extends State<BookCourtPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime(manilaNow.year, manilaNow.month, manilaNow.day + 1);
  Court? _court;
  String _startTime = '08:00:00';
  int _duration = 1;
  bool _isSubmitting = false;
  String? _message;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    _court ??= store.courts.where((court) => court.isAvailable).firstOrNull;
    final allowedDurations = store.allowedDurations(_startTime);
    if (!allowedDurations.contains(_duration)) {
      _duration = allowedDurations.first;
    }
    final total = (_court?.hourlyRate ?? defaultHourlyRate) * _duration;
    final available = _court == null
        ? false
        : store.isSlotAvailable(
            court: _court!,
            date: _date,
            startTime: _startTime,
            durationHours: _duration,
          );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Book a Court',
          subtitle: 'Select a court, date, start time, and rental duration.',
        ),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message != null)
                  MessageBanner(message: _message!, isError: _isError),
                DropdownButtonFormField<Court>(
                  initialValue: _court,
                  decoration: const InputDecoration(
                    labelText: 'Court',
                    prefixIcon: Icon(Icons.sports_tennis_rounded),
                  ),
                  items: store.courts
                      .map(
                        (court) => DropdownMenuItem(
                          value: court,
                          child: Text(
                            '${court.courtName} · ${currency(court.hourlyRate)}/hr',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (court) => setState(() => _court = court),
                  validator: (value) =>
                      value == null ? 'Choose a court.' : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(
                        store.now.year,
                        store.now.month,
                        store.now.day,
                      ),
                      lastDate: store.now.add(const Duration(days: 90)),
                      initialDate: _date.isBefore(store.now)
                          ? store.now
                          : _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(formatDateLong(_date)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _startTime,
                  decoration: const InputDecoration(
                    labelText: 'Start time',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  items: bookingStartHours
                      .map(
                        (hour) => DropdownMenuItem(
                          value: timeForHour(hour),
                          child: Text(formatTime(timeForHour(hour))),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _startTime = value ?? _startTime;
                    final durations = store.allowedDurations(_startTime);
                    if (!durations.contains(_duration)) {
                      _duration = durations.first;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _duration,
                  decoration: const InputDecoration(
                    labelText: 'Number of hours',
                    prefixIcon: Icon(Icons.timer_rounded),
                  ),
                  items: allowedDurations
                      .map(
                        (hours) => DropdownMenuItem(
                          value: hours,
                          child: Text('$hours hour${hours == 1 ? '' : 's'}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _duration = value ?? 1),
                ),
                const SizedBox(height: 14),
                AppCard(
                  color: available
                      ? AppColors.green50
                      : AppColors.red.withAlpha(18),
                  child: Row(
                    children: [
                      Icon(
                        available
                            ? Icons.check_circle_outline_rounded
                            : Icons.block_rounded,
                        color: available ? AppColors.green600 : AppColors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          available
                              ? 'This slot is available. Total amount: ${currency(total)}'
                              : 'This slot is not available. Choose another court or time.',
                          style: TextStyle(
                            color: available
                                ? AppColors.green800
                                : AppColors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSubmitting || !available
                      ? null
                      : () => _submit(store),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Submit Booking Request'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(AppStore store) async {
    if (!_formKey.currentState!.validate() || _court == null) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await store.createBooking(
        courtId: _court!.id,
        date: _date,
        startTime: _startTime,
        durationHours: _duration,
      );
      setState(() {
        _message =
            'Booking request submitted. Upload your payment proof from My Bookings.';
        _isError = false;
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class CourtAvailabilityPage extends StatefulWidget {
  const CourtAvailabilityPage({super.key});

  @override
  State<CourtAvailabilityPage> createState() => _CourtAvailabilityPageState();
}

class _CourtAvailabilityPageState extends State<CourtAvailabilityPage> {
  DateTime _date = DateTime(manilaNow.year, manilaNow.month, manilaNow.day);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageHeader(
          title: 'Court Availability',
          subtitle:
              'Green slots are available. Red or gray slots are occupied or unavailable.',
          action: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(
                  store.now.year,
                  store.now.month,
                  store.now.day,
                ),
                lastDate: store.now.add(const Duration(days: 90)),
                initialDate: _date,
              );
              if (picked != null) setState(() => _date = picked);
            },
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(formatDateLong(_date)),
          ),
        ),
        AppCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 110),
                    for (final hour in bookingStartHours)
                      _ScheduleHeader(label: formatTime(timeForHour(hour))),
                  ],
                ),
                const SizedBox(height: 8),
                for (final court in store.courts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            court.courtName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final hour in bookingStartHours)
                          _ScheduleCell(
                            available: store.isSlotAvailable(
                              court: court,
                              date: _date,
                              startTime: timeForHour(hour),
                              durationHours: 1,
                            ),
                            occupied:
                                store.bookingForSlot(court, _date, hour) !=
                                null,
                            maintenance:
                                store.maintenanceForSlot(court, _date, hour) ||
                                court.status == CourtStatus.maintenance,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  BookingStatus? _status;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final rows = store.myBookings.where((booking) {
      final matchesStatus = _status == null || booking.status == _status;
      final matchesSearch =
          query.isEmpty ||
          booking.bookingReference.toLowerCase().contains(query) ||
          (booking.court?.courtName.toLowerCase().contains(query) ?? false);
      return matchesStatus && matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'My Bookings',
          subtitle:
              'Track booking status, receipts, payment proof, and rental timers.',
        ),
        AppCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search bookings',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              DropdownButton<BookingStatus?>(
                value: _status,
                hint: const Text('All statuses'),
                items: [
                  const DropdownMenuItem<BookingStatus?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  ...BookingStatus.values.map(
                    (status) => DropdownMenuItem<BookingStatus?>(
                      value: status,
                      child: Text(statusLabel(status)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'No bookings found',
            message:
                'Your reservations will appear here after you submit a booking request.',
            action: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Use Book a Court'),
            ),
          )
        else
          ...rows.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BookingTile(
                booking: booking,
                now: store.now,
                onTap: () => openBookingDetails(context, booking),
              ),
            ),
          ),
      ],
    );
  }
}

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.adminMode = false,
  });

  final String bookingId;
  final bool adminMode;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final booking = store.bookings
        .where((item) => item.id == bookingId)
        .firstOrNull;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking details')),
        body: const Center(child: Text('Booking not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(booking.bookingReference)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PageHeader(
            title: 'Booking Details',
            subtitle:
                '${booking.court?.courtName ?? 'Court'} · ${formatDateLong(booking.bookingDate)}',
            action: booking.isBillable
                ? OutlinedButton.icon(
                    onPressed: printCurrentPage,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Receipt'),
                  )
                : null,
          ),
          ResponsiveGrid(
            children: [
              StatCard(
                title: 'Status',
                value: statusLabel(booking.status),
                icon: Icons.info_outline_rounded,
              ),
              StatCard(
                title: 'Payment',
                value: statusLabel(booking.paymentStatus),
                icon: Icons.verified_rounded,
                accent: booking.paymentStatus == PaymentStatus.verified
                    ? AppColors.green600
                    : AppColors.amber,
              ),
              StatCard(
                title: 'Duration',
                value: '${booking.durationHours}h',
                icon: Icons.timer_rounded,
                accent: AppColors.blue,
              ),
              StatCard(
                title: 'Total',
                value: currency(booking.totalAmount),
                icon: Icons.payments_rounded,
                accent: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (booking.status == BookingStatus.active) ...[
            AppCard(
              color: AppColors.green50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Remaining rental time',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  CountdownTimer(end: booking.localEnd, now: store.now),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          BookingReceiptCard(booking: booking),
          const SizedBox(height: 12),
          PaymentProofUploadPage(bookingId: booking.id, readOnly: adminMode),
          if (booking.adminNote != null && booking.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: AppColors.amber,
                ),
                title: const Text('Admin note'),
                subtitle: Text(booking.adminNote!),
              ),
            ),
          ],
          if (adminMode) ...[
            const SizedBox(height: 12),
            AdminBookingActions(booking: booking),
          ],
        ],
      ),
    );
  }
}

class PaymentProofUploadPage extends StatefulWidget {
  const PaymentProofUploadPage({
    super.key,
    required this.bookingId,
    this.readOnly = false,
  });

  final String bookingId;
  final bool readOnly;

  @override
  State<PaymentProofUploadPage> createState() => _PaymentProofUploadPageState();
}

class _PaymentProofUploadPageState extends State<PaymentProofUploadPage> {
  PlatformFile? _file;
  bool _isUploading = false;
  String? _message;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final booking = store.bookings
        .where((item) => item.id == widget.bookingId)
        .firstOrNull;
    if (booking == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Payment Proof',
            icon: Icons.upload_file_rounded,
          ),
          const SizedBox(height: 10),
          if (_message != null)
            MessageBanner(message: _message!, isError: _isError),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge.payment(booking.paymentStatus),
              if (booking.paymentProofUrl != null)
                OutlinedButton.icon(
                  onPressed: () => _previewProof(context, store, booking),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Preview Proof'),
                ),
            ],
          ),
          if (!widget.readOnly && booking.canUploadProof) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _file == null ? 'Choose JPG, PNG, or PDF' : _file!.name,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _file == null || _isUploading
                  ? null
                  : () async {
                      setState(() => _isUploading = true);
                      try {
                        await store.uploadPaymentProof(
                          booking: booking,
                          file: _file!,
                        );
                        if (!mounted) return;
                        setState(() {
                          _message =
                              'Payment proof uploaded for admin verification.';
                          _isError = false;
                          _file = null;
                        });
                      } catch (error) {
                        setState(() {
                          _message = error.toString();
                          _isError = true;
                        });
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    },
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: const Text('Upload Proof'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.single);
    }
  }

  Future<void> _previewProof(
    BuildContext context,
    AppStore store,
    Booking booking,
  ) async {
    final url = await store.signedPaymentProofUrl(booking);
    if (url == null || !context.mounted) return;
    final lower = (booking.paymentProofUrl ?? '').toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: const Text('Payment proof'),
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Flexible(child: Image.network(url, fit: BoxFit.contain)),
              ],
            ),
          ),
        ),
      );
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageHeader(
          title: 'Notifications',
          subtitle:
              'Booking updates, reminders, time alerts, and admin messages.',
          action: store.notifications.any((item) => !item.isRead)
              ? OutlinedButton.icon(
                  onPressed: store.markAllNotificationsRead,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Mark All Read'),
                )
              : null,
        ),
        if (store.notifications.isEmpty)
          const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'No notifications',
            message: 'Important booking updates will appear here.',
          )
        else
          ...store.notifications.map(
            (notification) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                color: notification.isRead ? null : AppColors.green50,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: AppColors.green600,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(
                    '${notification.message}\n${formatDateTime(notification.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: notification.isRead
                      ? null
                      : IconButton(
                          tooltip: 'Mark read',
                          onPressed: () =>
                              store.markNotificationRead(notification),
                          icon: const Icon(Icons.check_rounded),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PlayerLeaderboardPage extends StatelessWidget {
  const PlayerLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final rankings = store.playerOfWeek();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Player of the Week',
          subtitle:
              'Top players are ranked by completed rental hours this week.',
        ),
        if (rankings.isEmpty)
          const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No ranked players yet',
            message:
                'Completed rental hours this week will build the leaderboard.',
          )
        else
          ...rankings.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PlayerRankingTile(
                player: entry.value,
                rank: entry.key + 1,
              ),
            ),
          ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _contact = TextEditingController();
  PlatformFile? _image;
  bool _isSaving = false;
  bool _initialized = false;
  String? _message;
  bool _isError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = AppScope.of(context).currentProfile;
    _fullName.text = profile?.fullName ?? '';
    _contact.text = profile?.contactNumber ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final profile = store.currentProfile;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Profile',
          subtitle: 'Keep your player details current.',
        ),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message != null)
                  MessageBanner(message: _message!, isError: _isError),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.green100,
                  child: Text(
                    initials(profile?.fullName ?? 'APZ'),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.green800),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Full name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: profile == null ? '' : '@${profile.username}',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contact,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: const ['jpg', 'jpeg', 'png'],
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setState(() => _image = result.files.single);
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _image == null ? 'Choose Profile Photo' : _image!.name,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _save(store),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(AppStore store) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      await store.updateProfile(
        fullName: _fullName.text,
        contactNumber: _contact.text,
        imageFile: _image,
      );
      setState(() {
        _message = 'Profile updated.';
        _isError = false;
        _image = null;
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class BookingReceiptCard extends StatelessWidget {
  const BookingReceiptCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(compact: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Booking Receipt',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusBadge.booking(booking.status),
            ],
          ),
          const Divider(height: 28),
          _ReceiptRow(label: 'Reference', value: booking.bookingReference),
          _ReceiptRow(
            label: 'Customer',
            value: booking.customer?.fullName ?? 'Customer',
          ),
          _ReceiptRow(
            label: 'Court',
            value: booking.court?.courtName ?? 'Court',
          ),
          _ReceiptRow(
            label: 'Date',
            value: formatDateLong(booking.bookingDate),
          ),
          _ReceiptRow(label: 'Time', value: bookingTimeRange(booking)),
          _ReceiptRow(
            label: 'Duration',
            value:
                '${booking.durationHours} hour${booking.durationHours == 1 ? '' : 's'}',
          ),
          _ReceiptRow(
            label: 'Total amount',
            value: currency(booking.totalAmount),
          ),
          _ReceiptRow(
            label: 'Payment status',
            value: statusLabel(booking.paymentStatus),
          ),
        ],
      ),
    );
  }
}

class AdminBookingActions extends StatefulWidget {
  const AdminBookingActions({super.key, required this.booking});

  final Booking booking;

  @override
  State<AdminBookingActions> createState() => _AdminBookingActionsState();
}

class _AdminBookingActionsState extends State<AdminBookingActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final booking = widget.booking;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Admin Actions',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed:
                    _busy ||
                        booking.status != BookingStatus.pending ||
                        booking.paymentProofUrl == null
                    ? null
                    : () => _run(() => store.approveBooking(booking)),
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Approve'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || booking.status != BookingStatus.pending
                    ? null
                    : () => _decline(context, store, booking),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Decline'),
              ),
              OutlinedButton.icon(
                onPressed:
                    _busy ||
                        {
                          BookingStatus.completed,
                          BookingStatus.cancelled,
                          BookingStatus.declined,
                        }.contains(booking.status)
                    ? null
                    : () => _cancel(context, store, booking),
                icon: const Icon(Icons.event_busy_rounded),
                label: const Text('Cancel'),
              ),
              OutlinedButton.icon(
                onPressed:
                    _busy ||
                        !{
                          BookingStatus.approved,
                          BookingStatus.active,
                        }.contains(booking.status)
                    ? null
                    : () => _run(() => store.completeBooking(booking)),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Complete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline(
    BuildContext context,
    AppStore store,
    Booking booking,
  ) async {
    final note = await _noteDialog(context, 'Decline booking');
    if (note == null) return;
    await _run(() => store.declineBooking(booking, note));
  }

  Future<void> _cancel(
    BuildContext context,
    AppStore store,
    Booking booking,
  ) async {
    final note = await _noteDialog(context, 'Cancel booking');
    if (note == null) return;
    await _run(() => store.cancelBooking(booking, note));
  }
}

class PlayerRankingTile extends StatelessWidget {
  const PlayerRankingTile({super.key, required this.player, this.rank});

  final PlayerRanking player;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rank != null && rank! <= 3
                ? AppColors.amber
                : AppColors.green100,
            child: Text(rank?.toString() ?? initials(player.profile.fullName)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.profile.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${player.bookingCount} bookings · ${player.totalHours} hours · ${currency(player.totalAmount)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openBookingDetails(
  BuildContext context,
  Booking booking, {
  bool adminMode = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          BookingDetailsScreen(bookingId: booking.id, adminMode: adminMode),
    ),
  );
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({
    required this.available,
    required this.occupied,
    required this.maintenance,
  });

  final bool available;
  final bool occupied;
  final bool maintenance;

  @override
  Widget build(BuildContext context) {
    final color = maintenance
        ? AppColors.gray
        : occupied
        ? AppColors.red
        : available
        ? AppColors.green600
        : AppColors.gray;
    final label = maintenance
        ? 'Down'
        : occupied
        ? 'Busy'
        : available
        ? 'Open'
        : 'Closed';
    return Container(
      width: 82,
      height: 42,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.icon, this.action});

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.green600),
        const SizedBox(width: 9),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}

Future<String?> _noteDialog(BuildContext context, String title) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Admin note'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  return result;
}
