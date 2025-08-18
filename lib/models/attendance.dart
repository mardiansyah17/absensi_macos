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
}
