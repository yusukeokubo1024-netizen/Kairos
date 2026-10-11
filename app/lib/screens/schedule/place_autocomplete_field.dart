import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/locale_service.dart';

typedef _PlaceSuggestion = ({String main, String secondary});

/// The schedule form's location field: free text, plus Google place
/// suggestions (via the placesAutocomplete Cloud Function, which holds the
/// API key) shown below it while typing. Biased toward the user's saved
/// weather location.
class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  const PlaceAutocompleteField({super.key, required this.controller, required this.labelText});

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  static const _debounce = Duration(milliseconds: 400);
  static const _minChars = 2;

  final _callable = FirebaseFunctions.instanceFor(region: 'asia-northeast1')
      .httpsCallable('placesAutocomplete');
  final _focusNode = FocusNode();
  Timer? _timer;
  List<_PlaceSuggestion> _suggestions = const [];
  String _lastQuery = '';
  // Groups one typing session's requests (Google bills sessions, not keys).
  String _sessionToken = _newSessionToken();
  num? _lat;
  num? _lng;

  static String _newSessionToken() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
    });
    _loadBias();
  }

  Future<void> _loadBias() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _lat = doc.data()?['weather_lat'] as num?;
      _lng = doc.data()?['weather_lon'] as num?;
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final query = value.trim();
    if (query.length < _minChars) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    _lastQuery = query;
    try {
      final result = await _callable.call<Map<String, dynamic>>({
        'input': query,
        'language': LocaleService.instance.locale.value.languageCode,
        'sessionToken': _sessionToken,
        if (_lat != null && _lng != null) 'lat': _lat!.toDouble(),
        if (_lat != null && _lng != null) 'lng': _lng!.toDouble(),
      });
      // Ignore answers to a query the user has already typed past.
      if (!mounted || query != _lastQuery || !_focusNode.hasFocus) return;
      final list = (result.data['suggestions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) => (main: e['main'] as String? ?? '', secondary: e['secondary'] as String? ?? ''))
          .where((s) => s.main.isNotEmpty)
          .toList();
      setState(() => _suggestions = list);
    } catch (_) {
      // Suggestions are a convenience — typing freely still works.
      if (mounted) setState(() => _suggestions = const []);
    }
  }

  void _select(_PlaceSuggestion place) {
    final text = place.secondary.isEmpty ? place.main : '${place.main} ${place.secondary}';
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _timer?.cancel();
    setState(() {
      _suggestions = const [];
      _sessionToken = _newSessionToken();
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
        ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final place in _suggestions)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place.main),
                    subtitle: place.secondary.isEmpty
                        ? null
                        : Text(place.secondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _select(place),
                  ),
                // Attribution required by the Google Maps Platform terms when
                // Places results are shown outside a Google map.
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Google Maps',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
