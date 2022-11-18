class RedirectModel {
  String? redirect;
  String? type;

  RedirectModel({this.redirect});

  RedirectModel.fromJson(Map<String, dynamic> json) {
    redirect = json['redirect'];
    type = json['type'];
  }

  Map<String, dynamic> toJson(Map<String, dynamic>? test) {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['redirect'] = this.redirect;
    data['type'] = this.type;
    return data;
  }
}
