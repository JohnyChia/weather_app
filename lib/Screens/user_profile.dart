import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Services/db_service.dart';

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

    if (data.isNotEmpty) {
      setState(() {
        weather = data.first;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _state = ProfileState.loading);

    try {
      await DbService.update(
        'users',
        'id',
        widget.userId,
        {
          'username': _usernameController.text,
          'email': _emailController.text,
          'profile_image': _imageFile?.path ?? profileImagePath,
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _state = ProfileState.edit);
    }
  }

  Future<void> _deleteAccount() async {
    await DbService.delete('users', 'id', widget.userId);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("User Profile", style: TextStyle(color: Colors.black)),
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
                          : (profileImagePath != null
                          ? FileImage(File(profileImagePath!))
                          : null) as ImageProvider?,
                      child: _imageFile == null && profileImagePath == null
                          ? const Icon(Icons.person, color: Colors.black, size: 45)
                          : null,
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
                          child: Text(
                            _state == ProfileState.view
                                ? "Update Profile"
                                : "Save Changes",
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
                          child: const Text("Delete Account"),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            weather!['city'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Temperature: ${weather!['temperature']}°C",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  "Humidity: ${weather!['humidity']}%",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  "Wind: ${weather!['windSpeed']}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  "Risk: ${weather!['risk']}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            "Air Quality Index",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [

                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 160,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 25,
                                      sections: [
                                        PieChartSectionData(
                                          value: (weather!['co'] ?? 0).toDouble(),
                                          color: Colors.orange,
                                          title: "${weather!['co'] ?? 0}%",
                                          radius: 55,
                                          titleStyle: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: (weather!['no2'] ?? 0).toDouble(),
                                          color: Colors.red,
                                          title: "${weather!['no2'] ?? 0}%",
                                          radius: 55,
                                          titleStyle: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Carbon Monoxide (CO)",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),

                                    Text(
                                      "Nitrogen Dioxide (NO2)",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
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