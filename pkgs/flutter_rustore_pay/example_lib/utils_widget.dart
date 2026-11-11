import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';

class UtilsWidget extends StatelessWidget {
  const UtilsWidget({super.key});

  void _checkRuStoreInstalled(BuildContext context) async {
    RuStorePayClient.instance.ruStoreUtils
        .isRuStoreInstalled()
        .then((isInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isInstalled.toString()),
      ));
    });
  }

  Widget _buildButton(
      BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {
        'label': 'isRuStoreInstalled',
        'onPressed': () => _checkRuStoreInstalled(context)
      },
      {
        'label': 'openRuStoreAuthorization',
        'onPressed': () =>
            RuStorePayClient.instance.ruStoreUtils.openRuStoreAuthorization()
      },
      {
        'label': 'openRuStoreDownloadInstruction',
        'onPressed': () => RuStorePayClient.instance.ruStoreUtils
            .openRuStoreDownloadInstruction()
      },
      {
        'label': 'openRuStore',
        'onPressed': () => RuStorePayClient.instance.ruStoreUtils.openRuStore()
      },
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons.map((button) {
          return Column(
            children: [
              _buildButton(context, button['label'].toString(),
                  button['onPressed'] as VoidCallback),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}
