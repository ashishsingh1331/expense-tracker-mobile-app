import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction.dart';
import '../../services/repository/transaction_repository.dart';

/// Model for monthly summary data
class MonthlySummary {
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categoryBreakdown;
  final List<MerchantSummary> topMerchants;

  MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
    required this.topMerchants,
  });
}

/// Model for merchant summary data
class MerchantSummary {
  final String merchant;
  final double totalAmount;
  final int transactionCount;

  MerchantSummary({
    required this.merchant,
    required this.totalAmount,
    required this.transactionCount,
  });
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final dashboardProvider = Provider<DashboardViewModel>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return DashboardViewModel(repository);
});

class DashboardViewModel {
  final TransactionRepository _repository;

  DashboardViewModel(this._repository);

  /// Get monthly summary for a specific month or current month if not specified
  Future<MonthlySummary> getMonthSummary([DateTime? month]) async {
    month ??= DateTime.now();
    // Normalize to first day of month
    final targetMonth = DateTime(month.year, month.month, 1);

    // Get all transactions for the month
    final transactions = await _repository.getAllTransactions();
    final monthTransactions = transactions.where((t) {
      final txnDate = t.date;
      return txnDate.year == targetMonth.year &&
             txnDate.month == targetMonth.month;
    }).toList();

    // Calculate totals and breakdowns
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> categoryTotals = {};
    Map<String, MerchantSummary> merchantSummaries = {};

    for (final txn in monthTransactions) {
      if (txn.amount > 0) {
        totalIncome += txn.amount;
      } else {
        totalExpense += txn.amount.abs();
      }

      // Category breakdown
      final category = txn.category ?? 'Uncategorized';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + txn.amount.abs();

      // Merchant summary
      final merchant = txn.merchant;
      if (!merchantSummaries.containsKey(merchant)) {
        merchantSummaries[merchant] = MerchantSummary(
          merchant: merchant,
          totalAmount: 0,
          transactionCount: 0,
        );
      }
      var summary = merchantSummaries[merchant]!;
      merchantSummaries[merchant] = MerchantSummary(
        merchant: merchant,
        totalAmount: summary.totalAmount + txn.amount.abs(),
        transactionCount: summary.transactionCount + 1,
      );
    }

    // Get top merchants (sorted by total amount)
    final topMerchants = merchantSummaries.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return MonthlySummary(
      month: targetMonth,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      categoryBreakdown: categoryTotals,
      topMerchants: topMerchants.take(5).toList(), // Top 5 merchants
    );
  }

  /// Get year-to-date monthly summaries
  Future<List<MonthlySummary>> getYearToDateSummaries() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    List<MonthlySummary> summaries = [];

    for (var month = startOfYear;
         month.isBefore(now) || month.month == now.month;
         month = DateTime(month.year, month.month + 1)) {
      summaries.add(await getMonthSummary(month));
    }

    return summaries;
  }
}
