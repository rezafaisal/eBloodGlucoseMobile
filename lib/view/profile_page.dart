import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../controller/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Profil Saya",
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() => PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  controller.toggleEditMode();
                  break;
                case 'refresh':
                  controller.refreshProfile();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      controller.isEditMode.value ? Icons.visibility : Icons.edit,
                      color: Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(controller.isEditMode.value ? 'Lihat' : 'Edit'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.teal,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  )
                : const Icon(
                    Icons.more_vert,
                    color: Colors.teal,
                  ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.name.value.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                SizedBox(height: 16),
                Text(
                  "Memuat profil...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              // Profile Header Card
              _buildProfileHeader(),
              SizedBox(height: 3.h),
              
              // Profile Form
              _buildProfileForm(),
              
              // Save Button (only show in edit mode)
              Obx(() => controller.isEditMode.value
                  ? Column(
                      children: [
                        SizedBox(height: 3.h),
                        _buildSaveButton(),
                      ],
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade400,
                  Colors.teal.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 10.w,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Name and Email
          Obx(() => Text(
            controller.name.value.isNotEmpty 
                ? controller.name.value 
                : "Nama Pengguna",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          )),
          SizedBox(height: 1.h),
          Obx(() => Text(
            controller.email.value.isNotEmpty 
                ? controller.email.value 
                : "email@example.com",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Obx(() => Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Informasi Pribadi",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          SizedBox(height: 3.h),
          
          // Name Field
          _buildTextField(
            label: "Nama Lengkap",
            controller: controller.nameController,
            icon: Icons.person_outline,
            hintText: "Masukkan nama lengkap",
          ),
          SizedBox(height: 2.h),
          
          // Email Field (Read-only)
          _buildTextField(
            label: "Email",
            controller: TextEditingController(text: controller.email.value),
            icon: Icons.email_outlined,
            hintText: "Email pengguna",
            isReadOnly: true,
          ),
          SizedBox(height: 2.h),
          
          // Age Field
          _buildTextField(
            label: "Umur",
            controller: controller.ageController,
            icon: Icons.calendar_today_outlined,
            hintText: "Masukkan umur (tahun)",
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 2.h),
          
          // Gender Dropdown
          _buildDropdownField(
            label: "Jenis Kelamin",
            value: controller.gender.value,
            items: controller.genderOptions,
            icon: Icons.people_outline,
            onChanged: (value) => controller.gender.value = value!,
            itemBuilder: (value) => controller.getGenderDisplay(value),
          ),
          SizedBox(height: 2.h),
          
          // Blood Type Dropdown
          _buildDropdownField(
            label: "Golongan Darah",
            value: controller.bloodType.value,
            items: controller.bloodTypeOptions,
            icon: Icons.bloodtype_outlined,
            onChanged: (value) => controller.bloodType.value = value!,
            itemBuilder: (value) => value,
          ),
          SizedBox(height: 2.h),
          
          // Height Field
          _buildTextField(
            label: "Tinggi Badan (cm)",
            controller: controller.heightController,
            icon: Icons.height_outlined,
            hintText: "Masukkan tinggi badan",
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    ));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool isReadOnly = false,
  }) {
    bool effectiveReadOnly = isReadOnly || !this.controller.isEditMode.value;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: effectiveReadOnly,
          style: TextStyle(
            fontSize: 16.sp,
            color: effectiveReadOnly ? Colors.grey[600] : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14.sp,
            ),
            prefixIcon: Icon(
              icon,
              color: effectiveReadOnly ? Colors.grey[400] : Colors.teal,
              size: 5.w,
            ),
            filled: true,
            fillColor: effectiveReadOnly ? Colors.grey[100] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3.w),
              borderSide: BorderSide(
                color: Colors.teal,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 2.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    required String Function(String) itemBuilder,
  }) {
    bool isEditModeActive = controller.isEditMode.value;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: isEditModeActive ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: isEditModeActive
              ? DropdownButtonFormField<String>(
                  value: value,
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        itemBuilder(item),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      icon,
                      color: Colors.teal,
                      size: 5.w,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.teal,
                    size: 6.w,
                  ),
                )
              : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: Colors.grey[400],
                        size: 5.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        itemBuilder(value),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 7.h,
      child: ElevatedButton(
        onPressed: controller.isSaving.value
            ? null
            : () => controller.saveProfile(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 2,
          shadowColor: Colors.teal.withOpacity(0.3),
        ),
        child: controller.isSaving.value
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Menyimpan...",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                "Simpan Profil",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ));
  }
}
