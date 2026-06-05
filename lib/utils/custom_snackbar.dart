import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType type, // Bisa diisi: success, failure, warning, help
  }) {
    final snackBar = SnackBar(
      elevation: 0, // Hilangkan bayangan bawaan
      behavior: SnackBarBehavior.floating, // Bikin melayang
      backgroundColor: Colors.transparent, // Bikin background aslinya tembus pandang
      padding: const EdgeInsets.only(top: 20), // Beri jarak
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: type,
        inMaterialBanner: true, // Biar lebih presisi desainnya
      ),
    );

    // Hapus notifikasi yang lama sebelum menimpa yang baru
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}