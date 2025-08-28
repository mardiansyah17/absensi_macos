import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveCsvWithDialogOrFallback({
  required List<String> header,
  required List<List<String>> rows,
  String suggestedFileName = 'data.csv',
}) async {
  final csvRows = <List<String>>[header, ...rows];

  final csvString = const ListToCsvConverter().convert(csvRows);
  final Uint8List data = Uint8List.fromList(utf8.encode('\uFEFF' + csvString));

  try {
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: suggestedFileName,
    );

    if (location != null) {
      final xfile =
          XFile.fromData(data, mimeType: 'text/csv', name: suggestedFileName);
      await xfile.saveTo(location.path);
      return location.path;
    }
  } catch (e) {
    print('Save dialog gagal / exception: $e');
  }

  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$suggestedFileName';
  final file = File(path);
  await file.writeAsBytes(data, flush: true);
  return path;
}

Future<void> revealInFinder(String filePath) async {
  try {
    await Process.run('open', ['-R', filePath]);
  } catch (e) {
    print('Gagal membuka Finder: $e');
  }
}
