// widgets/session_confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../services/session_tracker_service.dart';

class SessionConfirmationDialog extends StatelessWidget {
  final String userId;
  final String currentDeviceId;
  final int otherSessionsCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const SessionConfirmationDialog({
    Key? key,
    required this.userId,
    required this.currentDeviceId,
    required this.otherSessionsCount,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text(
            'Sessão Ativa Encontrada',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encontramos sua conta ativa em $otherSessionsCount outro(s) dispositivo(s).',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ao continuar, as outras sessões serão desconectadas.',
                    style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Deseja desconectar dos outros dispositivos e fazer login aqui?',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text('Continuar e Desconectar'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
