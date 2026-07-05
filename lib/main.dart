import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_scope.dart';
import 'app_store.dart';
import 'models.dart';
import 'screens_admin.dart';
import 'screens_customer.dart';
import 'screens_public.dart';
import 'theme.dart';
import 'widgets.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const appName = 'Aps Pickle Zone';
const _supabaseConfigAsset = 'assets/config/supabase.json';
const _darkModeStorageKey = 'aps_pickle_zone_dark_mode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await SupabaseConfig.load();

  if (!config.isConfigured) {
    runApp(
      const StartupErrorApp(
        message:
            'Supabase is not configured. Add your Project URL and anon key in assets/config/supabase.json, or start the app with SUPABASE_URL and SUPABASE_ANON_KEY dart defines.',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
    final store = AppStore(Supabase.instance.client);
    await store.initialize();
    runApp(AppScope(store: store, child: const ApsPickleZoneApp()));
  } catch (error) {
    runApp(StartupErrorApp(message: 'Could not connect to Supabase: $error'));
  }
}

class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  bool get isConfigured =>
      _looksLikeUrl(url) &&
      anonKey.isNotEmpty &&
      !anonKey.contains('YOUR_') &&
      !url.contains('YOUR_PROJECT');

  static Future<SupabaseConfig> load() async {
    final assetConfig = await _loadAssetConfig();
    return SupabaseConfig(
      url: supabaseUrl.isNotEmpty ? supabaseUrl : assetConfig.url,
      anonKey: supabaseAnonKey.isNotEmpty
          ? supabaseAnonKey
          : assetConfig.anonKey,
    );
  }

  static Future<SupabaseConfig> _loadAssetConfig() async {
    try {
      final raw = await rootBundle.loadString(_supabaseConfigAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SupabaseConfig(
        url: _stringValue(json['SUPABASE_URL'] ?? json['supabaseUrl']),
        anonKey: _stringValue(
          json['SUPABASE_ANON_KEY'] ?? json['supabaseAnonKey'],
        ),
      );
    } catch (_) {
      return const SupabaseConfig(url: '', anonKey: '');
    }
  }

  static bool _looksLikeUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  static String _stringValue(Object? value) => value?.toString().trim() ?? '';
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 18),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ApsPickleZoneApp extends StatefulWidget {
  const ApsPickleZoneApp({super.key});

  @override
  State<ApsPickleZoneApp> createState() => _ApsPickleZoneAppState();
}

class _ApsPickleZoneAppState extends State<ApsPickleZoneApp> {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadThemeMode());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: GateScreen(isDarkMode: _darkMode, onDarkModeChanged: _setDarkMode),
    );
  }

  Future<void> _loadThemeMode() async {
    try {
      final savedDarkMode = await _preferences.getBool(_darkModeStorageKey);
      if (!mounted || savedDarkMode == null) return;
      setState(() => _darkMode = savedDarkMode);
    } catch (_) {
      // Theme choice is a comfort preference; keep the default if storage fails.
    }
  }

  void _setDarkMode(bool value) {
    setState(() => _darkMode = value);
    unawaited(_saveThemeMode(value));
  }

  Future<void> _saveThemeMode(bool value) async {
    try {
      await _preferences.setBool(_darkModeStorageKey, value);
    } catch (_) {
      // The toggle should still work for the current session if storage fails.
    }
  }
}

class GateScreen extends StatelessWidget {
  const GateScreen({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (store.isLoading) {
      return const _LoadingScreen();
    }
    if (!store.isAuthenticated || store.currentProfile == null) {
      return PublicShell(
        errorMessage: store.errorMessage,
        isDarkMode: isDarkMode,
        onDarkModeChanged: onDarkModeChanged,
      );
    }
    return store.currentProfile!.role == AppRole.admin
        ? AdminShell(
            isDarkMode: isDarkMode,
            onDarkModeChanged: onDarkModeChanged,
          )
        : CustomerShell(
            isDarkMode: isDarkMode,
            onDarkModeChanged: onDarkModeChanged,
          );
  }
}

class PublicShell extends StatefulWidget {
  const PublicShell({
    super.key,
    this.errorMessage,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final String? errorMessage;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<PublicShell> createState() => _PublicShellState();
}

class _PublicShellState extends State<PublicShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        page: LandingPage(
          onBookPressed: () => setState(() => _selected = 3),
          onRatesPressed: () => setState(() => _selected = 2),
        ),
      ),
      const _NavItem(
        label: 'About',
        icon: Icons.info_outline_rounded,
        page: AboutPage(),
      ),
      const _NavItem(
        label: 'Rates',
        icon: Icons.payments_outlined,
        page: RatesPage(),
      ),
      _NavItem(
        label: 'Login',
        icon: Icons.login_rounded,
        page: LoginPage(onRegisterPressed: () => setState(() => _selected = 4)),
      ),
      _NavItem(
        label: 'Register',
        icon: Icons.person_add_alt_1_rounded,
        page: RegisterPage(onLoginPressed: () => setState(() => _selected = 3)),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Scaffold(
          appBar: AppBar(
            title: const BrandMark(),
            actions: [
              _ThemeModeButton(
                isDarkMode: widget.isDarkMode,
                onChanged: widget.onDarkModeChanged,
              ),
              if (!compact) ...[
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selected = i),
                      icon: Icon(items[i].icon, size: 18),
                      label: Text(items[i].label),
                    ),
                  ),
              ],
              const SizedBox(width: 8),
            ],
          ),
          drawer: compact
              ? Drawer(
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: BrandMark(),
                        ),
                        for (var i = 0; i < items.length; i++)
                          ListTile(
                            selected: _selected == i,
                            leading: Icon(items[i].icon),
                            title: Text(items[i].label),
                            onTap: () {
                              setState(() => _selected = i);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  ),
                )
              : null,
          body: Column(
            children: [
              if (widget.errorMessage != null)
                MaterialBanner(
                  content: Text(widget.errorMessage!),
                  leading: const Icon(Icons.info_outline_rounded),
                  actions: [
                    TextButton(
                      onPressed: () => AppScope.of(context).loadAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: items[_selected].page,
                  ),
                ),
              ),
              const _MadeByFooter(),
            ],
          ),
        );
      },
    );
  }
}

class _MadeByFooter extends StatelessWidget {
  const _MadeByFooter();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Text(
          'Made by Charles Michael',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: CustomerDashboard(
          onBookPressed: () => setState(() => _selected = 1),
          onBookingsPressed: () => setState(() => _selected = 3),
          onNotificationsPressed: () => setState(() => _selected = 4),
        ),
      ),
      const _NavItem(
        label: 'Book',
        icon: Icons.add_circle_outline_rounded,
        page: BookCourtPage(),
      ),
      const _NavItem(
        label: 'Schedule',
        icon: Icons.calendar_month_outlined,
        page: CourtAvailabilityPage(),
      ),
      const _NavItem(
        label: 'Bookings',
        icon: Icons.receipt_long_outlined,
        page: MyBookingsPage(),
      ),
      const _NavItem(
        label: 'Notifications',
        icon: Icons.notifications_none_rounded,
        page: NotificationsPage(),
      ),
      const _NavItem(
        label: 'Leaderboard',
        icon: Icons.emoji_events_outlined,
        page: PlayerLeaderboardPage(),
      ),
      const _NavItem(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        page: ProfilePage(),
      ),
    ];
    return _AuthenticatedShell(
      items: items,
      selected: _selected,
      onSelected: (value) => setState(() => _selected = value),
      isDarkMode: widget.isDarkMode,
      onDarkModeChanged: widget.onDarkModeChanged,
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: AdminDashboard(
          onBookingsPressed: () => setState(() => _selected = 1),
        ),
      ),
      const _NavItem(
        label: 'Bookings',
        icon: Icons.fact_check_outlined,
        page: BookingManagementPage(),
      ),
      const _NavItem(
        label: 'Customers',
        icon: Icons.group_outlined,
        page: CustomerManagementPage(),
      ),
      const _NavItem(
        label: 'Courts',
        icon: Icons.sports_tennis_rounded,
        page: CourtManagementPage(),
      ),
      const _NavItem(
        label: 'Active',
        icon: Icons.timer_outlined,
        page: ActiveRentalsPage(),
      ),
      const _NavItem(
        label: 'Leaderboard',
        icon: Icons.emoji_events_outlined,
        page: PlayerLeaderboardPage(),
      ),
      const _NavItem(
        label: 'Reports',
        icon: Icons.bar_chart_rounded,
        page: ReportsPage(),
      ),
      const _NavItem(
        label: 'Maintenance',
        icon: Icons.construction_rounded,
        page: MaintenanceSchedulingPage(),
      ),
      const _NavItem(
        label: 'Logs',
        icon: Icons.history_rounded,
        page: ActivityLogsPage(),
      ),
    ];
    return _AuthenticatedShell(
      items: items,
      selected: _selected,
      onSelected: (value) => setState(() => _selected = value),
      isDarkMode: widget.isDarkMode,
      onDarkModeChanged: widget.onDarkModeChanged,
    );
  }
}

class _AuthenticatedShell extends StatelessWidget {
  const _AuthenticatedShell({
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        return Scaffold(
          appBar: AppBar(
            title: const BrandMark(),
            actions: [
              _ThemeModeButton(
                isDarkMode: isDarkMode,
                onChanged: onDarkModeChanged,
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () {
                      final index = items.indexWhere(
                        (item) => item.label == 'Notifications',
                      );
                      if (index >= 0) onSelected(index);
                    },
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  if (store.unreadNotificationCount > 0)
                    Positioned(
                      right: 7,
                      top: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => store.loadAll(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: store.logout,
                icon: const Icon(Icons.logout_rounded),
              ),
              const SizedBox(width: 6),
            ],
          ),
          drawer: compact
              ? _AppDrawer(
                  items: items,
                  selected: selected,
                  onSelected: onSelected,
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: onSelected,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 92,
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                  ],
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: items[selected].page,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(padding: EdgeInsets.all(12), child: BrandMark()),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                store.currentProfile?.fullName ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (var i = 0; i < items.length; i++)
              ListTile(
                selected: selected == i,
                leading: Icon(items[i].icon),
                title: Text(items[i].label),
                onTap: () {
                  onSelected(i);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({required this.isDarkMode, required this.onChanged});

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => onChanged(!isDarkMode),
      icon: Icon(
        isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.page});

  final String label;
  final IconData icon;
  final Widget page;
}
