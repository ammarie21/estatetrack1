class UserModel {
  const UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.password,
  });

  final int userId;
  final String name;
  final String phone;
  final String password;

  UserModel copyWith({
    int? userId,
    String? name,
    String? phone,
    String? password,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }
}