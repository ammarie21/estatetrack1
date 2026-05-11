import 'package:flutter/material.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/screens/payments/expense_form_screen.dart';
import 'package:estatetrack1/screens/payments/rental_transaction_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    super.key,
    required this.rentalTransactions,
    required this.bookings,
    required this.returns,
    required this.customers,
    required this.apartments,
    required this.expenses,
    required this.onRentalTransactionsChanged,
    required this.onExpensesChanged,
  });

  final List<RentalTransactionModel> rentalTransactions;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final List<ExpenseModel> expenses;
  final void Function(List<RentalTransactionModel>) onRentalTransactionsChanged;
  final void Function(List<ExpenseModel>) onExpensesChanged;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<RentalTransactionModel> _transactions;
  late List<ExpenseModel> _expenses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transactions = List.from(widget.rentalTransactions);
    _expenses = List.from(widget.expenses);
  }

  @override
  void didUpdateWidget(PaymentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rentalTransactions != widget.rentalTransactions) {
      _transactions = List.from(widget.rentalTransactions);
    }
    if (oldWidget.expenses != widget.expenses) {
      _expenses = List.from(widget.expenses);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _nextTransactionId() {
    if (_transactions.isEmpty) return 1;
    return _transactions
            .map((e) => e.transactionId)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  int _nextExpenseId() {
    if (_expenses.isEmpty) return 1;
    return _expenses.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  void _notifyTransactions() =>
      widget.onRentalTransactionsChanged(_transactions);

  void _notifyExpenses() => widget.onExpensesChanged(_expenses);

  Future<void> _openTransactionForm({RentalTransactionModel? existing}) async {
    final result = await Navigator.of(context).push<RentalTransactionModel>(
      MaterialPageRoute(
        builder: (context) => RentalTransactionFormScreen(
          existing: existing,
          bookings: widget.bookings,
          returns: widget.returns,
          customers: widget.customers,
          apartments: widget.apartments,
        ),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i =
            _transactions.indexWhere((t) => t.transactionId == existing.transactionId);
        if (i >= 0) {
          _transactions[i] = RentalTransactionModel(
            transactionId: existing.transactionId,
            bookingId: result.bookingId,
            returnId: result.returnId,
            paidInitialTotalDueAmount: result.paidInitialTotalDueAmount,
            actualTotalDueAmount: result.actualTotalDueAmount,
            totalRemaining: result.totalRemaining,
            totalRefundedAmount: result.totalRefundedAmount,
            transactionStatus: result.transactionStatus,
            updatedTransactionDate: result.updatedTransactionDate,
            paymentDetails: result.paymentDetails,
          );
        }
      } else {
        _transactions.add(
          RentalTransactionModel(
            transactionId: _nextTransactionId(),
            bookingId: result.bookingId,
            returnId: result.returnId,
            paidInitialTotalDueAmount: result.paidInitialTotalDueAmount,
            actualTotalDueAmount: result.actualTotalDueAmount,
            totalRemaining: result.totalRemaining,
            totalRefundedAmount: result.totalRefundedAmount,
            transactionStatus: result.transactionStatus,
            updatedTransactionDate: result.updatedTransactionDate,
            paymentDetails: result.paymentDetails,
          ),
        );
      }
    });
    _notifyTransactions();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Transaction updated' : 'Transaction added',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(RentalTransactionModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('Remove this rental transaction record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() =>
        _transactions.removeWhere((e) => e.transactionId == t.transactionId));
    _notifyTransactions();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted')),
    );
  }

  Future<void> _openExpenseForm({ExpenseModel? existing}) async {
    final result = await Navigator.of(context).push<ExpenseModel>(
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _expenses.indexWhere((e) => e.id == existing.id);
        if (i >= 0) {
          _expenses[i] = ExpenseModel(
            id: existing.id,
            category: result.category,
            amount: result.amount,
            date: result.date,
          );
        }
      } else {
        _expenses.add(ExpenseModel(
          id: _nextExpenseId(),
          category: result.category,
          amount: result.amount,
          date: result.date,
        ));
      }
    });
    _notifyExpenses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing != null ? 'Expense updated' : 'Expense added'),
      ),
    );
  }

  Future<void> _confirmDeleteExpense(ExpenseModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text('Remove this expense record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _expenses.removeWhere((x) => x.id == e.id));
    _notifyExpenses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense deleted')),
    );
  }

  String _bookingSubtitle(RentalTransactionModel t) {
    RentalBookingModel? b;
    for (final x in widget.bookings) {
      if (x.bookingId == t.bookingId) {
        b = x;
        break;
      }
    }
    if (b == null) return 'Booking ${t.bookingId}';
    String? cust;
    for (final c in widget.customers) {
      if (c.customerId == b.customerId) {
        cust = c.name;
        break;
      }
    }
    String? apt;
    for (final a in widget.apartments) {
      if (a.apartmentId == b.apartmentId) {
        apt = a.number ?? '#${a.apartmentId}';
        break;
      }
    }
    return '${cust ?? 'Customer'} · ${apt ?? 'Unit'}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final tx = _tabController.index == 0;
          return FloatingActionButton.extended(
            heroTag: 'fab_payments',
            onPressed: () {
              if (tx) {
                _openTransactionForm();
              } else {
                _openExpenseForm();
              }
            },
            icon: Icon(tx ? Icons.post_add_rounded : Icons.add_rounded),
            label: Text(tx ? 'New transaction' : 'New expense'),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final tx = _tabController.index == 0;
              return AppFlowBanner(
                icon: tx ? Icons.sync_alt_rounded : Icons.savings_outlined,
                text: tx
                    ? 'Each line is a Rental Transaction: tie it to a Rental Booking. '
                        'Link an Apartment Return when you are reconciling checkout.'
                    : 'Expenses are internal costs — they do not replace Rental Transactions for tenant rent.',
              );
            },
          ),
          Material(
            color: scheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Transactions'),
                Tab(text: 'Expenses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _transactionsList(scheme),
                _expensesList(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionsList(ColorScheme scheme) {
    if (_transactions.isEmpty) {
      return AppEmptyState(
        icon: Icons.payments_outlined,
        title: 'No rental transactions',
        message:
            'Create a transaction for each installment or settlement. Pick the Rental Booking; '
            'add the Apartment Return when you are closing out after checkout.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = _transactions[index];
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Booking #${t.bookingId}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                AppStatusChip(
                  label: t.transactionStatus,
                  tone: chipToneForBookingStatus(t.transactionStatus),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_bookingSubtitle(t)),
                  const SizedBox(height: 4),
                  Text(
                    'Paid \$${t.paidInitialTotalDueAmount.toStringAsFixed(2)} · '
                    'Remaining \$${t.totalRemaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${t.updatedTransactionDate.toString().split(' ')[0]}'
                    '${t.returnId != null ? ' · Linked return #${t.returnId}' : ' · No return linked'}',
                    style: TextStyle(
                      color: scheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openTransactionForm(existing: t),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: () => _confirmDeleteTransaction(t),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _expensesList(ColorScheme scheme) {
    if (_expenses.isEmpty) {
      return AppEmptyState(
        icon: Icons.category_outlined,
        title: 'No expenses logged',
        message: 'Track utilities, maintenance, and other building costs here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _expenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = _expenses[index];
        return Card(
          child: ListTile(
            title: Text(
              e.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Date: ${e.date}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${e.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.tertiary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openExpenseForm(existing: e),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: () => _confirmDeleteExpense(e),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
