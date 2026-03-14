import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kawiarnia/src/features/authentication/login_screen.dart';
import 'package:kawiarnia/src/features/cart/cart_provider.dart';
import 'package:kawiarnia/src/features/home/role_gate.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// === PALETA KOLORÓW KAWIARNI ===
const Color primaryColor = Color(0xFF6F4E37); // Ciepły brąz kawy
const Color secondaryColor = Color(0xFFD4A574); // Karmelowy odcień
const Color accentColor = Color(0xFFE8B55C); // Złoty akcent
const Color backgroundColor = Color(0xFFFAF7F2); // Ciepłe, kremowe tło
const Color surfaceColor = Color(0xFFFFFFFF); // Białe powierzchnie
const Color darkBrown = Color(0xFF3E2723); // Ciemny brąz do tekstów

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // === MOTYW KAWIARNI ===
    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,

      // Paleta kolorów
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: darkBrown,
        tertiary: accentColor,
        surface: surfaceColor,
        onSurface: darkBrown,
        background: backgroundColor,
        onBackground: darkBrown,
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
      ),

      // Typografia - czcionki w stylu kawiarni
      textTheme: GoogleFonts.ralewayTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 57, fontWeight: FontWeight.bold, color: darkBrown),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 45, fontWeight: FontWeight.bold, color: darkBrown),
        displaySmall: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold, color: darkBrown),
        headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: darkBrown),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w600, color: darkBrown),
        headlineSmall: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w600, color: darkBrown),
        titleLarge: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w600, color: darkBrown),
        titleMedium: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w500, color: darkBrown),
        titleSmall: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w500, color: darkBrown),
        bodyLarge: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.normal, color: darkBrown),
        bodyMedium: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.normal, color: darkBrown),
        bodySmall: GoogleFonts.raleway(fontSize: 12, fontWeight: FontWeight.normal, color: darkBrown.withOpacity(0.7)),
        labelLarge: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w600, color: darkBrown),
      ),

      // AppBar w stylu kawiarni
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: darkBrown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkBrown,
        ),
        iconTheme: const IconThemeData(color: darkBrown),
      ),

      // Karty
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: darkBrown.withOpacity(0.1),
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),

      // Przyciski
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Pola tekstowe
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        labelStyle: GoogleFonts.raleway(color: darkBrown.withOpacity(0.7)),
        hintStyle: GoogleFonts.raleway(color: darkBrown.withOpacity(0.5)),
      ),

      // Chipy
      chipTheme: ChipThemeData(
        backgroundColor: accentColor.withOpacity(0.2),
        labelStyle: GoogleFonts.raleway(color: darkBrown, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Ikony
      iconTheme: const IconThemeData(color: primaryColor, size: 24),

      // Dialogi
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkBrown,
        ),
        contentTextStyle: GoogleFonts.raleway(fontSize: 16, color: darkBrown),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkBrown,
        contentTextStyle: GoogleFonts.raleway(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: secondaryColor.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),
    );

    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'Kawiarnia',
        theme: theme, // Zastosowanie nowego motywu
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData) {
              return const RoleGate();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
