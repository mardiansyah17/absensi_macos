import 'package:face_client/core/network/dio_client.dart';
import 'package:face_client/core/utils/logger.dart';
import 'package:face_client/models/employe.dart';

class RemoteDatasource {
  final DioClient dioClient = DioClient();

// get employes
  Future<List<Employe>> getEmployes() async {
    try {
      final response = await dioClient.get('/employees');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data.map((e) => Employe.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load employes');
      }
    } catch (e) {
      logger.e(e);
      throw Exception('Failed to load employes: $e');
    }
  }

  // get departements
  Future<List<dynamic>> getDepartements() async {
    try {
      final response = await dioClient.get('/departments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to load departements');
      }
    } catch (e) {
      throw Exception('Failed to load departements: $e');
    }
  }

  // register employe
  Future<void> registerEmploye(Employe data) async {
    try {
      final response = await dioClient.post('/register-employe', data: {
        'name': data.name,
        'nip': data.nip,
        'email': data.email,
        'departmentId': data.department?.id,
      });
      if (response.statusCode != 201) {
        throw Exception('Failed to register employe');
      }
    } catch (e) {
      logger.e(e);
      throw Exception('Failed to register employe: $e');
    }
  }

// update employe
  Future<void> updateEmploye(String id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.put('/update-employee/$id', data: data);
      logger.w('Failed to update employe: ${response.data}');
      if (response.statusCode != 200) {
        throw Exception('Failed to update employe');
      }
    } catch (e) {
      logger.e(e);
      throw Exception('Failed to update employe: $e');
    }
  }
}
