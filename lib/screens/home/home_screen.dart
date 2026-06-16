import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:estatetrack1/data/contract_builder.dart';
import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/data/staff_user_registry.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/screens/admin/admin_accounts_screen.dart';
import 'package:estatetrack1/screens/buildings/buildings_screen.dart';
import 'package:estatetrack1/screens/calendar/calendar_screen.dart';
import 'package:estatetrack1/screens/contracts/contract_form_screen.dart';
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
  bool _showCalendar = false;
  bool _isLoadingFromApi = true;
  String? _apiError;

  List<CustomerModel> _customers = [];

  List<BuildingModel> _buildings = [];

  List<ApartmentModel> _apartments = [];

  List<ApartmentTypeModel> _apartmentTypes = [];

  /// ERD rental bookings (staff user from logged-in account).
  List<RentalBookingModel> _bookings = [];

  List<ContractModel> _contracts = [];

  List<ApartmentReturnModel> _returns = [];

  /// Derived from bookings + returns (matches backend RentalBooking fields).
  List<RentalTransactionModel> _rentalTransactions = [];

  List<MaintenanceModel> _maintenance = [];
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  Future<void> _loadFromApi({bool showFeedback = false}) async {
    setState(() {
      _isLoadingFromApi = true;
      _apiError = null;
    });

    try {
      final snapshot = await EstateApi.instance.loadSnapshot();
      if (!mounted) return;
      setState(() {
        _customers = List<CustomerModel>.from(snapshot.customers);
        _buildings = snapshot.buildings;
        _apartments = snapshot.apartments;
        _apartmentTypes = List<ApartmentTypeModel>.from(
          snapshot.apartmentTypes,
        );
        _bookings = snapshot.bookings;
        _contracts = snapshot.contracts;
        _returns = snapshot.returns;
        _rentalTransactions = snapshot.rentalTransactions;
        _maintenance = List<MaintenanceModel>.from(snapshot.maintenance)
          ..sort((a, b) => b.date.compareTo(a.date));
        _isLoadingFromApi = false;
        _lastRefreshed = DateTime.now();
      });
      if (!mounted) return;
      if (showFeedback) {
        AppSnackbars.success(context, 'Data refreshed from backend');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = e.message;
        _isLoadingFromApi = false;
      });
      if (!mounted) return;
      if (showFeedback) {
        AppSnackbars.error(context, 'API load failed: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = e.toString();
        _isLoadingFromApi = false;
      });
      AppSnackbars.error(context, 'API load failed');
    }
  }

  Future<void> _refreshFromApi() => _loadFromApi(showFeedback: true);

  Future<void> _confirmLogout() async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will return to the login screen.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (ok && mounted) _logout();
  }

  void _logout() {
    EstateApi.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _editContractFromCalendar(ContractModel existing) async {
    final result = await Navigator.of(context).push<ContractModel>(
      MaterialPageRoute(
        builder: (context) => ContractFormScreen(
          existing: existing,
          customers: _customers,
          buildings: _buildings,
          apartments: _apartments,
          bookings: _bookings,
        ),
      ),
    );
    if (!mounted || result == null) return;

    try {
      final staffUserId = staffUserIdForAccount(widget.account);
      final bookingId = existing.bookingId;
      final months = math.max(
        1,
        (result.endDate.difference(result.startDate).inDays / 30).ceil(),
      );
      final existingBooking = _bookings
          .where((b) => b.bookingId == bookingId)
          .firstOrNull;
      final booking = RentalBookingModel(
        bookingId: bookingId,
        userId: staffUserId,
        customerId: result.customerId,
        apartmentId: result.apartmentId,
        startDate: result.startDate,
        endDate: result.endDate,
        initialTotalDueAmount: result.totalAmount,
        bookingType: result.bookingType,
        periodFee: result.totalAmount / months,
        rentalPrice: existingBooking?.rentalPrice ?? 0,
        paymentDetails: existingBooking?.paymentDetails,
        isActive: existingBooking?.isActive ?? true,
        initialCheckNotes: result.notes,
      );
      final savedBooking = await EstateApi.instance.updateBooking(booking);

      setState(() {
        final bi = _bookings.indexWhere((b) => b.bookingId == bookingId);
        if (bi >= 0) {
          _bookings[bi] = savedBooking;
        }
        final ci = _contracts.indexWhere(
          (c) => c.contractId == existing.contractId,
        );
        if (ci >= 0) {
          _contracts[ci] = contractFromBooking(
            savedBooking,
            returns: _returns,
          ).copyWith(notes: result.notes);
        }
        _rentalTransactions = buildTransactionsFromBookings(
          _bookings,
          _returns,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Agreement save failed: ${e.message}');
    }
  }

  void _selectDrawerDestination(int? index) {
    Navigator.of(context).pop();
    setState(() {
      if (index == null) {
        _showCalendar = true;
      } else {
        _showCalendar = false;
        _index = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.account.isAdmin;
    final scheme = Theme.of(context).colorScheme;
    final staffUserId = staffUserIdForAccount(widget.account);

    final shellHints = <({String title, String hint})>[
      (
        title: 'Dashboard',
        hint: 'Apartment · Customer · Booking · Transaction snapshot',
      ),
      (title: 'Customers', hint: 'Customer records'),
      (title: 'Buildings', hint: 'Inventory · Maintenance · Apartment costs'),
      (title: 'Rentals', hint: 'Rental Booking · Agreement · Apartment Return'),
      (title: 'Payments', hint: 'Rental Transaction · Booking payments'),
      (title: 'Reports', hint: 'Revenue & occupancy analytics'),
      if (isAdmin) (title: 'Accounts', hint: 'Staff sign-in · Roles'),
    ];

    final screens = [
      DashboardScreen(
        apartments: _apartments,
        customers: _customers,
        bookings: _bookings,
        returns: _returns,
        contracts: _contracts,
        rentalTransactions: _rentalTransactions,
        maintenance: _maintenance,
        onRefresh: _refreshFromApi,
      ),
      CustomersScreen(
        customers: _customers,
        onCustomersChanged: (updated) => setState(() {
          _customers.clear();
          _customers.addAll(updated);
        }),
        onRefresh: _refreshFromApi,
      ),
      BuildingsScreen(
        buildings: _buildings,
        apartments: _apartments,
        apartmentTypes: _apartmentTypes,
        maintenance: _maintenance,
        onBuildingsChanged: (list) => setState(() {
          _buildings = List<BuildingModel>.from(list);
        }),
        onApartmentsChanged: (list) => setState(() {
          _apartments = List<ApartmentModel>.from(list);
        }),
        onMaintenanceChanged: (updated) => setState(() {
          _maintenance = List<MaintenanceModel>.from(updated);
        }),
        onRefresh: _refreshFromApi,
        onApartmentTypesChanged: (types) => setState(() {
          _apartmentTypes = List<ApartmentTypeModel>.from(types);
        }),
      ),
      ContractsScreen(
        staffUserId: staffUserId,
        customers: _customers,
        buildings: _buildings,
        apartments: _apartments,
        bookings: _bookings,
        contracts: _contracts,
        returns: _returns,
        onRefresh: _refreshFromApi,
        onBookingsChanged: (list) => setState(() {
          _bookings = List<RentalBookingModel>.from(list);
          _contracts = contractsFromBookings(_bookings, _returns);
          _rentalTransactions = buildTransactionsFromBookings(
            _bookings,
            _returns,
          );
        }),
        onContractsChanged: (list) => setState(() {
          _contracts = List<ContractModel>.from(list);
        }),
        onReturnsChanged: (list) => setState(() {
          _returns = List<ApartmentReturnModel>.from(list);
          _contracts = contractsFromBookings(_bookings, _returns);
          _rentalTransactions = buildTransactionsFromBookings(
            _bookings,
            _returns,
          );
        }),
        onApartmentsChanged: (list) => setState(() {
          _apartments = List<ApartmentModel>.from(list);
        }),
      ),
      PaymentsScreen(
        rentalTransactions: _rentalTransactions,
        staffUserId: staffUserId,
        bookings: _bookings,
        returns: _returns,
        customers: _customers,
        buildings: _buildings,
        apartments: _apartments,
        onRefresh: _refreshFromApi,
        onRentalTransactionsChanged: (updated) => setState(() {
          _rentalTransactions = List<RentalTransactionModel>.from(updated);
        }),
        onBookingsChanged: (list) => setState(() {
          _bookings = List<RentalBookingModel>.from(list);
          _contracts = contractsFromBookings(_bookings, _returns);
          _rentalTransactions = buildTransactionsFromBookings(
            _bookings,
            _returns,
          );
        }),
      ),
      ReportsScreen(
        rentalTransactions: _rentalTransactions,
        apartments: _apartments,
        buildings: _buildings,
        customers: _customers,
        bookings: _bookings,
        contracts: _contracts,
        maintenance: _maintenance,
        onRefresh: _refreshFromApi,
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
        icon: Icon(Icons.handshake_outlined),
        activeIcon: Icon(Icons.handshake),
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

    const calendarHint = (
      title: 'Calendar',
      hint: 'Lease start · end · return · payment dates',
    );

    return Scaffold(
      drawer: NavigationDrawer(
        selectedIndex: _showCalendar ? shellHints.length : _index,
        onDestinationSelected: (i) {
          if (i == shellHints.length) {
            _selectDrawerDestination(null);
          } else {
            _selectDrawerDestination(i);
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EstateTrack',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.account.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Customers'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: Text('Buildings'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: Text('Rentals'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: Text('Payments'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: Text('Reports'),
          ),
          if (isAdmin)
            const NavigationDrawerDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: Text('Accounts'),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: Text('Calendar'),
          ),
        ],
      ),
      appBar: AppBar(
        title: AppToolbarTitle(
          title: _showCalendar ? calendarHint.title : shellHints[_index].title,
          erdHint: _showCalendar ? calendarHint.hint : shellHints[_index].hint,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: AppBackendStatusChip(
                state: _isLoadingFromApi
                    ? AppBackendSyncState.loading
                    : _apiError != null
                    ? AppBackendSyncState.error
                    : AppBackendSyncState.online,
                lastRefreshed: _lastRefreshed,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showCalendar
                  ? Icons.calendar_month
                  : Icons.calendar_month_outlined,
            ),
            tooltip: 'Calendar',
            color: _showCalendar ? scheme.primary : null,
            onPressed: () => setState(() => _showCalendar = true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh API data',
            onPressed: _isLoadingFromApi ? null : _refreshFromApi,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _showCalendar
                ? CalendarScreen(
                    contracts: _contracts,
                    returns: _returns,
                    rentalTransactions: _rentalTransactions,
                    customers: _customers,
                    apartments: _apartments,
                    onEditContract: _editContractFromCalendar,
                  )
                : IndexedStack(index: _index, children: screens),
          ),
          if (_isLoadingFromApi)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
          if (_apiError != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 72,
              child: AppInlineError(
                message: 'API load failed: $_apiError',
                onRetry: _refreshFromApi,
                compact: true,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() {
          _showCalendar = false;
          _index = i;
        }),
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
