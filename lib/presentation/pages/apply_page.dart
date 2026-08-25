import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
// تأكد إن المسار ده مطابق لمكان ملف api_client عندك
import '../../core/network/api_client.dart';

// --- Model for Country Codes ---
class CountryCode {
  final String name;
  final String dialCode;
  final String regex;
  final String errorMsg;

  CountryCode({required this.name, required this.dialCode, required this.regex, required this.errorMsg});

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      name: json['countryName'] ?? json['CountryName'] ?? '',
      dialCode: json['dialCode'] ?? json['DialCode'] ?? '',
      regex: json['regexPattern'] ?? json['RegexPattern'] ?? '',
      errorMsg: json['errorMessage'] ?? json['ErrorMessage'] ?? 'Invalid format',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CountryCode && name == other.name && dialCode == other.dialCode;

  @override
  int get hashCode => Object.hash(name, dialCode);
}

class ApplyPage extends StatefulWidget {
  const ApplyPage({super.key});

  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final _formKey = GlobalKey<FormState>();
  late Dio _dio;
  final ImagePicker _picker = ImagePicker();

  // --- Controllers to capture user typing ---
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobile1Controller = TextEditingController();
  final TextEditingController _mobile2Controller = TextEditingController();

  // --- UI State Variables ---
  String? _selectedNationality;
  String _selectedIdType = 'NationalID';
  String? _selectedGov;
  String? _selectedGender;
  String? _selectedAccountType;
  final List<String> _availableAccounts = [];
  bool _isSubmitting = false;

  // --- Country Code Variables ---
  List<CountryCode> _countries = [];
  CountryCode? _selectedCountry1;
  CountryCode? _selectedCountry2;
  bool _isLoadingCountries = true;

  // --- File Variables ---
  File? _photoFile;
  File? _idFile;
  File? _signatureFile;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _fetchCountries();
  }

  // استخدام ApiClient بدلاً من إنشاء Dio من الصفر
  void _setupDio() {
    _dio = ApiClient.createDio();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _idController.dispose();
    _birthdateController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _mobile1Controller.dispose();
    _mobile2Controller.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. API CONNECTION LOGIC
  // ==========================================
  Future<void> _fetchCountries() async {
    try {
      // تم مسح الرابط الثابت والاكتفاء بباقي المسار
      final response = await _dio.get('/Account/countries');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print(response.data);
        setState(() {
          _countries = data.map((json) => CountryCode.fromJson(json)).toList();
          _isLoadingCountries = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print(e);
      setState(() => _isLoadingCountries = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load country codes: $e'), backgroundColor: Colors.red),

      );
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in red.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_photoFile == null || _idFile == null || _signatureFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      FormData formData = FormData.fromMap({
        'NameEnglish': _nameEnController.text,
        'NameArabic': _nameArController.text,
        'Nationality': _selectedNationality,
        'IdType': _selectedIdType,
        'IdNumber': _idController.text,
        'Birthdate': _birthdateController.text,
        'Governorate': _selectedGov,
        'Gender': _selectedGender,
        'Age': _ageController.text,
        'Address': _addressController.text,
        'Email': _emailController.text,
        'Mobile1': '${_selectedCountry1?.dialCode}${_mobile1Controller.text}',
        'Mobile2': _mobile2Controller.text.isNotEmpty ? '${_selectedCountry2?.dialCode}${_mobile2Controller.text}' : '',
        'AccountType': _selectedAccountType,
        'PhotoDoc': await MultipartFile.fromFile(_photoFile!.path, filename: 'photo.jpg'),
        'IdDoc': await MultipartFile.fromFile(_idFile!.path, filename: 'id.jpg'),
        'SignatureDoc': await MultipartFile.fromFile(_signatureFile!.path, filename: 'sig.jpg'),
      });

      // تم مسح الرابط الثابت هنا أيضاً
      final response = await _dio.post('/account/apply', data: formData);
      if (!mounted) return;

      if (response.statusCode == 200) {
        String token = response.data['token'] ?? 'UNKNOWN';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: Text('Your application was submitted.\n\nTracking Token: $token', style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Return to Home'),
              )
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMsg = e.response?.data?['message'] ?? 'Error submitting application: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ==========================================
  // 2. FILE PICKER LOGIC
  // ==========================================
  Future<void> _pickFile(String documentType) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.saibNavy),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.saibNavy),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final File pickedFile = File(picked.path);

      if (!mounted) return;
      setState(() {
        if (documentType == 'Photo') _photoFile = pickedFile;
        if (documentType == 'ID') _idFile = pickedFile;
        if (documentType == 'Signature') _signatureFile = pickedFile;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // 3. EGYPTIAN ID VALIDATION
  // ==========================================
  bool _isValidEgyptianID(String idStr) {
    if (idStr.length != 14 || RegExp(r'[^0-9]').hasMatch(idStr)) return false;
    int centuryDigit = int.parse(idStr[0]);
    if (centuryDigit != 2 && centuryDigit != 3) return false;
    int yearStr = int.parse(idStr.substring(1, 3));
    int month = int.parse(idStr.substring(3, 5));
    int day = int.parse(idStr.substring(5, 7));
    int fullYear = (centuryDigit == 2 ? 1900 : 2000) + yearStr;
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;
    try {
      DateTime checkDate = DateTime(fullYear, month, day);
      if (checkDate.year != fullYear || checkDate.month != month || checkDate.day != day) return false;
    } catch (e) {
      return false;
    }
    int govCode = int.parse(idStr.substring(7, 9));
    if (govCode < 1 || (govCode > 35 && govCode != 88)) return false;
    return true;
  }

  void _extractEgyptianData(String idStr) {
    int centuryDigit = int.parse(idStr[0]);
    int yearStr = int.parse(idStr.substring(1, 3));
    int month = int.parse(idStr.substring(3, 5));
    int day = int.parse(idStr.substring(5, 7));
    int fullYear = (centuryDigit == 2 ? 1900 : 2000) + yearStr;
    String bDateStr = "$fullYear-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    _birthdateController.text = bDateStr;
    _selectedGender = (int.parse(idStr[12]) % 2 != 0) ? 'Male' : 'Female';

    String govCode = idStr.substring(7, 9);
    if (govCode == '01') {
      _selectedGov = 'Cairo';
    } else if (govCode == '02') {
      _selectedGov = 'Alexandria';
    } else if (govCode == '21') {
      _selectedGov = 'Giza';
    } else {
      _selectedGov = 'Other';
    }

    _calculateAgeAndAccounts(bDateStr);
  }

  void _calculateAgeAndAccounts(String bDateStr) {
    try {
      DateTime bDate = DateTime.parse(bDateStr);
      DateTime today = DateTime.now();
      int calculatedAge = today.year - bDate.year;
      if (today.month < bDate.month || (today.month == bDate.month && today.day < bDate.day)) calculatedAge--;
      _ageController.text = calculatedAge.toString();
      _availableAccounts.clear();
      _selectedAccountType = null;
      if (calculatedAge >= 16 && calculatedAge <= 21) _availableAccounts.add('Youth Account (16-21)');
      if (calculatedAge > 21) {
        _availableAccounts.add('Saving Account (>21)');
        _availableAccounts.add('Current Account (>21)');
      }
    } catch (e) {
      _ageController.clear();
      _availableAccounts.clear();
    }
  }

  void _clearAutoFields() {
    _birthdateController.clear();
    _ageController.clear();
    _selectedGov = null;
    _selectedGender = null;
    _selectedAccountType = null;
    _availableAccounts.clear();
  }

  // ==========================================
  // 4. UI BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.saibCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        toolbarHeight: 80.0,
        title: Image.asset('assets/images/saibbank.png', height: 60.0),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.saibNavy), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Account Application', textAlign: TextAlign.center, style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
              ),

              // Section 1: Personal Info
              _buildSectionCard(
                title: '1. Personal Information',
                icon: Icons.badge_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Full Name (English)', controller: _nameEnController, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))], validator: (val) => (val == null || val.isEmpty) ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField('Full Name (Arabic)', controller: _nameArController, isRtl: true, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\u0600-\u06FF\s]'))], validator: (val) => (val == null || val.isEmpty) ? 'Required' : null),
                    const SizedBox(height: 16),
                    const Text('Nationality', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(),
                      initialValue: _selectedNationality,
                      items: const [DropdownMenuItem(value: 'Egyptian', child: Text('Egyptian')), DropdownMenuItem(value: 'Foreign', child: Text('Foreign'))],
                      validator: (val) => val == null ? 'Required' : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedNationality = val;
                          _idController.clear();
                          _clearAutoFields();
                          if (val == 'Egyptian') _selectedIdType = 'NationalID';
                          if (val == 'Foreign') _selectedIdType = 'Passport';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Identification Type', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('National ID', style: TextStyle(fontSize: 14)),
                            value: 'NationalID',
                            groupValue: _selectedIdType,
                            activeColor: AppColors.saibRed,
                            onChanged: _selectedNationality == 'Foreign' ? null : (val) => setState(() => _selectedIdType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Passport', style: TextStyle(fontSize: 14)),
                            value: 'Passport',
                            groupValue: _selectedIdType,
                            activeColor: AppColors.saibRed,
                            onChanged: _selectedNationality == 'Egyptian' ? null : (val) => setState(() => _selectedIdType = val!),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      'ID / Passport Number',
                      controller: _idController,
                      enabled: _selectedNationality != null,
                      inputFormatters: _selectedNationality == 'Egyptian' ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)] : [],
                      onChanged: (val) {
                        if (_selectedNationality == 'Egyptian') {
                          if (val.length == 14 && _isValidEgyptianID(val)) {
                            setState(() => _extractEgyptianData(val));
                          } else {
                            setState(() => _clearAutoFields());
                          }
                        }
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (_selectedNationality == 'Egyptian' && !_isValidEgyptianID(val)) return 'Invalid 14-digit ID';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Birthdate', controller: _birthdateController, enabled: _selectedNationality == 'Foreign', hint: 'YYYY-MM-DD', onChanged: (val) { if (_selectedNationality == 'Foreign') setState(() => _calculateAgeAndAccounts(val)); })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField('Age', controller: _ageController, enabled: false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _inputDecoration().copyWith(labelText: 'Governorate'),
                            initialValue: _selectedGov,
                            items: ['Cairo', 'Alexandria', 'Giza', 'Other'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: _selectedNationality == 'Egyptian' ? null : (val) => setState(() => _selectedGov = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _inputDecoration().copyWith(labelText: 'Gender'),
                            initialValue: _selectedGender,
                            items: ['Male', 'Female'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: _selectedNationality == 'Egyptian' ? null : (val) => setState(() => _selectedGender = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: Contact Details
              _buildSectionCard(
                title: '2. Contact Details',
                icon: Icons.phone,
                child: Column(
                  children: [
                    _buildTextField('Residential Address', controller: _addressController, prefixIcon: Icons.location_on, validator: (val) => (val == null || val.isEmpty) ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField('Email Address', controller: _emailController, prefixIcon: Icons.email, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-+]'))], validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(val)) return 'Invalid Email';
                      return null;
                    }),
                    const SizedBox(height: 16),
                    _buildPhoneField(label: 'Mobile No 1', controller: _mobile1Controller, selectedCountry: _selectedCountry1, isRequired: true, onCountryChanged: (val) => setState(() {
                      _selectedCountry1 = val;
                      _mobile1Controller.clear();
                      _formKey.currentState?.validate();
                    })),
                    const SizedBox(height: 16),
                    _buildPhoneField(label: 'Mobile No 2 (Optional)', controller: _mobile2Controller, selectedCountry: _selectedCountry2, isRequired: false, onCountryChanged: (val) => setState(() {
                      _selectedCountry2 = val;
                      _mobile2Controller.clear();
                      _formKey.currentState?.validate();
                    })),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Account Options
              _buildSectionCard(
                title: '3. Account Options',
                icon: Icons.account_balance_wallet,
                child: DropdownButtonFormField<String>(
                  decoration: _inputDecoration().copyWith(labelText: 'Desired Account Type'),
                  initialValue: _selectedAccountType,
                  items: _availableAccounts.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: _availableAccounts.isEmpty ? null : (val) => setState(() => _selectedAccountType = val),
                  validator: (val) => val == null ? 'Required' : null,
                  hint: Text(_availableAccounts.isEmpty ? 'Calculate age first...' : 'Select Account...'),
                ),
              ),
              const SizedBox(height: 16),

              // Section 4: Required Documents
              _buildSectionCard(
                title: '4. Required Documents',
                icon: Icons.upload_file,
                child: Column(
                  children: [
                    _buildDocumentUploadTile('Personal Photo', Icons.account_box_outlined, _photoFile, () => _pickFile('Photo')),
                    const SizedBox(height: 12),
                    _buildDocumentUploadTile('National ID / Passport', Icons.badge, _idFile, () => _pickFile('ID')),
                    const SizedBox(height: 12),
                    _buildDocumentUploadTile('Digital Signature', Icons.draw, _signatureFile, () => _pickFile('Signature')),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitApplication,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.saibRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
                child: _isSubmitting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Submit Application to Bank', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(color: AppColors.saibNavy, borderRadius: BorderRadius.vertical(top: Radius.circular(12.0))),
            child: Row(children: [Icon(icon, color: AppColors.saibLightBlue), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold))]),
          ),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, {bool isRtl = false, IconData? prefixIcon, String? hint, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator, TextEditingController? controller, bool enabled = true, void Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, enabled: enabled, textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr, validator: validator, inputFormatters: inputFormatters, onChanged: onChanged, decoration: _inputDecoration().copyWith(hintText: hint, prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.saibNavy) : null)),
      ],
    );
  }

  Widget _buildPhoneField({required String label, required TextEditingController controller, required CountryCode? selectedCountry, required bool isRequired, required void Function(CountryCode?) onCountryChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saibNavy)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<CountryCode>(
                key: ValueKey('country-dropdown-${selectedCountry?.dialCode ?? "none"}-$label'),
                decoration: _inputDecoration(),
                isExpanded: true,
                initialValue: selectedCountry,
                hint: _isLoadingCountries ? const Text('...') : const Text('Code'),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.dialCode))).toList(),
                onChanged: onCountryChanged,
                validator: (val) => (isRequired && val == null) ? 'Req.' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration().copyWith(hintText: 'Enter number...'),
                validator: (val) {
                  if (isRequired && (val == null || val.isEmpty)) return 'Required';
                  if (!isRequired && (val == null || val.isEmpty)) return null;
                  if (selectedCountry != null && selectedCountry.regex.isNotEmpty && !RegExp(selectedCountry.regex).hasMatch(val!)) return selectedCountry.errorMsg;
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentUploadTile(String label, IconData icon, File? file, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
      child: Row(
        children: [
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.file(file, width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            Icon(icon, size: 32, color: AppColors.saibLightBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (file != null) Text(file.path.split('/').last, style: const TextStyle(color: Colors.green, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          OutlinedButton(onPressed: onPressed, style: OutlinedButton.styleFrom(side: BorderSide(color: file != null ? Colors.green : AppColors.saibNavy)), child: Text(file != null ? 'Change' : 'Choose', style: TextStyle(color: file != null ? Colors.green : AppColors.saibNavy))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: AppColors.saibRed, width: 2.0)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Colors.red, width: 2.0)),
    );
  }
}