import 'package:flutter/material.dart';

import 'package:estatetrack1/data/mock_auth_repository.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/screens/buildings/buildings_screen.dart';
import 'package:estatetrack1/screens/admin/admin_accounts_screen.dart';
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

  void _logout() {
    MockAuthRepository.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.account.isAdmin;
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
      const DashboardScreen(),
      const CustomersScreen(),
      const BuildingsScreen(),
      const ContractsScreen(),
      const PaymentsScreen(),
      const ReportsScreen(),
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
