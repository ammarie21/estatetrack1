import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/user_model.dart';

/// ERD [User] rows aligned with [MockAuthRepository] accounts (same phones/passwords).
final List<UserModel> staffUsers = [
  const UserModel(
    userId: 1,
    name: 'Main Admin',
    phone: '01000000001',
    password: 'Admin@123',
  ),
  const UserModel(
    userId: 2,
    name: 'Default User',
    phone: '01000000002',
    password: 'User@1234',
  ),
];

/// Maps logged-in account to ERD staff user for [RentalBookingModel.userId].
int staffUserIdForAccount(AccountModel account) {
  final phone = account.phone.trim();
  for (final u in staffUsers) {
    if (u.phone == phone) return u.userId;
  }
  return staffUsers.first.userId;
}
