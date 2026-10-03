import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  DateTime? _startTime;
  Duration _accumulated = Duration.zero;
  bool _running = false;
  Timer? _ticker;
  final List<Duration> _laps = [];

  Duration get _elapsed =>
      _running ? _accumulated + DateTime.now().difference(_startTime!) : _accumulated;

  void _start() {
    setState(() {
      _startTime = DateTime.now();
      _running = true;
    });
    // Just forces a rebuild every tick — the actual elapsed time is always
    // recomputed from wall-clock timestamps, so this stays correct even if
    // the app is backgrounded and ticks get skipped/delayed.
    _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) => setState(() {}));
  }

  void _stop() {
    _ticker?.cancel();
    setState(() {
      _accumulated = _elapsed;
      _running = false;
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _startTime = null;
      _accumulated = Duration.zero;
      _running = false;
      _laps.clear();
    });
  }

  void _lap() {
    setState(() => _laps.insert(0, _elapsed));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final cs = (d.inMilliseconds.remainder(1000) / 10).floor();
    final hh = h > 0 ? '${h.toString().padLeft(2, '0')}:' : '';
    return '$hh${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTime = _startTime != null;

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 48),
          Text(
            _format(_elapsed),
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, fontFeatures: [
              FontFeature.tabularFigures(),
            ]),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: hasTime ? (_running ? _lap : _reset) : null,
                child: Text(_running ? l10n.stopwatchLap : l10n.stopwatchReset),
              ),
              const SizedBox(width: 24),
              FilledButton(
                onPressed: _running ? _stop : _start,
                child: Text(_running ? l10n.stopwatchStop : l10n.stopwatchStart),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _laps.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: Text(l10n.stopwatchLapNumber(_laps.length - index)),
                trailing: Text(_format(_laps[index]), style: const TextStyle(fontFeatures: [
                  FontFeature.tabularFigures(),
                ])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
