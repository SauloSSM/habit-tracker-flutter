class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  AppUser withName(String name) => AppUser(id: id, name: name, email: email);
}
