import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/session_controller.dart';
import 'header_action_button.dart';

/// "Sair" action used consistently across authenticated screens.
class LogoutCircleButton extends StatelessWidget {
  const LogoutCircleButton({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    return HeaderActionButton(
      tooltip: 'Sair',
      icon: PhosphorIcons.signOut(),
      onPressed: sessionController.isLoading ? null : sessionController.signOut,
    );
  }
}
