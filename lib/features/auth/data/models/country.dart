class Country {
  final String name;
  final String dialCode;
  final String nameGr;

  Country({required this.name, required this.dialCode, required this.nameGr});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      dialCode: json['dialCode'],
      nameGr: json['name_gr'],
    );
  }
}
