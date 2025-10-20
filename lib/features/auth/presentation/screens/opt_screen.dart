import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../notifiers/phone_auth_notifier.dart';

class OtpScreen extends StatefulWidget {
  final String phoneE164;

  const OtpScreen({super.key, required this.phoneE164});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());

  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      int i = index;
      for (final d in digits) {
        if (i >= 6) break;
        _controllers[i].text = d;
        i++;
      }
      if (i < 6) {
        _focusNodes[i].requestFocus();
      } else {
        _focusNodes.last.unfocus();
        _submitIfReady();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _submitIfReady();
      }
      return;
    }

    if (index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void _submitIfReady() async {
    debugPrint('SUB RUNS: true');
    final code = _controllers.map((c) => c.text).join();
    if (RegExp(r'^\d{6}$').hasMatch(code)) {
      debugPrint('OTP: $code');

      await context.read<PhoneAuthNotifier>().verifyCode(
        smsCode: code,
        phoneE164: widget.phoneE164,
      );

      if (mounted &&
          context.read<PhoneAuthNotifier>().state.stage == AuthStage.authed) {
        Navigator.of(context).popUntil((r) => r.isFirst); // πίσω στο home
      }
    }
  }

  Widget _buildBox(int index) {
    return SizedBox(
      width: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textInputAction: index < 5
            ? TextInputAction.next
            : TextInputAction.done,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        autofillHints: const [AutofillHints.oneTimeCode],
        // mobile OTP autofill
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        onChanged: (v) => _onChanged(index, v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<PhoneAuthNotifier>();

    final verifyingStage = auth.state.stage;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Βάλε τον κωδικο επαλήθευσης',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Στείλαμε SMS στο ${widget.phoneE164}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, _buildBox),
            ),

            const SizedBox(height: 12),

            if (verifyingStage == AuthStage.verifying)
              Center(child: CircularProgressIndicator()),

            if (verifyingStage == AuthStage.error && auth.state.errorMessage != null) ...[

              Text(
                auth.state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            ]

          ],
        ),
      ),
    );
  }
}
