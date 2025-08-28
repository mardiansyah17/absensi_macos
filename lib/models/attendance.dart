import 'package:face_client/models/employe.dart';

class Attendance {
  final Employe employe;
  final String? checkIn;
  final String? checkOut;
  final AttendanceStatus status;

  Attendance({
    required this.employe,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      employe: Employe.fromJson(json['employe'] ?? json['employee']),
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      status: attendanceStatusFromString(json['status'] as String?),
    );
  }
}

enum AttendanceStatus { present, absent, late, excused, unexcused, unknown }

AttendanceStatus attendanceStatusFromString(String? s) {
  if (s == null) return AttendanceStatus.unknown;
  switch (s.toLowerCase()) {
    case 'present':
    case 'hadir':
      return AttendanceStatus.present;
    case 'absent':
    case 'tidak hadir':
      return AttendanceStatus.absent;
    case 'late':
    case 'telat':
      return AttendanceStatus.late;
    case 'excused':
    case 'izin':
      return AttendanceStatus.excused;
    case 'unexcused':
      return AttendanceStatus.unexcused;
    default:
      return AttendanceStatus.unknown;
  }
}

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Hadir';
      case AttendanceStatus.absent:
        return 'Tidak Hadir';
      case AttendanceStatus.late:
        return 'Telat';
      case AttendanceStatus.excused:
        return 'Izin';
      case AttendanceStatus.unexcused:
        return 'Tanpa Keterangan';
      case AttendanceStatus.unknown:
      default:
        return '-';
    }
  }

  String get name => toString().split('.').last;
}
