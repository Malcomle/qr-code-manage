import 'dart:math';
import 'dart:io';
import 'package:MonLienQr/home.dart';
import 'package:MonLienQr/with_gallery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker_web/image_picker_web.dart';
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
        title: Text("QR_Code : Modification"),
      ),
      body: Stack(
        children: [
          Container(
            child: FutureBuilder<List<Image>>(
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
                              uploadImageWithoutHistory(index);
                            },
                            onDoubleTap: () {
                              addToFav(index);
                            },
                            child: ZoomTapAnimation(
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: snapshot.data![index]),
                              ),
                            ));
                      });
                } else if (snapshot.hasError) {
                  return Text("Error");
                }
                return Text("Loading...");
              },
            ),
          ),
        ],
      ),
    );
  }

  uploadImageWithoutHistory(int index) async {
    var fav = favoris[index];
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'redirect': "${fav.redirect}", 'type': "img"});

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

  List<RedirectModel> favoris = [];

  addToFav(int index) async {
    var fav = favoris[index];
    FirebaseFirestore.instance.collection("fav").add({
      "redirect": fav.redirect,
      "date": FieldValue.serverTimestamp(),
      "type": "img",
      'user': FirebaseAuth.instance.currentUser!.uid
    });

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

  Future<List<Image>> getHistory() async {
    await Firebase.initializeApp();
    var getHistory = await FirebaseFirestore.instance
        .collection("history")
        .where("type", isEqualTo: 'img')
        .where("user", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .limit(50)
        .get();

    var docs = getHistory.docs;

    List<Image> docsMap = [];

    docs.forEach((doc) async {
      var test = doc.data();
      RedirectModel model = RedirectModel.fromJson(test);
      Image image = Image.network(model.redirect!);
      docsMap.add(image);
      favoris.add(model);
    });

    return docsMap;
  }
}
