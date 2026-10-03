import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../../models/world_clock_city.dart';
import '../../services/world_clock_service.dart';
import '../../utils/world_cities.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  List<WorldClockCity> _cities = [];
  bool _loaded = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final cities = await WorldClockService.instance.load();
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _loaded = true;
    });
  }

  Future<void> _addCity() async {
    final picked = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CityPickerSheet(),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _cities = [..._cities, WorldClockCity(displayName: picked.$1, timezoneId: picked.$2)];
    });
    await WorldClockService.instance.save(_cities);
  }

  Future<void> _removeCity(int index) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _cities = [..._cities]..removeAt(index));
    await WorldClockService.instance.save(_cities);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.worldClockRemoved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    return Scaffold(
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _cities.isEmpty
              ? Center(child: Text(l10n.worldClockEmpty))
              : ListView.builder(
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    final city = _cities[index];
                    final location = tz.getLocation(city.timezoneId);
                    final cityTime = tz.TZDateTime.now(location);
                    final localDay = DateTime(now.year, now.month, now.day);
                    final cityDay = DateTime(cityTime.year, cityTime.month, cityTime.day);
                    final dayDiff = cityDay.difference(localDay).inDays;
                    final dayLabel = switch (dayDiff) {
                      -1 => l10n.worldClockYesterday,
                      1 => l10n.worldClockTomorrow,
                      _ when dayDiff != 0 => null,
                      _ => l10n.worldClockToday,
                    };
                    return Dismissible(
                      key: ValueKey('${city.timezoneId}_${city.displayName}_$index'),
                      onDismissed: (_) => _removeCity(index),
                      background: Container(color: Theme.of(context).colorScheme.errorContainer),
                      child: ListTile(
                        title: Text(city.displayName),
                        subtitle: dayLabel != null ? Text(dayLabel) : null,
                        trailing: Text(
                          '${cityTime.hour.toString().padLeft(2, '0')}:${cityTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCity,
        tooltip: l10n.worldClockAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = worldCities
        .where((c) => c.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.worldClockSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(l10n.worldClockNoResults))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final city = filtered[index];
                          return ListTile(
                            title: Text(city.$1),
                            subtitle: Text(city.$2),
                            onTap: () => Navigator.of(context).pop((city.$1, city.$2)),
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
