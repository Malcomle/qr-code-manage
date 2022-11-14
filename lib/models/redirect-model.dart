class RedirectModel {
  String? redirect;

  RedirectModel({this.redirect});

  RedirectModel.fromJson(Map<String, dynamic> json) {
    redirect = json['redirect'];
  }

  Map<String, dynamic> toJson(Map<String, dynamic>? test) {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['redirect'] = this.redirect;
    return data;
  }
}
