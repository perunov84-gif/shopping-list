import 'package:flutter/material.dart';
import 'package:flutter_rustore_pay/api/flutter_rustore_pay_client.dart';
import 'package:flutter_rustore_pay/model/coupon.dart';
import 'package:flutter_rustore_pay_example/filter_bottom_sheet.dart';

class CouponWidget extends StatefulWidget {
  const CouponWidget({super.key});

  @override
  State<CouponWidget> createState() => _CouponWidgetState();
}

enum _CouponSection { generators, userCoupons }

class _CouponFilters {
  const _CouponFilters({
    this.productScopes = const {},
    this.firstPurchaseOnly,
    this.userStatuses = const {},
    this.startDate,
    this.endDate,
  });

  final Set<CouponProductScope> productScopes;
  final bool? firstPurchaseOnly;
  final Set<CouponUserStatus> userStatuses;
  final DateTime? startDate;
  final DateTime? endDate;
}

class _CouponWidgetState extends State<CouponWidget> {
  _CouponSection _section = _CouponSection.generators;
  List<CouponGenerator> _generators = [];
  List<UserCouponInfo> _userCoupons = [];
  bool _isLoading = true;
  String? _error;
  int _requestId = 0;
  _CouponFilters _generatorsFilter = const _CouponFilters();
  _CouponFilters _userCouponsFilter = const _CouponFilters();

  @override
  void initState() {
    super.initState();
    _reloadCoupons();
  }

  Future<void> _reloadCoupons() async {
    final requestId = ++_requestId;
    final section = _section;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      List<CouponGenerator> generators = [];
      List<UserCouponInfo> userCoupons = [];
      final interactor = RuStorePayClient.instance.couponInteractor;
      if (section == _CouponSection.generators) {
        final filter = _generatorsFilter;
        generators = await interactor.getCouponGenerators(
          couponProductScopes: filter.productScopes.isEmpty
              ? null
              : filter.productScopes.toList(),
          firstPurchaseOnly: filter.firstPurchaseOnly,
          deepLinkDateIntervalStart: filter.startDate?.toIso8601String(),
          deepLinkDateIntervalEnd: filter.endDate?.toIso8601String(),
        );
      } else {
        final filter = _userCouponsFilter;
        userCoupons = await interactor.getUserCouponsInfo(
          couponProductScopes: filter.productScopes.isEmpty
              ? null
              : filter.productScopes.toList(),
          firstPurchaseOnly: filter.firstPurchaseOnly,
          couponUserStatuses:
              filter.userStatuses.isEmpty ? null : filter.userStatuses.toList(),
          couponDateIntervalStart: filter.startDate?.toIso8601String(),
          couponDateIntervalEnd: filter.endDate?.toIso8601String(),
        );
      }
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _generators = generators;
        _userCoupons = userCoupons;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'Ошибка при загрузке купонов: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _showFilters() async {
    final section = _section;
    final showGenerators = section == _CouponSection.generators;
    final filter = showGenerators ? _generatorsFilter : _userCouponsFilter;
    final productScopes = {...filter.productScopes};
    final userStatuses = {...filter.userStatuses};
    var firstPurchaseOnly = filter.firstPurchaseOnly;
    var startDate = filter.startDate;
    var endDate = filter.endDate;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => FilterBottomSheet(
          onReset: () => setSheetState(() {
            productScopes.clear();
            userStatuses.clear();
            firstPurchaseOnly = null;
            startDate = null;
            endDate = null;
          }),
          onApply: () => Navigator.of(sheetContext).pop(true),
          children: [
            MultiChoiceFilter<CouponProductScope>(
              title: 'Область применения купона',
              options: const {
                CouponProductScope.allProducts: 'Все продукты',
                CouponProductScope.consumableProducts: 'Потребляемые продукты',
                CouponProductScope.nonConsumableProducts:
                    'Непотребляемые продукты',
              },
              selected: productScopes,
              onToggle: (scope) => setSheetState(() {
                if (!productScopes.add(scope)) productScopes.remove(scope);
              }),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Только первая покупка',
                border: OutlineInputBorder(),
              ),
              child: DropdownButton<bool>(
                value: firstPurchaseOnly,
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Без фильтра'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Без фильтра')),
                  DropdownMenuItem(value: true, child: Text('Да')),
                  DropdownMenuItem(value: false, child: Text('Нет')),
                ],
                onChanged: (value) =>
                    setSheetState(() => firstPurchaseOnly = value),
              ),
            ),
            if (!showGenerators) ...[
              const SizedBox(height: 16),
              MultiChoiceFilter<CouponUserStatus>(
                title: 'Статусы купонов',
                options: const {
                  CouponUserStatus.active: 'Активен',
                  CouponUserStatus.expired: 'Истёк срок действия',
                  CouponUserStatus.redeemed: 'Использован',
                  CouponUserStatus.notActivated: 'Не активирован',
                },
                selected: userStatuses,
                onToggle: (status) => setSheetState(() {
                  if (!userStatuses.add(status)) userStatuses.remove(status);
                }),
              ),
            ],
            const SizedBox(height: 16),
            DateFilterField(
              title: showGenerators
                  ? 'Ссылка действует с (UTC)'
                  : 'Купон действует с (UTC)',
              date: startDate,
              onChanged: (date) => setSheetState(() => startDate = date),
            ),
            const SizedBox(height: 16),
            DateFilterField(
              title: showGenerators
                  ? 'Ссылка действует до (UTC)'
                  : 'Купон действует до (UTC)',
              date: endDate,
              endOfDay: true,
              onChanged: (date) => setSheetState(() => endDate = date),
            ),
          ],
        ),
      ),
    );
    if (apply != true || !mounted) return;
    final updatedFilter = _CouponFilters(
      productScopes: productScopes,
      firstPurchaseOnly: firstPurchaseOnly,
      userStatuses: userStatuses,
      startDate: startDate,
      endDate: endDate,
    );
    setState(() {
      if (showGenerators) {
        _generatorsFilter = updatedFilter;
      } else {
        _userCouponsFilter = updatedFilter;
      }
    });
    await _reloadCoupons();
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text),
    );
  }

  Widget _buildCard(String title, List<Widget> details) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildGenerator(CouponGenerator generator) {
    return _buildCard(generator.couponName, [
      _buildText(generator.couponShortDescription),
      _buildText('Продукты: ${generator.couponProductScope.name}'),
      _buildText(
          'Только первая покупка: ${generator.firstPurchaseOnly ? 'Да' : 'Нет'}'),
      _buildText('Номинал (мин. ед. валюты): ${generator.couponNominal}'),
      _buildText('Максимальное количество: ${generator.couponMaxQuantity}'),
      if (generator.minProductPrice != null)
        _buildText(
            'Минимальная цена (мин. ед. валюты): ${generator.minProductPrice}'),
      _buildText('Тип срока действия: ${generator.intervalCouponType}'),
      _buildText(
          'Ссылка действует с: ${generator.deepLinkDateInterval.startDate}'),
      _buildText(
          'Ссылка действует до: ${generator.deepLinkDateInterval.endDate}'),
      SelectableText('Ссылка: ${generator.deepLink}'),
    ]);
  }

  Widget _buildUserCoupon(UserCouponInfo coupon) {
    final interval = coupon.couponDateInterval;
    return _buildCard(coupon.couponName, [
      _buildText(coupon.couponShortDescription),
      _buildText('ID: ${coupon.couponId ?? 'Не задан'}'),
      _buildText('Статус: ${coupon.couponUserStatus.name}'),
      _buildText('Продукты: ${coupon.couponProductScope.name}'),
      _buildText(
          'Только первая покупка: ${coupon.firstPurchaseOnly ? 'Да' : 'Нет'}'),
      _buildText('Номинал (мин. ед. валюты): ${coupon.couponNominal}'),
      if (coupon.minProductPrice != null)
        _buildText(
            'Минимальная цена (мин. ед. валюты): ${coupon.minProductPrice}'),
      _buildText('Тип срока действия: ${coupon.intervalCouponType}'),
      if (interval != null) ...[
        _buildText('Купон действует с: ${interval.startDate}'),
        _buildText('Купон действует до: ${interval.endDate}'),
      ],
      _buildText(
          'Ссылка действует с: ${coupon.deepLinkDateInterval.startDate}'),
      _buildText('Ссылка действует до: ${coupon.deepLinkDateInterval.endDate}'),
      SelectableText('Ссылка: ${coupon.deepLink}'),
    ]);
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final showGenerators = _section == _CouponSection.generators;
    final count = showGenerators ? _generators.length : _userCoupons.length;
    return RefreshIndicator(
      onRefresh: _reloadCoupons,
      child: _error != null || count == 0
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error ??
                        (showGenerators
                            ? 'Нет генераторов купонов'
                            : 'Нет купонов пользователя'),
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
              itemCount: count,
              itemBuilder: (context, index) => showGenerators
                  ? _buildGenerator(_generators[index])
                  : _buildUserCoupon(_userCoupons[index]),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<_CouponSection>(
            segments: const [
              ButtonSegment(
                value: _CouponSection.generators,
                label: Text('Генераторы'),
              ),
              ButtonSegment(
                value: _CouponSection.userCoupons,
                label: Text('Купоны пользователя'),
              ),
            ],
            selected: {_section},
            onSelectionChanged: (selection) {
              final section = selection.first;
              if (section == _section) return;
              setState(() => _section = section);
              _reloadCoupons();
            },
          ),
        ),
        Expanded(child: _buildContent()),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _showFilters,
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Фильтры'),
            ),
          ),
        ),
      ],
    );
  }
}