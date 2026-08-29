import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RealAbhaService extends ChangeNotifier {
  // =========================================================================
  // ABDM Sandbox Credentials
  // Register at https://sandbox.abdm.gov.in to get these credentials
  // =========================================================================
  static const String _clientId = 'YOUR_SANDBOX_CLIENT_ID';
  static const String _clientSecret = 'YOUR_SANDBOX_CLIENT_SECRET';

  // Base URLs for ABDM Sandbox
  static const String _gatewayUrl = 'https://dev.abdm.gov.in/gateway/v0.5';
  static const String _abhaAuthUrl = 'https://healthidsbx.abdm.gov.in/api/v1/auth';

  // State Variables
  String? _accessToken;
  String? _transactionId;
  bool _isLinked = false;
  String? _linkedAbhaNumber;
  String? _userToken; // X-Token for actual data operations

  bool get isLinked => _isLinked;
  String? get linkedAbhaNumber => _linkedAbhaNumber;

  RealAbhaService() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isLinked = prefs.getBool('real_abha_linked') ?? false;
    _linkedAbhaNumber = prefs.getString('real_abha_number');
    _userToken = prefs.getString('real_abha_token');
    notifyListeners();
  }

  /// PHASE 1: GENERATE GATEWAY ACCESS TOKEN
  /// This token is required to talk to ANY ABDM API.
  Future<bool> generateGatewayToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "clientId": _clientId,
          "clientSecret": _clientSecret
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        return true;
      } else {
        print('ABDM Gateway Token Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Network Error: $e');
      return false;
    }
  }

  /// PHASE 2: SEND OTP TO ABHA NUMBER
  Future<String?> sendOtp(String abhaNumber) async {
    // 1. Ensure we have a gateway token first
    if (_accessToken == null) {
      bool tokenSuccess = await generateGatewayToken();
      if (!tokenSuccess) return 'Failed to authenticate with ABDM Gateway. Check Client ID/Secret.';
    }

    try {
      // Generate a unique Request ID for auditing
      final requestId = const Uuid().v4();

      final response = await http.post(
        Uri.parse('$_abhaAuthUrl/init'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
          'X-CM-ID': 'sbx' // Consent Manager ID for Sandbox
        },
        body: jsonEncode({
          "authMethod": "MOBILE_OTP",
          "healthid": abhaNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _transactionId = data['txnId']; // We need this txnId for verification
        return null; // Null means success
      } else {
        final error = jsonDecode(response.body);
        return error['details']?[0]?['message'] ?? 'Failed to send real OTP';
      }
    } catch (e) {
      return 'Network Error: $e';
    }
  }

  /// PHASE 2: VERIFY REAL OTP
  Future<String?> verifyOtp(String abhaNumber, String otp) async {
    if (_transactionId == null) return 'Transaction ID missing. Send OTP again.';

    try {
      final response = await http.post(
        Uri.parse('$_abhaAuthUrl/confirmWithMobileOTP'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          "otp": otp,
          "txnId": _transactionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userToken = data['token']; // The official user token (X-Token)

        // Save successfully linked state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('real_abha_linked', true);
        await prefs.setString('real_abha_number', abhaNumber);
        await prefs.setString('real_abha_token', _userToken!);

        _isLinked = true;
        _linkedAbhaNumber = abhaNumber;
        notifyListeners();

        return null; // Success
      } else {
        final error = jsonDecode(response.body);
        return error['details']?[0]?['message'] ?? 'Invalid OTP';
      }
    } catch (e) {
      return 'Network Error: $e';
    }
  }

  /// PHASE 3: HIU DATA FETCHING (PREVIEW)
  /// Note: Fetching actual FHIR data requires a webhook server to receive
  /// the asynchronous payload, and standard Diffie-Hellman cryptographic
  /// keys to decrypt the payload. 
  Future<void> requestHospitalRecords() async {
    if (_userToken == null) return;
    
    // In a full production HIU architecture, this function would:
    // 1. Generate RSA Public/Private Key pairs
    // 2. Call /v0.5/consent-requests/init
    // 3. Wait for the user to approve consent on their phone
    // 4. Receive the encrypted FHIR bundle on your backend Webhook
    // 5. Decrypt the FHIR bundle using your Private Key
    // 6. Return the parsed MedicalRecords to Flutter
    print("Requesting records via ABDM Consent Manager...");
  }
}
