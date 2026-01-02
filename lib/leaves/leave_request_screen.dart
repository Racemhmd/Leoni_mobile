import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _reasonController = TextEditingController();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = false;
  String? _matricule;
  String? _fullName;
  String? _leaveType;
  int _days = 0;
  int _leaveBalance = 0; // Default or fetched
  List<dynamic> _leaveTypes = [];
  List<dynamic> _supervisors = [];
  List<dynamic> _hrAdmins = [];
  int? _selectedSupervisorId;
  int? _selectedHrAdminId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchLeaveTypes();
    _fetchApprovers();
  }

  Future<void> _fetchApprovers() async {
      try {
          // Fetch Supervisors
          final supervisors = await _apiService.get('/users?role=SUPERVISOR');
          // Fetch HR Admins
          final hrs = await _apiService.get('/users?role=HR_ADMIN');

          if (mounted) {
              setState(() {
                  _supervisors = supervisors ?? [];
                  _hrAdmins = hrs ?? [];
              });
          }
      } catch (e) {
          debugPrint('Failed to fetch approvers: $e');
      }
  }

  Future<void> _fetchLeaveTypes() async {
      try {
          final types = await _apiService.get('/leaves/types');
          if (mounted) {
              setState(() {
                  _leaveTypes = types;
                  if (_leaveTypes.isNotEmpty) {
                      _leaveType = _leaveTypes[0]['code'];
                  }
              });
          }
      } catch (e) {
          debugPrint('Failed to fetch leave types: $e');
      }
  }
// ...
// ...


  Future<void> _loadUserProfile() async {
    // Ideally fetch from API /profile, but for now we might mock or use stored token info if available
    // For this demo, let's fetch profile
    try {
        final profile = await _apiService.get('/auth/profile');
        setState(() {
            _matricule = profile['matricule'];
            _fullName = profile['fullName'];
            _leaveBalance = profile['leaveBalance'] ?? 20; // Mock balance if not set
        });
    } catch (e) {
        debugPrint('Failed to load profile: $e');
    }
  }

  void _calculateDays() {
    if (_startDateController.text.isNotEmpty && _endDateController.text.isNotEmpty) {
      final start = DateTime.parse(_startDateController.text);
      final end = DateTime.parse(_endDateController.text);
      final diff = end.difference(start).inDays + 1; // Inclusive
      setState(() {
        _days = diff > 0 ? diff : 0;
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
         return Theme(
           data: Theme.of(context).copyWith(
             colorScheme: const ColorScheme.light(
               primary: Color(0xFF003366), 
             ),
           ),
           child: child!,
         );
      }
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
      _calculateDays();
    }
  }

  Future<void> _submit() async {
    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) return;

    if (_selectedSupervisorId == null) {
        showSnackBar('Please select a supervisor');
        return;
    }
    if (_selectedHrAdminId == null) {
        showSnackBar('Please select an HR Admin');
        return;
    }

    // Find selected type config
    final selectedTypeConfig = _leaveTypes.firstWhere(
        (t) => t['code'] == _leaveType,
        orElse: () => null,
    );
    
    // Check balance if required
    if (selectedTypeConfig != null && selectedTypeConfig['requiresBalance'] == true) {
        if (_days > _leaveBalance) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insufficient leave balance for this leave type'), backgroundColor: Colors.red),
            );
            return;
        }
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.post('/leaves', {
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'leaveType': _leaveType,
        'reason': _reasonController.text,
        'supervisorId': _selectedSupervisorId,
        'hrAdminId': _selectedHrAdminId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted to LTG System')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('New Leave Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF003366),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _buildEmployeeInfoCard(),
                    const SizedBox(height: 24),
                    _buildFormCard(),
                ],
            ),
        ),
    );
  }

  Widget _buildEmployeeInfoCard() {
      return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              _buildInfoField('EMPLOYEE', _fullName ?? 'Loading...'),
                              _buildInfoField('MATRICULE', _matricule ?? '...'),
                          ],
                      ),
                      const Divider(height: 24),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              _buildInfoField('CURRENT BALANCE', '$_leaveBalance Days'),
                              const Icon(Icons.info_outline, color: Colors.grey),
                          ],
                      ),
                  ],
              ),
          ),
      );
  }

  Widget _buildInfoField(String label, String value) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
          ],
      );
  }

  Widget _buildFormCard() {
      return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text('REQUEST DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 20),
                      
                      DropdownButtonFormField<String>(
                          value: _leaveType,
                          decoration: _inputDecoration('Leave Type'),
                          items: _leaveTypes.map<DropdownMenuItem<String>>((t) {
                              return DropdownMenuItem<String>(
                                  value: t['code'],
                                  child: Text(t['label']),
                              );
                          }).toList(),
                          onChanged: (v) => setState(() => _leaveType = v!),
                      ),
                      const SizedBox(height: 16),
                       DropdownButtonFormField<int>(
                          value: _selectedSupervisorId,
                          decoration: _inputDecoration('Supervisor'),
                          items: _supervisors.map<DropdownMenuItem<int>>((s) {
                                return DropdownMenuItem<int>(
                                    value: s['id'],
                                    child: Text(s['fullName']),
                                );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSupervisorId = v!),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                          value: _selectedHrAdminId,
                          decoration: _inputDecoration('HR Admin'),
                          items: _hrAdmins.map<DropdownMenuItem<int>>((h) {
                                return DropdownMenuItem<int>(
                                    value: h['id'],
                                    child: Text(h['fullName']),
                                );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedHrAdminId = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                          children: [
                              Expanded(
                                  child: TextField(
                                      controller: _startDateController,
                                      readOnly: true,
                                      decoration: _inputDecoration('Start Date').copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
                                      onTap: () => _selectDate(_startDateController),
                                  ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: TextField(
                                      controller: _endDateController,
                                      readOnly: true,
                                      decoration: _inputDecoration('End Date').copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
                                      onTap: () => _selectDate(_endDateController),
                                  ),
                              ),
                          ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                const Text('Total Duration:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('$_days Days', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                            ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: _inputDecoration('Reason (Optional)'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003366),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  elevation: 0,
                              ),
                              onPressed: _submit,
                              child: const Text('SUBMIT REQUEST', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ),
                      ),
                  ],
              ),
          ),
      );
  }

  InputDecoration _inputDecoration(String label) {
      return InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF003366))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          filled: true,
          fillColor: Colors.white,
      );
  }
}
