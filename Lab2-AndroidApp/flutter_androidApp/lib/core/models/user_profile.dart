class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String lecturerCode;
  final String department;
  final String campus;
  final String authProvider;
  final bool isEmailVerified;
  final DateTime? lastSignInTime;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl = '',
    this.lecturerCode = 'minhnd32',
    this.department = 'Software Engineering (SE)',
    this.campus = 'FPT University - HCM Campus',
    this.authProvider = 'google.com',
    this.isEmailVerified = true,
    this.lastSignInTime,
  });

  factory UserProfile.defaultLecturer({
    String? email,
    String? name,
    String? photoUrl,
    String? id,
  }) {
    return UserProfile(
      id: id ?? 'LECTURER-001',
      displayName: name?.isNotEmpty == true ? name! : 'Dr. Nguyen Van Minh',
      email: email?.isNotEmpty == true ? email! : 'minhnd32@fpt.edu.vn',
      photoUrl: photoUrl ?? '',
      lecturerCode: 'minhnd32',
      department: 'Software Engineering (SE)',
      campus: 'FPT University - HCM Campus',
      authProvider: 'google.com',
      isEmailVerified: true,
      lastSignInTime: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? lecturerCode,
    String? department,
    String? campus,
    String? authProvider,
    bool? isEmailVerified,
    DateTime? lastSignInTime,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      lecturerCode: lecturerCode ?? this.lecturerCode,
      department: department ?? this.department,
      campus: campus ?? this.campus,
      authProvider: authProvider ?? this.authProvider,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
    );
  }
}
