import 'package:face_client/core/utils/logger.dart';
import 'package:face_client/models/department.dart';

class Employe {
  final String id;
  final String name;
  final String nip;
  final String email;
  final Department? department;
  final String? faceImageUrl;

  Employe({
    required this.id,
    required this.name,
    required this.nip,
    required this.email,
    this.department,
    this.faceImageUrl,
  });

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
      id: json['id'] as String,
      name: json['name'] as String,
      nip: json['nip'] as String,
      email: json['email'] as String,
      department: Department.fromJson(json['department']),
      faceImageUrl: json['faceImageUrl'],
    );
  }
}
