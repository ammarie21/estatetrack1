/// Primary bottom-navigation destinations (max 5 for phone layouts).
enum ShellTab { dashboard, customers, buildings, rentals, payments }

/// Full-screen overlays outside the bottom tab stack.
enum ShellOverlay { none, calendar, settings, reports, search }

/// Dashboard "Needs attention" drill-down targets.
enum DashboardAction {
  vacantUnits,
  leasesEnding,
  unpaidBookings,
  outstandingBalances,
}

extension ShellTabLabels on ShellTab {
  String get title {
    switch (this) {
      case ShellTab.dashboard:
        return 'Dashboard';
      case ShellTab.customers:
        return 'Customers';
      case ShellTab.buildings:
        return 'Buildings';
      case ShellTab.rentals:
        return 'Rentals';
      case ShellTab.payments:
        return 'Payments';
    }
  }

  String get erdHint {
    switch (this) {
      case ShellTab.dashboard:
        return 'Apartment · Customer · Booking · Transaction snapshot';
      case ShellTab.customers:
        return 'Customer records';
      case ShellTab.buildings:
        return 'Inventory · Maintenance · Apartment costs';
      case ShellTab.rentals:
        return 'Rental Booking · Agreement · Apartment Return';
      case ShellTab.payments:
        return 'Rental Transaction · Booking payments';
    }
  }
}
