import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // Để dùng XFile

class UploadService {
  static const String _uploadUrl = 'https://cfig.ibytecdn.org/upload';
  static const int _maxSizeInBytes = 10 * 1024 * 1024; // 10MB

  /// Upload ảnh – hoạt động trên cả mobile và web
  /// Tham số: XFile (từ image_picker) hoặc File (mobile cũ)
  static Future<String> uploadImage(dynamic image) async {
    try {
      if (image == null) {
        throw Exception('Dữ liệu ảnh không được để trống.');
      }

      // --- 1. Kiểm tra kích thước file và lấy bytes/path ---
      int imageSizeInBytes;
      String? filePath;
      Uint8List? fileBytes;
      String fileName = 'image.jpg'; // Tên mặc định

      if (kIsWeb) {
        // --- WEB LOGIC ---
        if (image is! XFile) {
          throw Exception('Trên Web, đầu vào phải là XFile.');
        }
        final XFile xFile = image;
        fileBytes = await xFile.readAsBytes();
        imageSizeInBytes = fileBytes.length;
        fileName = xFile.name.isNotEmpty ? xFile.name : fileName;
      } else {
        // --- MOBILE/DESKTOP LOGIC ---
        if (image is File) {
          // Trường hợp 1: Đầu vào là dart:io.File
          filePath = image.path;
          imageSizeInBytes = await image.length();
          fileName = image.path.split('/').last;
        } else if (image is XFile) {
          // Trường hợp 2: Đầu vào là XFile (từ image_picker)
          filePath = image.path;
          imageSizeInBytes = await File(image.path).length();
          fileName = image.name.isNotEmpty ? image.name : fileName;
        } else {
          throw Exception(
            'Trên Mobile/Desktop, đầu vào phải là XFile hoặc dart:io.File.',
          );
        }
      }

      // Kiểm tra kích thước (Áp dụng chung)
      if (imageSizeInBytes > _maxSizeInBytes) {
        throw Exception('Ảnh quá lớn! Vui lòng chọn ảnh dưới 10MB.');
      }

      // --- 2. Chuẩn bị MultipartRequest ---
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['server'] = 'server_1';

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images[]',
            fileBytes!,
            filename: fileName,
          ),
        );
      } else {
        // Mobile/Desktop: dùng path (đã lấy ở bước 1)
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            filePath!, // Đảm bảo đã có path
            filename: fileName, // Thêm filename để request chuẩn hơn
          ),
        );
      }

      // --- 3. Gửi Request và xử lý Response ---
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['results'] != null &&
            jsonResponse['results'] is List &&
            jsonResponse['results'].isNotEmpty) {
          return jsonResponse['results'][0]['url'] as String;
        } else {
          throw Exception('Phản hồi API không hợp lệ: ${response.body}');
        }
      } else {
        throw Exception(
          'Upload thất bại (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      // Bắt tất cả các lỗi đã ném ra bên trên
      // Đối với lỗi Exception, chúng ta chỉ cần ném lại thông báo lỗi
      if (e is Exception) {
        throw e;
      }
      // Đối với các lỗi khác (như TypeError không được kiểm soát), ném ra lỗi chung
      throw Exception('Lỗi upload ảnh: ${e.toString()}');
    }
  }
}
