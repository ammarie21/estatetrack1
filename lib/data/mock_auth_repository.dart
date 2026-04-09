import 'package:estatetrack1/models/account_model.dart';

class MockAuthRepository {
  MockAuthRepository._();

  static final MockAuthRepository instance = MockAuthRepository._();

  final List<AccountModel> _accounts = [
    AccountModel(
      id: '1',
      name: 'Main Admin',
      email: 'admin@estatetrack.com',
      phone: '01000000001',
      password: 'Admin@123',
      role: 'Admin',
    ),
    AccountModel(
      id: '2',
      name: 'Default User',
      email: 'user@estatetrack.com',
      phone: '01000000002',
      password: 'User@1234',
      role: 'User',
    ),
  ];

  AccountModel? currentUser;

  List<AccountModel> get accounts => List.unmodifiable(_accounts);

  AccountModel? login({
    required String identifier,
    required String password,
  }) {
    final normalized = identifier.trim().toLowerCase();
    final account = _accounts.firstWhere(
      (a) =>
          (a.email.toLowerCase() == normalized || a.phone == normalized) &&
          a.password == password,
      orElse: () => AccountModel(
        id: '',
        name: '',
        email: '',
        phone: '',
        password: '',
        role: '',
        isActive: false,
      ),
    );

    if (account.id.isEmpty || !account.isActive) {
      return null;
    }

    currentUser = account;
    return account;
  }

  void logout() {
    currentUser = null;
  }

  String? validatePasswordRules(String password) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
      return 'Password needs upper, lower, number, and special character.';
    }
    return null;
  }

  String? createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) {
    if (_accounts.any((a) => a.email.toLowerCase() == email.toLowerCase())) {
      return 'Email already exists.';
    }
    if (_accounts.any((a) => a.phone == phone)) {
      return 'Phone already exists.';
    }

    _accounts.add(
      AccountModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        role: role,
      ),
    );
    return null;
  }

  String? updateAccount({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String role,
    required bool isActive,
  }) {
    final account = _accounts.firstWhere((a) => a.id == id);
    final emailTaken = _accounts.any(
      (a) => a.id != id && a.email.toLowerCase() == email.toLowerCase(),
    );
    if (emailTaken) {
      return 'Email already used by another account.';
    }
    final phoneTaken = _accounts.any((a) => a.id != id && a.phone == phone);
    if (phoneTaken) {
      return 'Phone already used by another account.';
    }

    account.name = name.trim();
    account.email = email.trim();
    account.phone = phone.trim();
    account.role = role;
    account.isActive = isActive;
    return null;
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
  }

  String? resetPassword({
    required String id,
    required String newPassword,
  }) {
    final ruleError = validatePasswordRules(newPassword);
    if (ruleError != null) {
      return ruleError;
    }
    final account = _accounts.firstWhere((a) => a.id == id);
    account.password = newPassword;
    return null;
  }

  String forgotPassword(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    final exists = _accounts.any(
      (a) => a.email.toLowerCase() == normalized || a.phone == normalized,
    );
    if (!exists) {
      return 'No account found with this email/phone.';
    }
    return 'Password reset request submitted (mock).';
  }
}
