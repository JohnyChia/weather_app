import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Services/db_service.dart';
import '../Utils/translator.dart';

enum ProfileState { view, edit, loading }

class UserProfile extends StatefulWidget {
  final String userId;

  const UserProfile({super.key, required this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  ProfileState _state = ProfileState.view;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _imageFile;
  String? profileImagePath;

  Map<String, dynamic>? weather;
  bool _isUserLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadWeather();
  }

  Future<void> _loadUser() async {
    final data = await DbService.view('users', {'id': widget.userId});

    if (data.isNotEmpty) {
      final user = data.first;

      setState(() {
        _usernameController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        profileImagePath = user['profile_image'];
        _isUserLoaded = true;
      });
    }
  }

  Future<void> _loadWeather() async {
    final data = await DbService.view('weather', {'user_id': widget.userId});

    if (!mounted) return;

    setState(() {
      if (data.isNotEmpty) {
        weather = data.first;
      }
      _isUserLoaded = true;
    });
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      final fileName = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, file);

      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload error: $e");
      return profileImagePath;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _state = ProfileState.loading);

    try {
      String? imageUrl = profileImagePath;

      if (_imageFile != null) {
        imageUrl = await uploadImage(_imageFile!);
      }

      await DbService.update('users', 'id', widget.userId, {
        'username': _usernameController.text,
        'email': _emailController.text,
        'profile_image': imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _state = ProfileState.edit);
    }
  }

  Future<void> _deleteAccount() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const AutoText("Confirm Delete"),
          content: const AutoText(
              "Are you sure you want to delete your account? This action cannot be undone."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AutoText("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const AutoText(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await DbService.update('users', 'id', widget.userId, {
        'status': 'inactive',
      });

      await Supabase.instance.client.auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AutoText("Account deleted successfully")),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login',
            (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: AutoText("Failed to delete account: $e")),
      );
    }
  }

  PieChartSectionData _section(dynamic val, Color color) {
    final double actualValue = (val ?? 0).toDouble();

    final double visualValue = actualValue < 15 ? 15 : actualValue;

    return PieChartSectionData(
      value: visualValue,
      color: color,
      showTitle: false,
      radius: 22,
    );
  }

  Widget _buildIndicator(Color color, String text, dynamic value) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),

        Flexible(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AutoText(
                text,
                style: const TextStyle(
                  fontWeight: .bold,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              AutoText(
                "${value ?? 0}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const AutoText("User Profile", style: TextStyle(color: Colors.black)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [

                  GestureDetector(
                    onTap: _state == ProfileState.edit ? _pickImage : null,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (profileImagePath != null &&
                          profileImagePath!.startsWith('http')
                          ? NetworkImage(profileImagePath!)
                          : null),
                      child: _imageFile == null && profileImagePath == null
                          ? const Icon(Icons.person, color: Colors.black, size: 45) : null,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: _usernameController,
                    readOnly: _state != ProfileState.edit,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: "Username",
                      labelStyle: TextStyle(color: Colors.black),
                      hintStyle: TextStyle(color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _emailController,
                    readOnly: _state != ProfileState.edit,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.black),
                      hintStyle: TextStyle(color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _state == ProfileState.loading
                              ? null
                              : () async {
                            if (_state == ProfileState.edit) {
                              await _updateProfile();
                            } else {
                              setState(() {
                                _state = ProfileState.edit;
                              });
                            }
                          },
                          child: AutoText(
                            _state == ProfileState.view
                                ? "Update Profile" : "Save Changes",
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _deleteAccount,
                          child: const AutoText("Delete Account"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_isUserLoaded && weather != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [

                          Text(
                            weather!['city'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: .bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                AutoText(
                                  "Temperature: ${weather!['temperature']}°C",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 6),

                                AutoText(
                                  "Humidity: ${weather!['humidity']}%",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 6),

                                AutoText(
                                  "Wind: ${weather!['windSpeed']}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 6),

                                AutoText(
                                  "Risk: ${weather!['risk']}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          const AutoText(
                            "Air Quality Index",
                            style: TextStyle(
                              fontWeight: .bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 140,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 50,
                                      sections: [
                                        _section(weather?['co'], Colors.orange),
                                        _section(weather?['no2'], Colors.red),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment: .center,
                                  crossAxisAlignment: .start,
                                  children: [
                                    _buildIndicator(Colors.orange, "Carbon Monoxide (CO)", weather?['co']),
                                    const SizedBox(height: 12),
                                    _buildIndicator(Colors.red, "Nitrogen Dioxide (NO2)", weather?['no2']),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}