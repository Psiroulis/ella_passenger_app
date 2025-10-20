import 'package:ella_passenger/features/home/presentation/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/notifiers/phone_auth_notifier.dart';
import '../features/auth/presentation/screens/phone_signin_screen.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: context.read<PhoneAuthNotifier>().authDs.watchUserId(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            //todo: Show a loading screen
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) return const PhoneSignInScreen();
        return const HomePage();
      },
    );
  }
}
