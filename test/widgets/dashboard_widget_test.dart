import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:expense_tracker/ui/dashboard/dashboard_page.dart';
import 'package:expense_tracker/ui/dashboard/dashboard_viewmodel.dart';
import 'package:expense_tracker/services/repository/transaction_repository.dart';
import 'package:expense_tracker/models/transaction.dart' as TxnModel;
import 'dashboard_widget_test.mocks.dart';

@GenerateMocks([TransactionRepository])
void main() {
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: DashboardPage(),
        ),
      ),
    );
  }

  testWidgets('Dashboard shows loading state initially',
      (WidgetTester tester) async {
    // Setup
    when(mockRepository.getAllTransactions()).thenAnswer((_) async => []);

    // Act
    await pumpDashboard(tester);

    // Assert
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('Dashboard shows data when loaded', (WidgetTester tester) async {
    // Setup
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    when(mockRepository.getAllTransactions()).thenAnswer((_) async => [
          TxnModel.Transaction(
            id: 1,
            date: currentMonth.add(const Duration(days: 1)),
            amount: 1000.0,
            merchant: "Salary",
            category: "Income",
          ),
          TxnModel.Transaction(
            id: 2,
            date: currentMonth.add(const Duration(days: 2)),
            amount: -50.0,
            merchant: "Grocery Store",
            category: "Food",
          ),
        ]);

    // Act
    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Income'), findsWidgets);
    expect(find.text('Expenses'), findsWidgets);
    expect(find.text('Year to Date Trends'), findsOneWidget);
    expect(find.text('Category Breakdown'), findsOneWidget);
    expect(find.text('Top Merchants'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Grocery Store'), findsOneWidget);
  });

  testWidgets('Pull to refresh triggers data reload',
      (WidgetTester tester) async {
    // Setup
    when(mockRepository.getAllTransactions())
        .thenAnswer((_) async => []); // Empty data for simplicity

    // Act
    await pumpDashboard(tester);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();

    // Verify
    verify(mockRepository.getAllTransactions()).called(greaterThan(1));
  });
}
