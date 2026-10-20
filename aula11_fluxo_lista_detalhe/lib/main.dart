import 'package:flutter/material.dart';

import 'screens/feed_noticias_screen.dart';

/// Ponto de entrada do aplicativo Portal de Notícias.
void main() {
  runApp(const PortalNoticiasApp());
}

/// Raiz do aplicativo: tema Material 3 e tela inicial do feed.
class PortalNoticiasApp extends StatelessWidget {
  const PortalNoticiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal de Notícias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const FeedNoticiasScreen(),
    );
  }
}
