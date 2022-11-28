class RedirectModel {
  String? redirect;
  String? type;
  String? user;
  bool? isRedirect;

  RedirectModel({this.redirect});

  RedirectModel.fromJson(Map<String, dynamic> json) {
    redirect = json['redirect'];
    user = json['user'];
    type = json['type'];
    isRedirect = json['isRedirect'];
  }

  Map<String, dynamic> toJson(Map<String, dynamic>? test) {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['redirect'] = this.redirect;
    data['type'] = this.type;
    data['user'] = this.user;
    data['isRedirect'] = this.isRedirect;
    return data;
  }
}
