import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'dashboard_viewmodel.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late Future<MonthlySummary> _currentMonthSummary;
  late Future<List<MonthlySummary>> _yearToDateSummaries;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final viewModel = ref.read(dashboardProvider);
    _currentMonthSummary = viewModel.getMonthSummary();
    _yearToDateSummaries = viewModel.getYearToDateSummaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadData();
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Month Overview
                _buildMonthOverview(),
                const SizedBox(height: 24),

                // YTD Monthly Trends
                _buildYearToDateTrends(),
                const SizedBox(height: 24),

                // Category Breakdown
                _buildCategoryBreakdown(),
                const SizedBox(height: 24),

                // Top Merchants
                _buildTopMerchants(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthOverview() {
    return FutureBuilder<MonthlySummary>(
      future: _currentMonthSummary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Error loading summary');
        }

        final summary = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMM().format(summary.month),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildOverviewRow(
                  'Income',
                  summary.totalIncome,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildOverviewRow(
                  'Expenses',
                  summary.totalExpense,
                  Colors.red,
                ),
                const SizedBox(height: 8),
                _buildOverviewRow(
                  'Net',
                  summary.totalIncome - summary.totalExpense,
                  Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          NumberFormat.currency(symbol: '\$').format(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildYearToDateTrends() {
    return FutureBuilder<List<MonthlySummary>>(
      future: _yearToDateSummaries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Error loading trends');
        }

        final summaries = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year to Date Trends',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: summaries.fold(0.0, (max, summary) =>
                          math.max(max as double, math.max(summary.totalIncome, summary.totalExpense))),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value < 0 || value >= summaries.length) return const Text('');
                              return Text(
                                DateFormat.MMM().format(summaries[value.toInt()].month),
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      barGroups: summaries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final summary = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: summary.totalIncome,
                              width: 12,
                              color: Colors.green,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: summary.totalExpense,
                              width: 12,
                              color: Colors.red,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown() {
    return FutureBuilder<MonthlySummary>(
      future: _currentMonthSummary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Error loading categories');
        }

        final summary = snapshot.data!;
        final categories = summary.categoryBreakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: categories.map((entry) {
                        final total = categories.fold(0.0, (sum, e) => sum + e.value);
                        final percentage = (entry.value / total * 100).toStringAsFixed(1);
                        return PieChartSectionData(
                          color: Colors.primaries[
                            categories.indexOf(entry) % Colors.primaries.length
                          ],
                          value: entry.value,
                          title: '${entry.key}\n$percentage%',
                          radius: 100,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopMerchants() {
    return FutureBuilder<MonthlySummary>(
      future: _currentMonthSummary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Error loading merchants');
        }

        final summary = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Merchants',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...summary.topMerchants.map((merchant) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              merchant.merchant,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            NumberFormat.currency(symbol: '\$')
                                .format(merchant.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${merchant.transactionCount} txns)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
