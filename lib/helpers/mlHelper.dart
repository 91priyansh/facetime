import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';

class MLHelper {
  final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
  Future<File> pickImage() async {
    PickedFile pickedFile =
        await ImagePicker().getImage(source: ImageSource.camera);
    return File(pickedFile.path);
  }

  Future<void> processImage() async {
    final File imageFile = await pickImage();
    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);
    labeler.processImage(visionImage).then((imageLabels) {
      imageLabels.forEach((element) {
        print(element.text);
        print(element.confidence);
        print(element.entityId);
      });
    });
  }

  void releaseResource() {
    labeler.close();
  }
}
