import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/abha_service.dart';

class AbhaVerificationScreen extends StatefulWidget {
  const AbhaVerificationScreen({Key? key}) : super(key: key);

  @override
  State<AbhaVerificationScreen> createState() => _AbhaVerificationScreenState();
}

class _AbhaVerificationScreenState extends State<AbhaVerificationScreen> {
  final _identifierController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSimulatedSms(String otp) {
    // Show a distinct popup at the top of the screen simulating an SMS
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(Icons.message, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('New Message - NHA_GOV', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('$otp is your secret OTP for Ayushman Bharat Health Account registration. Valid for 10 minutes. Do not share with anyone.'),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    final identifier = _identifierController.text.trim();
    final mobile = _mobileController.text.trim();
    
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your ABHA or Aadhaar number')));
      return;
    }
    
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit mobile number')));
      return;
    }

    setState(() => _isLoading = true);
    final abhaService = Provider.of<AbhaService>(context, listen: false);
    
    // sendOtp now returns the randomly generated OTP string, or an error message if validation fails in service
    final result = await abhaService.sendOtp(identifier, mobile);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // If result is 6 characters long and numeric, it's our OTP. Otherwise, it's an error string.
      if (result != null && result.length == 6 && int.tryParse(result) != null) {
        setState(() => _otpSent = true);
        
        // Show simulated SMS
        _showSimulatedSms(result);
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? 'Unknown error'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the 6-digit OTP')));
      return;
    }

    setState(() => _isLoading = true);
    final abhaService = Provider.of<AbhaService>(context, listen: false);
    final identifier = _identifierController.text.trim();
    
    final error = await abhaService.verifyOtp(identifier, otp);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        // Success
        Navigator.pop(context); // Go back to profile screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ABHA Account Linked Successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('National Health Authority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.health_and_safety, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Link ABHA Account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ayushman Bharat Health Account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // STEP 1: IDENTIFIER & MOBILE
            TextFormField(
              controller: _identifierController,
              enabled: !_otpSent && !_isLoading,
              decoration: InputDecoration(
                labelText: 'Enter ABHA Number or Aadhaar',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              enabled: !_otpSent && !_isLoading,
              decoration: InputDecoration(
                labelText: 'Enter Linked Mobile Number',
                prefixText: '+91 ',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            
            const SizedBox(height: 16),

            if (!_otpSent)
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Get OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

            // STEP 2: OTP
            if (_otpSent) ...[
              TextFormField(
                controller: _otpController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Enter 6-digit OTP',
                  hintText: 'Check the SMS notification',
                  prefixIcon: const Icon(Icons.lock_clock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Change Details / Resend OTP'),
              )
            ],
            
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'By proceeding, you consent to sharing your medical records with the National Health Network.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
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
