import 'package:flutter/material.dart';

class DemoUtils {
  static const bool esVersionDemo =
      true; // Cambia aquí para todas las pantallas

  static Widget buildDemoBadge() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'VERSIÓN DEMO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void mostrarLimiteDemo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Versión demo: función limitada. Adquiere la licencia para acceso completo.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
