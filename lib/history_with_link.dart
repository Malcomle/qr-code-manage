import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/redirect-model.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class HistoryWithLink extends StatefulWidget {
  const HistoryWithLink({super.key});

  @override
  State<HistoryWithLink> createState() => _HistoryWithLinkState();
}

class _HistoryWithLinkState extends State<HistoryWithLink> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final redirectInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("QR_Code : Historique"),
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
                        width: width * 0.90,
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

    var data = fbRedirect.data();
    RedirectModel redirectModel = RedirectModel.fromJson(data!);
    redirectInput.text = redirectModel.redirect!;

    //Navigator.pop(contextData);
    return redirectModel;
  }

  submitForm() async {
    var getRedirect = await FirebaseFirestore.instance
        .collection("redirect")
        .doc("AOWHcTNEqq1OMosU0Fav")
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
        .doc("AOWHcTNEqq1OMosU0Fav")
        .set({
      "redirect": redirectInput.value.text,
      "date": FieldValue.serverTimestamp(),
      "type": "url"
    });

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Redirection modif??e'),
      action: SnackBarAction(
        label: 'Fermer',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    ));
  }

  Future<List<RedirectModel>> getHistory() async {
    var url = "url";
    await Firebase.initializeApp();
    var getHistory = await FirebaseFirestore.instance
        .collection("history")
        .where("type", isEqualTo: url)
        .where("user", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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
        .where("user", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (isExist.size >= 1) {
      var id = isExist.docs[0].id;
      FirebaseFirestore.instance.collection("fav").doc("$id").delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${redirectInput.value.text} ?? ??te retir?? des favoris'),
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
          content: Text('${redirectInput.value.text} ?? ??te ajout?? au favoris'),
          action: SnackBarAction(
            label: 'Fermer',
            onPressed: () {
              // Some code to undo the change.
            },
          )));
    }

    setState(() {});
  }

  /*BuildContext _onLoading() {
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
  }*/
}
