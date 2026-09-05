import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class TrackTokenDialog extends StatefulWidget {
  const TrackTokenDialog({super.key});

  @override
  State<TrackTokenDialog> createState() => _TrackTokenDialogState();
}

class _TrackTokenDialogState extends State<TrackTokenDialog> {
  final TextEditingController _tokenController = TextEditingController();
  late Dio _dio;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Use the shared ApiClient so this file automatically uses
    // the same baseUrl and headers defined in ApiClient.
    _dio = ApiClient.createDio();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tracking token.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dio.get(
        '/api/account/status/$token',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Mapped exactly to your C# response:
        // { status = ..., reason = ..., cif = ... }

        final status =
        (data['status'] ?? data['Status'] ?? 'Pending').toString();

        final reason =
        (data['reason'] ?? data['Reason'] ?? '').toString();

        final cif =
        (data['cif'] ?? data['CIF'] ?? data['Cif'] ?? '').toString();

        if (!mounted) return;

        // Close the tracking input dialog
        Navigator.pop(context);

        // Show result dialog
        _showStatusResultDialog(
          status: status,
          reason: reason,
          cif: cif,
          token: token,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;

      String errorMsg = 'Failed to fetch status.';

      if (e.response?.statusCode == 404) {
        errorMsg =
        'Invalid tracking token. Please check and try again.';
      } else if (e.response?.data is Map &&
          e.response?.data['message'] != null) {
        errorMsg = e.response!.data['message'].toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showStatusResultDialog({
    required String status,
    required String reason,
    required String cif,
    required String token,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;

      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.highlight_off;
        break;

      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_outlined;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Application Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.saibNavy,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tracking Token: $token',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 16),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                status.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ACCEPTED
            if (status.toLowerCase() == 'accepted' &&
                cif.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Assigned CIF Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      cif,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.saibNavy,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Use this CIF on the CIF Dashboard to view details and open extra accounts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

            // REJECTED
            if (status.toLowerCase() == 'rejected' &&
                reason.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Rejection Reason',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

            // PENDING
            if (status.toLowerCase() == 'pending')
              const Text(
                'Your application has been received and is currently undergoing review by our operations team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.3,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.saibNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fingerprint,
            size: 64,
            color: AppColors.saibRed,
          ),

          const SizedBox(height: 16),

          const Text(
            'Track Application',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.saibNavy,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter your 8-digit tracking token to check current status.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _tokenController,
            textAlign: TextAlign.center,
            maxLength: 8,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'e.g. 12345678',
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.saibRed,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _checkStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saibRed,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Check Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}