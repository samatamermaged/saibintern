import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
  // 1. رابط ngrok الحالي
  static const String baseUrl = 'https://skimpily-lemon-crouton.ngrok-free.dev/';

  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),

      // 2. إضافة الـ Headers الأساسية وتخطي شاشة ngrok
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));

    // 3. الكود الخاص بتخطي شهادات الحماية
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

    return dio;
  }
}