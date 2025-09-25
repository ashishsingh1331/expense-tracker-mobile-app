import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:expense_tracker/services/repository/transaction_repository.dart';
import 'package:expense_tracker/ui/dashboard/dashboard_viewmodel.dart';
import 'package:expense_tracker/models/transaction.dart' as TxnModel;
import 'dashboard_test.mocks.dart';

@GenerateMocks([TransactionRepository])
void main() {
  group('DashboardViewModel', () {
    late MockTransactionRepository mockRepository;
    late DashboardViewModel viewModel;

    setUp(() {
      mockRepository = MockTransactionRepository();
      viewModel = DashboardViewModel(mockRepository);
    });

    test('getMonthSummary aggregates transactions correctly', () async {
      // Setup mock data
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);

      final mockTransactions = [
        TxnModel.Transaction(
          id: 1,
          date: currentMonth.add(Duration(days: 1)),
          amount: -50.0,
          merchant: "Coffee Shop",
          category: "Food",
        ),
        TxnModel.Transaction(
          id: 2,
          date: currentMonth.add(Duration(days: 2)),
          amount: -30.0,
          merchant: "Coffee Shop",
          category: "Food",
        ),
        TxnModel.Transaction(
          id: 3,
          date: currentMonth.add(Duration(days: 3)),
          amount: 1000.0,
          merchant: "Employer",
          category: "Income",
        ),
        TxnModel.Transaction(
          id: 4,
          date: currentMonth.add(Duration(days: 4)),
          amount: -20.0,
          merchant: "Bookstore",
          category: "Entertainment",
        ),
      ];

      when(mockRepository.getAllTransactions())
          .thenAnswer((_) async => mockTransactions);

      // Execute
      final summary = await viewModel.getMonthSummary(currentMonth);

      // Verify
      expect(summary.totalIncome, 1000.0);
      expect(summary.totalExpense, 100.0);
      expect(summary.categoryBreakdown, {
        'Food': 80.0,
        'Entertainment': 20.0,
        'Income': 1000.0,
      });

      // Verify top merchants
      expect(summary.topMerchants.length, 3);
      expect(summary.topMerchants[0].merchant, 'Employer');
      expect(summary.topMerchants[0].totalAmount, 1000.0);
      expect(summary.topMerchants[0].transactionCount, 1);

      expect(summary.topMerchants[1].merchant, 'Coffee Shop');
      expect(summary.topMerchants[1].totalAmount, 80.0);
      expect(summary.topMerchants[1].transactionCount, 2);
    });

    test('getYearToDateSummaries returns all months up to current', () async {
      // Setup mock data for multiple months
      final now = DateTime.now();
      final mockTransactions = [
        TxnModel.Transaction(
          id: 1,
          date: DateTime(now.year, 1, 15),
          amount: -100.0,
          merchant: "Store",
          category: "Shopping",
        ),
        TxnModel.Transaction(
          id: 2,
          date: DateTime(now.year, now.month, 1),
          amount: -50.0,
          merchant: "Store",
          category: "Shopping",
        ),
      ];

      when(mockRepository.getAllTransactions())
          .thenAnswer((_) async => mockTransactions);

      // Execute
      final summaries = await viewModel.getYearToDateSummaries();

      // Verify
      expect(summaries.length, now.month); // Should have entries up to current month
      expect(summaries.first.month.month, 1); // Should start from January
      expect(summaries.last.month.month, now.month); // Should end at current month

      // Verify January summary
      final janSummary = summaries.first;
      expect(janSummary.totalExpense, 100.0);

      // Verify current month summary
      final currentSummary = summaries.last;
      expect(currentSummary.totalExpense, 50.0);
    });
  });
}
