import 'package:face_client/models/employe.dart';

class Attendance {
  final Employe employe;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String status;

  Attendance({
    required this.employe,
    this.clockIn,
    this.clockOut,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      employe: Employe.fromJson(json['employe']),
      clockIn: json['clockIn'] != null ? DateTime.parse(json['clockIn']) : null,
      clockOut:
          json['clockOut'] != null ? DateTime.parse(json['clockOut']) : null,
      status: json['status'] ?? 'unknown',
    );
  }
}
