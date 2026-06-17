import 'package:flutter/material.dart';

import 'package:estatetrack1/data/staff_user_registry.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';
import 'package:estatetrack1/utils/payment_details_parser.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.contracts,
    required this.bookings,
    required this.rentalTransactions,
    required this.apartments,
    required this.buildings,
    this.returns = const [],
  });

  final CustomerModel customer;
  final List<ContractModel> contracts;
  final List<RentalBookingModel> bookings;
  final List<RentalTransactionModel> rentalTransactions;
  final List<ApartmentModel> apartments;
  final List<BuildingModel> buildings;
  final List<ApartmentReturnModel> returns;

  List<ContractModel> get _customerContracts =>
      contracts.where((c) => c.customerId == customer.customerId).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

  Set<int> get _customerBookingIds => bookings
      .where((b) => b.customerId == customer.customerId)
      .map((b) => b.bookingId)
      .toSet();

  List<RentalTransactionModel> get _customerTransactions =>
      rentalTransactions
          .where((t) => _customerBookingIds.contains(t.bookingId))
          .toList()
        ..sort(
          (a, b) =>
              b.updatedTransactionDate.compareTo(a.updatedTransactionDate),
        );

  List<ApartmentReturnModel> get _customerReturns =>
      returns
          .where(
            (r) =>
                r.bookingId != null &&
                _customerBookingIds.contains(r.bookingId),
          )
          .toList()
        ..sort((a, b) => b.actualReturnDate.compareTo(a.actualReturnDate));

  double get _totalPaid => _customerTransactions.fold(
    0.0,
    (sum, t) => sum + t.paidInitialTotalDueAmount,
  );

  double get _totalOutstanding =>
      _customerTransactions.fold(0.0, (sum, t) => sum + t.totalRemaining);

  ContractModel? get _activeContract {
    for (final contract in _customerContracts) {
      if (contract.status == 'Active') return contract;
    }
    return null;
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  AppChipTone _leaseExpiryTone(DateTime endDate) {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return AppChipTone.negative;
    if (daysLeft <= 30) return AppChipTone.warning;
    return AppChipTone.positive;
  }

  String _leaseExpiryLabel(DateTime endDate) {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'Expired';
    if (daysLeft <= 30) return '$daysLeft days left';
    return 'Active';
  }

  String _bookingTypeLabel(int bookingType) =>
      bookingType == 1 ? 'Daily' : 'Monthly';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final active = _activeContract;
    final activeBooking = active == null
        ? null
        : bookings.where((b) => b.bookingId == active.bookingId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, kAppListBottomInset),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.phone,
                          style: t.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (customer.nationalNum.isNotEmpty)
                          Text(
                            'National ID: ${customer.nationalNum}',
                            style: t.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _DetailStatCard(
                label: 'Total paid',
                value: '\$${_totalPaid.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
                accent: Colors.green.shade700,
              ),
              _DetailStatCard(
                label: 'Outstanding',
                value: '\$${_totalOutstanding.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                accent: _totalOutstanding > 0
                    ? Colors.amber.shade800
                    : scheme.primary,
              ),
              _DetailStatCard(
                label: 'Agreements',
                value: '${_customerContracts.length}',
                icon: Icons.description_outlined,
                accent: scheme.primary,
              ),
              _DetailStatCard(
                label: 'Payments',
                value: '${_customerTransactions.length}',
                icon: Icons.receipt_long_outlined,
                accent: scheme.secondary,
              ),
            ],
          ),
          if (active != null) ...[
            const SizedBox(height: 20),
            const AppSectionHeader(
              title: 'Active agreement',
              subtitle: 'Derived from backend booking',
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(
                  '${_formatDate(active.startDate)} → ${_formatDate(active.endDate)}',
                ),
                subtitle: Text(
                  [
                    apartmentDisplayLabelById(
                      active.apartmentId,
                      apartments,
                      buildings,
                    ),
                    _bookingTypeLabel(active.bookingType),
                    '\$${active.totalAmount.toStringAsFixed(0)} estimated',
                    'Staff: ${staffUserName(activeBooking?.userId ?? 0)}',
                    if (activeBooking?.initialCheckNotes?.trim().isNotEmpty ==
                        true)
                      activeBooking!.initialCheckNotes!.trim(),
                  ].join(' · '),
                ),
                trailing: AppStatusChip(
                  label: _leaseExpiryLabel(active.endDate),
                  tone: _leaseExpiryTone(active.endDate),
                ),
              ),
            ),
          ],
          if (_customerContracts.isNotEmpty) ...[
            const SizedBox(height: 20),
            AppSectionHeader(
              title: 'All agreements',
              subtitle: '${_customerContracts.length} total',
            ),
            const SizedBox(height: 8),
            ..._customerContracts.map((c) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.assignment_outlined,
                    color: scheme.primary,
                  ),
                  title: Text(
                    apartmentDisplayLabelById(
                      c.apartmentId,
                      apartments,
                      buildings,
                    ),
                  ),
                  subtitle: Text(
                    '${_formatDate(c.startDate)} → ${_formatDate(c.endDate)} · '
                    '${_bookingTypeLabel(c.bookingType)}',
                  ),
                  trailing: AppStatusChip(
                    label: c.status,
                    tone: chipToneForLeaseStatus(c.status),
                  ),
                ),
              );
            }),
          ],
          if (_customerTransactions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const AppSectionHeader(
              title: 'Payment history',
              subtitle: 'From booking rentalPrice and checkout records',
            ),
            const SizedBox(height: 8),
            ..._customerTransactions.map((tx) {
              final booking = bookings
                  .where((b) => b.bookingId == tx.bookingId)
                  .firstOrNull;
              final apartmentLabel = booking == null
                  ? 'Booking #${tx.bookingId}'
                  : apartmentDisplayLabelById(
                      booking.apartmentId,
                      apartments,
                      buildings,
                    );
              final paymentNotes = summarizePaymentDetails(tx.paymentDetails);
              final staffLabel = booking == null
                  ? null
                  : staffUserName(booking.userId);
              final subtitleParts = [
                _formatDate(tx.updatedTransactionDate),
                apartmentLabel,
                if (paymentNotes.isNotEmpty) paymentNotes,
                if (staffLabel != null) 'Staff: $staffLabel',
              ];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '\$${tx.paidInitialTotalDueAmount.toStringAsFixed(0)} paid',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(subtitleParts.join(' · ')),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppStatusChip(
                        label: tx.transactionStatus,
                        tone: chipToneForBookingStatus(tx.transactionStatus),
                      ),
                      if (tx.totalRemaining > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '\$${tx.totalRemaining.toStringAsFixed(0)} due',
                          style: t.labelSmall?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          if (_customerReturns.isNotEmpty) ...[
            const SizedBox(height: 20),
            AppSectionHeader(
              title: 'Check-out records',
              subtitle: '${_customerReturns.length} from backend returns',
            ),
            const SizedBox(height: 8),
            ..._customerReturns.map((item) {
              final booking = bookings
                  .where((b) => b.bookingId == item.bookingId)
                  .firstOrNull;
              final apartmentLabel = booking == null
                  ? 'Booking #${item.bookingId}'
                  : apartmentDisplayLabelById(
                      booking.apartmentId,
                      apartments,
                      buildings,
                    );
              final notes = item.finalCheckNotes?.trim();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    child: Icon(
                      Icons.logout_rounded,
                      color: scheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    apartmentLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      _formatDate(item.actualReturnDate),
                      '${item.actualRentalDays} days',
                      if (item.additionalCharges > 0)
                        '+\$${item.additionalCharges.toStringAsFixed(0)} charges',
                      if (notes != null && notes.isNotEmpty) notes,
                    ].join(' · '),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${item.actualTotalDueAmount.toStringAsFixed(0)}',
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.totalRemaining > 0)
                        Text(
                          '\$${item.totalRemaining.toStringAsFixed(0)} due',
                          style: t.labelSmall?.copyWith(color: scheme.error),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (_customerContracts.isEmpty &&
              _customerTransactions.isEmpty &&
              _customerReturns.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: AppEmptyState(
                icon: Icons.history_outlined,
                title: 'No rental activity yet',
                message:
                    'Agreements and payments appear here once bookings are created.',
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              label,
              style: t.labelSmall?.copyWith(
                color: accent.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
