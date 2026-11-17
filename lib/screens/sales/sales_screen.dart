import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/sale_model.dart';
import '../../providers/sale_provider.dart';
import '../../providers/ff_id_provider.dart';
import '../../providers/buyer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';
import 'make_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
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
        title: Text('Sales',
            style: GoogleFonts.orbitron(
                color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textGrey),
            onPressed: () => context.read<SaleProvider>().loadSales(),
          ),
        ],
      ),
      body: Consumer<SaleProvider>(
        builder: (ctx, sp, _) {
          if (sp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = sp.sales;
          if (sales.isEmpty) {
            return const EmptyState(
                message: 'No sales yet.\nTap + to record a sale.',
                icon: Icons.shopping_cart_outlined);
          }

          // Summary stats
          final totalSales = sales.fold<double>(0, (sum, s) => sum + s.sellingPrice);
          final totalProfit = sales.fold<double>(0, (sum, s) => sum + s.profit);
          final totalPending = sales.fold<double>(0, (sum, s) => sum + s.remainingBalance);

          return Column(
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: _miniStat('Total Sales', totalSales, AppColors.secondary)),
                  const SizedBox(width: 10),
                  Expanded(child: _miniStat('Total Profit', totalProfit, AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _miniStat('Pending', totalPending, AppColors.warning)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) => _SaleCard(sale: sales[i]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MakeSaleScreen()),
        ).then((_) {
          context.read<SaleProvider>().loadSales();
          context.read<FfIdProvider>().loadIds();
          context.read<BuyerProvider>().loadBuyers();
          context.read<DashboardProvider>().loadStats();
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: Text('New Sale', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(formatCurrency(value),
              style: GoogleFonts.orbitron(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sell_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sale.ffUid ?? 'ID #${sale.ffIdId}',
                          style: GoogleFonts.orbitron(
                              color: AppColors.textWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text('Buyer: ${sale.buyerName ?? 'Unknown'}',
                          style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatCurrency(sale.sellingPrice),
                        style: GoogleFonts.orbitron(
                            color: AppColors.secondary, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(formatDate(sale.saleDate),
                        style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.primary.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _stat('Profit', formatCurrency(sale.profit), AppColors.primary),
                _stat('Received', formatCurrency(sale.amountReceived), AppColors.secondary),
                _stat('Pending', formatCurrency(sale.remainingBalance),
                    sale.remainingBalance > 0 ? AppColors.warning : AppColors.textGrey),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sale.paymentMethod,
                        style: GoogleFonts.rajdhani(
                            color: AppColors.textGrey, fontSize: 11),
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 10)),
          Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
