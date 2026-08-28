import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;
  final String folder;
  CloudinaryService(
      {required this.cloudName,
      required this.uploadPreset,
      this.folder = 'kitchen-sync/products'});
  Future<Map<String, dynamic>> uploadProductImage(
      {required Uint8List bytes, required String sku}) async {
    final request = http.MultipartRequest('POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'))
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = sku
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: '$sku.jpg'));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Cloudinary upload failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
