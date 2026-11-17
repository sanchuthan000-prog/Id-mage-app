import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = true; // theme placeholder

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text('Settings',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            activeColor: AppColors.primary,
            title: Text('Dark Theme', style: GoogleFonts.rajdhani(color: AppColors.textWhite)),
            value: _isDark,
            onChanged: (v) => setState(() => _isDark = v),
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.secondary),
            title: Text('About', style: GoogleFonts.rajdhani(color: AppColors.textWhite)),
            subtitle: Text('Free Fire ID Sale Manager\nVersion 1.0.0', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
