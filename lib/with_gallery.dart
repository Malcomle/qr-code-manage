import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:MonLienQr/history_with_gallery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker_web/image_picker_web.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

import 'models/redirect-model.dart';

class WithGallery extends StatefulWidget {
  const WithGallery({super.key});

  @override
  State<WithGallery> createState() => _WithGalleryState();
}

class _WithGalleryState extends State<WithGallery> {
  File? _image;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryWithGallery()),
                  );
                },
                child: Icon(Icons.history),
              )),
        ],
        title: Text("QR_Code : Modification"),
      ),
      body: Stack(
        children: [
          Container(
            child: FutureBuilder<List<RedirectModel>>(
              future: getFav(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return GridView.builder(
                      itemCount: snapshot.data!.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                            onTap: () {
                              uploadImageWithoutHistory(
                                  snapshot.data![index].redirect!);
                            },
                            onDoubleTap: () {
                              deleteToFav(snapshot.data![index].redirect!);
                            },
                            child: ZoomTapAnimation(
                                child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: Image.file(
                                    File(snapshot.data![index].redirect!)),
                              ),
                            )));
                      });
                } else if (snapshot.hasError) {
                  return Text("Error");
                }
                return Text("Loading...");
              },
            ),
          ),
          Positioned(
            right: 30.0,
            bottom: 30.0,
            child: RawMaterialButton(
              onPressed: () {
                uploadImage();
              },
              elevation: 8.0,
              fillColor: Colors.cyan,
              child: Icon(
                Icons.photo,
                size: 18.0,
              ),
              padding: EdgeInsets.all(15.0),
              shape: CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  getImage() async {
    // You can also change the source to gallery like this: "source: ImageSource.camera"

    setState(() {});
  }

  uploadImageWithoutHistory(String img) async {
    //var modal = _onLoading();
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("AOWHcTNEqq1OMosU0Fav")
        .set({'redirect': "$img"});
    //Navigator.pop(modal);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Redirection modifée'),
      action: SnackBarAction(
        label: 'Fermer',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }

  deleteToFav(String img) async {
    //var modal = _onLoading();
    var fav = await FirebaseFirestore.instance
        .collection("fav")
        .where("redirect", isEqualTo: img)
        .get();

    for (var favDoc in fav.docs) {
      FirebaseFirestore.instance.collection("fav").doc("${favDoc.id}").delete();
    }

    setState(() {});

    // Navigator.pop(modal);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Supprimé des favoris'),
      action: SnackBarAction(
        label: 'Fermer',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }

  uploadImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    EasyLoading.show(status: 'loading...');

    if (result != null) {
      Uint8List fileBytes = result.files.first.bytes!;

      // Upload file
      try {
        await FirebaseStorage.instance
            .ref('uploads/${FirebaseAuth.instance.currentUser!.uid}')
            .putData(fileBytes);

        EasyLoading.showProgress(0.3, status: 'Loading...');

        var url = await FirebaseStorage.instance
            .ref('uploads/${FirebaseAuth.instance.currentUser!.uid}')
            .getDownloadURL();

        EasyLoading.showProgress(0.6, status: 'Loading...');

        FirebaseFirestore.instance
            .collection("redirect")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'redirect': url, 'type': 'img'});
      } catch (e) {
        EasyLoading.showError("Oh non pas ça!");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Une erreur a eu lieu'),
          action: SnackBarAction(
            label: 'Fermer',
            onPressed: () {},
          ),
        ));
      }

      EasyLoading.showSuccess("Et Hop!");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Redirection modifée'),
        action: SnackBarAction(
          label: 'Fermer',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      ));
    }
  }

  Future<List<RedirectModel>> getFav() async {
    await Firebase.initializeApp();
    var getHistory = await FirebaseFirestore.instance
        .collection("fav")
        .where("type", isEqualTo: 'img')
        .get();

    var docs = getHistory.docs;
    List<RedirectModel> docsMap = [];

    docs.forEach((doc) {
      var test = doc.data();
      RedirectModel model = RedirectModel.fromJson(test);
      docsMap.add(model);
    });
    return docsMap;
  }
}
