import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';

/// No-op reminders for platforms without local notification support (web).
class LeaseReminderService {
  LeaseReminderService._();

  static final LeaseReminderService instance = LeaseReminderService._();

  Future<void> init() async {}

  Future<void> clearReminders() async {}

  Future<void> syncLeaseReminders({
    required List<ContractModel> contracts,
    required List<CustomerModel> customers,
    EstateIndexes? indexes,
  }) async {}
}
