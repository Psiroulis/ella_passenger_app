import 'dart:convert';

import 'package:ella_passenger/features/auth/data/models/country.dart';
import 'package:flutter/services.dart';

class CountriesRepository {
  static Future<List<Country>> load() async {
    final raw = await rootBundle.loadString('assets/data/countries.json');
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    final countries = list
        .map((element) => Country.fromJson(element as Map<String, dynamic>))
        .toList();
    countries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return countries;
  }


}
