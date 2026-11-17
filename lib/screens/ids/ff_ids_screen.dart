import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/ff_id_model.dart';
import '../../providers/ff_id_provider.dart';
import '../../providers/seller_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';
import 'add_edit_id_screen.dart';
import 'id_detail_screen.dart';

class FfIdsScreen extends StatefulWidget {
  const FfIdsScreen({super.key});

  @override
  State<FfIdsScreen> createState() => _FfIdsScreenState();
}

class _FfIdsScreenState extends State<FfIdsScreen> {
  String _statusFilter = 'all';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        title: Text('Free Fire IDs',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textGrey),
            onPressed: () {
              context.read<FfIdProvider>().loadIds();
              context.read<DashboardProvider>().loadStats();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.rajdhani(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Search by UID...',
                    hintStyle: GoogleFonts.rajdhani(color: AppColors.textGrey),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: AppColors.textGrey, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              context.read<FfIdProvider>().searchByUid('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    context.read<FfIdProvider>().searchByUid(v);
                  },
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: ['all', 'available', 'sold'].map((s) {
                    final isSelected = _statusFilter == s;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _statusFilter = s);
                        context.read<FfIdProvider>().filterByStatus(s);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bgDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.textGrey.withOpacity(0.3)),
                        ),
                        child: Text(
                          s.toUpperCase(),
                          style: GoogleFonts.rajdhani(
                            color: isSelected ? AppColors.bgDark : AppColors.textGrey,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<FfIdProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ids = prov.filteredIds;
          if (ids.isEmpty) {
            return const EmptyState(
                message: 'No IDs found.\nTap + to add a new ID.',
                icon: Icons.games_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ids.length,
            itemBuilder: (ctx, i) => _IdCard(
              ffId: ids[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IdDetailScreen(ffId: ids[i])),
              ).then((_) {
                context.read<FfIdProvider>().loadIds();
                context.read<DashboardProvider>().loadStats();
              }),
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditIdScreen(ffId: ids[i])),
              ).then((_) {
                context.read<FfIdProvider>().loadIds();
                context.read<DashboardProvider>().loadStats();
              }),
              onDelete: () => _deleteId(context, ids[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditIdScreen()),
        ).then((_) {
          context.read<FfIdProvider>().loadIds();
          context.read<DashboardProvider>().loadStats();
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add ID', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _deleteId(BuildContext context, FfId ffId) {
    AppHelpers.confirmDelete(context, 'ID: ${ffId.uid}', () async {
      await context.read<FfIdProvider>().deleteId(ffId.id!);
      context.read<DashboardProvider>().loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ID deleted', style: GoogleFonts.rajdhani()),
                backgroundColor: AppColors.warning));
      }
    });
  }
}

class _IdCard extends StatelessWidget {
  final FfId ffId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IdCard({
    required this.ffId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = ffId.isAvailable;
    final statusColor = isAvailable ? AppColors.primary : AppColors.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.games_rounded, color: statusColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ffId.uid,
                            style: GoogleFonts.orbitron(
                                color: AppColors.textWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(ffId.loginEmail,
                            style: GoogleFonts.rajdhani(
                                color: AppColors.textGrey, fontSize: 12)),
                        if (ffId.sellerName != null)
                          Text('From: ${ffId.sellerName}',
                              style: GoogleFonts.rajdhani(
                                  color: AppColors.secondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  StatusBadge(status: ffId.status),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.primary.withOpacity(0.1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cost', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                        Text(formatCurrency(ffId.purchaseCost),
                            style: GoogleFonts.orbitron(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                        Text(formatCurrency(ffId.sellingPrice),
                            style: GoogleFonts.orbitron(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profit', style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                        Text(formatCurrency(ffId.profit),
                            style: GoogleFonts.orbitron(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                          icon: Icon(Icons.edit_rounded, color: AppColors.secondary, size: 18),
                          onPressed: onEdit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints()),
                      const SizedBox(width: 10),
                      IconButton(
                          icon: Icon(Icons.delete_rounded, color: AppColors.warning, size: 18),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
