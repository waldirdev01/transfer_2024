import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:transfer_2024/app/app_module.dart';
import 'package:transfer_2024/cadastro_direto.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(AppModule());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Transfer 2024',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const CadastroDireto());
  }
}
