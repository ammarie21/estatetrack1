import 'package:flutter/material.dart';

import 'package:estatetrack1/screens/apartments/apartments_screen.dart';
import 'package:estatetrack1/screens/customers/customers_screen.dart';
import 'package:estatetrack1/screens/dashboard/dashboard_screen.dart';
import 'package:estatetrack1/screens/login/login_screen.dart';
import 'package:estatetrack1/screens/payments/payments_screen.dart';
import 'package:estatetrack1/screens/reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Customers',
    'Apartments',
    'Payments',
    'Reports',
  ];

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
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
        children: const [
          DashboardScreen(),
          CustomersScreen(),
          ApartmentsScreen(),
          PaymentsScreen(),
          ReportsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            activeIcon: Icon(Icons.apartment),
            label: 'Apartments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
