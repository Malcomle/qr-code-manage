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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryWithGallery()),
                  ).then((_) => {_refreshData()});
                },
                child: Icon(Icons.history),
              )),
        ],
        title: Text("QR_Code : Modification"),
      ),
      body: Stack(
        children: [
          Container(
            child: FutureBuilder<List<Image>>(
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
                              uploadImageWithoutHistory(index);
                            },
                            onDoubleTap: () {
                              deleteToFav(index);
                            },
                            child: ZoomTapAnimation(
                                child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: snapshot.data![index],
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

  List<RedirectModel> myFav = [];
  _refreshData() async {
    myFav = [];
    getFav();
    setState(() {});
  }

  uploadImageWithoutHistory(int index) async {
    //var modal = _onLoading();
    var redirect = myFav[index];
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'redirect': "${redirect.redirect}", 'type': 'img'});
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

  deleteToFav(int index) async {
    //var modal = _onLoading();
    var deleteFav = myFav[index];
    var fav = await FirebaseFirestore.instance
        .collection("fav")
        .where("redirect", isEqualTo: deleteFav.redirect)
        .where('user', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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

    if (result == null) {
      return;
    }

    EasyLoading.show(status: 'loading...');

    if (result != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      var random = new Random();
      var rand = random.nextInt(1000000000);
      String name = "image:$rand";
      // Upload file
      try {
        await FirebaseStorage.instance
            .ref('${FirebaseAuth.instance.currentUser!.uid}/$name')
            .putData(fileBytes);

        EasyLoading.showProgress(0.3, status: 'Loading...');

        var url = await FirebaseStorage.instance
            .ref('${FirebaseAuth.instance.currentUser!.uid}/$name')
            .getDownloadURL();

        EasyLoading.showProgress(0.6, status: 'Loading...');

        FirebaseFirestore.instance.collection("history").add({
          "redirect": url,
          "date": FieldValue.serverTimestamp(),
          "type": "img",
          "user": FirebaseAuth.instance.currentUser!.uid
        });

        FirebaseFirestore.instance
            .collection("redirect")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'redirect': url, 'type': 'img'});

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
    }
  }

  Future<List<Image>> getFav() async {
    await Firebase.initializeApp();
    var getFav = await FirebaseFirestore.instance
        .collection("fav")
        .where("type", isEqualTo: 'img')
        .where('user', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    var docs = getFav.docs;
    List<Image> docsMap = [];

    docs.forEach((doc) {
      var test = doc.data();
      RedirectModel model = RedirectModel.fromJson(test);
      var image = Image.network(model.redirect!);
      myFav.add(model);
      docsMap.add(image);
    });
    return docsMap;
  }
}
