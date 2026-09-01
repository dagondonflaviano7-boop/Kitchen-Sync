import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierContactActions extends StatelessWidget {
  final String? phone;
  final String supplierName;
  final bool compact;

  const SupplierContactActions({
    super.key,
    required this.phone,
    required this.supplierName,
    this.compact = true,
  });

  String get _normalizedPhone {
    return (phone ?? '').trim();
  }

  bool get _hasPhone {
    final String value = _normalizedPhone;

    return value.isNotEmpty &&
        value.toLowerCase() != 'none' &&
        value.toLowerCase() != 'n/a';
  }

  Future<void> _openContactAction(
    BuildContext context, {
    required String scheme,
    required String actionName,
  }) async {
    if (!_hasPhone) {
      _showMessage(
        context,
        '$supplierName has no phone number.',
        isError: true,
      );

      return;
    }

    final Uri uri = Uri(
      scheme: scheme,
      path: _normalizedPhone,
    );

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showMessage(
          context,
          'Unable to open the $actionName application.',
          isError: true,
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Supplier $actionName launch failed: '
        '$error\n$stackTrace',
      );

      if (context.mounted) {
        _showMessage(
          context,
          'This device cannot start the '
          '$actionName action.',
          isError: true,
        );
      }
    }
  }

  Future<void> _call(
    BuildContext context,
  ) {
    return _openContactAction(
      context,
      scheme: 'tel',
      actionName: 'calling',
    );
  }

  Future<void> _text(
    BuildContext context,
  ) {
    return _openContactAction(
      context,
      scheme: 'sms',
      actionName: 'messaging',
    );
  }

  void _showMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Color disabledColor = Theme.of(context).disabledColor;

    final Widget callButton = IconButton(
      tooltip: _hasPhone ? 'Call $supplierName' : 'No phone number',
      onPressed: _hasPhone ? () => _call(context) : null,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      icon: Icon(
        Icons.call_outlined,
        size: compact ? 18 : 22,
        color: _hasPhone ? const Color(0xFF18794E) : disabledColor,
      ),
    );

    final Widget textButton = IconButton(
      tooltip: _hasPhone ? 'Text $supplierName' : 'No phone number',
      onPressed: _hasPhone ? () => _text(context) : null,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      icon: Icon(
        Icons.sms_outlined,
        size: compact ? 18 : 22,
        color: _hasPhone ? const Color(0xFF3568A8) : disabledColor,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        callButton,
        textButton,
      ],
    );
  }
}
