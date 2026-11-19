class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  AppUser withName(String name) =>
      AppUser(id: id, name: name, email: email, phone: phone);
}
