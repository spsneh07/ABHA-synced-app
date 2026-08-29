import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/medical_record.dart';

class RecordDetailsScreen extends StatelessWidget {
  final MedicalRecord record;

  const RecordDetailsScreen({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image Header
            if (record.imageUrl.isNotEmpty) 
              Container(
                width: double.infinity,
                height: 350,
                color: Colors.black,
                child: (record.imageUrl.startsWith('http') || record.imageUrl.startsWith('https')
                    ? Image.network(
                        record.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 350,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                        ),
                      )
                    : Image.file(
                        File(record.imageUrl.replaceFirst('file://', '')),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 350,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                        ),
                      )),
              ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.patientName != null || 
                      record.hospitalName != null || 
                      record.medicines.isNotEmpty ||
                      record.recordDate != null ||
                      record.diagnosis != null ||
                      record.patientAge != null ||
                      record.patientGender != null) ...[
                    const Text('AI Extracted Meta-Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2D3748))),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            if (record.hospitalName != null)
                              _buildMetaRow(Icons.local_hospital, 'Hospital/Clinic', record.hospitalName!),
                              
                            if (record.hospitalName != null && record.patientName != null)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),
                              
                            if (record.patientName != null)
                              _buildMetaRow(Icons.person, 'Patient Name', 
                                '${record.patientName!}'
                                '${record.patientAge != null ? ', ${record.patientAge}' : ''}'
                                '${record.patientGender != null ? ' (${record.patientGender})' : ''}'
                              ),

                            if ((record.hospitalName != null || record.patientName != null) && record.recordDate != null)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),
                              
                            if (record.recordDate != null)
                              _buildMetaRow(Icons.calendar_today, 'Record Date', record.recordDate!),

                            if ((record.hospitalName != null || record.patientName != null || record.recordDate != null) && record.diagnosis != null)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),

                            if (record.diagnosis != null)
                              _buildMetaRow(Icons.medical_information, 'Diagnosis', record.diagnosis!),

                            if ((record.hospitalName != null || record.patientName != null || record.recordDate != null || record.diagnosis != null) && record.medicines.isNotEmpty)
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1)),

                            if (record.medicines.isNotEmpty)
                              _buildMetaRow(Icons.medication, 'Prescription / Medicines', record.medicines.join('\n\n')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  const Text('Raw Extracted Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2D3748))),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SelectableText(
                      record.extractedText.isNotEmpty 
                          ? record.extractedText 
                          : 'No readable text was extracted for this record.',
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF4A5568)),
                    ),
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00796B).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00796B), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            ],
          ),
        ),
      ],
    );
  }
}
