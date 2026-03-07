import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:metting_app/providers/analytics_provider_simple.dart';

enum _AnalyticsPeriod {
  last7Days,
  last30Days,
  quarter,
  year,
}

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  _AnalyticsPeriod _selectedPeriod = _AnalyticsPeriod.last7Days;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRealtime();
    });
  }

  @override
  void dispose() {
    final analyticsProvider =
        Provider.of<SimpleAnalyticsProvider>(context, listen: false);
    analyticsProvider.stopRealtimeMeetingStats();
    super.dispose();
  }

  void _startRealtime() {
    final analyticsProvider =
        Provider.of<SimpleAnalyticsProvider>(context, listen: false);
    final range = _getDateRangeForPeriod(_selectedPeriod);
    analyticsProvider.startRealtimeMeetingStats(
      startDate: range.start,
      endDate: range.end,
    );
  }

  DateTimeRange _getDateRangeForPeriod(_AnalyticsPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case _AnalyticsPeriod.last7Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case _AnalyticsPeriod.last30Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
      case _AnalyticsPeriod.quarter:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 89)),
          end: now,
        );
      case _AnalyticsPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
    }
  }

  String _periodLabel(_AnalyticsPeriod period) {
    switch (period) {
      case _AnalyticsPeriod.last7Days:
        return '7 ngày';
      case _AnalyticsPeriod.last30Days:
        return '30 ngày';
      case _AnalyticsPeriod.quarter:
        return 'Quý';
      case _AnalyticsPeriod.year:
        return 'Năm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FB),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Báo cáo thống kê',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: Color(0xFF1A1A1A)),
            onPressed: () {
              // For now just show info; can be extended to custom range picker
              final range = _getDateRangeForPeriod(_selectedPeriod);
              final formatter = DateFormat('dd/MM/yyyy');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Khoảng thời gian: ${formatter.format(range.start)} - ${formatter.format(range.end)}',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<SimpleAnalyticsProvider>(
          builder: (context, analyticsProvider, _) {
            final stats = analyticsProvider.meetingStats;

            final totalMeetings = (stats['totalMeetings'] ?? 0) as int;
            final attendanceRate =
                (stats['attendanceRate'] ?? 0.0) as double; // %
            final averageParticipants =
                (stats['averageParticipants'] ?? 0.0) as double;
            final averageDurationMinutes =
                (stats['averageDurationMinutes'] ?? 0.0) as double;

            final statusCounts =
                (stats['statusCounts'] ?? <String, int>{}) as Map<String, int>;
            final locationTypeCounts =
                (stats['locationTypeCounts'] ?? <String, int>{})
                    as Map<String, int>;
            final topOrganizers =
                (stats['topOrganizers'] ?? <Map<String, dynamic>>[])
                    as List<dynamic>;
            final trends =
                (stats['trends'] ?? <String, double>{}) as Map<String, double>;

            return RefreshIndicator(
              onRefresh: () async {
                _startRealtime();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildKpiRow(
                      colorScheme: colorScheme,
                      totalMeetings: totalMeetings,
                      attendanceRate: attendanceRate,
                      averageParticipants: averageParticipants,
                      averageDurationMinutes: averageDurationMinutes,
                      trends: trends,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusChartCard(statusCounts),
                    const SizedBox(height: 16),
                    _buildLocationTypeCard(locationTypeCounts),
                    const SizedBox(height: 16),
                    _buildTopOrganizersCard(topOrganizers),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        for (final period in _AnalyticsPeriod.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_periodLabel(period)),
              selected: _selectedPeriod == period,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _selectedPeriod = period;
                });
                _startRealtime();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildKpiRow({
    required ColorScheme colorScheme,
    required int totalMeetings,
    required double attendanceRate,
    required double averageParticipants,
    required double averageDurationMinutes,
    required Map<String, double> trends,
  }) {
    String? formatTrend(String key) {
      final v = trends[key];
      if (v == null) return null;
      final rounded = v.abs() < 0.05 ? 0 : v.round();
      final sign = rounded > 0 ? '+' : '';
      return '$sign$rounded%';
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        _KpiCard(
          title: 'Tổng cuộc họp',
          value: totalMeetings.toString(),
          icon: Icons.people_alt_outlined,
          trendText: formatTrend('totalMeetings'),
          color: colorScheme.primary,
        ),
        _KpiCard(
          title: 'Tỷ lệ tham dự',
          value: '${attendanceRate.toStringAsFixed(0)}%',
          icon: Icons.stacked_line_chart_outlined,
          trendText: formatTrend('attendanceRate'),
          color: const Color(0xFF22C55E),
        ),
        _KpiCard(
          title: 'TB người/họp',
          value: averageParticipants.toStringAsFixed(1),
          icon: Icons.group_outlined,
          trendText: formatTrend('averageParticipants'),
          color: const Color(0xFF0EA5E9),
        ),
        _KpiCard(
          title: 'Thời lượng TB',
          value: '${averageDurationMinutes.toStringAsFixed(0)} ph',
          icon: Icons.access_time_outlined,
          trendText: formatTrend('averageDurationMinutes'),
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _buildStatusChartCard(Map<String, int> statusCounts) {
    final total = statusCounts.values.fold<int>(0, (sum, v) => sum + v);
    final items = <_StatusItem>[
      _StatusItem(
        label: 'Hoàn thành',
        key: 'completed',
        color: const Color(0xFF22C55E),
      ),
      _StatusItem(
        label: 'Sắp diễn ra',
        key: 'scheduled',
        color: const Color(0xFF0EA5E9),
      ),
      _StatusItem(
        label: 'Chờ duyệt',
        key: 'pending',
        color: const Color(0xFFFACC15),
      ),
      _StatusItem(
        label: 'Đã hủy',
        key: 'cancelled',
        color: const Color(0xFFEF4444),
      ),
    ];

    return _SectionCard(
      title: 'Trạng thái cuộc họp',
      child: Row(
        children: [
          // Simple donut chart approximation
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 14,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade200,
                  ),
                ),
                ..._buildStatusArcs(items, statusCounts, total),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 17),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'cuộc họp',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                final count = statusCounts[item.key] ?? 0;
                final percent =
                    total > 0 ? (count * 100 / total).toStringAsFixed(0) : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusArcs(
    List<_StatusItem> items,
    Map<String, int> statusCounts,
    int total,
  ) {
    if (total == 0) return [];

    double start = 0.0;
    final widgets = <Widget>[];

    for (final item in items) {
      final count = statusCounts[item.key] ?? 0;
      if (count == 0) continue;
      final sweep = count / total;
      widgets.add(
        _ArcSegment(
          start: start,
          sweep: sweep,
          color: item.color,
        ),
      );
      start += sweep;
    }
    return widgets;
  }

  Widget _buildLocationTypeCard(Map<String, int> locationTypeCounts) {
    final online =
        (locationTypeCounts['virtual'] ?? locationTypeCounts['online'] ?? 0);
    final offline =
        (locationTypeCounts['physical'] ?? locationTypeCounts['offline'] ?? 0);
    final hybrid = (locationTypeCounts['hybrid'] ?? 0);
    final total = online + offline + hybrid;

    return _SectionCard(
      title: 'Loại hình cuộc họp',
      child: Column(
        children: [
          _LinearStatRow(
            label: 'Trực tuyến (Online)',
            value: '$online cuộc',
            color: const Color(0xFF3B82F6),
            progress: total > 0 ? online / total : 0,
          ),
          const SizedBox(height: 8),
          _LinearStatRow(
            label: 'Trực tiếp (Offline)',
            value: '$offline cuộc',
            color: const Color(0xFF6366F1),
            progress: total > 0 ? offline / total : 0,
          ),
          const SizedBox(height: 8),
          _LinearStatRow(
            label: 'Kết hợp (Hybrid)',
            value: '$hybrid cuộc',
            color: const Color(0xFF10B981),
            progress: total > 0 ? hybrid / total : 0,
          ),
        ],
      ),
    );
  }

  Widget _buildTopOrganizersCard(List<dynamic> topOrganizers) {
    return _SectionCard(
      title: 'Người tổ chức hàng đầu',
      trailing: TextButton(
        onPressed: () {},
        child: const Text(
          'Xem tất cả',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      child: Column(
        children: topOrganizers.take(3).map((raw) {
          final item = raw as Map<String, dynamic>;
          final name = (item['creatorName'] ?? 'Không rõ') as String;
          final meetingCount = (item['meetingCount'] ?? 0) as int;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$meetingCount cuộc họp',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trendText;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trendText,
  });

  @override
  Widget build(BuildContext context) {
    Color? trendColor;
    if (trendText != null) {
      if (trendText!.startsWith('-')) {
        trendColor = const Color(0xFFEF4444);
      } else if (trendText == '0%') {
        trendColor = const Color(0xFF94A3B8);
      } else {
        trendColor = const Color(0xFF22C55E);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              if (trendText != null)
                Text(
                  trendText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: trendColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusItem {
  final String label;
  final String key;
  final Color color;

  _StatusItem({
    required this.label,
    required this.key,
    required this.color,
  });
}

class _ArcSegment extends StatelessWidget {
  final double start;
  final double sweep;
  final Color color;

  const _ArcSegment({
    required this.start,
    required this.sweep,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: sweep),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return CustomPaint(
            painter: _ArcPainter(
              color: color,
              start: start,
              sweep: value,
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double start;
  final double sweep;

  _ArcPainter({
    required this.color,
    required this.start,
    required this.sweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    const fullCircle = 3.1415926535897932 * 2;
    final startAngle = -3.1415926535897932 / 2 + fullCircle * start;
    final sweepAngle = fullCircle * sweep;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.start != start ||
        oldDelegate.sweep != sweep;
  }
}

class _LinearStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;

  const _LinearStatRow({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

