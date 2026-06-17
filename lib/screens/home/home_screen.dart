import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:estatetrack1/data/contract_builder.dart';
import 'package:estatetrack1/data/derived_estate_state.dart';
import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/data/estate_snapshot_cache.dart';
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
import 'package:estatetrack1/navigation/shell_navigation.dart';
import 'package:estatetrack1/notifications/lease_reminder_service.dart';
import 'package:estatetrack1/screens/admin/admin_accounts_screen.dart';
import 'package:estatetrack1/screens/buildings/buildings_screen.dart';
import 'package:estatetrack1/screens/calendar/calendar_screen.dart';
import 'package:estatetrack1/screens/contracts/contract_form_screen.dart';
import 'package:estatetrack1/screens/contracts/contracts_screen.dart';
import 'package:estatetrack1/screens/customers/customer_detail_screen.dart';
import 'package:estatetrack1/screens/customers/customers_screen.dart';
import 'package:estatetrack1/screens/dashboard/dashboard_screen.dart';
import 'package:estatetrack1/screens/login/login_screen.dart';
import 'package:estatetrack1/screens/payments/payments_screen.dart';
import 'package:estatetrack1/screens/reports/reports_screen.dart';
import 'package:estatetrack1/screens/search/global_search_screen.dart';
import 'package:estatetrack1/screens/settings/settings_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.account, super.key});
  final AccountModel account;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ShellTab _tab = ShellTab.dashboard;
  ShellOverlay _overlay = ShellOverlay.none;
  final Set<ShellTab> _visitedTabs = {ShellTab.dashboard};

  bool _isLoadingFromApi = false;
  String? _apiError;

  List<CustomerModel> _customers = [];
  List<BuildingModel> _buildings = [];
  List<ApartmentModel> _apartments = [];
  List<ApartmentTypeModel> _apartmentTypes = [];
  List<RentalBookingModel> _bookings = [];
  List<ContractModel> _contracts = [];
  List<ApartmentReturnModel> _returns = [];
  List<RentalTransactionModel> _rentalTransactions = [];
  List<MaintenanceModel> _maintenance = [];
  DateTime? _lastRefreshed;
  EstateIndexes? _indexes;

  int _tabFilterNonce = 0;
  String? _buildingsInitialFilter;
  String? _contractsInitialFilter;
  String? _paymentsInitialFilter;
  String? _contractsInitialQuery;
  String? _paymentsInitialQuery;

  bool get _hasLocalData =>
      _customers.isNotEmpty ||
      _buildings.isNotEmpty ||
      _apartments.isNotEmpty ||
      _bookings.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final cached = EstateSnapshotCache.instance.snapshot;
    if (cached != null) {
      _applySnapshot(cached, savedAt: EstateSnapshotCache.instance.savedAt);
      _loadFromApi(background: true);
    } else {
      _loadFromApi();
    }
  }

  void _applySnapshot(EstateSnapshot snapshot, {DateTime? savedAt}) {
    _customers = List<CustomerModel>.from(snapshot.customers);
    _buildings = snapshot.buildings;
    _apartments = snapshot.apartments;
    _apartmentTypes = List<ApartmentTypeModel>.from(snapshot.apartmentTypes);
    _bookings = snapshot.bookings;
    _contracts = snapshot.contracts;
    _returns = snapshot.returns;
    _rentalTransactions = snapshot.rentalTransactions;
    _maintenance = List<MaintenanceModel>.from(snapshot.maintenance)
      ..sort((a, b) => b.date.compareTo(a.date));
    _indexes = _buildIndexes();
    if (savedAt != null) {
      _lastRefreshed = savedAt;
    }
    _syncLeaseReminders();
  }

  void _syncLeaseReminders() {
    LeaseReminderService.instance.syncLeaseReminders(
      contracts: _contracts,
      customers: _customers,
      indexes: _indexes,
    );
  }

  EstateIndexes _buildIndexes() => EstateIndexes.fromLists(
    customers: _customers,
    buildings: _buildings,
    apartments: _apartments,
    apartmentTypes: _apartmentTypes,
    bookings: _bookings,
    returns: _returns,
    transactions: _rentalTransactions,
  );

  Future<void> _loadFromApi({
    bool showFeedback = false,
    bool background = false,
  }) async {
    setState(() {
      _isLoadingFromApi = true;
      if (!background) _apiError = null;
    });

    try {
      final snapshot = await EstateApi.instance.loadSnapshot();
      if (!mounted) return;
      setState(() {
        _applySnapshot(snapshot);
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
      if (showFeedback || !background) {
        AppSnackbars.error(context, 'API load failed: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiError = e.toString();
        _isLoadingFromApi = false;
      });
      if (showFeedback || !background) {
        AppSnackbars.error(context, 'API load failed');
      }
    }
  }

  Future<void> _refreshFromApi() => _loadFromApi(showFeedback: true);

  void _syncDerivedState() {
    final derived = deriveEstateState(bookings: _bookings, returns: _returns);
    _contracts = derived.contracts;
    _rentalTransactions = derived.rentalTransactions;
    _indexes = _buildIndexes();
  }

  BackendRecordCounts get _recordCounts => BackendRecordCounts(
    customers: _customers.length,
    buildings: _buildings.length,
    apartments: _apartments.length,
    bookings: _bookings.length,
    returns: _returns.length,
    maintenance: _maintenance.length,
    staff: EstateApi.instance.staffUsers.length,
  );

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
        rentalPrice: result.initialPayment > 0
            ? result.initialPayment
            : (existingBooking?.rentalPrice ?? 0),
        paymentDetails: result.initialPayment > 0
            ? 'Initial payment: \$${result.initialPayment.toStringAsFixed(2)}'
            : existingBooking?.paymentDetails,
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
        _syncDerivedState();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Agreement save failed: ${e.message}');
    }
  }

  void _selectTab(ShellTab tab) {
    Navigator.of(context).pop();
    setState(() {
      _overlay = ShellOverlay.none;
      _tab = tab;
      _visitedTabs.add(tab);
    });
  }

  void _openOverlay(ShellOverlay overlay) {
    Navigator.of(context).pop();
    setState(() => _overlay = overlay);
  }

  void _openAdminAccounts() {
    Navigator.of(context).pop();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const AppToolbarTitle(
              title: 'Accounts',
              erdHint: 'Staff sign-in · Roles',
            ),
          ),
          body: AdminAccountsScreen(
            initialUsers: EstateApi.instance.staffUsers,
          ),
        ),
      ),
    );
  }

  void _handleShellMenu(String value) {
    switch (value) {
      case 'refresh':
        if (!_isLoadingFromApi) _refreshFromApi();
      case 'calendar':
        setState(() => _overlay = ShellOverlay.calendar);
      case 'settings':
        setState(() => _overlay = ShellOverlay.settings);
      case 'reports':
        setState(() => _overlay = ShellOverlay.reports);
      case 'search':
        setState(() => _overlay = ShellOverlay.search);
      case 'logout':
        _confirmLogout();
    }
  }

  void _handleDashboardAction(DashboardAction action) {
    setState(() {
      _overlay = ShellOverlay.none;
      _tabFilterNonce++;
      switch (action) {
        case DashboardAction.vacantUnits:
          _tab = ShellTab.buildings;
          _buildingsInitialFilter = 'Vacant';
          _contractsInitialFilter = null;
          _paymentsInitialFilter = null;
          _contractsInitialQuery = null;
          _paymentsInitialQuery = null;
        case DashboardAction.leasesEnding:
          _tab = ShellTab.rentals;
          _contractsInitialFilter = 'Active';
          _buildingsInitialFilter = null;
          _paymentsInitialFilter = null;
          _contractsInitialQuery = null;
          _paymentsInitialQuery = null;
        case DashboardAction.unpaidBookings:
          _tab = ShellTab.payments;
          _paymentsInitialFilter = 'Pending';
          _buildingsInitialFilter = null;
          _contractsInitialFilter = null;
          _contractsInitialQuery = null;
          _paymentsInitialQuery = null;
        case DashboardAction.outstandingBalances:
          _tab = ShellTab.payments;
          _paymentsInitialFilter = 'Partial';
          _buildingsInitialFilter = null;
          _contractsInitialFilter = null;
          _contractsInitialQuery = null;
          _paymentsInitialQuery = null;
      }
      _visitedTabs.add(_tab);
    });
  }

  void _openCustomerFromSearch(CustomerModel customer) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          customer: customer,
          contracts: _contracts,
          bookings: _bookings,
          rentalTransactions: _rentalTransactions,
          apartments: _apartments,
          buildings: _buildings,
          returns: _returns,
        ),
      ),
    );
  }

  void _openBookingFromSearch(int bookingId) {
    setState(() {
      _overlay = ShellOverlay.none;
      _tab = ShellTab.rentals;
      _tabFilterNonce++;
      _contractsInitialFilter = 'All';
      _contractsInitialQuery = bookingId.toString();
      _visitedTabs.add(ShellTab.rentals);
    });
  }

  void _openOutstandingFromReports(int bookingId, String status) {
    setState(() {
      _overlay = ShellOverlay.none;
      _tab = ShellTab.payments;
      _tabFilterNonce++;
      _paymentsInitialFilter = status;
      _paymentsInitialQuery = bookingId.toString();
      _visitedTabs.add(ShellTab.payments);
    });
    AppSnackbars.info(context, 'Booking #$bookingId · collect payment');
  }

  void _openLeaseExpiryFromReports(ContractModel contract) {
    setState(() {
      _overlay = ShellOverlay.none;
      _tab = ShellTab.rentals;
      _tabFilterNonce++;
      _contractsInitialFilter = 'Active';
      _contractsInitialQuery = contract.bookingId.toString();
      _visitedTabs.add(ShellTab.rentals);
    });
    AppSnackbars.info(context, 'Booking #${contract.bookingId} · renew or return');
  }

  void _openCustomerFromReports(int customerId) {
    final customer = _customers
        .where((c) => c.customerId == customerId)
        .firstOrNull;
    if (customer == null) return;
    _openCustomerFromSearch(customer);
  }

  void _openApartmentFromSearch(int apartmentId) {
    setState(() {
      _overlay = ShellOverlay.none;
      _tab = ShellTab.buildings;
      _visitedTabs.add(ShellTab.buildings);
    });
  }

  ({String title, String hint}) _appBarContent() {
    switch (_overlay) {
      case ShellOverlay.calendar:
        return (
          title: 'Calendar',
          hint: 'Lease start · end · return · payment dates',
        );
      case ShellOverlay.settings:
        return (title: 'Settings', hint: 'Account · Backend · Appearance');
      case ShellOverlay.reports:
        return (
          title: 'Reports',
          hint: 'Revenue & occupancy analytics',
        );
      case ShellOverlay.search:
        return (
          title: 'Search',
          hint: 'Customers · apartments · bookings',
        );
      case ShellOverlay.none:
        return (title: _tab.title, hint: _tab.erdHint);
    }
  }

  Widget _buildTabBody(ShellTab tab) {
    if (!_visitedTabs.contains(tab)) {
      return const SizedBox.shrink();
    }

    final staffUserId = staffUserIdForAccount(widget.account);

    switch (tab) {
      case ShellTab.dashboard:
        return DashboardScreen(
          apartments: _apartments,
          customers: _customers,
          bookings: _bookings,
          returns: _returns,
          contracts: _contracts,
          rentalTransactions: _rentalTransactions,
          maintenance: _maintenance,
          onRefresh: _refreshFromApi,
          onAttentionTap: _handleDashboardAction,
        );
      case ShellTab.customers:
        return CustomersScreen(
          customers: _customers,
          contracts: _contracts,
          bookings: _bookings,
          rentalTransactions: _rentalTransactions,
          apartments: _apartments,
          buildings: _buildings,
          returns: _returns,
          onCustomersChanged: (updated) => setState(() {
            _customers.clear();
            _customers.addAll(updated);
            _indexes = _buildIndexes();
          }),
          onRefresh: _refreshFromApi,
        );
      case ShellTab.buildings:
        return BuildingsScreen(
          key: ValueKey('buildings-$_tabFilterNonce-${_buildingsInitialFilter ?? 'All'}'),
          buildings: _buildings,
          apartments: _apartments,
          apartmentTypes: _apartmentTypes,
          maintenance: _maintenance,
          contracts: _contracts,
          customers: _customers,
          initialAvailabilityFilter: _buildingsInitialFilter,
          onBuildingsChanged: (list) => setState(() {
            _buildings = List<BuildingModel>.from(list);
            _indexes = _buildIndexes();
          }),
          onApartmentsChanged: (list) => setState(() {
            _apartments = List<ApartmentModel>.from(list);
            _indexes = _buildIndexes();
          }),
          onMaintenanceChanged: (updated) => setState(() {
            _maintenance = List<MaintenanceModel>.from(updated);
          }),
          onRefresh: _refreshFromApi,
          onApartmentTypesChanged: (types) => setState(() {
            _apartmentTypes = List<ApartmentTypeModel>.from(types);
            _indexes = _buildIndexes();
          }),
        );
      case ShellTab.rentals:
        return ContractsScreen(
          key: ValueKey(
            'rentals-$_tabFilterNonce-${_contractsInitialFilter ?? 'All'}-${_contractsInitialQuery ?? ''}',
          ),
          staffUserId: staffUserId,
          customers: _customers,
          buildings: _buildings,
          apartments: _apartments,
          bookings: _bookings,
          contracts: _contracts,
          returns: _returns,
          initialStatusFilter: _contractsInitialFilter,
          initialSearchQuery: _contractsInitialQuery,
          onRefresh: _refreshFromApi,
          onBookingsChanged: (list) => setState(() {
            _bookings = List<RentalBookingModel>.from(list);
            _syncDerivedState();
          }),
          onContractsChanged: (list) => setState(() {
            _contracts = List<ContractModel>.from(list);
            _indexes = _buildIndexes();
          }),
          onReturnsChanged: (list) => setState(() {
            _returns = List<ApartmentReturnModel>.from(list);
            _syncDerivedState();
          }),
          onApartmentsChanged: (list) => setState(() {
            _apartments = List<ApartmentModel>.from(list);
            _indexes = _buildIndexes();
          }),
        );
      case ShellTab.payments:
        return PaymentsScreen(
          key: ValueKey(
            'payments-$_tabFilterNonce-${_paymentsInitialFilter ?? 'All'}-${_paymentsInitialQuery ?? ''}',
          ),
          rentalTransactions: _rentalTransactions,
          staffUserId: staffUserId,
          bookings: _bookings,
          returns: _returns,
          customers: _customers,
          buildings: _buildings,
          apartments: _apartments,
          initialTxnFilter: _paymentsInitialFilter,
          initialSearchQuery: _paymentsInitialQuery,
          onRefresh: _refreshFromApi,
          onRentalTransactionsChanged: (updated) => setState(() {
            _rentalTransactions = List<RentalTransactionModel>.from(updated);
            _indexes = _buildIndexes();
          }),
          onBookingsChanged: (list) => setState(() {
            _bookings = List<RentalBookingModel>.from(list);
            _syncDerivedState();
          }),
        );
    }
  }

  Widget _buildOverlayBody() {
    switch (_overlay) {
      case ShellOverlay.calendar:
        return CalendarScreen(
          contracts: _contracts,
          returns: _returns,
          rentalTransactions: _rentalTransactions,
          customers: _customers,
          apartments: _apartments,
          maintenance: _maintenance,
          onRefresh: _refreshFromApi,
          onEditContract: _editContractFromCalendar,
        );
      case ShellOverlay.settings:
        return SettingsScreen(
          account: widget.account,
          isLoadingFromApi: _isLoadingFromApi,
          apiError: _apiError,
          lastRefreshed: _lastRefreshed,
          recordCounts: _recordCounts,
          onRefresh: _refreshFromApi,
          onLogout: _confirmLogout,
        );
      case ShellOverlay.reports:
        return ReportsScreen(
          rentalTransactions: _rentalTransactions,
          apartments: _apartments,
          buildings: _buildings,
          customers: _customers,
          bookings: _bookings,
          contracts: _contracts,
          maintenance: _maintenance,
          onRefresh: _refreshFromApi,
          onOpenOutstandingBooking: _openOutstandingFromReports,
          onOpenLeaseExpiry: _openLeaseExpiryFromReports,
          onOpenCustomer: _openCustomerFromReports,
        );
      case ShellOverlay.search:
        final indexes = _indexes ?? _buildIndexes();
        return GlobalSearchScreen(
          indexes: indexes,
          onOpenCustomer: _openCustomerFromSearch,
          onOpenBooking: _openBookingFromSearch,
          onOpenApartment: _openApartmentFromSearch,
        );
      case ShellOverlay.none:
        return Stack(
          children: [
            for (final tab in ShellTab.values)
              Offstage(
                offstage: _tab != tab,
                child: _buildTabBody(tab),
              ),
          ],
        );
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  Widget _drawerSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(selected ? selectedIcon : icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? scheme.primary : null,
        ),
      ),
      selected: selected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.account.isAdmin;
    final scheme = Theme.of(context).colorScheme;
    final appBar = _appBarContent();
    final showLoadingBar = _isLoadingFromApi && !_hasLocalData;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        _initials(widget.account.name),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.account.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Container(
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
                            child: Text(
                              widget.account.role,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAdmin
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerSectionLabel('MAIN'),
                    _drawerTile(
                      icon: Icons.dashboard_outlined,
                      selectedIcon: Icons.dashboard,
                      label: 'Dashboard',
                      selected:
                          _overlay == ShellOverlay.none &&
                          _tab == ShellTab.dashboard,
                      onTap: () => _selectTab(ShellTab.dashboard),
                    ),
                    _drawerTile(
                      icon: Icons.people_outline,
                      selectedIcon: Icons.people,
                      label: 'Customers',
                      selected:
                          _overlay == ShellOverlay.none &&
                          _tab == ShellTab.customers,
                      onTap: () => _selectTab(ShellTab.customers),
                    ),
                    _drawerTile(
                      icon: Icons.apartment_outlined,
                      selectedIcon: Icons.apartment,
                      label: 'Buildings',
                      selected:
                          _overlay == ShellOverlay.none &&
                          _tab == ShellTab.buildings,
                      onTap: () => _selectTab(ShellTab.buildings),
                    ),
                    _drawerTile(
                      icon: Icons.handshake_outlined,
                      selectedIcon: Icons.handshake,
                      label: 'Rentals',
                      selected:
                          _overlay == ShellOverlay.none &&
                          _tab == ShellTab.rentals,
                      onTap: () => _selectTab(ShellTab.rentals),
                    ),
                    _drawerTile(
                      icon: Icons.account_balance_wallet_outlined,
                      selectedIcon: Icons.account_balance_wallet,
                      label: 'Payments',
                      selected:
                          _overlay == ShellOverlay.none &&
                          _tab == ShellTab.payments,
                      onTap: () => _selectTab(ShellTab.payments),
                    ),
                    _drawerSectionLabel('TOOLS'),
                    _drawerTile(
                      icon: Icons.search_rounded,
                      selectedIcon: Icons.search,
                      label: 'Search',
                      selected: _overlay == ShellOverlay.search,
                      onTap: () => _openOverlay(ShellOverlay.search),
                    ),
                    _drawerTile(
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart,
                      label: 'Reports',
                      selected: _overlay == ShellOverlay.reports,
                      onTap: () => _openOverlay(ShellOverlay.reports),
                    ),
                    _drawerTile(
                      icon: Icons.calendar_month_outlined,
                      selectedIcon: Icons.calendar_month,
                      label: 'Calendar',
                      selected: _overlay == ShellOverlay.calendar,
                      onTap: () => _openOverlay(ShellOverlay.calendar),
                    ),
                    _drawerTile(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      selected: _overlay == ShellOverlay.settings,
                      onTap: () => _openOverlay(ShellOverlay.settings),
                    ),
                    if (isAdmin)
                      _drawerTile(
                        icon: Icons.manage_accounts_outlined,
                        selectedIcon: Icons.manage_accounts,
                        label: 'Accounts',
                        selected: false,
                        onTap: _openAdminAccounts,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Log out'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmLogout();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: AppToolbarTitle(title: appBar.title, erdHint: appBar.hint),
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
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: _handleShellMenu,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                enabled: !_isLoadingFromApi,
                child: const ListTile(
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'calendar',
                child: ListTile(
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('Calendar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: ListTile(
                  leading: Icon(Icons.bar_chart_outlined),
                  title: Text('Reports'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search_rounded),
                  title: Text('Search'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Log out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildOverlayBody()),
          if (showLoadingBar && _overlay == ShellOverlay.none)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.surface,
                child: _tab == ShellTab.dashboard
                    ? const AppSkeletonDashboard()
                    : const AppSkeletonList(),
              ),
            ),
          if (showLoadingBar)
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
              bottom: _overlay == ShellOverlay.none ? 72 : 12,
              child: AppInlineError(
                message: 'API load failed: $_apiError',
                onRetry: _refreshFromApi,
                compact: true,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _overlay == ShellOverlay.none
          ? BottomNavigationBar(
              currentIndex: ShellTab.values.indexOf(_tab),
              onTap: (i) => setState(() {
                _tab = ShellTab.values[i];
                _visitedTabs.add(_tab);
              }),
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
                  label: 'Buildings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.handshake_outlined),
                  activeIcon: Icon(Icons.handshake),
                  label: 'Rentals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet),
                  label: 'Payments',
                ),
              ],
            )
          : null,
    );
  }
}
