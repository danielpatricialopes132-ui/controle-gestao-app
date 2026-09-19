import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportUtils {
  static Future<void> exportToCsv({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    String csv = rows.map((row) => row.map((e) => '"${e.toString().replaceAll('"', '""')}"').join(',')).join('\n');

    if (kIsWeb) {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(csv.codeUnits),
            mimeType: 'text/csv',
            name: '$fileName.csv',
          )
        ],
        text: 'Baixar CSV: $fileName',
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Exportação: $fileName');
  }
}
