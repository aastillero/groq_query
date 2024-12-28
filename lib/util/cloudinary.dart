import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloudinary/cloudinary.dart';

class CloudinaryApi {
  static const String cloudName = "dnal7gdyw";
  static const String apiKey = "746455743935276";
  static const String apiSecret = "W3O7oKB9TANXgjDHHqdZH0X4Hk4";
  //static CloudinaryPublic cloudinary = CloudinaryPublic(cloudName, 'groq_up', cache: false);
  static Cloudinary cloudinary = Cloudinary.signedConfig(
    apiKey: apiKey,
    apiSecret: apiSecret,
    cloudName: cloudName,
  );

  static Future<String?> uploadImageFile(File asset) async {
    try {
      File file = asset;
      /*CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
            file.path,
            resourceType: CloudinaryResourceType.Image
        ),
      );*/

      /*final response = await cloudinary.destroy(
        "groq_signed/${file.path}",
        resourceType: CloudinaryResourceType.image,
      );

      if(response.isSuccessful ?? false){
        print("successfully deleted");
      }*/
      
      final response = await cloudinary.upload(
        file: file.path,
        fileBytes: file.readAsBytesSync(),
        resourceType: CloudinaryResourceType.image,
        folder: 'groq_signed',
        fileName: file.path,
        progressCallback: (count, total) {
          //print('Uploading image from file with progress: $count/$total');
        }
      );

      print('Image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  /*static Future<String?> uploadImageAsset(String assetPath) async {
    try {
      // Load image from assets
      ByteData byteData = await rootBundle.load(assetPath);
      // Get the application documents directory
      Directory dir = await getApplicationDocumentsDirectory();

      // Create a new file in the documents directory
      File file = File('${dir.path}/prob.png');

      // Write the ByteData to the file
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
      );

      print('Image uploaded: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }*/
}