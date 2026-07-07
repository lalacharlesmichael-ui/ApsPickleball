enum AppRole { admin, customer }

enum CourtStatus { available, maintenance, inactive }

enum BookingStatus { pending, approved, declined, active, completed, cancelled }

enum PaymentStatus { pending, verified, rejected }

AppRole roleFromText(Object? value) {
  return value == 'admin' ? AppRole.admin : AppRole.customer;
}

CourtStatus courtStatusFromText(Object? value) {
  return CourtStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => CourtStatus.available,
  );
}

BookingStatus bookingStatusFromText(Object? value) {
  return BookingStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => BookingStatus.pending,
  );
}

PaymentStatus paymentStatusFromText(Object? value) {
  return PaymentStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => PaymentStatus.pending,
  );
}

DateTime parseDateOnly(Object? value) {
  final parsed = value is DateTime
      ? value
      : DateTime.parse(value?.toString() ?? DateTime.now().toIso8601String());
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime parseDateTime(Object? value) {
  if (value == null) return DateTime.now();
  return DateTime.parse(value.toString()).toLocal();
}

int intFrom(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double doubleFrom(Object? value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.contactNumber,
    this.profileImageUrl,
  });

  final String id;
  final String fullName;
  final String username;
  final String? contactNumber;
  final AppRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == AppRole.admin;

  factory Profile.fromMap(Map<String, dynamic> row) {
    return Profile(
      id: row['id'].toString(),
      fullName: row['full_name']?.toString() ?? '',
      username: _usernameFromRow(row),
      contactNumber: row['contact_number']?.toString(),
      role: roleFromText(row['role']),
      profileImageUrl: row['profile_image_url']?.toString(),
      createdAt: parseDateTime(row['created_at']),
      updatedAt: parseDateTime(row['updated_at']),
    );
  }

  Map<String, dynamic> toProfileUpdate() {
    return {
      'full_name': fullName,
      'contact_number': contactNumber,
      'profile_image_url': profileImageUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? username,
    String? contactNumber,
    AppRole? role,
    String? profileImageUrl,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      contactNumber: contactNumber ?? this.contactNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

String _usernameFromRow(Map<String, dynamic> row) {
  final username = row['username']?.toString();
  if (username != null && username.isNotEmpty) return username;
  return row['id']?.toString() ?? '';
}

class Court {
  const Court({
    required this.id,
    required this.courtName,
    required this.courtNumber,
    required this.hourlyRate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.maintenanceNote,
  });

  final String id;
  final String courtName;
  final int courtNumber;
  final double hourlyRate;
  final CourtStatus status;
  final String? maintenanceNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable => status == CourtStatus.available;

  factory Court.fromMap(Map<String, dynamic> row) {
    return Court(
      id: row['id'].toString(),
      courtName: row['court_name']?.toString() ?? '',
      courtNumber: intFrom(row['court_number']),
      hourlyRate: doubleFrom(row['hourly_rate'], 250),
      status: courtStatusFromText(row['status']),
      maintenanceNote: row['maintenance_note']?.toString(),
      createdAt: parseDateTime(row['created_at']),
      updatedAt: parseDateTime(row['updated_at']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Court && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Booking {
  const Booking({
    required this.id,
    required this.bookingReference,
    required this.customerId,
    required this.courtId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.hourlyRate,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.paymentProofUrl,
    this.adminNote,
    this.approvedBy,
    this.approvedAt,
    this.court,
    this.customer,
  });

  final String id;
  final String bookingReference;
  final String customerId;
  final String courtId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final int durationHours;
  final double hourlyRate;
  final double totalAmount;
  final BookingStatus status;
  final String? paymentProofUrl;
  final PaymentStatus paymentStatus;
  final String? adminNote;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Court? court;
  final Profile? customer;

  DateTime get localStart {
    final parts = startTime
        .split(':')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    return DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      parts.isNotEmpty ? parts[0] : 0,
      parts.length > 1 ? parts[1] : 0,
    );
  }

  DateTime get localEnd {
    final parts = endTime
        .split(':')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    var value = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      parts.isNotEmpty ? parts[0] : 0,
      parts.length > 1 ? parts[1] : 0,
    );
    if (!value.isAfter(localStart)) {
      value = value.add(const Duration(days: 1));
    }
    return value;
  }

  bool get canUploadProof =>
      status == BookingStatus.pending &&
      paymentStatus != PaymentStatus.verified;

  bool get isBillable =>
      status == BookingStatus.approved ||
      status == BookingStatus.active ||
      status == BookingStatus.completed;

  factory Booking.fromMap(
    Map<String, dynamic> row, {
    Court? court,
    Profile? customer,
  }) {
    return Booking(
      id: row['id'].toString(),
      bookingReference: row['booking_reference']?.toString() ?? '',
      customerId: row['customer_id'].toString(),
      courtId: row['court_id'].toString(),
      bookingDate: parseDateOnly(row['booking_date']),
      startTime: row['start_time']?.toString() ?? '00:00:00',
      endTime: row['end_time']?.toString() ?? '00:00:00',
      durationHours: intFrom(row['duration_hours'], 1),
      hourlyRate: doubleFrom(row['hourly_rate'], 250),
      totalAmount: doubleFrom(row['total_amount']),
      status: bookingStatusFromText(row['status']),
      paymentProofUrl: row['payment_proof_url']?.toString(),
      paymentStatus: paymentStatusFromText(row['payment_status']),
      adminNote: row['admin_note']?.toString(),
      approvedBy: row['approved_by']?.toString(),
      approvedAt: row['approved_at'] == null
          ? null
          : parseDateTime(row['approved_at']),
      createdAt: parseDateTime(row['created_at']),
      updatedAt: parseDateTime(row['updated_at']),
      court: court,
      customer: customer,
    );
  }

  Booking attach({Court? court, Profile? customer}) {
    return Booking(
      id: id,
      bookingReference: bookingReference,
      customerId: customerId,
      courtId: courtId,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      durationHours: durationHours,
      hourlyRate: hourlyRate,
      totalAmount: totalAmount,
      status: status,
      paymentProofUrl: paymentProofUrl,
      paymentStatus: paymentStatus,
      adminNote: adminNote,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      court: court ?? this.court,
      customer: customer ?? this.customer,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedBookingId,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? relatedBookingId;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'].toString(),
      userId: row['user_id'].toString(),
      title: row['title']?.toString() ?? '',
      message: row['message']?.toString() ?? '',
      type: row['type']?.toString() ?? 'booking_reminder',
      isRead: row['is_read'] == true,
      relatedBookingId: row['related_booking_id']?.toString(),
      createdAt: parseDateTime(row['created_at']),
    );
  }
}

class CourtMaintenance {
  const CourtMaintenance({
    required this.id,
    required this.courtId,
    required this.startDateTime,
    required this.endDateTime,
    required this.reason,
    required this.createdAt,
    this.createdBy,
    this.court,
  });

  final String id;
  final String courtId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String reason;
  final String? createdBy;
  final DateTime createdAt;
  final Court? court;

  factory CourtMaintenance.fromMap(Map<String, dynamic> row, {Court? court}) {
    return CourtMaintenance(
      id: row['id'].toString(),
      courtId: row['court_id'].toString(),
      startDateTime: parseDateTime(row['start_datetime']),
      endDateTime: parseDateTime(row['end_datetime']),
      reason: row['reason']?.toString() ?? '',
      createdBy: row['created_by']?.toString(),
      createdAt: parseDateTime(row['created_at']),
      court: court,
    );
  }
}

class AdminActivityLog {
  const AdminActivityLog({
    required this.id,
    required this.action,
    required this.details,
    required this.createdAt,
    this.adminId,
    this.relatedBookingId,
  });

  final String id;
  final String? adminId;
  final String action;
  final String details;
  final String? relatedBookingId;
  final DateTime createdAt;

  factory AdminActivityLog.fromMap(Map<String, dynamic> row) {
    return AdminActivityLog(
      id: row['id'].toString(),
      adminId: row['admin_id']?.toString(),
      action: row['action']?.toString() ?? '',
      details: row['details']?.toString() ?? '',
      relatedBookingId: row['related_booking_id']?.toString(),
      createdAt: parseDateTime(row['created_at']),
    );
  }
}

class PlayerRanking {
  const PlayerRanking({
    required this.profile,
    required this.bookingCount,
    required this.totalHours,
    required this.totalAmount,
  });

  final Profile profile;
  final int bookingCount;
  final int totalHours;
  final double totalAmount;

  factory PlayerRanking.fromMap(Map<String, dynamic> row) {
    final now = DateTime.now();
    return PlayerRanking(
      profile: Profile(
        id: row['customer_id'].toString(),
        fullName: row['full_name']?.toString() ?? 'Player',
        username: row['username']?.toString() ?? '',
        role: AppRole.customer,
        createdAt: now,
        updatedAt: now,
      ),
      bookingCount: intFrom(row['booking_count']),
      totalHours: intFrom(row['total_hours']),
      totalAmount: doubleFrom(row['total_amount']),
    );
  }
}

class DailyActivity {
  const DailyActivity({
    required this.date,
    required this.bookingCount,
    required this.hours,
  });

  final DateTime date;
  final int bookingCount;
  final int hours;

  bool get hasActivity => bookingCount > 0 || hours > 0;
}

class PersonalProgress {
  const PersonalProgress({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalHours,
    required this.weeklyHours,
    required this.monthlyHours,
    required this.monthlyGoalHours,
    required this.activeDaysThisMonth,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.upcomingSessions,
    required this.pendingSessions,
    required this.verifiedSpend,
    required this.completionRate,
    required this.productivityScore,
    required this.monthlyActivity,
    this.favoriteCourtName,
  });

  final int totalSessions;
  final int completedSessions;
  final int totalHours;
  final int weeklyHours;
  final int monthlyHours;
  final int monthlyGoalHours;
  final int activeDaysThisMonth;
  final int currentStreakDays;
  final int bestStreakDays;
  final int upcomingSessions;
  final int pendingSessions;
  final double verifiedSpend;
  final double completionRate;
  final int productivityScore;
  final List<DailyActivity> monthlyActivity;
  final String? favoriteCourtName;

  double get monthlyGoalProgress {
    if (monthlyGoalHours <= 0) return 0;
    return (monthlyHours / monthlyGoalHours).clamp(0.0, 1.0).toDouble();
  }
}
