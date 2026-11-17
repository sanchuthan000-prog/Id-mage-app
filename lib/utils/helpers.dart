import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

import 'constants.dart';
import '../theme/app_theme.dart';

/// Formats a numeric amount to Sri Lankan Rupee currency string:
/// Example: 1234.0 -> "Rs. 1,234.00"
String formatCurrency(double amount, {String? symbol}) {
  final sym = symbol ?? AppConstants.defaultCurrencySymbol;
  final formatter = NumberFormat.currency(
    symbol: '$sym ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Converts any UTC or Local DateTime to Asia/Colombo timezone (UTC+5:30).
DateTime getColomboDateTime([DateTime? dt]) {
  final target = dt ?? DateTime.now();
  final utcTime = target.isUtc ? target : target.toUtc();
  return utcTime.add(AppConstants.colomboUtcOffset);
}

/// Formats a DateTime into a clean date string:
/// Example: "15 Nov 2026"
String formatDate(DateTime dt) {
  return DateFormat('dd MMM yyyy').format(dt);
}

/// Parses an ISO-8601 string or date string and formats it to "dd MMM yyyy".
/// Returns fallback if parsing fails.
String formatDateString(String? dateStr, {String fallback = 'N/A'}) {
  if (dateStr == null || dateStr.trim().isEmpty) return fallback;
  try {
    final parsed = DateTime.parse(dateStr);
    return formatDate(parsed);
  } catch (_) {
    return dateStr;
  }
}

/// Formats a DateTime into a date and 12-hour time string:
/// Example: "15 Nov 2026 07:48 PM"
String formatDateTime(DateTime dt) {
  return DateFormat('dd MMM yyyy hh:mm a').format(dt);
}

/// Parses an ISO-8601 string or date string and formats it to "dd MMM yyyy hh:mm a".
String formatDateTimeString(String? dateStr, {String fallback = 'N/A'}) {
  if (dateStr == null || dateStr.trim().isEmpty) return fallback;
  try {
    final parsed = DateTime.parse(dateStr);
    return formatDateTime(parsed);
  } catch (_) {
    return dateStr;
  }
}

/// Returns the current timestamp in Asia/Colombo (Sri Lanka) formatted as:
/// Example: "15 Nov 2026 07:48 PM"
String formatDateTimeColomboBased() {
  final colomboNow = getColomboDateTime();
  return formatDateTime(colomboNow);
}

/// Returns current ISO-8601 string in Asia/Colombo offset (+05:30).
String getColomboIsoNow() {
  return getColomboDateTime().toIso8601String();
}

/// Normalizes phone numbers to international standard with Sri Lanka fallback.
/// Strips spaces, hyphens, and converts "0712345678" -> "94712345678".
String cleanPhoneNumber(String phone) {
  String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (cleaned.startsWith('+')) {
    cleaned = cleaned.substring(1);
  }
  if (cleaned.startsWith('0') && cleaned.length >= 10) {
    cleaned = '94${cleaned.substring(1)}';
  }
  return cleaned;
}

/// Generates a valid WhatsApp chat URL:
/// https://wa.me/{phone}?text={encoded_message}
String generateWhatsAppUrl(String phone, String message) {
  final normalizedPhone = cleanPhoneNumber(phone);
  final encodedMsg = Uri.encodeComponent(message);
  return 'https://wa.me/$normalizedPhone?text=$encodedMsg';
}

/// Opens WhatsApp or default browser with the generated chat link.
Future<bool> openWhatsApp(
  BuildContext context,
  String phone,
  String message,
) async {
  final urlString = generateWhatsAppUrl(phone, message);
  final uri = Uri.parse(urlString);

  try {
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Try launching in platform default browser
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    if (context.mounted) {
      showCustomSnackBar(
        context,
        'Could not open WhatsApp: $e',
        isError: true,
      );
    }
    return false;
  }
}

/// Encrypts text using SHA-256 derived XOR stream cipher and returns Base64.
/// Completely reversible with [simpleDecrypt].
String simpleEncrypt(String text, String key) {
  if (text.isEmpty) return '';
  final textBytes = utf8.encode(text);
  final keyHash = sha256.convert(utf8.encode(key)).bytes;

  final encryptedBytes = List<int>.generate(
    textBytes.length,
    (i) => textBytes[i] ^ keyHash[i % keyHash.length],
  );

  return base64.encode(encryptedBytes);
}

/// Decrypts text encrypted by [simpleEncrypt].
String simpleDecrypt(String encrypted, String key) {
  if (encrypted.isEmpty) return '';
  try {
    final cipherBytes = base64.decode(encrypted);
    final keyHash = sha256.convert(utf8.encode(key)).bytes;

    final decryptedBytes = List<int>.generate(
      cipherBytes.length,
      (i) => cipherBytes[i] ^ keyHash[i % keyHash.length],
    );

    return utf8.decode(decryptedBytes);
  } catch (e) {
    // Return original string if deciphering fails
    return encrypted;
  }
}

/// Displays a themed confirmation dialog for deleting items.
Future<bool> confirmDelete(
  BuildContext ctx,
  String itemName,
  VoidCallback onConfirm,
) async {
  final result = await showDialog<bool>(
    context: ctx,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirm Delete',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$itemName"?\nThis action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            child: Text(
              'Delete',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

/// Shows a custom styled dark snack bar notification.
void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError
          ? AppColors.error.withOpacity(0.95)
          : AppColors.surfaceLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isError ? AppColors.error : AppColors.cardBorder,
        ),
      ),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.white : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      duration: duration,
      action: action,
    ),
  );
}
