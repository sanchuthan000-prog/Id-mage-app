import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ff_id_model.dart';
import '../../providers/ff_id_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';
import 'add_edit_id_screen.dart';
import '../sales/make_sale_screen.dart';

class IdDetailScreen extends StatefulWidget {
  final FfId ffId;
  const IdDetailScreen({super.key, required this.ffId});

  @override
  State<IdDetailScreen> createState() => _IdDetailScreenState();
}

class _IdDetailScreenState extends State<IdDetailScreen> {
  bool _showPass = false;
  late FfId _ffId;

  @override
  void initState() {
    super.initState();
    _ffId = widget.ffId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textWhite, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Text('ID Details',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.secondary, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditIdScreen(ffId: _ffId)),
            ).then((_) async {
              final updated = await context.read<FfIdProvider>().getIdById(_ffId.id!);
              if (updated != null && mounted) setState(() => _ffId = updated);
            }),
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: AppColors.warning, size: 20),
            onPressed: () => AppHelpers.confirmDelete(context, 'ID: ${_ffId.uid}', () async {
              await context.read<FfIdProvider>().deleteId(_ffId.id!);
              context.read<DashboardProvider>().loadStats();
              if (mounted) Navigator.pop(context);
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Carousel
            if (_ffId.images.isNotEmpty) _buildImagesSection(),
            const SizedBox(height: 16),

            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _ffId.isAvailable
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _ffId.isAvailable ? AppColors.primary : AppColors.warning,
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  _ffId.isAvailable ? '✅ AVAILABLE FOR SALE' : '🔴 SOLD',
                  style: GoogleFonts.orbitron(
                      color: _ffId.isAvailable ? AppColors.primary : AppColors.warning,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Account Info
            _card([
              _infoRow('Free Fire UID', _ffId.uid, copyable: true, icon: Icons.games_rounded),
              _divider(),
              _infoRow('Login Email', _ffId.loginEmail, copyable: true, icon: Icons.email_rounded),
              _divider(),
              _passwordRow(),
            ]),
            const SizedBox(height: 14),

            // Pricing
            _card([
              _infoRow('Purchase Cost', formatCurrency(_ffId.purchaseCost),
                  valueColor: AppColors.warning, icon: Icons.paid_rounded),
              _divider(),
              _infoRow('Selling Price', formatCurrency(_ffId.sellingPrice),
                  valueColor: AppColors.secondary, icon: Icons.sell_rounded),
              _divider(),
              _infoRow('Profit', formatCurrency(_ffId.profit),
                  valueColor: AppColors.primary, icon: Icons.trending_up_rounded),
            ]),
            const SizedBox(height: 14),

            // Additional Info
            _card([
              if (_ffId.sellerName != null)
                _infoRow('Seller', _ffId.sellerName!, icon: Icons.person_rounded),
              if (_ffId.sellerName != null) _divider(),
              _infoRow('Purchase Date', formatDateTime(_ffId.purchaseDate),
                  icon: Icons.calendar_today_rounded),
              if (_ffId.notes != null && _ffId.notes!.isNotEmpty) ...[
                _divider(),
                _infoRow('Notes', _ffId.notes!, icon: Icons.note_rounded),
              ],
              _divider(),
              _infoRow('Added On', formatDateTime(_ffId.createdAt),
                  icon: Icons.access_time_rounded),
            ]),
            const SizedBox(height: 20),

            // Sale history
            if (_ffId.isSold) _buildSaleHistory(),

            // Sell button
            if (_ffId.isAvailable) ...[
              const SizedBox(height: 10),
              PrimaryButton(
                label: '🛒 Sell This ID',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MakeSaleScreen(preselectedId: _ffId)),
                ).then((_) async {
                  final updated = await context.read<FfIdProvider>().getIdById(_ffId.id!);
                  if (updated != null && mounted) {
                    setState(() => _ffId = updated);
                    context.read<DashboardProvider>().loadStats();
                  }
                }),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: _ffId.images.length,
        itemBuilder: (ctx, i) {
          final imgFile = File(_ffId.images[i].imagePath);
          return GestureDetector(
            onTap: () => _viewImage(context, _ffId.images[i].imagePath),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imgFile.existsSync()
                    ? Image.file(imgFile, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.cardBg,
                        child: Icon(Icons.broken_image_rounded, color: AppColors.textGrey, size: 40)),
              ),
            ),
          );
        },
      ),
    );
  }

  void _viewImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.file(File(path)),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleHistory() {
    return Consumer<SaleProvider>(
      builder: (ctx, sp, _) {
        final sales = sp.sales.where((s) => s.ffIdId == _ffId.id).toList();
        if (sales.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sale History',
                style: GoogleFonts.orbitron(
                    color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...sales.map((sale) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sold to: ${sale.buyerName ?? 'Unknown'}',
                          style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(formatCurrency(sale.sellingPrice),
                          style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${formatDateTime(sale.saleDate)} • ${sale.paymentMethod}',
                      style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                  if (sale.remainingBalance > 0)
                    Text('Remaining: ${formatCurrency(sale.remainingBalance)}',
                        style: GoogleFonts.rajdhani(color: AppColors.warning, fontSize: 12)),
                ],
              ),
            )),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.primary.withOpacity(0.1), indent: 16, endIndent: 16);

  Widget _infoRow(String label, String value,
      {bool copyable = false, Color? valueColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.secondary, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.rajdhani(
                        color: valueColor ?? AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy_rounded, color: AppColors.textGrey, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied!', style: GoogleFonts.rajdhani()),
                        backgroundColor: AppColors.cardBg, duration: const Duration(seconds: 1)));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _passwordRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _showPass ? _ffId.loginPasswordEncrypted : '••••••••',
                  style: GoogleFonts.rajdhani(color: AppColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textGrey, size: 18),
            onPressed: () => setState(() => _showPass = !_showPass),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.copy_rounded, color: AppColors.textGrey, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _ffId.loginPasswordEncrypted));
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password copied!', style: GoogleFonts.rajdhani()),
                      backgroundColor: AppColors.cardBg, duration: const Duration(seconds: 1)));
            },
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
