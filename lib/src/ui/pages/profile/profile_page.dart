import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stress_notificator/src/ui/pages/home/home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGender = 'Laki-Laki';
  File? _image;
  String? _imageUrl;
  final _picker = ImagePicker();
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  int _selectedIndex = 1; // Menyimpan indeks tab yang dipilih

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = _databaseReference
          .child('user_data')
          .child(user.email!.replaceAll('.', ','));
      DataSnapshot snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<String, dynamic> profile =
            Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _weightController.text = profile['weight'] ?? '';
          _heightController.text = profile['height'] ?? '';
          _selectedGender = profile['gender'] ?? 'Laki-Laki';
          _imageUrl = profile['image'];
        });
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      Reference storageReference = FirebaseStorage.instance.ref(
          'profile_images/${FirebaseAuth.instance.currentUser!.email}.jpg');
      TaskSnapshot taskSnapshot = await storageReference.putFile(image);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _deleteImage() async {
    try {
      Reference storageReference = FirebaseStorage.instance.ref(
          'profile_images/${FirebaseAuth.instance.currentUser!.email}.jpg');
      await storageReference.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  void _showCustomPopup(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  Future<void> _saveForm() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? imageUrl =
          _image != null ? await _uploadImage(_image!) : _imageUrl;
      final newProfileData = {
        'gender': _selectedGender,
        'height': _heightController.text,
        'image': imageUrl,
        'name': _nameController.text,
        'weight': _weightController.text,
      };

      final emailKey = user.email!.replaceAll('.', ',');
      final userRef = _databaseReference.child('user_data/$emailKey');

      try {
        await userRef.update(newProfileData);
        _showCustomPopup('Data Profile Berhasil Disimpan!');

        // Redirect to HomePage setelah menutup popup
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      } catch (e) {
        _showCustomPopup('Error saving profile data.');
        print('Error saving profile data: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Lihat Foto'),
              onTap: () {
                Navigator.pop(context);
                if (_imageUrl != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Image.network(_imageUrl!),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Hapus Foto'),
              onTap: () async {
                await _deleteImage();
                setState(() {
                  _image = null;
                  _imageUrl = null;
                });
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final emailKey = user.email!.replaceAll('.', ',');
                  final userRef =
                      _databaseReference.child('user_data/$emailKey');
                  await userRef.child('image').remove();
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected page
    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = const HomePage();
        break;
      case 1:
        page = const ProfilePage();
        break;
      default:
        page = const HomePage();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 28, 51),
      appBar: AppBar(
        title:
            const Text('Profile Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 28, 51),
        actions: [
          IconButton(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset('assets/SN.png'),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _image == null && _imageUrl == null
                            ? _pickImage
                            : _showImageOptions,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : _imageUrl != null
                                  ? NetworkImage(_imageUrl!) as ImageProvider
                                  : const AssetImage('assets/unknown.png'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 52, 52, 89),
                      labelText: 'Nama',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    items: const [
                      DropdownMenuItem(
                        value: 'Laki-Laki',
                        child: Text('Laki-Laki'),
                      ),
                      DropdownMenuItem(
                        value: 'Perempuan',
                        child: Text('Perempuan'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 52, 52, 89),
                      labelText: 'Jenis Kelamin',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _weightController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 52, 52, 89),
                      labelText: 'Berat Badan',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _heightController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 52, 52, 89),
                      labelText: 'Tinggi Badan',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color.fromARGB(255, 28, 28, 51),
        selectedItemColor: const Color.fromARGB(255, 75, 57, 239),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
