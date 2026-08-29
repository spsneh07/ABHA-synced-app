import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/abha_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import 'edit_profile_screen.dart';
import 'abha_verification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  double? _calculateBMI(String? heightCm, String? weightKg) {
    if (heightCm == null || weightKg == null) return null;
    final h = double.tryParse(heightCm);
    final w = double.tryParse(weightKg);
    if (h != null && w != null && h > 0) {
      final hMeters = h / 100;
      return w / (hMeters * hMeters);
    }
    return null;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi >= 18.5 && bmi < 25) return 'Normal weight';
    if (bmi >= 25 && bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMICategoryColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi >= 18.5 && bmi < 25) return Colors.green;
    if (bmi >= 25 && bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final abhaService = Provider.of<AbhaService>(context);
    final user = authService.user;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: DatabaseService().getUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data ?? UserProfile(uid: user.uid);
          final bmi = _calculateBMI(profile.height, profile.weight);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, profile, user.email ?? ''),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(profile: profile),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Medical Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // BMI / Vitals Card
                _buildVitalsCard(context, profile, bmi),
                const SizedBox(height: 16),

                // Emergency Card
                _buildEmergencyCard(context, profile),
                const SizedBox(height: 16),

                // Clinical Details Card
                _buildClinicalCard(context, profile),
                const SizedBox(height: 16),

                // ABHA Integration Card
                _buildAbhaCard(context, abhaService, primaryColor),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => authService.signOut(),
                    icon: const Icon(Icons.logout, color: Colors.blueGrey),
                    label: const Text('Sign Out', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, authService),
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('Delete Account', style: TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This action is permanent and cannot be undone. All your medical data and profile information will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final error = await authService.deleteAccount();
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile profile, String email) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: profile.photoUrl.isNotEmpty ? NetworkImage(profile.photoUrl) : null,
          child: profile.photoUrl.isEmpty ? Icon(Icons.person, size: 50, color: primaryColor) : null,
        ),
        const SizedBox(height: 16),
        Text(
          profile.name.isNotEmpty ? profile.name : 'Unknown Patient',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge(profile.age.isNotEmpty ? '${profile.age} yrs' : 'Age N/A', Colors.blue),
            const SizedBox(width: 8),
            _buildBadge(profile.gender.isNotEmpty ? profile.gender : 'Gender N/A', Colors.purple),
            const SizedBox(width: 8),
            _buildBadge(profile.bloodType.isNotEmpty ? profile.bloodType : 'Blood N/A', Colors.red),
          ],
        )
      ],
    );
  }

  Widget _buildBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context, UserProfile profile, double? bmi) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 12),
                const Text('Vitals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildInfoRow('Height', profile.height.isNotEmpty ? '${profile.height} cm' : '--')),
                Expanded(child: _buildInfoRow('Weight', profile.weight.isNotEmpty ? '${profile.weight} kg' : '--')),
              ],
            ),
            if (bmi != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBMICategoryColor(bmi).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BMI', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      _getBMICategory(bmi),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getBMICategoryColor(bmi),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalCard(BuildContext context, UserProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 12),
                const Text('Clinical Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Allergies', profile.allergies.isNotEmpty ? profile.allergies : 'None reported'),
            const SizedBox(height: 16),
            _buildInfoRow('Chronic Conditions', profile.conditions.isNotEmpty ? profile.conditions : 'None reported'),
            const SizedBox(height: 16),
            _buildInfoRow('Current Medications', profile.currentMedications.isNotEmpty ? profile.currentMedications : 'None reported'),
            const SizedBox(height: 16),
            _buildInfoRow('Primary Physician', profile.primaryPhysician.isNotEmpty ? profile.primaryPhysician : 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, UserProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.red.shade100)
      ),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Text('Emergency Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Emergency Contact', profile.emergencyContactName.isNotEmpty ? profile.emergencyContactName : 'Not provided'),
            const SizedBox(height: 16),
            _buildInfoRow('Contact Phone', profile.emergencyContactPhone.isNotEmpty ? profile.emergencyContactPhone : 'Not provided'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Organ Donor:', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text(
                  profile.isOrganDonor ? 'YES' : 'NO', 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: profile.isOrganDonor ? Colors.teal : Colors.grey.shade700
                  )
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildAbhaCard(BuildContext context, AbhaService abhaService, Color primaryColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'ABHA Integration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (abhaService.isLinked) ...[
              const Text(
                'Your Ayushman Bharat Health Account is successfully linked.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        abhaService.abhaNumber!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: abhaService.unlinkAbhaAccount,
                child: const Text('Unlink Account', style: TextStyle(color: Colors.red)),
              )
            ] else ...[
              const Text(
                'Link your ABHA ID to sync your medical records securely across the national health network.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AbhaVerificationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Link ABHA Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
