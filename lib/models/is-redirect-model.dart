class IsRedirectModel {
  bool? isRedirect;

  IsRedirectModel({this.isRedirect});

  IsRedirectModel.fromJson(Map<String, dynamic> json) {
    isRedirect = json['isRedirect'];
  }

  Map<String, dynamic> toJson(Map<String, dynamic>? test) {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['isRedirect'] = this.isRedirect;
    return data;
  }
}
