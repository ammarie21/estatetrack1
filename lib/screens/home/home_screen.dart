import 'package:flutter/material.dart';
import 'package:estatetrack1/data/mock_auth_repository.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/payment_model.dart';
import 'package:estatetrack1/screens/admin/admin_accounts_screen.dart';
import 'package:estatetrack1/screens/buildings/buildings_screen.dart';
import 'package:estatetrack1/screens/contracts/contracts_screen.dart';
import 'package:estatetrack1/screens/customers/customers_screen.dart';
import 'package:estatetrack1/screens/dashboard/dashboard_screen.dart';
import 'package:estatetrack1/screens/login/login_screen.dart';
import 'package:estatetrack1/screens/payments/payments_screen.dart';
import 'package:estatetrack1/screens/reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.account, super.key});
  final AccountModel account;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<CustomerModel> _customers = [
    const CustomerModel(
      customerId: 1,
      name: 'Sara Al-Masri',
      phone: '+962 79 000 1111',
      nationalNum: '9900123456',
      numberOfRentedApartments: 1,
      idNumber: '9900123456',
      apartment: 'A-101',
      startDate: '2024-06-01',
      endDate: '2025-05-31',
    ),
    const CustomerModel(
      customerId: 2,
      name: 'Omar Haddad',
      phone: '+962 78 222 3333',
      nationalNum: '8800654321',
      numberOfRentedApartments: 1,
      idNumber: '8800654321',
      apartment: 'B-204',
      startDate: '2024-01-15',
      endDate: '2025-01-14',
    ),
    const CustomerModel(
      customerId: 3,
      name: 'Layla Nasser',
      phone: '+962 77 444 5555',
      nationalNum: '7700112233',
      numberOfRentedApartments: 1,
      idNumber: '7700112233',
      apartment: 'C-310',
      startDate: '2023-09-01',
      endDate: '2024-08-31',
    ),
  ];

  final List<ApartmentModel> _apartments = [
    const ApartmentModel(
      apartmentId: 1,
      buildingId: 1,
      typeId: 1,
      sizeM2: 85,
      rentPricePerMonth: 450,
      rentPricePerDay: 20,
      isAvailable: false,
      bedrooms: 2,
      bathrooms: 2,
      hasBalcony: true,
      furnished: false,
      hasInternet: true,
      parking: true,
      elevator: true,
      number: 'A-101',
      location: 'Tower A, Floor 1',
    ),
    const ApartmentModel(
      apartmentId: 2,
      buildingId: 1,
      typeId: 1,
      sizeM2: 80,
      rentPricePerMonth: 420,
      rentPricePerDay: 18,
      isAvailable: true,
      bedrooms: 2,
      bathrooms: 1,
      hasBalcony: false,
      furnished: false,
      hasInternet: true,
      parking: false,
      elevator: true,
      number: 'A-102',
      location: 'Tower A, Floor 1',
    ),
    const ApartmentModel(
      apartmentId: 3,
      buildingId: 2,
      typeId: 2,
      sizeM2: 120,
      rentPricePerMonth: 680,
      rentPricePerDay: 30,
      isAvailable: false,
      bedrooms: 3,
      bathrooms: 2,
      hasBalcony: true,
      furnished: true,
      hasInternet: true,
      parking: true,
      elevator: true,
      number: 'B-204',
      location: 'Tower B, Floor 2',
    ),
    const ApartmentModel(
      apartmentId: 4,
      buildingId: 2,
      typeId: 2,
      sizeM2: 115,
      rentPricePerMonth: 650,
      rentPricePerDay: 28,
      isAvailable: false,
      bedrooms: 3,
      bathrooms: 2,
      hasBalcony: true,
      furnished: false,
      hasInternet: true,
      parking: true,
      elevator: true,
      number: 'B-205',
      location: 'Tower B, Floor 2',
    ),
    const ApartmentModel(
      apartmentId: 5,
      buildingId: 3,
      typeId: 3,
      sizeM2: 160,
      rentPricePerMonth: 890,
      rentPricePerDay: 40,
      isAvailable: true,
      bedrooms: 4,
      bathrooms: 3,
      hasBalcony: true,
      furnished: true,
      hasInternet: true,
      parking: true,
      elevator: true,
      number: 'C-310',
      location: 'Tower C, Floor 3',
    ),
  ];

  final List<PaymentModel> _payments = [
    const PaymentModel(
      id: 1,
      customer: 'Sara Al-Masri',
      apartment: 'A-101',
      amount: 450,
      date: '2025-03-01',
    ),
    const PaymentModel(
      id: 2,
      customer: 'Omar Haddad',
      apartment: 'B-204',
      amount: 680,
      date: '2025-03-02',
    ),
  ];

  final List<ExpenseModel> _expenses = [
    const ExpenseModel(
      id: 1,
      category: 'Utilities',
      amount: 180,
      date: '2025-03-06',
    ),
    const ExpenseModel(
      id: 2,
      category: 'Cleaning',
      amount: 120,
      date: '2025-03-10',
    ),
  ];

  void _logout() {
    MockAuthRepository.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
          builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.account.isAdmin;
    final scheme = Theme.of(context).colorScheme;

    final titles = [
      'Dashboard',
      'Customers',
      'Buildings',
      'Contracts',
      'Payments',
      'Reports',
      if (isAdmin) 'Accounts',
    ];

    final screens = [
      DashboardScreen(
        apartments: _apartments,
        customers: _customers,
        payments: _payments,
        expenses: _expenses,
      ),
      CustomersScreen(
        customers: _customers,
        onCustomersChanged: (updated) => setState(() {
          _customers.clear();
          _customers.addAll(updated);
        }),
      ),
      const BuildingsScreen(),
      const ContractsScreen(),
      PaymentsScreen(
        payments: _payments,
        expenses: _expenses,
        onPaymentsChanged: (updated) => setState(() {
          _payments.clear();
          _payments.addAll(updated);
        }),
        onExpensesChanged: (updated) => setState(() {
          _expenses.clear();
          _expenses.addAll(updated);
        }),
      ),
      ReportsScreen(
        payments: _payments,
        expenses: _expenses,
        apartments: _apartments,
        customers: _customers,
        maintenance: const [],
      ),
      if (isAdmin) const AdminAccountsScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline),
        activeIcon: Icon(Icons.people),
        label: 'Customers',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.apartment_outlined),
        activeIcon: Icon(Icons.apartment),
        label: 'Buildings',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.description_outlined),
        activeIcon: Icon(Icons.description),
        label: 'Contracts',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet_outlined),
        activeIcon: Icon(Icons.account_balance_wallet),
        label: 'Payments',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Reports',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts_outlined),
          activeIcon: Icon(Icons.manage_accounts),
          label: 'Accounts',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.person_outline,
                      size: 14,
                      color: isAdmin
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.account.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}