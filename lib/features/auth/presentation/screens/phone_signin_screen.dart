import 'package:ella_passenger/features/auth/presentation/notifiers/phone_auth_notifier.dart';
import 'package:ella_passenger/features/auth/presentation/widgets/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/country.dart';
import 'opt_screen.dart';

class PhoneSignInScreen extends StatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  State<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends State<PhoneSignInScreen> {
  final _phoneCtrl = TextEditingController();
  late final PhoneAuthNotifier authProvider;
  bool _navigated = false;
  bool _isNumberValid = false;
  String phoneCode = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      authProvider = context.read<PhoneAuthNotifier>();
      authProvider.addListener(_authListener);
    });
  }

  void _authListener() {
    final authState = authProvider.state;

    if (!_navigated && authState.stage == AuthStage.codeSent) {
      _navigated = true;

      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(phoneE164: "$phoneCode${_phoneCtrl.text.trim()}"),
            ),
          )
          .then((_) => _navigated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("SignInScreen: build");
    final sending = context.select<PhoneAuthNotifier, bool>(
      (n) => n.state.stage == AuthStage.sendingCode,
    );

    final auth = context.watch<PhoneAuthNotifier>();

    Country? _chosen = Country(
      name: "Greece",
      dialCode: "+30",
      nameGr: "Ελλάδα",
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ποίος είναι ο αριθμός σου;',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Θα λάβεις έναν κωδικό για επαλήθευση'),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CountryPicker(
                    initialCountry: _chosen,
                    locale: "GR",
                    onSelected:(c){
                      setState(() {
                        _chosen=c;
                        phoneCode = c.dialCode;
                      });
                    },
                  ),
                  Text("|"),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      autofocus: true,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hint: Text("Αριθμός Τηλεφώνου"),
                      ),
                      onChanged: (value) {
                        if (value.length >= 6) {
                          setState(() {
                            _isNumberValid = true;
                          });
                        } else {
                          setState(() {
                            _isNumberValid = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (auth.state.stage == AuthStage.error &&
                auth.state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            Spacer(),

            SizedBox(
              child: ElevatedButton(
                onPressed: sending || _isNumberValid == false
                    ? null
                    : () async {
                  String phoneE164 = "${_chosen?.dialCode}${_phoneCtrl.text.trim()}";
                        await context.read<PhoneAuthNotifier>().start(
                          phoneE164: phoneE164,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), //
                  ),
                ),
                child: sending
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Στείλε κωδικό',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("SignInScreen: Dispose");
    authProvider.removeListener(_authListener);
    super.dispose();
  }
}
