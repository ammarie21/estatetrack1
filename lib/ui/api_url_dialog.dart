import 'package:flutter/material.dart';

import 'package:estatetrack1/config/api_config.dart';
import 'package:estatetrack1/settings/app_settings.dart';

/// Lets the user change the backend URL before signing in.
Future<bool> showApiUrlDialog(BuildContext context) async {
  final controller = TextEditingController(
    text: AppSettings.instance.effectiveApiBaseUrl,
  );
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('API base URL'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Backend URL',
          hintText: ApiConfig.defaultBaseUrl,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await AppSettings.instance.resetApiBaseUrl();
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Reset default'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (saved != true) return false;

  final value = controller.text.trim();
  if (value.isNotEmpty && value != ApiConfig.defaultBaseUrl) {
    await AppSettings.instance.setApiBaseUrl(value);
  } else if (value.isEmpty || value == ApiConfig.defaultBaseUrl) {
    await AppSettings.instance.resetApiBaseUrl();
  }
  return true;
}
