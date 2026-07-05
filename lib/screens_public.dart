import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'theme.dart';
import 'utils.dart';
import 'widgets.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({
    super.key,
    required this.onBookPressed,
    required this.onRatesPressed,
  });

  final VoidCallback onBookPressed;
  final VoidCallback onRatesPressed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 780;
            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Image.asset(appLogoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aps pickle zone',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(color: AppColors.green900),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pickleball Court Rental Management System',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.green700,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reserve a court, upload payment proof, and follow your rental time from one clean dashboard.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: onBookPressed,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Book a Court'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onRatesPressed,
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('Court Rates'),
                    ),
                  ],
                ),
              ],
            );

            final visual = const CourtVisual(height: 280);
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [text, const SizedBox(height: 22), visual],
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 460),
              child: Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 28),
                  const Expanded(child: CourtVisual(height: 340)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          children: const [
            StatCard(
              title: 'Courts',
              value: '3',
              icon: Icons.sports_tennis_rounded,
            ),
            StatCard(
              title: 'Rate',
              value: '₱250/hr',
              icon: Icons.sell_rounded,
              accent: AppColors.amber,
            ),
            StatCard(
              title: 'Timezone',
              value: 'Manila',
              icon: Icons.schedule_rounded,
              accent: AppColors.blue,
            ),
          ],
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeader(
          title: 'About Aps pickle zone',
          subtitle:
              'A modern booking desk for pickleball players and court administrators.',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Built for simple court operations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Aps pickle zone keeps reservations, payment verification, court maintenance, active rental timers, notifications, receipts, and reporting in one Supabase-backed system.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              const CourtVisual(height: 190),
            ],
          ),
        ),
      ],
    );
  }
}

class RatesPage extends StatelessWidget {
  const RatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageHeader(
          title: 'Court Rates',
          subtitle:
              'Every pickleball court rents at ${currency(defaultHourlyRate)} per hour.',
        ),
        ResponsiveGrid(
          children: [
            for (var court = 1; court <= 3; court++)
              StatCard(
                title: 'Court $court',
                value: currency(defaultHourlyRate),
                icon: Icons.sports_tennis_rounded,
              ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rental totals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RateRow(hours: 1, amount: defaultHourlyRate),
              _RateRow(hours: 2, amount: defaultHourlyRate * 2),
              _RateRow(hours: 3, amount: defaultHourlyRate * 3),
              _RateRow(hours: 4, amount: defaultHourlyRate * 4),
            ],
          ),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onRegisterPressed});

  final VoidCallback onRegisterPressed;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPanel(
      title: 'Login',
      subtitle: 'Open your Aps pickle zone dashboard.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message != null)
              MessageBanner(message: _message!, isError: _isError),
            TextFormField(
              controller: _username,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: _validateUsername,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Password must be at least 6 characters.'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: const Text('Login'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onRegisterPressed,
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await AppScope.of(
        context,
      ).login(username: _username.text, password: _password.text);
    } catch (error) {
      setState(() {
        _message = _friendlyLoginError(error);
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

String _friendlyLoginError(Object error) {
  final text = error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('failed to fetch') ||
      lower.contains('authretryablefetchexception') ||
      lower.contains('clientexception')) {
    return 'Could not reach Supabase Auth. Check your internet connection, Supabase project status, Project URL, and anon/publishable key, then restart the app.';
  }
  if (text.contains('invalid_credentials') ||
      lower.contains('invalid login credentials')) {
    return 'No account was found for that username and password. Create the account first, then promote it to admin in Supabase if it is not the first registered user.';
  }
  if (lower.contains('email not confirmed')) {
    return 'This username is waiting for account confirmation. Disable email confirmation in Supabase Auth for username-only login, or confirm the generated auth user in Supabase.';
  }
  return text;
}

String? _validateUsername(String? value) {
  final username = value?.trim().toLowerCase() ?? '';
  final valid = RegExp(r'^[a-z0-9._-]{3,32}$').hasMatch(username);
  return valid
      ? null
      : 'Use 3-32 lowercase letters, numbers, dots, dashes, or underscores.';
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onLoginPressed});

  final VoidCallback onLoginPressed;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthPanel(
      title: 'Registration',
      subtitle: 'Create a secure player profile.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message != null)
              MessageBanner(message: _message!, isError: _isError),
            TextFormField(
              controller: _fullName,
              textCapitalization: TextCapitalization.words,
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
              controller: _username,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: _validateUsername,
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
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Password must be at least 6 characters.'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Create Account'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onLoginPressed,
              child: const Text('I already have an account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await AppScope.of(context).register(
        fullName: _fullName.text,
        username: _username.text,
        contactNumber: _contact.text,
        password: _password.text,
      );
      if (!mounted) return;
      setState(() {
        _message =
            'Registration successful. You can now use your Aps pickle zone dashboard.';
        _isError = false;
      });
    } catch (error) {
      setState(() {
        _message = _friendlyRegistrationError(error);
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

String _friendlyRegistrationError(Object error) {
  final text = error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('username is already taken') ||
      lower.contains('duplicate key') ||
      lower.contains('already registered')) {
    return 'That username is already taken. Choose another username.';
  }
  if (lower.contains('database error saving new user') ||
      lower.contains('unexpected_failure')) {
    return 'Supabase could not create the profile. Run supabase/username_only_profiles_patch.sql in the Supabase SQL Editor, then try registering again.';
  }
  if (lower.contains('function public.is_username_available') ||
      lower.contains('is_username_available')) {
    return 'The username SQL patch has not been applied yet. Run supabase/username_only_profiles_patch.sql in Supabase, then restart the app.';
  }
  return text;
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          Center(
            child: BrandMark(compact: MediaQuery.sizeOf(context).width < 420),
          ),
          const SizedBox(height: 18),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.hours, required this.amount});

  final int hours;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: AppColors.green600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$hours hour${hours == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            currency(amount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
