import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'app_store.dart';
import 'models.dart';
import 'screens_customer.dart';
import 'theme.dart';
import 'utils.dart';
import 'widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.onBookingsPressed});

  final VoidCallback onBookingsPressed;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final approvedToday = store.bookings
        .where(
          (booking) =>
              isSameDate(booking.bookingDate, store.now) &&
              {
                BookingStatus.approved,
                BookingStatus.active,
                BookingStatus.completed,
              }.contains(booking.status),
        )
        .length;
    final topPlayers = store.playerOfWeek().take(3).toList();
    final pending = store.bookings
        .where((booking) => booking.status == BookingStatus.pending)
        .take(5)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageHeader(
          title: 'Admin Dashboard',
          subtitle: 'Court operations for ${formatDateTime(store.now)}.',
          action: FilledButton.icon(
            onPressed: onBookingsPressed,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review Bookings'),
          ),
        ),
        ResponsiveGrid(
          children: [
            StatCard(
              title: 'Total Customers',
              value: '${store.totalCustomers}',
              icon: Icons.group_outlined,
            ),
            StatCard(
              title: 'Pending Requests',
              value: '${store.pendingBookings}',
              icon: Icons.pending_actions_rounded,
              accent: AppColors.amber,
            ),
            StatCard(
              title: 'Approved Today',
              value: '$approvedToday',
              icon: Icons.event_available_rounded,
              accent: AppColors.blue,
            ),
            StatCard(
              title: 'Active Renters',
              value: '${store.activeRentals}',
              icon: Icons.timer_rounded,
              accent: AppColors.green800,
            ),
            StatCard(
              title: 'Available Courts',
              value: '${store.availableCourtCount}/3',
              icon: Icons.sports_tennis_rounded,
            ),
            StatCard(
              title: 'Total Income',
              value: currency(store.totalIncome),
              icon: Icons.payments_rounded,
              accent: AppColors.amber,
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final requests = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminSectionTitle(
                    title: 'Recent booking requests',
                    icon: Icons.inbox_outlined,
                    action: TextButton(
                      onPressed: onBookingsPressed,
                      child: const Text('Manage'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (pending.isEmpty)
                    const Text('No pending booking requests.')
                  else
                    ...pending.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BookingTile(
                          booking: booking,
                          now: store.now,
                          showCustomer: true,
                          onTap: () => openBookingDetails(
                            context,
                            booking,
                            adminMode: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
            final active = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AdminSectionTitle(
                    title: 'Active rental countdowns',
                    icon: Icons.timer_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (store.activeBookings.isEmpty)
                    const Text('No courts are currently active.')
                  else
                    ...store.activeBookings.map(
                      (booking) => _ActiveRentalCompact(booking: booking),
                    ),
                ],
              ),
            );
            final leaderboard = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AdminSectionTitle(
                    title: 'Player of the Week',
                    icon: Icons.emoji_events_outlined,
                  ),
                  const SizedBox(height: 10),
                  if (topPlayers.isEmpty)
                    const Text('No completed rentals this week.')
                  else
                    ...topPlayers.map(
                      (player) => PlayerRankingTile(player: player),
                    ),
                ],
              ),
            );

            if (!wide) {
              return Column(
                children: [
                  requests,
                  const SizedBox(height: 12),
                  active,
                  const SizedBox(height: 12),
                  leaderboard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: requests),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [active, const SizedBox(height: 12), leaderboard],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  final _search = TextEditingController();
  BookingStatus? _status;
  Court? _court;
  DateTimeRange? _range;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final rows = store.bookings.where((booking) {
      final matchesStatus = _status == null || booking.status == _status;
      final matchesCourt = _court == null || booking.courtId == _court!.id;
      final matchesRange =
          _range == null ||
          (!booking.bookingDate.isBefore(_range!.start) &&
              !booking.bookingDate.isAfter(_range!.end));
      final customer = booking.customer?.fullName.toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty ||
          booking.bookingReference.toLowerCase().contains(query) ||
          customer.contains(query) ||
          (booking.court?.courtName.toLowerCase().contains(query) ?? false);
      return matchesStatus && matchesCourt && matchesRange && matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Booking Management',
          subtitle:
              'Review requests, verify payments, and manage booking status.',
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
                    labelText: 'Search reference or customer',
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
              DropdownButton<Court?>(
                value: _court,
                hint: const Text('All courts'),
                items: [
                  const DropdownMenuItem<Court?>(
                    value: null,
                    child: Text('All courts'),
                  ),
                  ...store.courts.map(
                    (court) => DropdownMenuItem<Court?>(
                      value: court,
                      child: Text(court.courtName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _court = value),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(store.now.year - 1),
                    lastDate: DateTime(store.now.year + 1),
                    initialDateRange: _range,
                  );
                  if (picked != null) setState(() => _range = picked);
                },
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  _range == null
                      ? 'Date range'
                      : '${formatDate(_range!.start)} to ${formatDate(_range!.end)}',
                ),
              ),
              if (_range != null ||
                  _status != null ||
                  _court != null ||
                  query.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _range = null;
                    _status = null;
                    _court = null;
                    _search.clear();
                  }),
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'No bookings found',
            message: 'Try another status, court, date range, or search term.',
          )
        else
          ...rows.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BookingTile(
                booking: booking,
                now: store.now,
                showCustomer: true,
                onTap: () =>
                    openBookingDetails(context, booking, adminMode: true),
              ),
            ),
          ),
      ],
    );
  }
}

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
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
    final rows = store.customers.where((profile) {
      return query.isEmpty ||
          profile.fullName.toLowerCase().contains(query) ||
          profile.username.toLowerCase().contains(query) ||
          (profile.contactNumber?.contains(query) ?? false);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Customer Management',
          subtitle:
              'Search customer profiles and review booking history, hours, and payments.',
        ),
        AppCard(
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search users',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const EmptyState(
            icon: Icons.group_off_outlined,
            title: 'No customers found',
            message: 'Customer profiles appear after registration.',
          )
        else
          ...rows.map((profile) => _CustomerCard(profile: profile)),
      ],
    );
  }
}

class CourtManagementPage extends StatelessWidget {
  const CourtManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Court Management',
          subtitle: 'Set availability, maintenance state, and court notes.',
        ),
        ...store.courts.map(
          (court) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.green100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sports_tennis_rounded,
                          color: AppColors.green700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              court.courtName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('${currency(court.hourlyRate)} per hour'),
                          ],
                        ),
                      ),
                      StatusBadge.court(court.status),
                    ],
                  ),
                  if (court.maintenanceNote != null &&
                      court.maintenanceNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(court.maintenanceNote!),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: court.status == CourtStatus.available
                            ? null
                            : () => store.updateCourtStatus(
                                court: court,
                                status: CourtStatus.available,
                              ),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Available'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _courtNoteDialog(
                          context,
                          court,
                          CourtStatus.maintenance,
                        ),
                        icon: const Icon(Icons.construction_rounded),
                        label: const Text('Maintenance'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _courtNoteDialog(
                          context,
                          court,
                          CourtStatus.inactive,
                        ),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('Inactive'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _courtNoteDialog(
    BuildContext context,
    Court court,
    CourtStatus status,
  ) async {
    final store = AppScope.of(context);
    final controller = TextEditingController(text: court.maintenanceNote ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set ${court.courtName} ${statusLabel(status)}'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Maintenance note'),
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
    if (note != null) {
      await store.updateCourtStatus(court: court, status: status, note: note);
    }
  }
}

class ActiveRentalsPage extends StatelessWidget {
  const ActiveRentalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Active Rentals',
          subtitle: 'Live timers for courts currently in play.',
        ),
        if (store.activeBookings.isEmpty)
          const EmptyState(
            icon: Icons.timer_off_outlined,
            title: 'No active rentals',
            message:
                'Approved bookings become active when their start time arrives.',
          )
        else
          ...store.activeBookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.sports_tennis_rounded,
                      color: AppColors.green600,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.court?.courtName ?? 'Court',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${booking.customer?.fullName ?? 'Customer'} · ${bookingTimeRange(booking)}',
                          ),
                        ],
                      ),
                    ),
                    CountdownTimer(end: booking.localEnd, now: store.now),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final week = weekStart(store.now);
    final weeklyRevenue = store.bookings
        .where(
          (booking) =>
              !booking.localStart.isBefore(week) &&
              booking.isBillable &&
              booking.paymentStatus == PaymentStatus.verified,
        )
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);
    final statusSummary = store.bookingStatusSummary();
    final topRenters = _topRenters(store).take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Reports',
          subtitle:
              'Revenue, utilization, renters, and booking status analytics.',
        ),
        ResponsiveGrid(
          children: [
            StatCard(
              title: 'Daily Income',
              value: currency(store.todayRevenue),
              icon: Icons.today_rounded,
            ),
            StatCard(
              title: 'Weekly Income',
              value: currency(weeklyRevenue),
              icon: Icons.calendar_view_week_rounded,
              accent: AppColors.blue,
            ),
            StatCard(
              title: 'Monthly Income',
              value: currency(store.monthlyRevenue),
              icon: Icons.calendar_month_rounded,
              accent: AppColors.amber,
            ),
            StatCard(
              title: 'Most Rented Court',
              value: store.mostRentedCourt?.courtName ?? 'None',
              icon: Icons.sports_tennis_rounded,
              accent: AppColors.green800,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 820;
            final renters = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AdminSectionTitle(
                    title: 'Top renters',
                    icon: Icons.leaderboard_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (topRenters.isEmpty)
                    const Text('No completed rentals yet.')
                  else
                    ...topRenters.map(
                      (player) => PlayerRankingTile(player: player),
                    ),
                ],
              ),
            );
            final statuses = AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AdminSectionTitle(
                    title: 'Booking status summary',
                    icon: Icons.pie_chart_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  for (final entry in statusSummary.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          StatusBadge.booking(entry.key),
                          const Spacer(),
                          Text(
                            '${entry.value}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
            if (!wide) {
              return Column(
                children: [renters, const SizedBox(height: 12), statuses],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: renters),
                const SizedBox(width: 12),
                Expanded(child: statuses),
              ],
            );
          },
        ),
      ],
    );
  }
}

class MaintenanceSchedulingPage extends StatefulWidget {
  const MaintenanceSchedulingPage({super.key});

  @override
  State<MaintenanceSchedulingPage> createState() =>
      _MaintenanceSchedulingPageState();
}

class _MaintenanceSchedulingPageState extends State<MaintenanceSchedulingPage> {
  final _reason = TextEditingController();
  Court? _court;
  DateTime _date = DateTime(manilaNow.year, manilaNow.month, manilaNow.day + 1);
  String _startTime = '08:00:00';
  int _hours = 1;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    _court ??= store.courts.firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Maintenance Scheduling',
          subtitle: 'Block courts for maintenance or private events.',
        ),
        AppCard(
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
                        child: Text(court.courtName),
                      ),
                    )
                    .toList(),
                onChanged: (court) => setState(() => _court = court),
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
                    lastDate: store.now.add(const Duration(days: 180)),
                    initialDate: _date,
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
                onChanged: (value) =>
                    setState(() => _startTime = value ?? _startTime),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _hours,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.timer_rounded),
                ),
                items: [1, 2, 3, 4, 5, 6, 8]
                    .map(
                      (hours) => DropdownMenuItem(
                        value: hours,
                        child: Text('$hours hours'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _hours = value ?? 1),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(store),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_busy_rounded),
                label: const Text('Schedule Maintenance'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...store.maintenance.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.construction_rounded,
                  color: AppColors.amber,
                ),
                title: Text(item.court?.courtName ?? 'Court'),
                subtitle: Text(
                  '${formatDateTime(item.startDateTime)} - ${formatDateTime(item.endDateTime)}\n${item.reason}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(AppStore store) async {
    if (_court == null || _reason.text.trim().isEmpty) {
      setState(() {
        _message = 'Choose a court and add a maintenance reason.';
        _isError = true;
      });
      return;
    }
    final hour = int.tryParse(_startTime.split(':').first) ?? 8;
    final start = DateTime(_date.year, _date.month, _date.day, hour);
    final end = start.add(Duration(hours: _hours));
    setState(() => _saving = true);
    try {
      await store.scheduleMaintenance(
        court: _court!,
        start: start,
        end: end,
        reason: _reason.text,
      );
      setState(() {
        _message = 'Maintenance block scheduled.';
        _isError = false;
        _reason.clear();
      });
    } catch (error) {
      setState(() {
        _message = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class InterfaceBackgroundsPage extends StatefulWidget {
  const InterfaceBackgroundsPage({super.key});

  @override
  State<InterfaceBackgroundsPage> createState() =>
      _InterfaceBackgroundsPageState();
}

class _InterfaceBackgroundsPageState extends State<InterfaceBackgroundsPage> {
  final _title = TextEditingController();
  PlatformFile? _image;
  bool _saving = false;
  String? _workingBackgroundId;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final image = _image;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Screen Backgrounds',
          subtitle:
              'Manage the slideshow shown behind public and customer screens.',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_message != null)
                MessageBanner(message: _message!, isError: _isError),
              TextField(
                controller: _title,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Background title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (image?.bytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(image!.bytes!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      image == null ? 'Choose Image' : 'Change Image',
                    ),
                  ),
                  if (image != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        '${image.name} - ${_adminFileSizeLabel(image.size)}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: image == null || _saving
                        ? null
                        : () => _upload(store),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_saving ? 'Uploading...' : 'Upload'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (store.interfaceBackgrounds.isEmpty)
          const EmptyState(
            icon: Icons.wallpaper_outlined,
            title: 'No slideshow images yet',
            message:
                'Upload JPG or PNG images to show them on user-facing screens.',
          )
        else
          ...store.interfaceBackgrounds.map(
            (background) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InterfaceBackgroundCard(
                background: background,
                publicUrl: store.publicInterfaceBackgroundUrl(
                  background.storagePath,
                ),
                isWorking: _workingBackgroundId == background.id,
                onActiveChanged: (value) =>
                    _setActive(store, background, value),
                onDelete: () => _deleteBackground(store, background),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.size > 15 * 1024 * 1024) {
      setState(() {
        _message = 'Interface backgrounds must be 15 MB or smaller.';
        _isError = true;
      });
      return;
    }
    setState(() {
      _image = file;
      _message = null;
    });
  }

  Future<void> _upload(AppStore store) async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await store.uploadInterfaceBackground(title: _title.text, file: image);
      if (!mounted) return;
      setState(() {
        _title.clear();
        _image = null;
        _message = 'Background uploaded and added to the slideshow.';
        _isError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setActive(
    AppStore store,
    InterfaceBackground background,
    bool isActive,
  ) async {
    setState(() {
      _workingBackgroundId = background.id;
      _message = null;
    });
    try {
      await store.setInterfaceBackgroundActive(
        background: background,
        isActive: isActive,
      );
      if (!mounted) return;
      setState(() {
        _message = isActive
            ? 'Background is now visible to users.'
            : 'Background was hidden from users.';
        _isError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _workingBackgroundId = null);
    }
  }

  Future<void> _deleteBackground(
    AppStore store,
    InterfaceBackground background,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${background.title}?'),
        content: const Text(
          'This removes the image from the user screen slideshow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _workingBackgroundId = background.id;
      _message = null;
    });
    try {
      await store.deleteInterfaceBackground(background);
      if (!mounted) return;
      setState(() {
        _message = 'Background removed.';
        _isError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _workingBackgroundId = null);
    }
  }
}

class _InterfaceBackgroundCard extends StatelessWidget {
  const _InterfaceBackgroundCard({
    required this.background,
    required this.publicUrl,
    required this.isWorking,
    required this.onActiveChanged,
    required this.onDelete,
  });

  final InterfaceBackground background;
  final String publicUrl;
  final bool isWorking;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final preview = ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: compact ? double.infinity : 168,
              height: compact ? null : 96,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: publicUrl.isEmpty
                    ? const ColoredBox(color: AppColors.gray)
                    : Image.network(
                        publicUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: AppColors.gray),
                      ),
              ),
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                background.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(
                    label: background.isActive ? 'Visible' : 'Hidden',
                    color: background.isActive
                        ? AppColors.green600
                        : AppColors.gray,
                  ),
                  Text('Order ${background.displayOrder}'),
                ],
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Switch(
                value: background.isActive,
                onChanged: isWorking ? null : onActiveChanged,
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: isWorking ? null : onDelete,
                icon: isWorking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                preview,
                const SizedBox(height: 12),
                details,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }
          return Row(
            children: [
              preview,
              const SizedBox(width: 14),
              Expanded(child: details),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class ActivityLogsPage extends StatelessWidget {
  const ActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'Admin Activity Logs',
          subtitle: 'Important booking, payment, and court changes.',
        ),
        if (store.activityLogs.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No activity yet',
            message: 'Admin actions will be recorded here.',
          )
        else
          ...store.activityLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.history_rounded,
                    color: AppColors.green600,
                  ),
                  title: Text(log.action),
                  subtitle: Text(
                    '${log.details}\n${formatDateTime(log.createdAt)}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final customerBookings = store.bookings
        .where((booking) => booking.customerId == profile.id)
        .toList();
    final totalHours = customerBookings
        .where((booking) => booking.status == BookingStatus.completed)
        .fold(0, (sum, booking) => sum + booking.durationHours);
    final totalPayments = customerBookings
        .where(
          (booking) =>
              booking.isBillable &&
              booking.paymentStatus == PaymentStatus.verified,
        )
        .fold(0.0, (sum, booking) => sum + booking.totalAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(profile: profile, radius: 24, showBorder: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '@${profile.username}${profile.contactNumber == null ? '' : ' · ${profile.contactNumber}'}',
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sendNotification(context, profile),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Notify'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusBadge(
                  label: '${customerBookings.length} bookings',
                  color: AppColors.blue,
                ),
                StatusBadge(
                  label: '$totalHours rental hours',
                  color: AppColors.green600,
                ),
                StatusBadge(
                  label: currency(totalPayments),
                  color: AppColors.amber,
                ),
              ],
            ),
            if (customerBookings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent bookings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...customerBookings
                  .take(3)
                  .map(
                    (booking) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(booking.bookingReference),
                      subtitle: Text(
                        '${booking.court?.courtName ?? 'Court'} · ${formatDateLong(booking.bookingDate)}',
                      ),
                      trailing: StatusBadge.booking(booking.status),
                      onTap: () =>
                          openBookingDetails(context, booking, adminMode: true),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification(BuildContext context, Profile profile) async {
    final store = AppScope.of(context);
    final title = TextEditingController();
    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notify ${profile.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: message,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (sent == true &&
        title.text.trim().isNotEmpty &&
        message.text.trim().isNotEmpty) {
      await store.sendNotification(
        user: profile,
        title: title.text,
        message: message.text,
      );
    }
    title.dispose();
    message.dispose();
  }
}

class _ActiveRentalCompact extends StatelessWidget {
  const _ActiveRentalCompact({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.court?.courtName ?? 'Court',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${booking.customer?.fullName ?? 'Customer'} · ends ${formatTime(booking.endTime)}',
                ),
              ],
            ),
          ),
          CountdownTimer(end: booking.localEnd, now: store.now, compact: true),
        ],
      ),
    );
  }
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle({
    required this.title,
    required this.icon,
    this.action,
  });

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

String _adminFileSizeLabel(int bytes) {
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB selected';
}

List<PlayerRanking> _topRenters(AppStore store) {
  final totals = <String, ({int bookings, int hours, double amount})>{};
  for (final booking in store.bookings.where(
    (booking) => booking.status == BookingStatus.completed,
  )) {
    final current =
        totals[booking.customerId] ?? (bookings: 0, hours: 0, amount: 0);
    totals[booking.customerId] = (
      bookings: current.bookings + 1,
      hours: current.hours + booking.durationHours,
      amount: current.amount + booking.totalAmount,
    );
  }
  final profiles = {for (final profile in store.profiles) profile.id: profile};
  final rows =
      totals.entries
          .where((entry) => profiles[entry.key] != null)
          .map(
            (entry) => PlayerRanking(
              profile: profiles[entry.key]!,
              bookingCount: entry.value.bookings,
              totalHours: entry.value.hours,
              totalAmount: entry.value.amount,
            ),
          )
          .toList()
        ..sort((a, b) => b.totalHours.compareTo(a.totalHours));
  return rows;
}
