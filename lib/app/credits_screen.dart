import 'package:flutter/material.dart';

import 'theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: AppColors.textMuted, height: 1.5);
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Baraja española', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Ilustraciones de la baraja "Naipes Libres" de Wikimedia Commons, '
            'por Basquetteur, a partir del trabajo de Germarquezm '
            '("Baraja española.svg" y "Baraja española completa.png").\n'
            'Licencia: Creative Commons Atribución-CompartirIgual 3.0 '
            '(CC BY-SA 3.0) — creativecommons.org/licenses/by-sa/3.0\n'
            'Cambios: recortadas en cartas individuales y reescaladas.',
            style: muted,
          ),
          SizedBox(height: 24),
          Text('Juega con responsabilidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Solo para mayores de edad. Nadie está obligado a beber: '
            'cualquier trago se puede cambiar por un reto o un vaso de agua.',
            style: muted,
          ),
        ],
      ),
    );
  }
}
