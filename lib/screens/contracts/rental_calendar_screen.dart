import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/report_period.dart';

/// Month grid calendar for lease starts/ends, checkout returns, and payments.
class RentalCalendarScreen extends StatefulWidget {
  const RentalCalendarScreen({
    super.key,
    required this.contracts,
    required this.returns,
    required this.rentalTransactions,
    required this.customers,
    required this.apartments,
    this.maintenance = const [],
    this.onEditContract,
  });

  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final List<RentalTransactionModel> rentalTransactions;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final List<MaintenanceModel> maintenance;
  final void Function(ContractModel contract)? onEditContract;

  @override
  State<RentalCalendarScreen> createState() => _RentalCalendarScreenState();
}

class _RentalCalendarScreenState extends State<RentalCalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) => _dateOnly(a) == _dateOnly(b);

  String _customerName(int customerId) {
    for (final c in widget.customers) {
      if (c.customerId == customerId) return c.name;
    }
    return 'Unknown';
  }

  String _apartmentNumber(int apartmentId) {
    for (final a in widget.apartments) {
      if (a.apartmentId == apartmentId) {
        return a.number ?? '#$apartmentId';
      }
    }
    return 'Unknown';
  }

  ContractModel? _contractForTransaction(RentalTransactionModel txn) {
    for (final c in widget.contracts) {
      if (c.bookingId == txn.bookingId) return c;
    }
    return null;
  }

  bool _isStartDay(DateTime day) =>
      widget.contracts.any((c) => _sameDay(c.startDate, day));

  bool _isEndDay(DateTime day) =>
      widget.contracts.any((c) => _sameDay(c.endDate, day));

  bool _isReturnDay(DateTime day) =>
      widget.returns.any((r) => _sameDay(r.actualReturnDate, day));

  bool _isPaymentDay(DateTime day) => widget.rentalTransactions.any(
    (t) => _sameDay(t.updatedTransactionDate, day),
  );

  DateTime? _maintenanceDate(MaintenanceModel m) => parseReportDate(m.date);

  bool _isMaintenanceDay(DateTime day) => widget.maintenance.any((m) {
    final d = _maintenanceDate(m);
    return d != null && _sameDay(d, day);
  });

  List<MaintenanceModel> _maintenanceForDay(DateTime day) =>
      widget.maintenance.where((m) {
        final d = _maintenanceDate(m);
        return d != null && _sameDay(d, day);
      }).toList();

  List<ContractModel> _contractsForDay(DateTime day) {
    return widget.contracts.where((c) {
      return _sameDay(c.startDate, day) || _sameDay(c.endDate, day);
    }).toList();
  }

  List<ApartmentReturnModel> _returnsForDay(DateTime day) =>
      widget.returns.where((r) => _sameDay(r.actualReturnDate, day)).toList();

  List<RentalTransactionModel> _paymentsForDay(DateTime day) => widget
      .rentalTransactions
      .where((t) => _sameDay(t.updatedTransactionDate, day))
      .toList();

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDay = null;
    });
  }

  bool _inFocusedMonth(DateTime date) =>
      date.month == _focusedMonth.month && date.year == _focusedMonth.year;

  Widget _allEventsList(ColorScheme scheme) {
    final allEvents = <_CalendarEvent>[];

    for (final c in widget.contracts) {
      if (_inFocusedMonth(c.startDate)) {
        allEvents.add(
          _CalendarEvent(
            date: c.startDate,
            type: _EventType.start,
            contract: c,
          ),
        );
      }
      if (_inFocusedMonth(c.endDate)) {
        allEvents.add(
          _CalendarEvent(date: c.endDate, type: _EventType.end, contract: c),
        );
      }
    }

    for (final r in widget.returns) {
      if (_inFocusedMonth(r.actualReturnDate)) {
        allEvents.add(
          _CalendarEvent(
            date: r.actualReturnDate,
            type: _EventType.returnEvent,
            returnModel: r,
          ),
        );
      }
    }

    for (final t in widget.rentalTransactions) {
      if (_inFocusedMonth(t.updatedTransactionDate)) {
        allEvents.add(
          _CalendarEvent(
            date: t.updatedTransactionDate,
            type: _EventType.payment,
            transaction: t,
          ),
        );
      }
    }

    for (final m in widget.maintenance) {
      final d = _maintenanceDate(m);
      if (d != null && _inFocusedMonth(d)) {
        allEvents.add(
          _CalendarEvent(date: d, type: _EventType.maintenance, maintenance: m),
        );
      }
    }

    allEvents.sort((a, b) => a.date.compareTo(b.date));

    if (allEvents.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No events this month',
        message:
            'Lease, return, payment, and maintenance dates appear here when recorded.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: allEvents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _eventCard(allEvents[i], scheme),
    );
  }

  Widget _selectedDayList(ColorScheme scheme) {
    final selectedContracts = _contractsForDay(_selectedDay!);
    final selectedReturns = _returnsForDay(_selectedDay!);
    final selectedPayments = _paymentsForDay(_selectedDay!);
    final selectedMaintenance = _maintenanceForDay(_selectedDay!);

    if (selectedContracts.isEmpty &&
        selectedReturns.isEmpty &&
        selectedPayments.isEmpty &&
        selectedMaintenance.isEmpty) {
      return const AppEmptyState(
        icon: Icons.event_outlined,
        title: 'No events on this day',
        message: 'Select another date or add bookings and payments.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (selectedContracts.isNotEmpty) ...[
          Text(
            'Agreements',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ...selectedContracts.map((c) {
            final isStart = _sameDay(c.startDate, _selectedDay!);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStart
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      isStart ? Icons.play_arrow_rounded : Icons.flag_rounded,
                      color: isStart
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _customerName(c.customerId),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Apt ${_apartmentNumber(c.apartmentId)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          isStart ? 'Start' : 'End',
                          style: TextStyle(
                            fontSize: 12,
                            color: isStart
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        backgroundColor: isStart
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        side: BorderSide.none,
                      ),
                      if (widget.onEditContract != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => widget.onEditContract!(c),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
        if (selectedReturns.isNotEmpty) ...[
          Text(
            'Returns',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ...selectedReturns.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.purple.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Return #${r.returnId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    r.bookingId != null
                        ? 'Booking #${r.bookingId}'
                        : 'Booking not linked',
                  ),
                  trailing: Chip(
                    label: Text(
                      '\$${r.actualTotalDueAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    backgroundColor: Colors.purple.shade100,
                    side: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (selectedPayments.isNotEmpty) ...[
          Text(
            'Payments',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ...selectedPayments.map((t) {
            final contract = _contractForTransaction(t);
            final customer = contract != null
                ? _customerName(contract.customerId)
                : 'Booking #${t.bookingId}';
            final apartment = contract != null
                ? _apartmentNumber(contract.apartmentId)
                : '—';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.payments_outlined,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    customer,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Apt $apartment'),
                  trailing: Text(
                    '\$${t.paidInitialTotalDueAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
        if (selectedMaintenance.isNotEmpty) ...[
          Text(
            'Maintenance',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ...selectedMaintenance.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(
                      Icons.build_outlined,
                      color: Colors.teal.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    m.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Apt ${_apartmentNumber(int.tryParse(m.apartmentId) ?? 0)}'),
                  trailing: Chip(
                    label: Text(
                      m.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    backgroundColor: Colors.teal.shade100,
                    side: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _eventCard(_CalendarEvent event, ColorScheme scheme) {
    late Color color;
    late IconData icon;
    late String label;
    late String title;
    late String subtitle;

    switch (event.type) {
      case _EventType.start:
        final c = event.contract!;
        color = Colors.green;
        icon = Icons.play_arrow_rounded;
        label = 'Start';
        title = _customerName(c.customerId);
        subtitle = 'Apt ${_apartmentNumber(c.apartmentId)}';
        break;
      case _EventType.end:
        final c = event.contract!;
        color = Colors.red;
        icon = Icons.flag_rounded;
        label = 'End';
        title = _customerName(c.customerId);
        subtitle = 'Apt ${_apartmentNumber(c.apartmentId)}';
        break;
      case _EventType.returnEvent:
        final r = event.returnModel!;
        color = Colors.purple;
        icon = Icons.logout_rounded;
        label = 'Return';
        title = 'Return #${r.returnId}';
        subtitle = r.bookingId != null
            ? 'Booking #${r.bookingId}'
            : 'Booking not linked';
        break;
      case _EventType.payment:
        final t = event.transaction!;
        final contract = _contractForTransaction(t);
        color = Colors.orange;
        icon = Icons.payments_outlined;
        label = 'Payment';
        title = contract != null
            ? _customerName(contract.customerId)
            : 'Booking #${t.bookingId}';
        subtitle = contract != null
            ? 'Apt ${_apartmentNumber(contract.apartmentId)} • \$${t.paidInitialTotalDueAmount.toStringAsFixed(0)}'
            : '\$${t.paidInitialTotalDueAmount.toStringAsFixed(0)}';
        break;
      case _EventType.maintenance:
        final m = event.maintenance!;
        color = Colors.teal;
        icon = Icons.build_outlined;
        label = 'Maintenance';
        title = m.description;
        subtitle =
            'Apt ${_apartmentNumber(int.tryParse(m.apartmentId) ?? 0)} • \$${m.cost.toStringAsFixed(0)}';
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          '${event.date.day} ${_monthName(_focusedMonth.month)}',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(subtitle),
          ],
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(label, style: TextStyle(fontSize: 12, color: color)),
          backgroundColor: color.withValues(alpha: 0.15),
          side: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot(color: Colors.green, label: 'Start'),
              _LegendDot(color: Colors.red, label: 'End'),
              _LegendDot(color: Colors.purple, label: 'Return'),
              _LegendDot(color: Colors.orange, label: 'Payment'),
              _LegendDot(color: Colors.teal, label: 'Maintenance'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final day = index - startWeekday + 1;
              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                day,
              );
              final isToday = _sameDay(date, now);
              final isSelected =
                  _selectedDay != null && _sameDay(date, _selectedDay!);
              final isStart = _isStartDay(date);
              final isEnd = _isEndDay(date);
              final isReturn = _isReturnDay(date);
              final isPayment = _isPaymentDay(date);
              final isMaintenance = _isMaintenanceDay(date);
              final hasDots =
                  isStart || isEnd || isReturn || isPayment || isMaintenance;

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : isToday
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? scheme.onPrimary
                              : isToday
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                      if (hasDots)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isStart) const _Dot(color: Colors.green),
                            if (isStart &&
                                (isEnd || isReturn || isPayment || isMaintenance))
                              const SizedBox(width: 2),
                            if (isEnd) const _Dot(color: Colors.red),
                            if (isEnd && (isReturn || isPayment || isMaintenance))
                              const SizedBox(width: 2),
                            if (isReturn) const _Dot(color: Colors.purple),
                            if (isReturn && (isPayment || isMaintenance))
                              const SizedBox(width: 2),
                            if (isPayment) const _Dot(color: Colors.orange),
                            if (isPayment && isMaintenance)
                              const SizedBox(width: 2),
                            if (isMaintenance) const _Dot(color: Colors.teal),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: _selectedDay == null
              ? _allEventsList(scheme)
              : _selectedDayList(scheme),
        ),
      ],
    );
  }

  String _monthName(int month) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month];
}

enum _EventType { start, end, returnEvent, payment, maintenance }

class _CalendarEvent {
  const _CalendarEvent({
    required this.date,
    required this.type,
    this.contract,
    this.returnModel,
    this.transaction,
    this.maintenance,
  });

  final DateTime date;
  final _EventType type;
  final ContractModel? contract;
  final ApartmentReturnModel? returnModel;
  final RentalTransactionModel? transaction;
  final MaintenanceModel? maintenance;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
