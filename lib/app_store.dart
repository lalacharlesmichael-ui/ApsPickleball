import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'utils.dart';

const _usernameAuthPrefix = 'apspicklezone+';
const _usernameAuthDomain = 'gmail.com';

class AppStore extends ChangeNotifier {
  AppStore(this.client);

  final SupabaseClient client;

  Profile? currentProfile;
  final List<Court> courts = [];
  final List<Booking> bookings = [];
  final List<Profile> profiles = [];
  final List<AppNotification> notifications = [];
  final List<CourtMaintenance> maintenance = [];
  final List<AdminActivityLog> activityLogs = [];
  final List<PlayerRanking> weeklyRankings = [];

  bool isLoading = true;
  String? errorMessage;
  DateTime now = manilaNow;
  bool _weeklyRankingsLoaded = false;

  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _realtimeChannel;
  Timer? _clock;
  Timer? _refreshTimer;

  bool get isAuthenticated => client.auth.currentUser != null;
  bool get isAdmin => currentProfile?.isAdmin ?? false;
  List<Profile> get customers =>
      profiles.where((profile) => profile.role == AppRole.customer).toList();
  List<Booking> get myBookings => bookings
      .where((booking) => booking.customerId == currentProfile?.id)
      .toList();
  int get unreadNotificationCount =>
      notifications.where((notification) => !notification.isRead).length;

  Future<void> initialize() async {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      now = manilaNow;
      notifyListeners();
    });
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(refreshBookingStatuses(quiet: true));
    });
    _authSubscription = client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession ||
          state.event == AuthChangeEvent.userUpdated) {
        unawaited(loadAll());
      }
      if (state.event == AuthChangeEvent.signedOut) {
        _clearSession();
      }
    });
    await loadAll();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _refreshTimer?.cancel();
    _authSubscription?.cancel();
    final channel = _realtimeChannel;
    if (channel != null) {
      unawaited(client.removeChannel(channel));
    }
    super.dispose();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    await client.auth.signInWithPassword(
      email: authEmailForUsername(username),
      password: password,
    );
    await loadAll();
  }

  Future<void> register({
    required String fullName,
    required String username,
    required String password,
    String? contactNumber,
  }) async {
    final normalizedUsername = normalizeUsername(username);
    final usernameAvailable = await isUsernameAvailable(normalizedUsername);
    if (!usernameAvailable) {
      throw Exception('Username is already taken.');
    }

    await client.auth.signUp(
      email: authEmailForUsername(normalizedUsername),
      password: password,
      data: {
        'username': normalizedUsername,
        'full_name': fullName.trim(),
        'contact_number': contactNumber?.trim(),
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await loadAll();
  }

  Future<bool> isUsernameAvailable(String username) async {
    final normalizedUsername = normalizeUsername(username);
    final result = await client.rpc(
      'is_username_available',
      params: {'p_username': normalizedUsername},
    );
    return result == true;
  }

  Future<void> logout() async {
    await client.auth.signOut();
    _clearSession();
  }

  Future<void> loadAll({bool quiet = false}) async {
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      _clearSession();
      return;
    }

    if (!quiet) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      await refreshBookingStatuses(quiet: true);
      final profileRow = await client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (profileRow == null) {
        throw StateError(
          'Your profile is still being prepared. Please refresh in a moment.',
        );
      }

      currentProfile = Profile.fromMap(Map<String, dynamic>.from(profileRow));

      final courtRows = rowsOf(
        await client.from('courts').select().order('court_number'),
      );
      courts
        ..clear()
        ..addAll(courtRows.map(Court.fromMap));

      if (isAdmin) {
        final profileRows = rowsOf(
          await client
              .from('profiles')
              .select()
              .order('created_at', ascending: false),
        );
        profiles
          ..clear()
          ..addAll(profileRows.map(Profile.fromMap));
      } else {
        profiles
          ..clear()
          ..add(currentProfile!);
      }

      final bookingRows = isAdmin
          ? rowsOf(
              await client
                  .from('bookings')
                  .select()
                  .order('created_at', ascending: false),
            )
          : rowsOf(
              await client
                  .from('bookings')
                  .select()
                  .eq('customer_id', currentProfile!.id)
                  .order('created_at', ascending: false),
            );

      final courtById = {for (final court in courts) court.id: court};
      final profileById = {for (final profile in profiles) profile.id: profile};
      bookings
        ..clear()
        ..addAll(
          bookingRows.map((row) {
            final booking = Booking.fromMap(row);
            return booking.attach(
              court: courtById[booking.courtId],
              customer: profileById[booking.customerId],
            );
          }),
        )
        ..sort(compareBookings);

      final notificationRows = rowsOf(
        await client
            .from('notifications')
            .select()
            .eq('user_id', currentProfile!.id)
            .order('created_at', ascending: false)
            .limit(80),
      );
      notifications
        ..clear()
        ..addAll(notificationRows.map(AppNotification.fromMap));

      final maintenanceRows = rowsOf(
        await client
            .from('court_maintenance')
            .select()
            .order('start_datetime', ascending: false)
            .limit(isAdmin ? 100 : 30),
      );
      maintenance
        ..clear()
        ..addAll(
          maintenanceRows.map((row) {
            final item = CourtMaintenance.fromMap(row);
            return CourtMaintenance.fromMap(
              row,
              court: courtById[item.courtId],
            );
          }),
        );

      if (isAdmin) {
        final logRows = rowsOf(
          await client
              .from('admin_activity_logs')
              .select()
              .order('created_at', ascending: false)
              .limit(100),
        );
        activityLogs
          ..clear()
          ..addAll(logRows.map(AdminActivityLog.fromMap));
      } else {
        activityLogs.clear();
      }

      await _loadWeeklyRankings();

      isLoading = false;
      errorMessage = null;
      notifyListeners();
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> refreshBookingStatuses({bool quiet = false}) async {
    if (client.auth.currentUser == null) return;
    try {
      await client.rpc('refresh_booking_statuses');
      if (!quiet) await loadAll(quiet: true);
    } catch (_) {
      // The schema may not be applied yet during first local setup.
    }
  }

  Future<String?> createBooking({
    required String courtId,
    required DateTime date,
    required String startTime,
    required int durationHours,
  }) async {
    final result = await client.rpc(
      'create_booking',
      params: {
        'p_court_id': courtId,
        'p_booking_date': formatDate(date),
        'p_start_time': startTime,
        'p_duration_hours': durationHours,
      },
    );
    await loadAll();
    return result?.toString();
  }

  Future<void> uploadPaymentProof({
    required Booking booking,
    required PlatformFile file,
  }) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Choose a JPG, PNG, or PDF file before uploading.');
    }
    if (file.size > 8 * 1024 * 1024) {
      throw StateError('Payment proof must be 8 MB or smaller.');
    }
    final extension = (file.extension ?? '').toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'pdf'};
    if (!allowed.contains(extension)) {
      throw StateError(
        'Allowed payment proof types are JPG, JPEG, PNG, and PDF.',
      );
    }

    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '${currentProfile!.id}/${booking.id}/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await client.storage
        .from('payment-proofs')
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: true,
          ),
        );

    await client.rpc(
      'upload_payment_proof',
      params: {'p_booking_id': booking.id, 'p_payment_proof_url': path},
    );
    await loadAll();
  }

  Future<void> updateProfile({
    required String fullName,
    String? contactNumber,
    PlatformFile? imageFile,
  }) async {
    var imagePath = currentProfile?.profileImageUrl;
    if (imageFile != null) {
      final bytes = imageFile.bytes;
      final extension = (imageFile.extension ?? '').toLowerCase();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Choose an image before uploading.');
      }
      if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
        throw StateError('Profile photos must be JPG or PNG.');
      }
      if (imageFile.size > 5 * 1024 * 1024) {
        throw StateError('Profile photos must be 5 MB or smaller.');
      }
      final safeName = imageFile.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      imagePath =
          '${currentProfile!.id}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await client.storage
          .from('profile-images')
          .uploadBinary(
            imagePath,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: _contentType(extension),
              upsert: true,
            ),
          );
    }

    await client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'contact_number': contactNumber?.trim(),
          'profile_image_url': imagePath,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', currentProfile!.id);
    await loadAll();
  }

  Future<String?> signedPaymentProofUrl(Booking booking) async {
    final path = booking.paymentProofUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return client.storage.from('payment-proofs').createSignedUrl(path, 600);
  }

  Future<String?> signedProfileImageUrl(Profile profile) async {
    final path = profile.profileImageUrl;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return client.storage.from('profile-images').createSignedUrl(path, 600);
  }

  Future<void> markNotificationRead(AppNotification notification) async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notification.id)
        .eq('user_id', currentProfile!.id);
    await loadAll(quiet: true);
  }

  Future<void> markAllNotificationsRead() async {
    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', currentProfile!.id)
        .eq('is_read', false);
    await loadAll(quiet: true);
  }

  Future<void> approveBooking(Booking booking) async {
    await client.rpc('approve_booking', params: {'p_booking_id': booking.id});
    await loadAll();
  }

  Future<void> declineBooking(Booking booking, String note) async {
    await client.rpc(
      'decline_booking',
      params: {'p_booking_id': booking.id, 'p_admin_note': note.trim()},
    );
    await loadAll();
  }

  Future<void> cancelBooking(Booking booking, String note) async {
    await client.rpc(
      'cancel_booking',
      params: {'p_booking_id': booking.id, 'p_admin_note': note.trim()},
    );
    await loadAll();
  }

  Future<void> completeBooking(Booking booking) async {
    await client.rpc('complete_booking', params: {'p_booking_id': booking.id});
    await loadAll();
  }

  Future<void> updateCourtStatus({
    required Court court,
    required CourtStatus status,
    String? note,
  }) async {
    await client.rpc(
      'set_court_status',
      params: {
        'p_court_id': court.id,
        'p_status': status.name,
        'p_note': note?.trim(),
      },
    );
    await loadAll();
  }

  Future<void> scheduleMaintenance({
    required Court court,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) async {
    await client.rpc(
      'schedule_court_maintenance',
      params: {
        'p_court_id': court.id,
        'p_start_datetime': start.toUtc().toIso8601String(),
        'p_end_datetime': end.toUtc().toIso8601String(),
        'p_reason': reason.trim(),
      },
    );
    await loadAll();
  }

  Future<void> sendNotification({
    required Profile user,
    required String title,
    required String message,
  }) async {
    await client.from('notifications').insert({
      'user_id': user.id,
      'title': title.trim(),
      'message': message.trim(),
      'type': 'admin_message',
    });
    await loadAll(quiet: true);
  }

  bool isSlotAvailable({
    required Court court,
    required DateTime date,
    required String startTime,
    required int durationHours,
  }) {
    if (!court.isAvailable) return false;
    if (durationHours < 1 || durationHours > defaultMaxRentalHours) {
      return false;
    }
    final startHour = int.tryParse(startTime.split(':').first) ?? 0;
    if (startHour + durationHours > 22) return false;
    final start = DateTime(date.year, date.month, date.day, startHour);
    final end = start.add(Duration(hours: durationHours));
    if (!start.isAfter(now)) return false;

    final blocks = bookings.where(
      (booking) =>
          booking.courtId == court.id &&
          isSameDate(booking.bookingDate, date) &&
          {
            BookingStatus.pending,
            BookingStatus.approved,
            BookingStatus.active,
          }.contains(booking.status),
    );
    for (final booking in blocks) {
      if (booking.localStart.isBefore(end) &&
          start.isBefore(booking.localEnd)) {
        return false;
      }
    }

    for (final item in maintenance.where((item) => item.courtId == court.id)) {
      if (item.startDateTime.isBefore(end) &&
          start.isBefore(item.endDateTime)) {
        return false;
      }
    }
    return true;
  }

  Booking? bookingForSlot(Court court, DateTime date, int hour) {
    final slotStart = DateTime(date.year, date.month, date.day, hour);
    final slotEnd = slotStart.add(const Duration(hours: 1));
    return bookings.where((booking) {
      if (booking.courtId != court.id ||
          !isSameDate(booking.bookingDate, date)) {
        return false;
      }
      if (!{
        BookingStatus.pending,
        BookingStatus.approved,
        BookingStatus.active,
      }.contains(booking.status)) {
        return false;
      }
      return booking.localStart.isBefore(slotEnd) &&
          slotStart.isBefore(booking.localEnd);
    }).firstOrNull;
  }

  bool maintenanceForSlot(Court court, DateTime date, int hour) {
    final slotStart = DateTime(date.year, date.month, date.day, hour);
    final slotEnd = slotStart.add(const Duration(hours: 1));
    return maintenance.any(
      (item) =>
          item.courtId == court.id &&
          item.startDateTime.isBefore(slotEnd) &&
          slotStart.isBefore(item.endDateTime),
    );
  }

  List<int> allowedDurations(String startTime) {
    final startHour = int.tryParse(startTime.split(':').first) ?? 6;
    final maxByClosing = 22 - startHour;
    final max = maxByClosing.clamp(1, defaultMaxRentalHours);
    return [for (var value = 1; value <= max; value++) value];
  }

  List<PlayerRanking> playerOfWeek() {
    if (_weeklyRankingsLoaded) {
      return List.unmodifiable(weeklyRankings);
    }

    final start = weekStart(now);
    final totals = <String, ({int bookings, int hours, double amount})>{};
    for (final booking in bookings) {
      if (booking.status != BookingStatus.completed ||
          booking.localStart.isBefore(start)) {
        continue;
      }
      final current =
          totals[booking.customerId] ?? (bookings: 0, hours: 0, amount: 0);
      totals[booking.customerId] = (
        bookings: current.bookings + 1,
        hours: current.hours + booking.durationHours,
        amount: current.amount + booking.totalAmount,
      );
    }
    final profileById = {for (final profile in profiles) profile.id: profile};
    final rows =
        totals.entries
            .where((entry) => profileById[entry.key] != null)
            .map(
              (entry) => PlayerRanking(
                profile: profileById[entry.key]!,
                bookingCount: entry.value.bookings,
                totalHours: entry.value.hours,
                totalAmount: entry.value.amount,
              ),
            )
            .toList()
          ..sort((a, b) {
            final hours = b.totalHours.compareTo(a.totalHours);
            if (hours != 0) return hours;
            return b.totalAmount.compareTo(a.totalAmount);
          });
    return rows;
  }

  int get totalCustomers => customers.length;
  int get pendingBookings => bookings
      .where((booking) => booking.status == BookingStatus.pending)
      .length;
  int get activeRentals => bookings
      .where((booking) => booking.status == BookingStatus.active)
      .length;
  int get availableCourtCount =>
      courts.where((court) => court.status == CourtStatus.available).length;
  double get totalIncome => bookings
      .where(
        (booking) =>
            booking.isBillable &&
            booking.paymentStatus == PaymentStatus.verified,
      )
      .fold(0, (sum, booking) => sum + booking.totalAmount);
  double get todayRevenue => bookings
      .where(
        (booking) =>
            isSameDate(booking.bookingDate, now) &&
            booking.isBillable &&
            booking.paymentStatus == PaymentStatus.verified,
      )
      .fold(0, (sum, booking) => sum + booking.totalAmount);
  double get monthlyRevenue => bookings
      .where(
        (booking) =>
            booking.bookingDate.year == now.year &&
            booking.bookingDate.month == now.month &&
            booking.isBillable &&
            booking.paymentStatus == PaymentStatus.verified,
      )
      .fold(0, (sum, booking) => sum + booking.totalAmount);

  Court? get mostRentedCourt {
    final counts = <String, int>{};
    for (final booking in bookings.where(
      (booking) => booking.status == BookingStatus.completed,
    )) {
      counts[booking.courtId] =
          (counts[booking.courtId] ?? 0) + booking.durationHours;
    }
    if (counts.isEmpty) return null;
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return courts.where((court) => court.id == top.key).firstOrNull;
  }

  List<Booking> get activeBookings =>
      bookings
          .where((booking) => booking.status == BookingStatus.active)
          .toList()
        ..sort((a, b) => a.localEnd.compareTo(b.localEnd));

  List<Booking> get upcomingBookings =>
      myBookings
          .where(
            (booking) =>
                booking.localStart.isAfter(now) &&
                {
                  BookingStatus.pending,
                  BookingStatus.approved,
                }.contains(booking.status),
          )
          .toList()
        ..sort((a, b) => a.localStart.compareTo(b.localStart));

  Booking? get currentActiveBooking => myBookings
      .where((booking) => booking.status == BookingStatus.active)
      .firstOrNull;

  Map<BookingStatus, int> bookingStatusSummary([Iterable<Booking>? source]) {
    final summary = {for (final status in BookingStatus.values) status: 0};
    for (final booking in source ?? bookings) {
      summary[booking.status] = (summary[booking.status] ?? 0) + 1;
    }
    return summary;
  }

  void _subscribeRealtime() {
    final previous = _realtimeChannel;
    if (previous != null) {
      unawaited(client.removeChannel(previous));
    }
    _realtimeChannel = client
        .channel('greencourt-public')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => unawaited(loadAll(quiet: true)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) => unawaited(loadAll(quiet: true)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'courts',
          callback: (_) => unawaited(loadAll(quiet: true)),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'court_maintenance',
          callback: (_) => unawaited(loadAll(quiet: true)),
        )
        .subscribe();
  }

  void _clearSession() {
    currentProfile = null;
    courts.clear();
    bookings.clear();
    profiles.clear();
    notifications.clear();
    maintenance.clear();
    activityLogs.clear();
    weeklyRankings.clear();
    _weeklyRankingsLoaded = false;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _loadWeeklyRankings() async {
    try {
      final rankingRows = rowsOf(await client.rpc('player_of_week'));
      weeklyRankings
        ..clear()
        ..addAll(rankingRows.map(PlayerRanking.fromMap));
      _weeklyRankingsLoaded = true;
    } catch (_) {
      weeklyRankings.clear();
      _weeklyRankingsLoaded = false;
    }
  }
}

List<Map<String, dynamic>> rowsOf(Object? response) {
  final rows = response as List<dynamic>? ?? const [];
  return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
}

String normalizeUsername(String value) {
  return value.trim().toLowerCase();
}

String authEmailForUsername(String username) {
  final normalized = normalizeUsername(username);
  if (normalized.contains('@')) return normalized;
  return '$_usernameAuthPrefix$normalized@$_usernameAuthDomain';
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
