import 'package:flutter/material.dart';
import 'dart:async';

class SaranSedang extends StatefulWidget {
  const SaranSedang({Key? key}) : super(key: key);

  @override
  _SaranSedangState createState() => _SaranSedangState();
}

class _SaranSedangState extends State<SaranSedang>
    with TickerProviderStateMixin {
  late Timer _phaseTimer;
  String _currentPhase = 'Berjalan';
  int _secondsRemaining = 60;
  double _stickmanPosition = 0.0;
  String _currentGif = 'assets/gif/walking.gif'; // GIF default

  @override
  void initState() {
    super.initState();
    _startPhaseTimer();
  }

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
          if (_secondsRemaining > 45) {
            _stickmanPosition += 0.02;
          }
        });
      } else {
        _phaseTimer.cancel();
        Navigator.of(context).pop();
      }

      if (_secondsRemaining == 45) {
        _currentPhase = 'Duduk';
        _currentGif = 'assets/gif/sitting.gif';
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 236, 200),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aktivitas Untuk Menurunkan Tingkat Stress Sedang',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 205, 102, 0),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                Image.asset(
                  _currentGif,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                Text(
                  _getPhaseDescription(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Waktu Tersisa: $_secondsRemaining detik',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 205, 102, 0),
              ),
              onPressed: () {
                _phaseTimer.cancel();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseDescription() {
    switch (_currentPhase) {
      case 'Berjalan':
        return 'Berjalan kaki santai selama 15 detik';
      case 'Duduk':
        return 'Sesi duduk, tenangkan pikiran, dan Have Fun';
      default:
        return '';
    }
  }
}
