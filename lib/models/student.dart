/// Represents a student enrolled in the Arabic teacher's platform.
class Student {
  final int? id;
  final String name;
  final String? phone;
  final String? parentPhone;
  final String barcodeNumber;
  final String? grade;
  final int? groupId;
  final bool feePaid;
  final String status; // 'active' | 'inactive'
  final DateTime? createdAt;

  const Student({
    this.id,
    required this.name,
    this.phone,
    this.parentPhone,
    required this.barcodeNumber,
    this.grade,
    this.groupId,
    this.feePaid = false,
    this.status = 'active',
    this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] != null ? (map['id'] as num).toInt() : null,
      name: (map['name'] ?? '').toString(),
      phone: map['phone'] as String?,
      parentPhone: map['parentPhone'] as String?,
      barcodeNumber: (map['barcodeNumber'] ?? '').toString(),
      grade: map['grade'] as String?,
      groupId: map['groupId'] != null ? (map['groupId'] as num).toInt() : null,
      feePaid: (map['feePaid'] == 1 || map['feePaid'] == true),
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'parentPhone': parentPhone,
      'barcodeNumber': barcodeNumber,
      'grade': grade,
      'groupId': groupId,
      'feePaid': feePaid ? 1 : 0,
      'status': status,
    };
  }

  Student copyWith({
    int? id,
    String? name,
    String? phone,
    String? parentPhone,
    String? barcodeNumber,
    String? grade,
    int? groupId,
    bool? feePaid,
    String? status,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      barcodeNumber: barcodeNumber ?? this.barcodeNumber,
      grade: grade ?? this.grade,
      groupId: groupId ?? this.groupId,
      feePaid: feePaid ?? this.feePaid,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Student && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
