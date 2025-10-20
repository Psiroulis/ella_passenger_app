import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/countries_repository.dart';
import '../../data/models/country.dart';

class CountryPicker extends StatefulWidget {
  final Country? initialCountry;
  final String locale;
  final ValueChanged<Country> onSelected;

  const CountryPicker({
    super.key,
    this.initialCountry,
    required this.locale,
    required this.onSelected,
  });

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  Country? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCountry;
  }

  Future<void> _openPicker() async {
    final result = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CountryPickerSheet(locale: widget.locale),
    );

    if (result != null) {
      setState(() => _selected = result);
      widget.onSelected(result); // ενημερώνει τον γονέα
    }
  }

  @override
  Widget build(BuildContext context) {
    final flagPath = _selected != null
        ? 'assets/flags/${countryNameToFile(_selected!.name)}.png'
        : null;
    final dial = _selected?.dialCode ?? '';

    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: _openPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flagPath != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Image.asset(
                flagPath,
                width: 24,
                height: 16,
                fit: BoxFit.cover,
              ),
            ),
          Text('(${dial.isNotEmpty ? dial : '—'})'),
        ],
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final String locale;

  const _CountryPickerSheet({required this.locale});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  List<Country> _all = [];
  String _query = '';

  final List<String> _favorites = [
    "Austria",
    "Germany",
    "United States",
    "United Kingdom",
    "Spain",
    "France",
    "Italy",
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await CountriesRepository.load();
    setState(() => _all = data);
  }

  List<Country> get _filtered {
    if (_query.trim().isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.dialCode.toLowerCase().contains(q) ||
              c.nameGr.toLowerCase().contains(q),
        )
        .toList();
  }

  Map<String, List<Country>> get _grouped {
    final String defaultLocale = Platform.localeName;

    final map = <String, List<Country>>{};
    for (final c in _filtered) {
      if (defaultLocale != "el_GR") {
        final key = c.name.isNotEmpty ? c.name[0].toUpperCase() : '#';
        map.putIfAbsent(key, () => []).add(c);
      } else {
        final key = c.nameGr.isNotEmpty
            ? removeGreekAccents(c.nameGr[0].toUpperCase())
            : '#';
        map.putIfAbsent(key, () => []).add(c);
      }
    }
    final sortedKeys = map.keys.toList()..sort();
    return {
      for (final k in sortedKeys)
        k: (map[k]!..sort((a,b) {
          if (defaultLocale != "el_GR") {
            return a.name.compareTo(b.name);
          } else {
            return removeGreekAccents(a.nameGr).compareTo(removeGreekAccents(b.nameGr));
          }
        }))
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Material(
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: const Text(
                        'Επέλεξε χώρα',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Αναζήτηση',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 4),
              // Λίστα με αλφαβητικό ευρετήριο/ομαδοποίηση
              Expanded(
                child: _all.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: controller,
                        itemCount: _grouped.length,
                        itemBuilder: (context, i) {
                          final letter = _grouped.keys.elementAt(i);
                          final items = _grouped[letter]!;
                          return _Section(
                            header: letter,
                            children: items
                                .map(
                                  (c) => _CountryTile(
                                    country: c,
                                    onTap: () {
                                      Navigator.of(context).pop(c);
                                    },
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String header;
  final List<Widget> children;

  const _Section({required this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Επικεφαλίδα γράμματος
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            header,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...children,
        const Divider(height: 0),
      ],
    );
  }
}

class _CountryTile extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const _CountryTile({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final flagPath = 'assets/flags/${countryNameToFile(country.name)}.png';
    final String defaultLocale = Platform.localeName;
    return ListTile(
      leading: Image.asset(flagPath, width: 28, height: 20, fit: BoxFit.cover),
      title: defaultLocale != "el_GR"
          ? Text('${country.name} (${country.dialCode})')
          : Text('${country.nameGr} (${country.dialCode})'),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

String countryNameToFile(String name) {
  String cleaned = name.replaceAll(' ', '_');

  cleaned = cleaned.replaceAll('(', '').replaceAll(')', '');

  cleaned = cleaned
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõöø]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[ñ]'), 'n');

  return cleaned;
}

String removeGreekAccents(String input) {
  const withAccents = "ΆάΈέΉήΊίΪϊΐΌόΎύΫϋΰΏώ";
  const withoutAccents = "ΑαΕεΗηΙιΙιιΟοΥυΥυυΩω";

  String output = input;
  for (int i = 0; i < withAccents.length; i++) {
    output = output.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return output;
}
