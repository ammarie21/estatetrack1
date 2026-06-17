import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/account_model.dart';

/// Maps logged-in account to ERD staff user for [RentalBookingModel.userId].
int staffUserIdForAccount(AccountModel account) {
  final parsedId = int.tryParse(account.id);
  if (parsedId != null && parsedId > 0) return parsedId;

  final phone = account.phone.trim();
  for (final user in EstateApi.instance.staffUsers) {
    if (user.phone == phone) return user.userId;
  }
  return parsedId ?? 1;
}

/// Resolves backend [User] name for display on agreements and payments.
String staffUserName(int userId) {
  if (userId < 1) return 'Unknown staff';
  for (final user in EstateApi.instance.staffUsers) {
    if (user.userId == userId) return user.name;
  }
  return 'Staff #$userId';
}
