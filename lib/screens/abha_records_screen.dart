import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/abha_service.dart';
import '../models/medical_record.dart';

class AbhaRecordsScreen extends StatefulWidget {
  const AbhaRecordsScreen({Key? key}) : super(key: key);

  @override
  State<AbhaRecordsScreen> createState() => _AbhaRecordsScreenState();
}

class _AbhaRecordsScreenState extends State<AbhaRecordsScreen> {
  late Future<List<MedicalRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    final abhaService = Provider.of<AbhaService>(context, listen: false);
    _recordsFuture = abhaService.fetchOfficialHospitalRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Official ABHA Records', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<MedicalRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D9488)),
                  SizedBox(height: 16),
                  Text('Fetching records from National Health Exchange...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load records: ${snapshot.error}'));
          }

          final records = snapshot.data;
          if (records == null || records.isEmpty) {
            return const Center(child: Text('No official records found on your ABHA ID.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildRecordCard(record);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade200, width: 1.5),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: const Text('ABDM VERIFIED', style: TextStyle(fontSize: 10, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(record.hospitalName ?? 'Unknown Hospital', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(record.recordDate ?? DateFormat('dd MMM yyyy').format(record.createdAt), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            if (record.diagnosis != null && record.diagnosis!.isNotEmpty) ...[
              const Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(record.diagnosis!),
              const SizedBox(height: 12),
            ],
            if (record.medicines != null && record.medicines!.isNotEmpty) ...[
              const Text('Prescribed Medications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              ...record.medicines!.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(m)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
