class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String role;
  final bool isActive;
  final String createdAt;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    bool? isActive,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }
}
