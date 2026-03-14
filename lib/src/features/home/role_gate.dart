import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kawiarnia/src/features/client_panel/client_panel_screen.dart';
import 'package:kawiarnia/src/features/employee_panel/employee_panel_screen.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const Scaffold(body: Center(child: Text('Błąd logowania, uruchom aplikację ponownie.')));
        }

        final user = userSnapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (roleSnapshot.hasError) {
              return const Scaffold(body: Center(child: Text('Nie można pobrać roli użytkownika.')));
            }
            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const ClientPanelScreen(); 
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String?;

            // Zaktualizowana logika nawigacji
            if (role == 'pracownik') {
              return const EmployeePanelScreen(); // Nowy panel główny pracownika
            } else {
              return const ClientPanelScreen(); // Panel klienta
            }
          },
        );
      },
    );
  }
}
