import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Manejo de errores global
//   FlutterError.onError = (FlutterErrorDetails details) {
//     print('Error global: ${details.exception}');
//     // Aquí podrías mostrar un diálogo de error
//   };

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Pedidos App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
//       home: const HomeScreen(),
//     );
//   }
// }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedidos App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'), // Español
        Locale('en', 'US'), // Inglés
      ],
      home: const HomeScreen(),
    );
  }
}
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // ELIMINAR BASE DE DATOS PARA RECREAR CON NUEVA ESTRUCTURA
//   var databasesPath = await getDatabasesPath();
//   String path = '$databasesPath/pedidos_app.db';
//   await deleteDatabase(path);
//   print('🗑️ Base de datos eliminada');

//   runApp(const MyApp());
// }
