import 'dart:math';
import 'dart:io';
import 'package:MonLienQr/home.dart';
import 'package:MonLienQr/with_gallery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

import 'main.dart';
import 'models/redirect-model.dart';

class HistoryWithGallery extends StatefulWidget {
  const HistoryWithGallery({super.key});

  @override
  State<HistoryWithGallery> createState() => _HistoryWithGallery();
}

class _HistoryWithGallery extends State<HistoryWithGallery> {
  File? _image;

  //final picker = ImagePicker();

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
                        builder: (context) => Home(
                              selectedIndex: 1,
                            )),
                  );
                },
                child: Icon(Icons.arrow_back_ios),
              )),
        ],
        title: Text("QR_Code : Modification"),
      ),
      body: Stack(
        children: [
          Container(
            child: FutureBuilder<List<RedirectModel>>(
              future: getHistory(),
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
                              addToFav(snapshot.data![index].redirect!);
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
    var modal = _onLoading();
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("AOWHcTNEqq1OMosU0Fav")
        .set({'redirect': "$img"});
    Navigator.pop(modal);
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

  addToFav(String img) async {
    var modal = _onLoading();
    FirebaseFirestore.instance.collection("fav").add(
        {"redirect": img, "date": FieldValue.serverTimestamp(), "type": "img"});

    Navigator.pop(modal);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Ajoutée au favoris'),
      action: SnackBarAction(
        label: 'Fermer',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }

  uploadImage() async {
    var pickedFile = null;

    var img = File(pickedFile!.path);

    var modal = _onLoading();

    await Firebase.initializeApp();

    var random = new Random();
    var rand = random.nextInt(1000000000);
    String name = "image:$rand";

    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("AOWHcTNEqq1OMosU0Fav")
        .get();

    var data = fbRedirect.data();
    RedirectModel redirectModel = RedirectModel.fromJson(data!);

    if (redirectModel.type == "img") {
      firebase_storage.FirebaseStorage.instance
          .refFromURL(redirectModel.redirect!)
          .delete();
    }

    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('$name.jpg')
          .putFile(img)
          .then((taskSnapshot) => {
                if (taskSnapshot.state == TaskState.success)
                  {
                    FirebaseStorage.instance
                        .ref('$name.jpg')
                        .getDownloadURL()
                        .then((url) async {
                      var fbRedirect = FirebaseFirestore.instance
                          .collection("redirect")
                          .doc("AOWHcTNEqq1OMosU0Fav")
                          .set({'redirect': url, 'type': 'img'});

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
                    }).catchError((onError) {
                      print("Got Error $onError");
                    })
                  }
              });
    } on firebase_core.FirebaseException catch (e) {
      print(e);
    }
  }

  Future<List<RedirectModel>> getHistory() async {
    var url = "img";
    await Firebase.initializeApp();
    var getHistory = await FirebaseFirestore.instance
        .collection("history")
        .where("type", isEqualTo: url)
        .limit(50)
        .get();

    var docs = getHistory.docs;
    List<RedirectModel> docsMap = [];

    docs.forEach((doc) async {
      var test = doc.data();
      RedirectModel model = RedirectModel.fromJson(test);
      //var image = Image.file(File(model.redirect!));
      docsMap.add(model);
    });

    return docsMap;
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
