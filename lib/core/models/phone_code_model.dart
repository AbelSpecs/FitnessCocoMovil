class PhoneCode {
  final int id;
  final String code;
  final int countryId;

  PhoneCode({required this.id, required this.code, required this.countryId});

  factory PhoneCode.fromJson(Map<String, dynamic> json) {
    return PhoneCode(
      id: json['id'] as int,
      code: json['code'] as String,
      countryId: json['countryId'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneCode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
