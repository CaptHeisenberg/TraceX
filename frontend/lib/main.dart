import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/theme.dart';
import 'core/routes/router.dart';
import 'features/auth/providers/auth_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yiofgssgpyaytawviihl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlpb2Znc3NncHlheXRhd3ZpaWhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2MjIxOTYsImV4cCI6MjA5OTE5ODE5Nn0.973tngpzqQCUxXxNitc-xI7jACNJ0Jo8NfcXrDpF3N4',
  );

  runApp(
    const ProviderScope(
      child: TraceXApp(),
    ),
  );
}

class TraceXApp extends ConsumerWidget {
  const TraceXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);

    // Render loading splash screen during startup authentication state checks
    if (!authState.isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitPulse(
                  color: AppColors.primary,
                  size: 60.0,
                ),
                const SizedBox(height: 16),
                Text(
                  'TRACEX DAEMON INITIALIZING',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Configuring secure factory networks...',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'TraceX AOI Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
