import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _bloodTypeController;
  
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _medicationsController;
  late TextEditingController _physicianController;
  
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  String _gender = '';
  bool _isOrganDonor = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(text: widget.profile.age);
    _heightController = TextEditingController(text: widget.profile.height);
    _weightController = TextEditingController(text: widget.profile.weight);
    _bloodTypeController = TextEditingController(text: widget.profile.bloodType);
    
    _allergiesController = TextEditingController(text: widget.profile.allergies);
    _conditionsController = TextEditingController(text: widget.profile.conditions);
    _medicationsController = TextEditingController(text: widget.profile.currentMedications);
    _physicianController = TextEditingController(text: widget.profile.primaryPhysician);
    
    _emergencyNameController = TextEditingController(text: widget.profile.emergencyContactName);
    _emergencyPhoneController = TextEditingController(text: widget.profile.emergencyContactPhone);
    
    _gender = widget.profile.gender.isNotEmpty ? widget.profile.gender : 'Not Specified';
    _isOrganDonor = widget.profile.isOrganDonor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _physicianController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final updatedProfile = widget.profile.copyWith(
      name: _nameController.text.trim(),
      age: _ageController.text.trim(),
      gender: _gender,
      height: _heightController.text.trim(),
      weight: _weightController.text.trim(),
      bloodType: _bloodTypeController.text.trim(),
      allergies: _allergiesController.text.trim(),
      conditions: _conditionsController.text.trim(),
      currentMedications: _medicationsController.text.trim(),
      primaryPhysician: _physicianController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      isOrganDonor: _isOrganDonor,
    );

    await DatabaseService().saveUserProfile(updatedProfile);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medical Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Information', Icons.person),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.calendar_today)),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                      items: ['Not Specified', 'Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _gender = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Vitals', Icons.monitor_weight),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(labelText: 'Height (cm)', prefixIcon: Icon(Icons.height)),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale)),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bloodTypeController,
                decoration: const InputDecoration(labelText: 'Blood Type (e.g. O+)', prefixIcon: Icon(Icons.bloodtype)),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z+\-]'))],
              ),
              const SizedBox(height: 32),
              
              _buildSectionHeader('Clinical History', Icons.medical_services),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies', prefixIcon: Icon(Icons.warning_amber)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(labelText: 'Chronic Conditions / Past History', prefixIcon: Icon(Icons.history)),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(labelText: 'Current Medications', prefixIcon: Icon(Icons.medication)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _physicianController,
                decoration: const InputDecoration(labelText: 'Primary Care Physician', prefixIcon: Icon(Icons.local_hospital)),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('Emergency', Icons.emergency),
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(labelText: 'Emergency Contact Name', prefixIcon: Icon(Icons.contacts)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(labelText: 'Emergency Contact Phone', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Registered Organ Donor', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Opt-in to indicate you are an organ donor.'),
                value: _isOrganDonor,
                activeColor: Colors.teal,
                onChanged: (bool value) {
                  setState(() {
                    _isOrganDonor = value;
                  });
                },
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
