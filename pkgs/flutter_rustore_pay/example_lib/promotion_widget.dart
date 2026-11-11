import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';
import 'package:flutter_rustore_pay/model/promotion.dart';
import 'package:flutter_rustore_pay_example/filter_bottom_sheet.dart';

class PromotionWidget extends StatefulWidget {
  const PromotionWidget({super.key});

  @override
  State<PromotionWidget> createState() => _PromotionWidgetState();
}

class _PromotionWidgetState extends State<PromotionWidget> {
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String? _error;
  String? _loadingPromotionCode;
  Set<PromotionStatus> _statuses = {};
  DateTime? _startDateFrom;
  DateTime? _endDateTo;

  @override
  void initState() {
    super.initState();
    _reloadPromotions();
  }

  Future<void> _reloadPromotions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final promotions =
          await RuStorePayClient.instance.promotionInteractor.getPromotions(
        statuses: _statuses.isEmpty ? null : _statuses.toList(),
        startDateFrom: _startDateFrom?.toIso8601String(),
        endDateTo: _endDateTo?.toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка при загрузке акций: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _showFilters() async {
    final statuses = {..._statuses};
    var startDateFrom = _startDateFrom;
    var endDateTo = _endDateTo;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => FilterBottomSheet(
          onReset: () => setSheetState(() {
            statuses.clear();
            startDateFrom = null;
            endDateTo = null;
          }),
          onApply: () => Navigator.of(sheetContext).pop(true),
          children: [
            MultiChoiceFilter<PromotionStatus>(
              title: 'Статусы акций',
              options: const {
                PromotionStatus.active: 'Активная',
                PromotionStatus.scheduled: 'Запланированная',
              },
              selected: statuses,
              onToggle: (status) => setSheetState(() {
                if (!statuses.add(status)) statuses.remove(status);
              }),
            ),
            const SizedBox(height: 16),
            DateFilterField(
              title: 'Дата начала от (UTC)',
              date: startDateFrom,
              onChanged: (date) => setSheetState(() => startDateFrom = date),
            ),
            const SizedBox(height: 16),
            DateFilterField(
              title: 'Дата завершения до (UTC)',
              date: endDateTo,
              endOfDay: true,
              onChanged: (date) => setSheetState(() => endDateTo = date),
            ),
          ],
        ),
      ),
    );
    if (apply != true || !mounted) return;
    setState(() {
      _statuses = statuses;
      _startDateFrom = startDateFrom;
      _endDateTo = endDateTo;
    });
    await _reloadPromotions();
  }

  Future<void> _showPromotion(String code) async {
    setState(() => _loadingPromotionCode = code);
    try {
      final promotion = await RuStorePayClient.instance.promotionInteractor
          .getPromotion(code);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(promotion.name),
          scrollable: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildDetails(promotion, showProducts: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при получении акции: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingPromotionCode = null);
      }
    }
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text),
    );
  }

  List<Widget> _buildDetails(Promotion promotion, {bool showProducts = false}) {
    final discount = switch (promotion.discountType) {
      PercentDiscount(:final percents) => 'Скидка: $percents%',
      PromoCost(:final value, :final currency) =>
        'Цена по акции: $value (в минимальных единицах $currency)',
    };
    final status = switch (promotion.status) {
      PromotionStatus.active => 'Активная',
      PromotionStatus.scheduled => 'Запланированная',
    };
    final productCodes = promotion.productCodes;
    return [
      _buildText('Код: ${promotion.code}'),
      _buildText('Статус: $status'),
      _buildText(discount),
      _buildText('Начало: ${promotion.startDate}'),
      _buildText('Окончание: ${promotion.endDate ?? 'Не задано'}'),
      if (showProducts)
        _buildText(
          'Продукты: ${productCodes == null ? 'Все продукты' : productCodes.isEmpty ? 'Нет продуктов' : productCodes.join(', ')}',
        ),
    ];
  }

  Widget _buildItem(Promotion promotion) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promotion.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ..._buildDetails(promotion),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadingPromotionCode == null
                    ? () => _showPromotion(promotion.code)
                    : null,
                icon: const Icon(Icons.info_outline),
                label: Text(
                  _loadingPromotionCode == promotion.code
                      ? 'Загрузка…'
                      : 'Инфо',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _reloadPromotions,
      child: _error != null || _promotions.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error ?? 'Нет акций',
                    textAlign: TextAlign.center,
                    style: _error == null
                        ? null
                        : TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _promotions.length,
              itemBuilder: (context, index) => _buildItem(_promotions[index]),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildContent()),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton.icon(
              onPressed: _isLoading || _loadingPromotionCode != null
                  ? null
                  : _showFilters,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Фильтры'),
            ),
          ),
        ),
      ],
    );
  }
}