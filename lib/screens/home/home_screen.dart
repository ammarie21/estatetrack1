import 'package:flutter/material.dart';
import 'package:estatetrack1/data/mock_auth_repository.dart';
import 'package:estatetrack1/data/staff_user_registry.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/screens/admin/admin_accounts_screen.dart';
import 'package:estatetrack1/screens/buildings/buildings_screen.dart';
import 'package:estatetrack1/screens/contracts/contracts_screen.dart';
import 'package:estatetrack1/screens/customers/customers_screen.dart';
import 'package:estatetrack1/screens/dashboard/dashboard_screen.dart';
import 'package:estatetrack1/screens/login/login_screen.dart';
import 'package:estatetrack1/screens/payments/payments_screen.dart';
import 'package:estatetrack1/screens/reports/reports_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

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

  List<BuildingModel> _buildings = [
    const BuildingModel(
      buildingId: 1,
      name: 'Tower A',
      floorsCount: 5,
      constructionYear: 2020,
      totalApartments: 15,
      location: 'Downtown',
    ),
    const BuildingModel(
      buildingId: 2,
      name: 'Tower B',
      floorsCount: 8,
      constructionYear: 2019,
      totalApartments: 24,
      location: 'Business District',
    ),
    const BuildingModel(
      buildingId: 3,
      name: 'Tower C',
      floorsCount: 10,
      constructionYear: 2021,
      totalApartments: 30,
      location: 'Residential Area',
    ),
  ];

  List<ApartmentModel> _apartments = [
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

  /// ERD rental bookings (staff user from logged-in account).
  List<RentalBookingModel> _bookings = [
    RentalBookingModel(
      bookingId: 1,
      userId: 1,
      customerId: 1,
      apartmentId: 1,
      startDate: DateTime(2024, 6, 1),
      endDate: DateTime(2025, 5, 31),
      initialTotalDueAmount: 5400,
      bookingType: 0,
      periodFee: 450,
      initialCheckNotes: 'Yearly lease',
    ),
    RentalBookingModel(
      bookingId: 2,
      userId: 1,
      customerId: 2,
      apartmentId: 3,
      startDate: DateTime(2024, 1, 15),
      endDate: DateTime(2025, 1, 14),
      initialTotalDueAmount: 8160,
      bookingType: 0,
      periodFee: 680,
    ),
  ];

  List<ContractModel> _contracts = [
    ContractModel(
      contractId: 1,
      customerId: 1,
      apartmentId: 1,
      startDate: DateTime(2024, 6, 1),
      endDate: DateTime(2025, 5, 31),
      totalAmount: 5400,
      status: 'Active',
      bookingId: 1,
      notes: 'Yearly contract',
    ),
    ContractModel(
      contractId: 2,
      customerId: 2,
      apartmentId: 3,
      startDate: DateTime(2024, 1, 15),
      endDate: DateTime(2025, 1, 14),
      totalAmount: 8160,
      status: 'Active',
      bookingId: 2,
      notes: 'Annual lease',
    ),
  ];

  List<ApartmentReturnModel> _returns = [];

  /// ERD rental transactions (linked to bookings; [returnId] when checkout exists).
  List<RentalTransactionModel> _rentalTransactions = [
    RentalTransactionModel(
      transactionId: 1,
      bookingId: 1,
      returnId: null,
      paidInitialTotalDueAmount: 450,
      actualTotalDueAmount: 5400,
      totalRemaining: 4950,
      totalRefundedAmount: 0,
      transactionStatus: 'Partial',
      updatedTransactionDate: DateTime(2025, 3, 1),
      paymentDetails: 'Monthly rent — March',
    ),
    RentalTransactionModel(
      transactionId: 2,
      bookingId: 2,
      returnId: null,
      paidInitialTotalDueAmount: 680,
      actualTotalDueAmount: 8160,
      totalRemaining: 7480,
      totalRefundedAmount: 0,
      transactionStatus: 'Partial',
      updatedTransactionDate: DateTime(2025, 3, 2),
      paymentDetails: 'Monthly rent — March',
    ),
  ];

  List<ExpenseModel> _expenses = [
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
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.account.isAdmin;
    final scheme = Theme.of(context).colorScheme;
    final staffUserId = staffUserIdForAccount(widget.account);

    final shellHints = <({String title, String hint})>[
      (
        title: 'Dashboard',
        hint: 'Apartment · Customer · Booking · Transaction snapshot'
      ),
      (title: 'Customers', hint: 'Customer records'),
      (
        title: 'Buildings',
        hint: 'Building · Apartment inventory'
      ),
      (
        title: 'Rentals',
        hint: 'Rental Booking · Agreement · Apartment Return'
      ),
      (
        title: 'Payments',
        hint: 'Rental Transaction · Expenses'
      ),
      (title: 'Reports', hint: 'Revenue & occupancy analytics'),
      if (isAdmin) (title: 'Accounts', hint: 'Staff sign-in · Roles'),
    ];

    final screens = [
      DashboardScreen(
        apartments: _apartments,
        customers: _customers,
        bookings: _bookings,
        returns: _returns,
        rentalTransactions: _rentalTransactions,
        expenses: _expenses,
      ),
      CustomersScreen(
        customers: _customers,
        onCustomersChanged: (updated) => setState(() {
          _customers.clear();
          _customers.addAll(updated);
        }),
      ),
      BuildingsScreen(
        buildings: _buildings,
        apartments: _apartments,
        onBuildingsChanged: (list) => setState(() {
          _buildings = List<BuildingModel>.from(list);
        }),
        onApartmentsChanged: (list) => setState(() {
          _apartments = List<ApartmentModel>.from(list);
        }),
      ),
      ContractsScreen(
        staffUserId: staffUserId,
        customers: _customers,
        apartments: _apartments,
        bookings: _bookings,
        contracts: _contracts,
        returns: _returns,
        onBookingsChanged: (list) => setState(() {
          _bookings = List<RentalBookingModel>.from(list);
        }),
        onContractsChanged: (list) => setState(() {
          _contracts = List<ContractModel>.from(list);
        }),
        onReturnsChanged: (list) => setState(() {
          _returns = List<ApartmentReturnModel>.from(list);
        }),
        onApartmentsChanged: (list) => setState(() {
          _apartments = List<ApartmentModel>.from(list);
        }),
      ),
      PaymentsScreen(
        rentalTransactions: _rentalTransactions,
        bookings: _bookings,
        returns: _returns,
        customers: _customers,
        apartments: _apartments,
        expenses: _expenses,
        onRentalTransactionsChanged: (updated) => setState(() {
          _rentalTransactions = List<RentalTransactionModel>.from(updated);
        }),
        onExpensesChanged: (updated) => setState(() {
          _expenses = List<ExpenseModel>.from(updated);
        }),
      ),
      ReportsScreen(
        rentalTransactions: _rentalTransactions,
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
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: 'Rentals',
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
        title: AppToolbarTitle(
          title: shellHints[_index].title,
          erdHint: shellHints[_index].hint,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
