import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/design_system.dart';

final _count = NumberFormat('#,##0');

/// Footer for paged lists: "Showing 1–50 of 1,234 households" and first / previous / next / last
/// page buttons. [page] is zero-based; [shown] is how many rows the current page holds.
class TropaPager extends StatelessWidget {
  final int page;
  final int pageSize;
  final int total;
  final int shown;
  final String noun;
  final ValueChanged<int> onPage;

  const TropaPager({
    super.key,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.shown,
    required this.noun,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final subCol = TropaColors.textMedium(context);
    final pages = math.max(1, (total / pageSize).ceil());
    final first = page * pageSize + 1;
    final last = page * pageSize + shown;
    final hasPrev = page > 0;
    final hasNext = page + 1 < pages;
    final compact = context.isCompactScreen;

    return Row(
      children: [
        Expanded(
          child: Text(
            compact
                ? '${_count.format(first)}–${_count.format(last)} of ${_count.format(total)}'
                : 'Showing ${_count.format(first)}–${_count.format(last)} of ${_count.format(total)} $noun',
            style: TropaText.meta(subCol),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!compact)
          IconButton(
            tooltip: 'First page',
            icon: const Icon(Icons.first_page),
            onPressed: hasPrev ? () => onPage(0) : null,
          ),
        IconButton(
          tooltip: 'Previous page',
          icon: const Icon(Icons.chevron_left),
          onPressed: hasPrev ? () => onPage(page - 1) : null,
        ),
        Text('Page ${page + 1} of $pages', style: TropaText.meta(subCol)),
        IconButton(
          tooltip: 'Next page',
          icon: const Icon(Icons.chevron_right),
          onPressed: hasNext ? () => onPage(page + 1) : null,
        ),
        if (!compact)
          IconButton(
            tooltip: 'Last page',
            icon: const Icon(Icons.last_page),
            onPressed: hasNext ? () => onPage(pages - 1) : null,
          ),
      ],
    );
  }
}
