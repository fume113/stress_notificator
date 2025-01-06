import 'package:flutter/material.dart';

class SaranTinggi extends StatefulWidget {
  const SaranTinggi({Key? key}) : super(key: key);

  @override
  _SaranTinggiState createState() => _SaranTinggiState();
}

class _SaranTinggiState extends State<SaranTinggi>
    with TickerProviderStateMixin {
  late AnimationController _activityController;

  @override
  void initState() {
    super.initState();

    _activityController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(() {
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 218, 218), // Merah lembut
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Beberapa Pilihan olahraga untuk meringankan Stres Tinggi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 156, 0, 0), // Merah gelap
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimations(),
            const SizedBox(height: 20),
            Text(
              'Pilihan olahraga diatas merupakan pilihan olahraga yang umum dan mudah dilakukan',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 156, 0, 0), // Merah gelap
              ),
              onPressed: () {
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

  Widget _buildAnimations() {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildSingleAnimation('Sepak Bola', 'assets/gif/soccer.gif'),
            _buildSingleAnimation('Basket', 'assets/gif/basket.gif'),
            _buildSingleAnimation('Tenis', 'assets/gif/tennis.gif'),
            _buildSingleAnimation('Lari', 'assets/gif/running.gif'),
            _buildSingleAnimation('Jalan Ringan', 'assets/gif/walking.gif'),
            _buildSingleAnimation('Berenang', 'assets/gif/swimming.gif'),
          ]),
    );
  }

  Widget _buildSingleAnimation(String activity, String assetPath) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 100,
            width: 100,
            child: Center(
              child: _buildAnimatedImage(assetPath),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          activity,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnimatedImage(String assetPath) {
    final animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _activityController,
        curve: Curves.elasticInOut,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
