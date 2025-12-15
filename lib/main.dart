import 'package:flutter/material.dart';
import 'package:house_pal/Screens/Commom/Auth/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:house_pal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    //- đăng ký state user global
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MyAuthProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HousePal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const SplashScreen(),
      home: AuthWrapper(),
      // home:const NewsScreen(),
    );
  }
}
