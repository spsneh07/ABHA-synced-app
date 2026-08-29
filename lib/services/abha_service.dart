import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medical_record.dart';

class AbhaService extends ChangeNotifier {
  static const String _abhaLinkedKey = 'is_abha_linked';
  static const String _abhaNumberKey = 'abha_number';

  bool _isLinked = false;
  String? _abhaNumber;

  bool get isLinked => _isLinked;
  String? get abhaNumber => _abhaNumber;

  // Storing the expected mock OTP in memory
  String? _expectedOtp;

  AbhaService() {
    _loadAbhaStatus();
  }

  Future<void> _loadAbhaStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLinked = prefs.getBool(_abhaLinkedKey) ?? false;
    _abhaNumber = prefs.getString(_abhaNumberKey);
    notifyListeners();
  }

  Future<String?> sendOtp(String identifier, String mobile) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate a random 6-digit OTP for demo purposes
    _expectedOtp = (100000 + Random().nextInt(900000)).toString();
    return _expectedOtp;
  }

  Future<String?> verifyOtp(String identifier, String otp) async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (otp == _expectedOtp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_abhaLinkedKey, true);
      await prefs.setString(_abhaNumberKey, identifier);
      
      _isLinked = true;
      _abhaNumber = identifier;
      notifyListeners();
      
      return null; // Return null on success
    }
    return 'Invalid OTP entered. Please try again.';
  }

  Future<void> unlinkAbhaAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_abhaLinkedKey);
    await prefs.remove(_abhaNumberKey);
    
    _isLinked = false;
    _abhaNumber = null;
    notifyListeners();
  }

  // New HIU Feature: Fetch Official Records
  Future<List<MedicalRecord>> fetchOfficialHospitalRecords() async {
    await Future.delayed(const Duration(seconds: 3));

    return [
      MedicalRecord(
        id: 'abha_mock_1',
        userId: 'current_user',
        title: 'Apollo Hospitals - Blood Test',
        extractedText: 'Official ABHA Health Record\nPatient: MADHURI HEMANT MANE\nHospital: Apollo Hospitals',
        imageUrl: '', // No image for digital records
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        patientName: 'MADHURI HEMANT MANE',
        hospitalName: 'Apollo Hospitals, Pune',
        medicines: ['Tab. Paracetamol 500mg - 1-0-1'],
        recordDate: '12 May 2026',
        diagnosis: 'Viral Fever',
        patientAge: '48',
        patientGender: 'Female',
      ),
      MedicalRecord(
        id: 'abha_mock_2',
        userId: 'current_user',
        title: 'AIIMS - Orthopedic Consultation',
        extractedText: 'Official ABHA Health Record\nPatient: MADHURI HEMANT MANE\nHospital: AIIMS New Delhi',
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        patientName: 'MADHURI HEMANT MANE',
        hospitalName: 'AIIMS, New Delhi',
        medicines: ['Cap. Vitamin D3 60K IU - Once a week', 'Tab. Calcium 500mg - 1-0-0'],
        recordDate: '01 Mar 2026',
        diagnosis: 'Osteoarthritis',
        patientAge: '48',
        patientGender: 'Female',
      ),
    ];
  }
}
