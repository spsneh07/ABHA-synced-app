import 'package:flutter/material.dart';
import '../services/abha_service.dart';

class LinkAbhaScreen extends StatefulWidget {
  const LinkAbhaScreen({super.key});

  @override
  State<LinkAbhaScreen> createState() => _LinkAbhaScreenState();
}

class _LinkAbhaScreenState extends State<LinkAbhaScreen> {
  final AbhaService _abhaService = AbhaService();
  final TextEditingController _abhaNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;

  void _sendOtp() async {
    if (_abhaNumberController.text.length < 14) {
      setState(() {
        _errorMessage = 'Please enter a valid 14-digit ABHA number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = await _abhaService.sendOtp(_abhaNumberController.text);
    
    setState(() {
      _isLoading = false;
      if (success) {
        _otpSent = true;
      } else {
        _errorMessage = 'Failed to send OTP. Please try again.';
      }
    });
  }

  void _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = await _abhaService.verifyOtp(_abhaNumberController.text, _otpController.text);
    
    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ABHA Account Linked Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid OTP. For demo use: 123456';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Link ABHA Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D9488), // Teal color representing health
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.health_and_safety_rounded,
              size: 100,
              color: Color(0xFF0D9488),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ayushman Bharat Health Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Link your official digital health identity to instantly access your hospital records from across India.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // ABHA Number Input
            TextField(
              controller: _abhaNumberController,
              enabled: !_otpSent,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter 14-Digit ABHA Number',
                prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF0D9488)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                ),
              ),
            ),
            
            if (_otpSent) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter 6-Digit OTP',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D9488)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Demo Mode: Enter OTP "123456"',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),
            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _otpSent ? 'Verify & Link' : 'Send OTP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
