import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';

/// Sentinel key used when an expense has no category.
const _kOtherCategory = '__other__';

/// One slide of the dashboard chart carousel.
class DashboardCharts extends StatefulWidget {
  const DashboardCharts({required this.entries, required this.symbol, super.key});

  final List<Entry> entries;
  final String symbol;

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_DailyTotals> get _lastSevenDays {
    final today = DateTime.now();
    final days = <_DailyTotals>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      var income = 0.0;
      var expense = 0.0;
      for (final e in widget.entries) {
        if (e.date.isBefore(day) || !e.date.isBefore(next)) continue;
        if (e.kind.isCashIn) income += e.amount;
        if (e.kind.isCashOut) expense += e.amount;
      }
      days.add(_DailyTotals(day, income, expense));
    }
    return days;
  }

  Map<String, double> get _expenseByCategory {
    final map = <String, double>{};
    for (final e in widget.entries) {
      if (e.kind != EntryKind.expense) continue;
      final key = (e.category?.trim().isNotEmpty ?? false)
          ? e.category!.trim()
          : _kOtherCategory;
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  }

  List<FlSpot> get _netSeries {
    final today = DateTime.now();
    final spots = <FlSpot>[];
    var running = 0.0;
    for (var i = 13; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final next = day.add(const Duration(days: 1));
      for (final e in widget.entries) {
        if (e.date.isBefore(day) || !e.date.isBefore(next)) continue;
        if (e.kind.isCashIn) running += e.amount;
        if (e.kind.isCashOut) running -= e.amount;
      }
      spots.add(FlSpot((13 - i).toDouble(), running));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final l10n = AppLocalizations.of(context);
    final slides = <Widget>[
      _ChartCard(
        title: l10n.chartLast7Days,
        child: _BarChart(days: _lastSevenDays, symbol: widget.symbol),
      ),
      _ChartCard(
        title: l10n.chartExpensesByCategory,
        child: _PieChart(data: _expenseByCategory, symbol: widget.symbol),
      ),
      _ChartCard(
        title: l10n.chartCashBalance,
        child: _LineChart(spots: _netSeries, color: app.profit),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: slides,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? context.colors.primary
                      : context.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DailyTotals {
  const _DailyTotals(this.day, this.income, this.expense);
  final DateTime day;
  final double income;
  final double expense;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.days, required this.symbol});

  final List<_DailyTotals> days;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final maxValue = days.fold<double>(
      0,
      (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b),
    );
    if (maxValue <= 0) {
      return Center(
        child: Text(
          AppLocalizations.of(context).chartNoData,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('E').format(days[i].day),
                    style: context.texts.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: days[i].income,
                  color: app.income,
                  width: 7,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: days[i].expense,
                  color: app.expense,
                  width: 7,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.data, required this.symbol});

  final Map<String, double> data;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).chartNoExpenses,
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      );
    }

    final palette = <Color>[
      context.appColors.expense,
      context.appColors.income,
      context.appColors.profit,
      context.appColors.bank,
      context.appColors.wallet,
      context.colors.tertiary,
      context.colors.secondary,
    ];
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    color: palette[i % palette.length],
                    radius: 42,
                    title: '',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette[i % palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entries[i].key == _kOtherCategory
                          ? AppLocalizations.of(context).categoryOther
                          : entries[i].key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.spots, required this.color});

  final List<FlSpot> spots;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox();

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              reservedSize: 22,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${value.toInt()}d',
                  style: context.texts.labelSmall,
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  compactMoney(s.y),
                  context.texts.labelSmall!,
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
