import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:transfer_2024/app/app_module.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(AppModule());
}
