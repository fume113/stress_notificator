import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:stress_notificator/src/ui/pages/login/login_page.dart';
import 'package:stress_notificator/src/ui/pages/profile/profile_page.dart';
import 'package:stress_notificator/src/ui/pages/tampil_tingkat_stres/my_tingkat_stress_card.dart';
import 'package:stress_notificator/src/ui/pages/saran/saran_stress_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  int _selectedIndex = 0;

  Future<bool> _isProfileComplete() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      DatabaseReference userRef = _databaseReference
          .child('user_data')
          .child(user.email!.replaceAll('.', ','));
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> profile =
            Map<String, dynamic>.from(snapshot.value as Map);
        return profile.containsKey('name') &&
            profile.containsKey('weight') &&
            profile.containsKey('height') &&
            profile.containsKey('gender');
      }
    } catch (e) {
      print('Error checking profile: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 51),
      appBar: AppBar(
        title: const Text('Home Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 28, 51),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _isProfileComplete(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            } else if (snapshot.hasError) {
              return _buildError(snapshot.error);
            } else if (snapshot.hasData) {
              return _buildContent(snapshot.data ?? false);
            } else {
              return _buildNoData();
            }
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex)
            return; // Hindari reload saat tab yang sama dipilih
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        backgroundColor: const Color.fromARGB(255, 28, 28, 51),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(Object? error) {
    return Center(child: Text('Error: $error'));
  }

  Widget _buildNoData() {
    return const Center(child: Text('Tidak ada data profil.'));
  }

  Widget _buildContent(bool isProfileComplete) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      children: [
        const MyTingkatStresCard(),
        if (!isProfileComplete)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'Silahkan isi profile untuk melihat Riwayat Tingkat Stres',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        const SaranStressCard(),
      ],
    );
  }
}
