import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'history_with_link.dart';
import 'models/redirect-model.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class WithLink extends StatefulWidget {
  const WithLink({super.key});

  @override
  State<WithLink> createState() => _WithLinkState();
}

class _WithLinkState extends State<WithLink> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final redirectInput = TextEditingController();
  bool isSwitched = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                        builder: (context) => const HistoryWithLink()),
                  ).then((_) => {_refreshData()});
                },
                child: Icon(Icons.history),
              )),
        ],
        title: Text("QR_Code : Modification V0.2.2"),
      ),
      body: Column(children: [
        Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      SizedBox(
                        width: width * 0.75,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter a message',
                            suffixIcon: IconButton(
                              onPressed: redirectInput.clear,
                              icon: Icon(Icons.clear),
                            ),
                          ),
                          controller: redirectInput,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        child: FutureBuilder<RedirectModel>(
                          future: getData(),
                          builder: (context, _snapshot) {
                            return Switch(
                              value: _snapshot.data?.isRedirect ?? false,
                              onChanged: (value) async {
                                await updateRedirect();
                                getData();
                                setState(() {});
                              },
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      RawMaterialButton(
                        onPressed: () {
                          addToFavorite();
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
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                submitForm();
                              }
                            },
                            child: const Text('Modifier'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        const Text(
          "Favoris : ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        Divider(
          height: 10,
        ),
        FutureBuilder(
            future: getFav(),
            builder: (context, AsyncSnapshot<List<RedirectModel>> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Text(''));
              } else {
                return Container(
                    child: Expanded(
                  child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            redirectInput.text =
                                snapshot.data![index].redirect!;

                            SnackBar(
                              content: const Text('Yay! A SnackBar!'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  // Some code to undo the change.
                                },
                              ),
                            );
                          },
                          child: SizedBox(
                            width: width,
                            child: ListTile(
                              title: Text(snapshot.data![index].redirect!),
                            ),
                          ),
                        );
                      }),
                ));
              }
            }),
      ]),
    );
  }

  _refreshData() {
    getFav();
    setState(() {});
  }

  Future<RedirectModel> getData() async {
    var user = FirebaseAuth.instance.currentUser!.uid;
    await Firebase.initializeApp();
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (!fbRedirect.exists) {
      var fbRedirect = await FirebaseFirestore.instance
          .collection("redirect")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        "redirect": "https://google.com",
        "type": "url",
        "isRedirect": true
      });
    }
    var data = fbRedirect.data();
    RedirectModel redirectModel = RedirectModel.fromJson(data!);
    redirectInput.text = redirectModel.redirect!;
    return redirectModel;
  }

  submitForm() async {
    var getRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    var data = getRedirect.data();
    RedirectModel redirectModel = RedirectModel.fromJson(data!);

    if (redirectModel.type == "img") {
      firebase_storage.FirebaseStorage.instance
          .refFromURL(redirectModel.redirect!)
          .delete();
    }

    var updateRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'redirect': "${redirectInput.value.text}",
      'type': 'url',
      "isRedirect": true
    });

    var getHistory =
        await FirebaseFirestore.instance.collection("history").add({
      "redirect": redirectInput.value.text,
      "date": FieldValue.serverTimestamp(),
      "type": "url",
      "user": FirebaseAuth.instance.currentUser!.uid
    });

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Redirection modifiée'),
      action: SnackBarAction(
        label: 'Fermer',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }

  updateRedirect() async {
    var fbRedirect = FirebaseFirestore.instance
        .collection("redirect")
        .doc(FirebaseAuth.instance.currentUser!.uid);

    var dataRed = await fbRedirect.get();
    var data = dataRed.data();
    RedirectModel redirectModel = RedirectModel.fromJson(data!);
    if (redirectModel.isRedirect == true) {
      fbRedirect.update({"isRedirect": false});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Redirection désactivé'),
        action: SnackBarAction(
          label: 'Fermer',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      ));
    } else {
      fbRedirect.update({"isRedirect": true});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Redirection activé'),
        action: SnackBarAction(
          label: 'Fermer',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      ));
    }
  }

  addToFavorite() async {
    var isExist = await FirebaseFirestore.instance
        .collection("fav")
        .where("redirect", isEqualTo: redirectInput.value.text)
        .where(
          "user",
          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
        )
        .get();

    if (isExist.size >= 1) {
      var id = isExist.docs[0].id;
      FirebaseFirestore.instance.collection("fav").doc("$id").delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${redirectInput.value.text} à éte retiré des favoris'),
          action: SnackBarAction(
            label: 'Fermer',
            onPressed: () {
              // Some code to undo the change.
            },
          )));
    } else {
      var fbRedirect = FirebaseFirestore.instance.collection("fav").add({
        "redirect": redirectInput.value.text,
        "date": FieldValue.serverTimestamp(),
        "type": "url",
        "user": FirebaseAuth.instance.currentUser!.uid
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${redirectInput.value.text} à éte ajouté au favoris'),
          action: SnackBarAction(
            label: 'Fermer',
            onPressed: () {
              // Some code to undo the change.
            },
          )));
    }

    setState(() {});
  }

  Future<List<RedirectModel>> getFav() async {
    await Firebase.initializeApp();
    var getHistory = await FirebaseFirestore.instance
        .collection("fav")
        .where("type", isEqualTo: 'url')
        .where("user", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    var docs = getHistory.docs;
    List<RedirectModel> docsMap = [];

    if (docs.isEmpty) {
      return [];
    }
    docs.forEach((doc) {
      var test = doc.data();
      RedirectModel model = RedirectModel.fromJson(test);
      docsMap.add(model);
    });
    return docsMap;
  }
}
