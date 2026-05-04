class AccountModel {
  AccountModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.isActive = true,
  });

  final String id;
  String name;
  String email;
  String phone;
  String password;
  String role;
  bool isActive;

  bool get isAdmin => role == 'Admin';
}