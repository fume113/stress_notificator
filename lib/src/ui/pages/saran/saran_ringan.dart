import 'package:flutter/material.dart';
import 'dart:async';

class SaranRingan extends StatefulWidget {
  const SaranRingan({Key? key}) : super(key: key);

  @override
  _SaranRinganState createState() => _SaranRinganState();
}

class _SaranRinganState extends State<SaranRingan>
    with TickerProviderStateMixin {
  late AnimationController _sizeController;
  late Animation<double> _sizeAnimation;
  late Timer _countdownTimer;
  late Timer _phaseTimer;
  int _secondsRemaining = 60;
  String _currentPhase = 'Tarik Nafas';
  double _sizeFactor = 0.8;
  int _currentPhaseDuration = 2;

  Color _circleColor = Colors.teal.withOpacity(0.3);
  Color _textColor = Colors.white; // Mengubah warna teks menjadi putih

  @override
  void initState() {
    super.initState();

    _sizeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {});
      });

    _sizeAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _sizeController, curve: Curves.easeInOut),
    );

    _startCountdown();
    _startPhaseTimer();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _countdownTimer.cancel();
        _phaseTimer.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        return;
      }

      _currentPhaseDuration--;
      if (_currentPhaseDuration <= 0) {
        switch (_currentPhase) {
          case 'Tarik Nafas':
            _currentPhase = 'Tahan Nafas';
            _currentPhaseDuration = 1;
            _sizeFactor = 0.96;
            _sizeController.duration = const Duration(seconds: 1);
            _sizeController.forward(from: 0.0);
            _circleColor = Colors.orange.withOpacity(0.3);
            break;
          case 'Tahan Nafas':
            _currentPhase = 'Buang Nafas';
            _currentPhaseDuration = 3;
            _sizeFactor = 0.8;
            _sizeController.duration = const Duration(seconds: 3);
            _sizeController.reverse(from: 1.0);
            _circleColor = Colors.red.withOpacity(0.3);
            break;
          case 'Buang Nafas':
            _currentPhase = 'Tarik Nafas';
            _currentPhaseDuration = 2;
            _sizeFactor = 0.8;
            _sizeController.duration = const Duration(seconds: 2);
            _sizeController.forward(from: 0.0);
            _circleColor = Colors.teal.withOpacity(0.3);
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _countdownTimer.cancel();
    _phaseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 235, 255),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Latihan Pernapasan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 74, 173),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _sizeController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _currentPhase == 'Tahan Nafas'
                      ? _sizeFactor
                      : _sizeAnimation.value * _sizeFactor,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [_circleColor.withOpacity(0.6), _circleColor],
                        stops: [0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _circleColor.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _currentPhase,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColor, // Teks berwarna putih
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Waktu Tersisa: $_secondsRemaining detik',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 74, 173),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                _countdownTimer.cancel();
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
}
