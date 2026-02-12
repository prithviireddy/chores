import 'package:flat_chore/models/user_model.dart';
import 'package:flat_chore/screens/auth/login_screen.dart';
import 'package:flat_chore/screens/flat/join_flat_screen.dart';
import 'package:flat_chore/screens/home/home_screen.dart';
import 'package:flat_chore/services/auth_service.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<UserModel?>(
      stream: authService.user,
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
         }
         
         if (snapshot.hasData) {
           // User is logged in
           UserModel user = snapshot.data!;
           if (user.currentFlatId == null) {
             return const JoinFlatScreen();
           } else {
             return HomeScreen(user: user);
           }
         } else {
           return const LoginScreen();
         }
      },
    );
  }
}
