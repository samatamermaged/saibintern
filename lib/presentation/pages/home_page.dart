import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'apply_page.dart';
import 'track_token_dialog.dart';
import 'cif_dashboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.saibCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        toolbarHeight: 80.0,
        title: Image.asset('assets/images/saibbank.png', height: 60.0),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Chip(
              backgroundColor: AppColors.saibNavy,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: AppColors.saibLightBlue, size: 16.0),
                  SizedBox(width: 4.0),
                  Text('Secure', style: TextStyle(color: Colors.white, fontSize: 12.0)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.white, width: 4.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16.0,
                    offset: Offset(0, 8.0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  'https://images.unsplash.com/photo-1563986768494-4dee2763ff3f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  width: double.infinity,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28.0),

            // Headline
            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saibNavy,
                  fontFamily: 'Segoe UI',
                  height: 1.2,
                ),
                children: [
                  TextSpan(text: 'Banking made for\nyour '),
                  TextSpan(
                    text: 'future.',
                    style: TextStyle(color: AppColors.saibRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Subtitle
            const Text(
              'Open your new account entirely online in minutes. Experience secure, lightning-fast banking without ever stepping foot in a branch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32.0),

            // Open Account Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ApplyPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saibRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 2.0,
                ),
                child: const Text(
                  'Open an Account',
                  style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // Secondary Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const TrackTokenDialog(),
                      );
                    },
                    icon: const Icon(Icons.search, color: AppColors.saibNavy, size: 20.0),
                    label: const Text(
                      'Track Token',
                      style: TextStyle(
                        color: AppColors.saibNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.saibNavy, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CifDashboardPage()),
                      );
                    },
                    icon: const Icon(Icons.person_outline, color: AppColors.saibNavy, size: 20.0),
                    label: const Text(
                      'CIF Dashboard',
                      style: TextStyle(
                        color: AppColors.saibNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.saibNavy, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}