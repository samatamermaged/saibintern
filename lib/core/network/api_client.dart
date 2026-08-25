import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ApiClient {
// 1. استبدل الرقم ده بالـ IPv4 الخاص باللاب توب بتاعك
  static const String baseUrl = 'http://172.20.10.3:5057/api';

static Dio createDio() {
final dio = Dio(BaseOptions(
baseUrl: baseUrl,
connectTimeout: const Duration(seconds: 15),
receiveTimeout: const Duration(seconds: 15), sendTimeout: const Duration(seconds: 15),

// 2. إضافة الـ Headers الأساسية لتعريف لغة الحوار مع السيرفر
// headers: {
// 'Content-Type': 'application/json',
// 'Accept': 'application/json',
// },
));

// 3. الكود الخاص بتخطي شهادات الحماية ممتاز وسنتركه كما هو
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
