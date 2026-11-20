class Admin {
  final int id;
  final String name;
  final String email;
  final String department;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    // 'department' may come from 'company.name' in JSONPlaceholder
    String parsedDepartment = '';
    if (json['department'] != null) {
      parsedDepartment = json['department'].toString();
    } else if (json['company'] != null && json['company'] is Map) {
      parsedDepartment = json['company']['name']?.toString() ?? '';
    }

    return Admin(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      department: parsedDepartment,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'department': department,
      };
}
