import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';
import '../sellers/sellers_screen.dart';
import '../buyers/buyers_screen.dart';
import '../deo/deo_screen.dart';
import '../reports/reports_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text('More',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          _menuItem(context, Icons.person_outline, 'Sellers', () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SellersScreen()))),
          _menuItem(context, Icons.person_outline, 'Buyers', () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const BuyersScreen()))),
          _menuItem(context, Icons.assignment_outlined, 'DEO Management', () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DeoScreen()))),
          _menuItem(context, Icons.bar_chart_rounded, 'Reports', () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          _menuItem(context, Icons.backup_rounded, 'Backup / Restore', () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const BackupScreen()))),
          _menuItem(context, Icons.settings_rounded, 'Settings', () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
      onTap: onTap,
    );
  }
}
