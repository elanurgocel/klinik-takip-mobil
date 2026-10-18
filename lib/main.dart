import 'package:flutter/material.dart';
import 'dart:io';
import 'login_page.dart';

// Geliştirme aşamasında yerel SSL sertifika hatalarını aşmak için
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // SSL hatasını yoksayma komutu
  HttpOverrides.global = MyHttpOverrides();

  // Asıl uygulamanın sınıf adını (SaglikTakipApp) çağırıyoruz
  runApp(const SaglikTakipApp());
}

class SaglikTakipApp extends StatelessWidget {
  const SaglikTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klinik Takip Sistemi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(), // İlk açılacak sayfa
    );
  }
}
