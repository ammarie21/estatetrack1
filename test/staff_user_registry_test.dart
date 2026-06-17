import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/data/staff_user_registry.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('staffUserName resolves cached backend users', () {
    EstateApi.instance.staffUsers = const [
      UserModel(
        userId: 2,
        name: 'Default User',
        phone: '01000000002',
        password: 'User@1234',
      ),
    ];

    expect(staffUserName(2), 'Default User');
    expect(staffUserName(99), 'Staff #99');
  });

  test('staffUserIdForAccount prefers parsed account id', () {
    EstateApi.instance.staffUsers = const [
      UserModel(
        userId: 2,
        name: 'Default User',
        phone: '01000000002',
        password: 'User@1234',
      ),
    ];

    final account = AccountModel(
      id: '2',
      name: 'Default User',
      email: '',
      phone: '01000000002',
      password: '',
      role: 'Staff',
    );

    expect(staffUserIdForAccount(account), 2);
  });
}
