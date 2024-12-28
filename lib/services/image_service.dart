import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../util/cloudinary.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Captures an image from the device's camera.
  Future<File?> captureImage() async {
    try {
      final XFile? capturedImage = await _picker.pickImage(source: ImageSource.camera);
      if (capturedImage == null) {
        return null; // User canceled the capture
      }

      // Save the captured image to the app's documents directory
      final String fileName = 'prob.png';
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/$fileName';

      return File(capturedImage.path).copy(filePath);
    } catch (e) {
      print('Error capturing image: $e');
      throw Exception('Failed to capture image.');
    }
  }

  Future<XFile?> captureXFile() async {
    try {
      final XFile? capturedImage = await _picker.pickImage(source: ImageSource.camera);
      if (capturedImage == null) {
        return null; // User canceled the capture
      }
      return capturedImage;
    } catch (e) {
      print('Error capturing image: $e');
      throw Exception('Failed to capture image.');
    }
  }

  Future<String?> createImageAndSend(XFile? capturedImage) async {
    try {
      if (capturedImage == null) {
        return null; // User canceled the capture
      }
      // Save the captured image to the app's documents directory
      final String fileName = 'prob.png';
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/$fileName';
      File image = await File(capturedImage.path).copy(filePath);
      String? imageUrl = await uploadImage(image);

      return imageUrl;
    } catch (e) {
      print('Error capturing image: $e');
      throw Exception('Failed to capture image.');
    }
  }

  /// Selects an image from the device's gallery.
  Future<File?> selectImageFromGallery() async {
    try {
      final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (selectedImage == null) {
        return null; // User canceled the selection
      }

      // Save the selected image to the app's documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      return File(selectedImage.path).copy(filePath);
    } catch (e) {
      print('Error selecting image: $e');
      throw Exception('Failed to select image.');
    }
  }

  /// Uploads an image to Cloudinary and returns the URL.
  Future<String?> uploadImage(File image) async {
    try {
      final String? imageUrl = await CloudinaryApi.uploadImageFile(image);
      if (imageUrl == null) {
        throw Exception('Failed to upload image.');
      }
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image.');
    }
  }
}