import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../service/utils_service.dart';

class ProfileController extends GetxController {
  final UtilService utilService = UtilService();
  
  // Observable variables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isEditMode = false.obs; // Add edit mode toggle
  
  // Profile data
  final name = ''.obs;
  final email = ''.obs;
  final age = ''.obs;
  final gender = 'male'.obs;
  final bloodType = 'A'.obs;
  final height = ''.obs;
  
  // Form controllers
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  
  // Dropdown options
  final List<String> genderOptions = ['male', 'female'];
  final List<String> bloodTypeOptions = ['A', 'B', 'AB', 'O'];
  
  @override
  void onInit() {
    super.onInit();
    getUserProfile();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    ageController.dispose();
    heightController.dispose();
    super.onClose();
  }
  
  // Toggle edit mode
  void toggleEditMode() {
    isEditMode.value = !isEditMode.value;
    if (!isEditMode.value) {
      // If exiting edit mode, reset form controllers to original values
      nameController.text = name.value;
      ageController.text = age.value;
      heightController.text = height.value;
    }
  }
  
  // Get user profile from server
  Future<void> getUserProfile() async {
    isLoading.value = true;
    try {
      if (Hive.isBoxOpen('token')) {
        var tokenBox = await Hive.openBox('token');
        final token = tokenBox.getAt(0);
        
        if (token != null) {
          final connect = GetConnect();
          print('Getting user profile from server...');
          
          final response = await connect.get(
            '${utilService.url}/api/me',
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );
          
          print('Profile response: ${response.statusCode}');
          print('Profile response body: ${response.body}');
          
          if (response.statusCode == 200) {
            var user = response.body['user'];
            if (user != null) {
              // Update observable values
              name.value = user['name'] ?? '';
              email.value = user['email'] ?? '';
              age.value = user['age']?.toString() ?? '';
              gender.value = user['gender'] ?? 'male';
              bloodType.value = user['blood_type'] ?? 'A';
              height.value = user['height']?.toString() ?? '';
              
              // Update form controllers
              nameController.text = name.value;
              ageController.text = age.value;
              heightController.text = height.value;
              
              // Save to local storage as cache
              await _saveProfileToLocal(user);
              
              print('Profile loaded from server');
              
              Get.snackbar(
                "Berhasil",
                "Profil berhasil dimuat dari server",
                margin: const EdgeInsets.all(8),
                icon: const Icon(Icons.check, color: Colors.green),
                duration: const Duration(seconds: 2),
              );
            }
          } else {
            print('Failed to get profile from server: ${response.statusCode}');
            await _loadProfileFromLocal();
            
            Get.snackbar(
              "Info",
              "Gagal memuat dari server, menggunakan data lokal",
              margin: const EdgeInsets.all(8),
              icon: const Icon(Icons.info, color: Colors.orange),
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          await _loadProfileFromLocal();
        }
      } else {
        await _loadProfileFromLocal();
      }
    } catch (e) {
      print('Error getting user profile: $e');
      await _loadProfileFromLocal();
      
      Get.snackbar(
        "Error",
        "Terjadi kesalahan saat memuat profil",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Save profile to server
  Future<void> saveProfile() async {
    if (!_validateForm()) return;
    
    isSaving.value = true;
    try {
      if (Hive.isBoxOpen('token')) {
        var tokenBox = await Hive.openBox('token');
        final token = tokenBox.getAt(0);
        
        if (token != null) {
          final connect = GetConnect();
          print('Updating user profile to server...');
          
          final requestData = {
            'name': nameController.text.trim(),
            'age': int.tryParse(ageController.text.trim()) ?? 0,
            'gender': gender.value,
            'blood_type': bloodType.value,
            'height': double.tryParse(heightController.text.trim()) ?? 0.0,
          };
          
          print('Request data: $requestData');
          
          final response = await connect.patch(
            '${utilService.url}/api/me',
            requestData,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          );
          
          print('Update profile response: ${response.statusCode}');
          print('Update profile response body: ${response.body}');
          
          if (response.statusCode == 200) {
            // Update observable values
            name.value = nameController.text.trim();
            age.value = ageController.text.trim();
            height.value = heightController.text.trim();
            
            // Save to local cache
            await _saveProfileToLocal(requestData);
            
            // Exit edit mode after successful save
            isEditMode.value = false;
            
            Get.snackbar(
              "Berhasil",
              "Profil berhasil diperbarui",
              margin: const EdgeInsets.all(8),
              icon: const Icon(Icons.check, color: Colors.green),
              duration: const Duration(seconds: 2),
            );
          } else {
            print('Failed to update profile: ${response.statusCode}');
            Get.snackbar(
              "Gagal",
              "Gagal memperbarui profil: ${response.statusCode}",
              margin: const EdgeInsets.all(8),
              icon: const Icon(Icons.error, color: Colors.red),
              duration: const Duration(seconds: 3),
            );
          }
        } else {
          Get.snackbar(
            "Error",
            "Token tidak ditemukan, silakan login ulang",
            margin: const EdgeInsets.all(8),
            icon: const Icon(Icons.error, color: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      Get.snackbar(
        "Error",
        "Terjadi kesalahan saat menyimpan profil: $e",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSaving.value = false;
    }
  }
  
  // Validate form inputs
  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        "Validasi Error",
        "Nama tidak boleh kosong",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return false;
    }
    
    if (ageController.text.trim().isEmpty) {
      Get.snackbar(
        "Validasi Error",
        "Umur tidak boleh kosong",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return false;
    }
    
    final ageValue = int.tryParse(ageController.text.trim());
    if (ageValue == null || ageValue <= 0 || ageValue > 150) {
      Get.snackbar(
        "Validasi Error",
        "Umur harus berupa angka valid (1-150)",
        margin: const EdgeInsets.all(8),
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return false;
    }
    
    if (heightController.text.trim().isNotEmpty) {
      final heightValue = double.tryParse(heightController.text.trim());
      if (heightValue == null || heightValue <= 0 || heightValue > 300) {
        Get.snackbar(
          "Validasi Error",
          "Tinggi badan harus berupa angka valid (1-300 cm)",
          margin: const EdgeInsets.all(8),
          icon: const Icon(Icons.warning, color: Colors.orange),
        );
        return false;
      }
    }
    
    return true;
  }
  
  // Save profile to local storage
  Future<void> _saveProfileToLocal(Map<String, dynamic> userData) async {
    try {
      var box = await Hive.openBox('userProfile');
      await box.put('profile', userData);
      print('Profile saved to local storage');
    } catch (e) {
      print('Error saving profile to local: $e');
    }
  }
  
  // Load profile from local storage
  Future<void> _loadProfileFromLocal() async {
    try {
      var box = await Hive.openBox('userProfile');
      var userData = box.get('profile');
      
      if (userData != null) {
        name.value = userData['name']?.toString() ?? '';
        email.value = userData['email']?.toString() ?? '';
        age.value = userData['age']?.toString() ?? '';
        gender.value = userData['gender']?.toString() ?? 'male';
        bloodType.value = userData['blood_type']?.toString() ?? 'A';
        height.value = userData['height']?.toString() ?? '';
        
        // Update form controllers
        nameController.text = name.value;
        ageController.text = age.value;
        heightController.text = height.value;
        
        print('Profile loaded from local storage');
      }
    } catch (e) {
      print('Error loading profile from local: $e');
    }
  }
  
  // Refresh profile from server
  Future<void> refreshProfile() async {
    await getUserProfile();
  }
  
  // Get gender display text
  String getGenderDisplay(String genderValue) {
    return genderValue == 'male' ? 'Laki-laki' : 'Perempuan';
  }
}
