import 'package:flutter/material.dart';
import 'saran_ringan.dart';
import 'saran_sedang.dart';
import 'saran_tinggi.dart';

class SaranStressCard extends StatefulWidget {
  const SaranStressCard({Key? key}) : super(key: key);

  @override
  _SaranStressCardState createState() => _SaranStressCardState();
}

class _SaranStressCardState extends State<SaranStressCard> {
  String? _selectedCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard(
          context,
          title: 'Mengatasi Stres Ringan',
          summary: 'Latihan pernapasan dan istirahat sejenak.',
          details: const [],
          backgroundColor: const Color.fromARGB(255, 227, 235, 255),
          titleColor: const Color.fromARGB(255, 0, 74, 173),
          dividerColor: const Color.fromARGB(255, 0, 74, 173),
          onCardTap: () => _showDialog(SaranRingan()),
          isSelected: _selectedCard == 'ringan',
          onSelect: () => _selectCard('ringan'),
        ),
        _buildCard(
          context,
          title: 'Mengatasi Stres Sedang',
          summary: 'Olahraga ringan, meditasi, dan kegiatan kreatif.',
          details: const [],
          backgroundColor: const Color.fromARGB(255, 255, 236, 200),
          titleColor: const Color.fromARGB(255, 205, 102, 0),
          dividerColor: const Color.fromARGB(255, 205, 102, 0),
          onCardTap: () => _showDialog(SaranSedang()),
          isSelected: _selectedCard == 'sedang',
          onSelect: () => _selectCard('sedang'),
        ),
        _buildCard(
          context,
          title: 'Mengatasi Stres Tinggi',
          summary:
              'Olahraga berat, Aktivitas tubuh, untuk melancarkan Peredaran Darah',
          details: const [],
          backgroundColor: const Color.fromARGB(255, 255, 218, 218),
          titleColor: const Color.fromARGB(255, 156, 0, 0),
          dividerColor: const Color.fromARGB(255, 156, 0, 0),
          onCardTap: () => _showDialog(SaranTinggi()),
          isSelected: _selectedCard == 'tinggi',
          onSelect: () => _selectCard('tinggi'),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String summary,
    required List<String> details,
    required Color backgroundColor,
    required Color titleColor,
    required Color dividerColor,
    required VoidCallback onCardTap,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Card(
      margin: const EdgeInsets.all(15),
      color: isSelected ? backgroundColor.withOpacity(0.8) : backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.black.withOpacity(0.3) : dividerColor,
          width: 2,
        ),
      ),
      elevation: isSelected ? 10 : 5,
      child: InkWell(
        onTap: () {
          onCardTap();
          onSelect();
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(
                color: dividerColor,
                height: 20,
                thickness: 1,
              ),
              Text(
                summary,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    onCardTap();
                    onSelect();
                  },
                  child: Text(
                    'Lihat Saran Aktivitas >',
                    style: TextStyle(color: titleColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialog(Widget dialog) {
    showDialog(
      context: context,
      builder: (context) => dialog,
    );
  }

  void _selectCard(String cardType) {
    setState(() {
      _selectedCard = cardType;
    });
  }
}
