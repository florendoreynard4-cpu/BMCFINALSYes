import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:ecommerce_app/screens/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// --- APP COLOR PALETTE ---
const Color kRichBlack = Color(0xFF1D1F24);
const Color kBrown = Color(0xFF8B5E3C);
const Color kLightBrown = Color(0xFFD2B48C);
const Color kOffWhite = Color(0xFFF8F4F0);

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Preserve splash until app is fully ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());

  // Optional: add a short delay to ensure splash is visible
  // await Future.delayed(const Duration(seconds: 1));

  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'eCommerce App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kBrown,
            brightness: Brightness.light,
            primary: kBrown,
            onPrimary: Colors.white,
            secondary: kLightBrown,
            background: kOffWhite,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: kOffWhite,
          textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            labelStyle: TextStyle(color: kBrown.withOpacity(0.8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBrown, width: 2.0),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: kRichBlack,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
