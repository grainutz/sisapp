// admin_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});

  @override
  State<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Requests'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton('pending', 'Pending', Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterButton('approved', 'Approved', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterButton('rejected', 'Rejected', Colors.red),
                ),
              ],
            ),
          ),
          
          // Registration Requests List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('registration_requests')
                  .where('status', isEqualTo: _selectedFilter)
                  .orderBy('requestedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data?.docs ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_selectedFilter} requests',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final data = request.data() as Map<String, dynamic>;
                    
                    return _buildRequestCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    final role = data['role'] ?? '';
    final status = data['status'] ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  role == 'student' ? Icons.school : Icons.person,
                  color: role == 'student' ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '${role.toUpperCase()} REQUEST',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: role == 'student' ? Colors.blue : Colors.green,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Name', data['name'] ?? ''),
            _buildInfoRow('Email', data['email'] ?? ''),
            
            if (role == 'student') ...[
              _buildInfoRow('Student ID', data['studentId'] ?? ''),
            ] else if (role == 'teacher') ...[
              _buildInfoRow('Employee ID', data['employeeId'] ?? ''),
              _buildInfoRow('Department', data['department'] ?? ''),
            ],
            
            _buildInfoRow('Requested', _formatDate(data['requestedAt'])),
            
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(data['uid']),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectRequest(data['uid']),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'Unknown';
  }

  Future<void> _approveRequest(String uid) async {
    try {
      // Update user status to approved
      await _firestore.collection('users').doc(uid).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update registration request status
      await _firestore.collection('registration_requests').doc(uid).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String uid) async {
    try {
      // Update user status to rejected
      await _firestore.collection('users').doc(uid).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Update registration request status
      await _firestore.collection('registration_requests').doc(uid).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}