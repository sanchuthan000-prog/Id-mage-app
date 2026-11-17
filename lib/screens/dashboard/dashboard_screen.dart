import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/dashboard_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardBg,
        onRefresh: () async {
          await context.read<DashboardProvider>().loadStats();
          await context.read<SaleProvider>().loadSales();
          await context.read<TransactionProvider>().loadTransactions();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              backgroundColor: AppColors.bgDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.bgDark, AppColors.cardBg],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: Icon(Icons.games_rounded, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FF ID Manager',
                                  style: GoogleFonts.orbitron(
                                      color: AppColors.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              Text(formatDate(AppHelpers.nowColombo()),
                                  style: GoogleFonts.rajdhani(
                                      color: AppColors.textGrey, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: Consumer<DashboardProvider>(
                builder: (ctx, dp, _) {
                  if (dp.isLoading) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final s = dp.stats;
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // ID Stats Row
                      _sectionTitle('📊 ID Overview'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: StatCard(
                                  title: 'Total IDs',
                                  value: s.totalIds.toString(),
                                  icon: Icons.inventory_2_rounded,
                                  color: AppColors.secondary)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: StatCard(
                                  title: 'Available',
                                  value: s.availableIds.toString(),
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.primary)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: StatCard(
                                  title: 'Sold',
                                  value: s.soldIds.toString(),
                                  icon: Icons.sell_rounded,
                                  color: AppColors.warning)),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 20),

                      // Financial Cards
                      _sectionTitle('💰 Financial Summary'),
                      const SizedBox(height: 10),
                      _financialCard('Total Investment', s.totalInvestment,
                          Icons.trending_down_rounded, AppColors.warning),
                      const SizedBox(height: 10),
                      _financialCard('Total Sales', s.totalSales,
                          Icons.trending_up_rounded, AppColors.secondary),
                      const SizedBox(height: 10),
                      _profitCard(s.totalProfit),
                      const SizedBox(height: 20),

                      // Payment Summary
                      _sectionTitle('💳 Payment Summary'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _payCard('Seller Payments', s.totalSellerPayments,
                                AppColors.warning)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _payCard(
                                'Buyer Payments', s.totalBuyerPayments, AppColors.primary)),
                      ]),
                      const SizedBox(height: 10),
                      _financialCard('Outstanding Balance', s.totalOutstandingBalance,
                          Icons.pending_actions_rounded, AppColors.warning),
                      const SizedBox(height: 20),

                      // DEO Summary
                      _sectionTitle('📋 DEO Summary'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _payCard('DEO Total', s.deoTotal, AppColors.secondary)),
                        const SizedBox(width: 8),
                        Expanded(child: _payCard('DEO Paid', s.deoPaid, AppColors.primary)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _payCard('DEO Remaining', s.deoRemaining, AppColors.warning)),
                      ]),
                      const SizedBox(height: 20),

                      // Recent Sales
                      _sectionTitle('🕐 Recent Sales'),
                      const SizedBox(height: 10),
                      Consumer<SaleProvider>(builder: (ctx, sp, _) {
                        final recent = sp.sales.take(5).toList();
                        if (recent.isEmpty) {
                          return const EmptyState(message: 'No sales yet', icon: Icons.sell_outlined);
                        }
                        return Column(
                          children: recent
                              .map((sale) => _recentSaleCard(sale))
                              .toList(),
                        );
                      }),
                      const SizedBox(height: 20),

                      // Recent Transactions
                      _sectionTitle('📝 Recent Transactions'),
                      const SizedBox(height: 10),
                      Consumer<TransactionProvider>(builder: (ctx, tp, _) {
                        final recent = tp.transactions.take(5).toList();
                        if (recent.isEmpty) {
                          return const EmptyState(
                              message: 'No transactions yet',
                              icon: Icons.receipt_long_outlined);
                        }
                        return Column(
                          children: recent.map((t) => _recentTxCard(t)).toList(),
                        );
                      }),
                      const SizedBox(height: 30),
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.orbitron(
            color: AppColors.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5));
  }

  Widget _financialCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
              Text(formatCurrency(amount),
                  style: GoogleFonts.orbitron(
                      color: color, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, duration: 400.ms);
  }

  Widget _profitCard(double profit) {
    final isPositive = profit >= 0;
    final color = isPositive ? AppColors.primary : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), AppColors.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Profit',
                  style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 13)),
              Text(formatCurrency(profit),
                  style: GoogleFonts.orbitron(
                      color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95), duration: 400.ms);
  }

  Widget _payCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(formatCurrency(amount),
              style: GoogleFonts.orbitron(
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _recentSaleCard(dynamic sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.sell_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.ffUid ?? 'ID #${sale.ffIdId}',
                    style: GoogleFonts.orbitron(
                        color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(sale.buyerName ?? 'Buyer',
                    style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(sale.sellingPrice),
                  style: GoogleFonts.orbitron(
                      color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(formatDate(sale.saleDate),
                  style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentTxCard(dynamic tx) {
    final isIncoming = tx.personType == 'buyer';
    final color = isIncoming ? AppColors.primary : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(
                isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.personName ?? 'Unknown',
                    style: GoogleFonts.orbitron(
                        color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(tx.typeDisplayName,
                    style: GoogleFonts.rajdhani(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Text(formatCurrency(tx.amount),
              style: GoogleFonts.orbitron(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
