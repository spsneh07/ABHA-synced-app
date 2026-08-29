import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../scanner_ocr_api.dart';
import '../models/medical_record.dart';
import '../widgets/record_card.dart';
import 'record_details_screen.dart';
import '../utils/ocr_parser.dart';
import '../services/abha_service.dart';
import 'abha_records_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final ScannerOcrApi _scannerApi = ScannerOcrApi();
  
  bool _isProcessing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _startScan(String userId) async {
    setState(() => _isProcessing = true);

    try {
      final ScanResult result = await _scannerApi.scanDocument();
      
      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (result.status == ScanStatus.success && result.enhancedImage != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                scanResult: result,
                onSave: () => _saveRecord(userId, result),
              ),
            ),
          );
        }
      } else if (result.status != ScanStatus.cancelled) {
        if (mounted) {
          ErrorDialog.show(context, result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveRecord(String userId, ScanResult result) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final imageUrl = await _storageService.uploadImage(result.enhancedImage!, userId);
      
      if (imageUrl != null) {
        final String extracted = result.extractedText ?? '';
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        
        final newRecord = await OcrParser.analyzeMedicalText(
          extracted, 
          tempId, 
          userId, 
          imageUrl
        );
        
        await _dbService.addRecord(newRecord);
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context); // Close ResultScreen and go back to Dashboard
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record successfully saved!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save image.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, MedicalRecord record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.deleteRecord(record.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted'), backgroundColor: Colors.grey),
        );
      }
    }
  }

  @override
  void dispose() {
    _scannerApi.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Records', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          Consumer<AbhaService>(
            builder: (context, abhaService, child) {
              return IconButton(
                icon: Icon(abhaService.isLinked ? Icons.health_and_safety : Icons.health_and_safety_outlined),
                tooltip: 'Official ABHA Records',
                color: abhaService.isLinked ? Colors.tealAccent : Colors.grey.shade300,
                onPressed: () {
                  if (abhaService.isLinked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AbhaRecordsScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please link your ABHA in your Profile first.')),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search records, doctors, text...',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { _searchQuery = ''; });
                      },
                    )
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('User not logged in'))
          : Stack(
              children: [
                StreamBuilder<List<MedicalRecord>>(
                  stream: _dbService.getUserRecords(userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allRecords = snapshot.data ?? [];
                    
                    final records = allRecords.where((record) {
                      return record.title.toLowerCase().contains(_searchQuery) ||
                             (record.hospitalName?.toLowerCase().contains(_searchQuery) ?? false) ||
                             (record.patientName?.toLowerCase().contains(_searchQuery) ?? false) ||
                             record.extractedText.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.folder_open : Icons.search_off, 
                              size: 80, 
                              color: Colors.grey.shade300
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty 
                                ? 'No medical records yet.'
                                : 'No records match your search.',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isEmpty)
                              Text(
                                'Tap the + button to scan and secure\nyour first document.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: 16), 
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return RecordCard(
                          record: record,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecordDetailsScreen(record: record),
                              ),
                            );
                          },
                          onDelete: () => _confirmDelete(context, record),
                        );
                      },
                    );
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 24),
                              Text('Processing Record...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Extracting text and securing data', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: userId != null
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : () => _startScan(userId),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              icon: const Icon(Icons.document_scanner, color: Colors.white),
              label: const Text('Scan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
