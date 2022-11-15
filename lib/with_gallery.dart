import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class WithGallery extends StatefulWidget {
  const WithGallery({super.key});

  @override
  State<WithGallery> createState() => _WithGalleryState();
}

class _WithGalleryState extends State<WithGallery> {
  File? _image;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          child: _image == null
              ? Center(
                  child: ElevatedButton(
                    child: const Icon(Icons.add_a_photo_outlined),
                    onPressed: () => getImage(),
                  ),
                )
              : Center(
                  child: Image.file(_image!),
                )),
      floatingActionButton: RawMaterialButton(
        onPressed: () {
          if (_image != null) {
            return uploadImage(_image);
          }
        },
        elevation: 2.0,
        fillColor: Colors.white,
        child: Icon(
          Icons.favorite,
          size: 18.0,
        ),
        padding: EdgeInsets.all(15.0),
        shape: CircleBorder(),
      ),
    );
  }

  getImage() async {
    // You can also change the source to gallery like this: "source: ImageSource.camera"
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image has been selected.');
      }
    });
  }

  uploadImage(img) async {
    var modal = _onLoading();

    await Firebase.initializeApp();
    var random = new Random();
    var rand = random.nextInt(1000000000);
    // Give the image a random name
    String name = "image:$rand";
    try {
      await firebase_storage.FirebaseStorage.instance
          // Give the image a name
          .ref('$name.jpg')
          // Upload image to firebase
          .putFile(img)
          .then((taskSnapshot) => {
                if (taskSnapshot.state == TaskState.success)
                  {
                    FirebaseStorage.instance
                        .ref('$name.jpg')
                        .getDownloadURL()
                        .then((url) async {
                      var fbRedirect = await FirebaseFirestore.instance
                          .collection("redirect")
                          .doc("AOWHcTNEqq1OMosU0Fav")
                          .set({'redirect': "$url"});

                      var getHistory = await FirebaseFirestore.instance
                          .collection("history")
                          .add({
                        "redirect": url,
                        "date": FieldValue.serverTimestamp(),
                        "type": "img"
                      });

                      Navigator.pop(modal);
                      //FirebaseStorage.instance.refFromURL(url).delete();

                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Redirection modifée'),
                        action: SnackBarAction(
                          label: 'Fermer',
                          onPressed: () {
                            // Some code to undo the change.
                          },
                        ),
                      ));
                      return url;
                    }).catchError((onError) {
                      print("Got Error $onError");
                    })
                  }
              });
    } on firebase_core.FirebaseException catch (e) {
      print(e);
    }
  }

  BuildContext _onLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
    return context;
  }
}
