import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/is-redirect-model.dart';
import 'models/redirect-model.dart';

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
    getData();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(children: [
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
                      child: Switch(
                        value: isSwitched,
                        onChanged: (value) {
                          setState(() {
                            isSwitched = value;
                            print(isSwitched);
                          });
                          updateRedirect();
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
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
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith(
                                (states) => Colors.red)),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            redirectInput.text = "";
                          }
                        },
                        child: const Text('Effacer'),
                      ),
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
        "Historique : ",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      ),
      Divider(
        height: 10,
      ),
      FutureBuilder(
          future: getHistory(),
          builder: (context, AsyncSnapshot<List<RedirectModel>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return Container(
                  child: Expanded(
                child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          redirectInput.text = snapshot.data![index].redirect!;
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
      const Text(
        "Favories : ",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      ),
      Divider(
        height: 10,
      ),
      FutureBuilder(
          future: getFav(),
          builder: (context, AsyncSnapshot<List<RedirectModel>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return Container(
                  child: Expanded(
                child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          redirectInput.text = snapshot.data![index].redirect!;

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
    ]);
  }

  Future<RedirectModel> getData() async {
    await Firebase.initializeApp();
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("AOWHcTNEqq1OMosU0Fav")
        .get();

    var fbIsRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("cR1FRK9sulvd22pEfvk3")
        .get();

    var databool = fbIsRedirect.data();
    IsRedirectModel redirectModel2 = IsRedirectModel.fromJson(databool!);
    isSwitched = redirectModel2.isRedirect!;

    var data = fbRedirect.data();
    RedirectModel redirectModel = RedirectModel.fromJson(data!);
    redirectInput.text = redirectModel.redirect!;
    return redirectModel;
  }

  submitForm() async {
    var fbRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("AOWHcTNEqq1OMosU0Fav")
        .set({'redirect': "${redirectInput.value.text}"});

    var getHistory = await FirebaseFirestore.instance
        .collection("history")
        .add({
      "redirect": redirectInput.value.text,
      "date": FieldValue.serverTimestamp()
    });
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
  }

  updateRedirect() async {
    var fbRedirect = FirebaseFirestore.instance
        .collection("redirect")
        .doc("cR1FRK9sulvd22pEfvk3");

    var dataRed = await fbRedirect.get();
    var data = dataRed.data();
    IsRedirectModel redirectModel = IsRedirectModel.fromJson(data!);
    if (redirectModel.isRedirect == true) {
      fbRedirect.set({"isRedirect": false});
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
      fbRedirect.set({"isRedirect": true});
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

  Future<List<RedirectModel>> getHistory() async {
    await Firebase.initializeApp();
    var getHistory = await FirebaseFirestore.instance
        .collection("history")
        .orderBy("date", descending: true)
        .limit(50)
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

  addToFavorite() async {
    var isExist = await FirebaseFirestore.instance
        .collection("fav")
        .where("redirect", isEqualTo: redirectInput.value.text)
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
      var fbRedirect = FirebaseFirestore.instance
          .collection("fav")
          .add({"redirect": redirectInput.value.text});

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
    var getHistory = await FirebaseFirestore.instance.collection("fav").get();

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
