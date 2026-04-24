import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value;
    final profile = user?.profile ?? {};

    _nameController = TextEditingController(text: profile['fullName']?.toString() ?? '');
    _ageController = TextEditingController(text: profile['age']?.toString() ?? '');
    _heightController = TextEditingController(text: profile['heightCm']?.toString() ?? '');
    _weightController = TextEditingController(text: profile['weightKg']?.toString() ?? '');
    
    _selectedGender = profile['gender']?.toString();
    if (_selectedGender != null && !_genders.contains(_selectedGender)) {
      _selectedGender = null;
    }

    _selectedBloodGroup = profile['bloodGroup']?.toString();
    if (_selectedBloodGroup != null && !_bloodGroups.contains(_selectedBloodGroup)) {
      _selectedBloodGroup = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'fullName': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'heightCm': double.tryParse(_heightController.text.trim()),
        'weightKg': double.tryParse(_weightController.text.trim()),
        'gender': _selectedGender,
        'bloodGroup': _selectedBloodGroup,
      };

      updates.removeWhere((key, value) => value == null);

      await ref.read(authProvider.notifier).updateProfile(updates);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AyushColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Profile', style: AyushTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AyushColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AyushSpacing.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Full Name', _nameController, Icons.person_outline),
              const SizedBox(height: AyushSpacing.lg),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Age', _ageController, Icons.cake_outlined, isNumber: true)),
                  const SizedBox(width: AyushSpacing.md),
                  Expanded(
                    child: _buildDropdown(
                      'Gender', 
                      _selectedGender, 
                      _genders, 
                      (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AyushSpacing.lg),

              Row(
                children: [
                  Expanded(child: _buildTextField('Height (cm)', _heightController, Icons.height, isNumber: true)),
                  const SizedBox(width: AyushSpacing.md),
                  Expanded(child: _buildTextField('Weight (kg)', _weightController, Icons.monitor_weight_outlined, isNumber: true)),
                ],
              ),
              const SizedBox(height: AyushSpacing.lg),

              _buildDropdown(
                'Blood Group', 
                _selectedBloodGroup, 
                _bloodGroups, 
                (val) => setState(() => _selectedBloodGroup = val),
              ),

              const SizedBox(height: AyushSpacing.xxl),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AyushColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AyushSpacing.radiusLg)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes', style: AyushTextStyles.h3.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.name,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AyushColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AyushSpacing.radiusLg),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
