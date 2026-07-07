import 'package:flutter_test/flutter_test.dart';
import 'package:aps_pickle_zone/main.dart';

void main() {
  testWidgets('shows a useful Supabase configuration error', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(message: 'Supabase is not configured.'),
    );

    expect(find.text('Supabase is not configured.'), findsOneWidget);
  });
}
