import 'package:flutter/material.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/payment_model.dart';
import 'package:estatetrack1/screens/payments/expense_form_screen.dart';
import 'package:estatetrack1/screens/payments/payment_form_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    super.key,
    required this.payments,
    required this.expenses,
    required this.onPaymentsChanged,
    required this.onExpensesChanged,
  });

  final List<PaymentModel> payments;
  final List<ExpenseModel> expenses;
  final void Function(List<PaymentModel>) onPaymentsChanged;
  final void Function(List<ExpenseModel>) onExpensesChanged;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<PaymentModel> _payments;
  late List<ExpenseModel> _expenses;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _payments = List.from(widget.payments);
    _expenses = List.from(widget.expenses);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _nextPaymentId() {
    if (_payments.isEmpty) return 1;
    return _payments.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  int _nextExpenseId() {
    if (_expenses.isEmpty) return 1;
    return _expenses.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  void _notifyPayments() => widget.onPaymentsChanged(_payments);
  void _notifyExpenses() => widget.onExpensesChanged(_expenses);

  Future<void> _openPaymentForm({PaymentModel? existing}) async {
    final result = await Navigator.of(context).push<PaymentModel>(
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _payments.indexWhere((p) => p.id == existing.id);
        if (i >= 0) {
          _payments[i] = PaymentModel(
            id: existing.id,
            customer: result.customer,
            apartment: result.apartment,
            amount: result.amount,
            date: result.date,
          );
        }
      } else {
        _payments.add(PaymentModel(
          id: _nextPaymentId(),
          customer: result.customer,
          apartment: result.apartment,
          amount: result.amount,
          date: result.date,
        ));
      }
    });
    _notifyPayments();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing != null ? 'Payment updated' : 'Payment added'),
      ),
    );
  }

  Future<void> _confirmDeletePayment(PaymentModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment?'),
        content: const Text('Remove this payment record?'),
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

    setState(() => _payments.removeWhere((e) => e.id == p.id));
    _notifyPayments();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment deleted')),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return FloatingActionButton(
            heroTag: 'fab_payments',
            onPressed: () {
              if (_tabController.index == 0) {
                _openPaymentForm();
              } else {
                _openExpenseForm();
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
      body: Column(
        children: [
          Material(
            color: scheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Payments'),
                Tab(text: 'Expenses'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _paymentsList(scheme),
                _expensesList(scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentsList(ColorScheme scheme) {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text('No payments yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to add a payment.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _payments[index];
        return Card(
          child: ListTile(
            title: Text(p.customer,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apartment: ${p.apartment}'),
                  Text('Date: ${p.date}'),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${p.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: scheme.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openPaymentForm(existing: p),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: () => _confirmDeletePayment(p),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: scheme.outline),
            const SizedBox(height: 16),
            Text('No expenses yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to add an expense.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = _expenses[index];
        return Card(
          child: ListTile(
            title: Text(e.category,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Date: ${e.date}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${e.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: scheme.tertiary),
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