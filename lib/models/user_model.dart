enum UserRole {
  owner,
  officer,
  gatc,
  admin,
  public;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Instrument Owner';
      case UserRole.officer:
        return 'Legal Metrology Officer (LMO)';
      case UserRole.gatc:
        return 'GATC Verification Officer';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.public:
        return 'Public Consumer';
    }
  }

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == role.toLowerCase(),
      orElse: () => UserRole.public,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? department;
  final String? designation;
  final String? state;
  final String? district;
  final String? token;
  final String? profilePhoto;
  final String? address;
  final String? serviceArea;
  final String status; // active, pending, inactive
  final DateTime createdAt;
  final DateTime? lastLogin;

  String get userId => id;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.department,
    this.designation,
    this.state,
    this.district,
    this.token,
    this.profilePhoto,
    this.address,
    this.serviceArea,
    this.status = 'active',
    DateTime? createdAt,
    this.lastLogin,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'public'),
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      designation: json['designation'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
      token: json['token'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      address: json['address'] as String?,
      serviceArea: json['serviceArea'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'department': department,
      'designation': designation,
      'state': state,
      'district': district,
      'token': token,
      'profilePhoto': profilePhoto,
      'address': address,
      'serviceArea': serviceArea,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? department,
    String? designation,
    String? state,
    String? district,
    String? token,
    String? profilePhoto,
    String? address,
    String? serviceArea,
    String? status,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      state: state ?? this.state,
      district: district ?? this.district,
      token: token ?? this.token,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      address: address ?? this.address,
      serviceArea: serviceArea ?? this.serviceArea,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
