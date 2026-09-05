import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class CifDashboardPage extends StatefulWidget {
  const CifDashboardPage({super.key});

  @override
  State<CifDashboardPage> createState() => _CifDashboardPageState();
}

class _CifDashboardPageState extends State<CifDashboardPage> {
  final TextEditingController _cifController = TextEditingController();
  late Dio _dio;

  bool _isLoading = false;
  bool _profileLoaded = false;
  Map<String, dynamic> _profileData = {};
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _dio = ApiClient.createDio();
  }

  Future<void> _searchCif() async {
    final cif = _cifController.text.trim();
    if (cif.isEmpty) return;

    setState(() {
      _isLoading = true;
      _profileLoaded = false;
    });

    try {
      final response = await _dio.get('/api/account/dashboard/$cif');

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _profileData = response.data['profile'] ?? response.data['Profile'] ?? {};
          _requests = response.data['requests'] ?? response.data['Requests'] ?? [];
          _profileLoaded = true;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMsg = 'Failed to load dashboard.';
      if (e.response?.statusCode == 404) {
        errorMsg = 'No records found for this CIF.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _applyFromCif(String accountType) async {
    try {
      final response = await _dio.post(
          '/api/account/apply-from-cif',
          data: {
            'cif': _cifController.text.trim(),
            'accountType': accountType
          }
      );

      if (response.statusCode == 200) {
        String token = response.data['token'];
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account requested successfully!'), backgroundColor: Colors.green),
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Application Submitted'),
            content: Text('Your tracking token is: $token'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _searchCif(); // Refresh dashboard data
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String error = e.response?.data?['message'] ?? 'Failed to apply.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  void _showNewAccountDialog() {
    String selectedType = 'Saving Account (>21)';
    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Open Additional Account', style: TextStyle(color: AppColors.saibNavy)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Desired Account Type:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Youth Account (16-21)', child: Text('Youth Account (16-21)')),
                    DropdownMenuItem(value: 'Saving Account (>21)', child: Text('Saving Account (>21)')),
                    DropdownMenuItem(value: 'Current Account (>21)', child: Text('Current Account (>21)')),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFromCif(selectedType);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.saibRed, foregroundColor: Colors.white),
                child: const Text('Submit Request'),
              )
            ],
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.saibCream,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 1, toolbarHeight: 80,
        title: const Text('Customer Information Dashboard', style: TextStyle(color: AppColors.saibNavy, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.saibNavy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Enter Your CIF Number', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cifController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'e.g. 123456', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _searchCif,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.saibRed, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24)),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Search Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_profileLoaded) _buildProfileView(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Customer Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showNewAccountDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Open Additional Account'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.saibRed, foregroundColor: Colors.white),
                      ),
                    )
                  ],
                ),
                const Divider(height: 32),

                Row(
                  children: [
                    Expanded(child: _infoItem('FULL NAME (ENGLISH)', _profileData['nameEn'] ?? _profileData['NameEn'] ?? 'N/A')),
                    Expanded(child: _infoItem('BIRTH DATE', _profileData['birthDate'] ?? _profileData['BirthDate'] ?? 'N/A')),
                    Expanded(child: _infoItem('RESIDENTIAL ADDRESS', _profileData['address'] ?? _profileData['Address'] ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _infoItem('FULL NAME (ARABIC)', _profileData['nameAr'] ?? _profileData['NameAr'] ?? 'N/A')),
                    Expanded(child: _infoItem('AGE', _profileData['age']?.toString() ?? _profileData['Age']?.toString() ?? 'N/A')),
                    Expanded(child: _infoItem('EMAIL ADDRESS', _profileData['email'] ?? _profileData['Email'] ?? 'N/A')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _infoItem('NATIONALITY', _profileData['nationality'] ?? _profileData['Nationality'] ?? 'N/A')),
                    Expanded(child: _infoItem('GENDER', _profileData['gender'] ?? _profileData['Gender'] ?? 'N/A')),
                    Expanded(child: _infoItem('MOBILE 1', _profileData['mobile1'] ?? _profileData['Mobile1'] ?? 'N/A')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        DefaultTabController(
          length: 4,
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application & Account History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
                  const SizedBox(height: 16),
                  const TabBar(
                    labelColor: AppColors.saibRed, unselectedLabelColor: Colors.grey, indicatorColor: AppColors.saibRed,
                    tabs: [Tab(text: 'All Requests'), Tab(text: 'Accepted'), Tab(text: 'Pending'), Tab(text: 'Rejected')],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildHistoryList(_requests),
                        _buildHistoryList(_requests.where((r) => _getStatus(r) == 'Accepted').toList()),
                        _buildHistoryList(_requests.where((r) => _getStatus(r) == 'Pending').toList()),
                        _buildHistoryList(_requests.where((r) => _getStatus(r) == 'Rejected').toList()),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStatus(dynamic req) {
    return req['status'] ?? req['Status'] ?? req['applicationStatus'] ?? req['ApplicationStatus'] ?? 'Unknown';
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.saibLightBlue)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
      ],
    );
  }

  Widget _buildHistoryList(List<dynamic> filteredRequests) {
    if (filteredRequests.isEmpty) {
      return const Center(child: Text('No requests found in this category.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final req = filteredRequests[index];

        final status = _getStatus(req);
        final accountType = req['accountType'] ?? req['AccountType'] ?? 'N/A';
        final requestRef = req['requestID']?.toString() ?? req['RequestID']?.toString() ?? 'N/A';
        final accNumber = req['accountNumber'] ?? req['AccountNumber'];

        Color statusColor = Colors.grey;
        if (status == 'Accepted') statusColor = Colors.green;
        if (status == 'Rejected') statusColor = Colors.red;
        if (status == 'Pending') statusColor = Colors.orange;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 1,
          child: ListTile(
            title: Text('Account Type: $accountType', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Ref: REQ-$requestRef${accNumber != null ? '\nAccount #: $accNumber' : ''}'),
            trailing: Chip(
              backgroundColor: statusColor.withValues(alpha: 0.1),
              label: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}