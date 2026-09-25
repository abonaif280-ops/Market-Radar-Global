import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/utils/arabic_format.dart';
import '../domain/case_enums.dart';
import '../domain/case_query.dart';
import '../domain/case_views.dart';
import '../../export/data/case_export_service.dart';
import '../../export/presentation/export_flow.dart';
import 'case_filters_sheet.dart';
import 'widgets/status_chip.dart';

/// الحالات السابقة مع البحث والتصفية، الأحدث أولًا ومجمعة باليوم.
///
/// التحميل تدريجي (30 حالة لكل صفحة) ويتحدث تلقائيًا عند أي تغيير في الحالات.
class CasesListScreen extends ConsumerStatefulWidget {
  const CasesListScreen({
    super.key,
    this.title = 'الحالات السابقة',
    this.autofocusSearch = false,
    this.selectionMode = false,
    this.baseQuery = const CaseQuery(),
    this.selectionBarBuilder,
    this.tapOpensDetails = false,
    this.header,
  });

  final String title;

  /// محتوى إضافي أعلى القائمة (مثل تنبيه القرارات المعلقة في دفعة).
  final Widget? header;
  final bool autofocusSearch;

  /// وضع التحديد المتعدد (افتراضيًا للتصدير).
  final bool selectionMode;

  /// فلاتر ثابتة لا يمسحها المستخدم (مثل حالات دفعة واردة معينة).
  final CaseQuery baseQuery;

  /// شريط إجراءات مخصص للمحدد؛ الافتراضي زر "تصدير المحدد".
  final Widget Function(Set<String> selected, VoidCallback clearSelection)?
  selectionBarBuilder;

  /// في وضع التحديد: الضغط على البطاقة يفتح التفاصيل ومربع الاختيار يحدد.
  final bool tapOpensDetails;

  @override
  ConsumerState<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends ConsumerState<CasesListScreen> {
  static const int pageSize = 30;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late CaseQuery _query = widget.baseQuery;
  List<CaseListItem> _items = const [];
  CaseCursor? _next;
  int? _count;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  final Set<String> _selected = {};

  /// يُهمل نتائج الطلبات القديمة إذا تغير البحث أثناء تنفيذها.
  int _generation = 0;
  Timer? _searchDebounce;
  Timer? _changesDebounce;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _changes = ref.read(casesRepositoryProvider).watchChanges().listen((_) {
      _changesDebounce?.cancel();
      _changesDebounce = Timer(const Duration(milliseconds: 250), _reload);
    });
    _reload();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _changesDebounce?.cancel();
    _changes?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final repo = ref.read(casesRepositoryProvider);
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        repo.searchCases(_query, limit: pageSize),
        repo.countCases(_query),
      ]);
      if (!mounted || generation != _generation) return;
      final page = results[0] as CasePage;
      setState(() {
        _items = page.items;
        _next = page.next;
        _count = results[1] as int;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _next;
    if (cursor == null || _loadingMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(casesRepositoryProvider)
          .searchCases(_query, after: cursor, limit: pageSize);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [..._items, ...page.items];
        _next = page.next;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 600) _loadMore();
  }

  void _setQuery(CaseQuery query) {
    setState(() {
      _query = query;
      _items = const [];
      _next = null;
      _count = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _reload();
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _setQuery(_query.copyWith(text: text)),
    );
  }

  void _toggleDate(DatePreset preset) => _setQuery(
    _query.copyWith(
      datePreset: _query.datePreset == preset ? DatePreset.any : preset,
      customFrom: null,
      customTo: null,
    ),
  );

  void _toggleExport(ExportState state) => _setQuery(
    _query.copyWith(exportState: _query.exportState == state ? null : state),
  );

  Future<void> _openFilters() async {
    final result = await CaseFiltersSheet.show(context, _query);
    if (result != null) _setQuery(result);
  }

  void _toggleSelected(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  void _selectAllLoaded() {
    setState(() {
      final allSelected = _items.every((i) => _selected.contains(i.id));
      if (allSelected) {
        _selected.removeAll(_items.map((i) => i.id));
      } else {
        _selected.addAll(_items.map((i) => i.id));
      }
    });
  }

  Future<void> _exportSelected() async {
    final done = await ExportFlow.run(
      context,
      ref,
      ExportRequest.selected(_selected.toList()),
    );
    if (done && mounted) Navigator.of(context).pop();
  }

  void _clearAll() {
    _searchController.clear();
    _setQuery(widget.baseQuery);
  }

  bool get _isFiltered =>
      _query.text.trim().isNotEmpty ||
      _query.datePreset != DatePreset.any ||
      _query.exportState != null ||
      _query.caseTypeId != widget.baseQuery.caseTypeId ||
      _query.governorateId != widget.baseQuery.governorateId ||
      _query.reportSourceId != widget.baseQuery.reportSourceId ||
      _query.pendingReviewOnly != widget.baseQuery.pendingReviewOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.selectionMode && _items.isNotEmpty)
            TextButton(
              onPressed: _selectAllLoaded,
              child: Text(
                _items.every((i) => _selected.contains(i.id))
                    ? 'إلغاء التحديد'
                    : 'تحديد الكل',
              ),
            ),
        ],
      ),
      bottomNavigationBar: widget.selectionMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child:
                    widget.selectionBarBuilder?.call(
                      Set.unmodifiable(_selected),
                      () => setState(_selected.clear),
                    ) ??
                    FilledButton.icon(
                      onPressed: _selected.isEmpty ? null : _exportSelected,
                      icon: const Icon(Icons.inventory_2),
                      label: Text('تصدير المحدد (${_selected.length})'),
                    ),
              ),
            )
          : null,
      body: Column(
        children: [
          ?widget.header,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: widget.autofocusSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث برقم الحالة أو الموقع أو أي كلمة',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح البحث',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _setQuery(_query.copyWith(text: ''));
                        },
                      ),
              ),
              onChanged: (text) {
                setState(() {});
                _onSearchChanged(text);
              },
            ),
          ),
          _FilterChipsRow(
            query: _query,
            onToggleDate: _toggleDate,
            onToggleExport: _toggleExport,
            onOpenFilters: _openFilters,
          ),
          if (_count != null && _isFiltered)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  Text('$_count حالة مطابقة'),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('مسح الفلاتر'),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) {
      return Center(child: Text('تعذر تحميل الحالات: $_error'));
    }
    if (_items.isEmpty) {
      return _EmptyState(filtered: _isFiltered, onClear: _clearAll);
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: _GroupedList(
        items: _items,
        controller: _scrollController,
        loadingMore: _loadingMore,
        selected: widget.selectionMode ? _selected : null,
        onToggle: _toggleSelected,
        tapOpensDetails: widget.tapOpensDetails,
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.query,
    required this.onToggleDate,
    required this.onToggleExport,
    required this.onOpenFilters,
  });

  final CaseQuery query;
  final ValueChanged<DatePreset> onToggleDate;
  final ValueChanged<ExportState> onToggleExport;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final advanced = query.advancedFilterCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ActionChip(
            avatar: Icon(
              advanced > 0 ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: 18,
            ),
            label: Text(advanced > 0 ? 'الفلاتر ($advanced)' : 'الفلاتر'),
            visualDensity: VisualDensity.compact,
            onPressed: onOpenFilters,
          ),
          for (final preset in [DatePreset.today, DatePreset.week])
            FilterChip(
              label: Text(preset.label),
              selected: query.datePreset == preset,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onToggleDate(preset),
            ),
          for (final (state, label) in [
            (ExportState.notExported, 'غير مصدرة'),
            (ExportState.exported, 'مصدرة'),
            (ExportState.modifiedAfterExport, 'معدلة بعد التصدير'),
          ])
            FilterChip(
              label: Text(label),
              selected: query.exportState == state,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onToggleExport(state),
            ),
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.items,
    required this.controller,
    required this.loadingMore,
    this.selected,
    this.onToggle,
    this.tapOpensDetails = false,
  });

  final bool tapOpensDetails;
  final List<CaseListItem> items;
  final ScrollController controller;
  final bool loadingMore;

  /// null خارج وضع التحديد.
  final Set<String>? selected;
  final ValueChanged<String>? onToggle;

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today
        .difference(DateTime(day.year, day.month, day.day))
        .inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return ArabicFormat.weekdayDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final entries = <Object>[];
    String? currentDay;
    for (final item in items) {
      final day = _dayLabel(item.occurredAt);
      if (day != currentDay) {
        entries.add(day);
        currentDay = day;
      }
      entries.add(item);
    }

    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      itemCount: entries.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final entry = entries[index];
        if (entry is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              entry,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CaseTile(
            item: entry as CaseListItem,
            selected: selected?.contains(entry.id),
            onToggle: onToggle,
            tapOpensDetails: tapOpensDetails,
          ),
        );
      },
    );
  }
}

class _CaseTile extends StatelessWidget {
  const _CaseTile({
    required this.item,
    this.selected,
    this.onToggle,
    this.tapOpensDetails = false,
  });

  final bool tapOpensDetails;

  final CaseListItem item;

  /// null خارج وضع التحديد.
  final bool? selected;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selecting = selected != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected == true
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: InkWell(
        onTap: selecting && !tapOpensDetails
            ? () => onToggle?.call(item.id)
            : () => AppRoutes.openCaseDetails(context, item.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (selecting)
                Checkbox(
                  value: selected,
                  onChanged: (_) => onToggle?.call(item.id),
                ),
              SizedBox(
                width: 56,
                child: Text(
                  ArabicFormat.time24(item.occurredAt),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.caseTypeLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.placeLabel != null)
                      Text(item.placeLabel!, style: textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusChip(item.displayStatus),
                        if (item.imageCount > 0) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.photo_outlined, size: 18),
                          const SizedBox(width: 2),
                          Text('${item.imageCount}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!selecting || tapOpensDetails) const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.search_off : Icons.folder_open,
            size: 72,
            color: scheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? 'لا توجد حالات مطابقة' : 'لا توجد حالات بعد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          if (filtered)
            TextButton(
              onPressed: onClear,
              child: const Text('مسح البحث والفلاتر'),
            )
          else
            Text(
              'ابدأ بزر "حالة جديدة"',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
