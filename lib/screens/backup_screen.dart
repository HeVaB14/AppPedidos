import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  // ============ EXPORTAR RESPALDO ============
  Future<void> _exportarBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/pedidos_app.db');

      if (!await dbFile.exists()) {
        _mostrarMensaje('No se encontró la base de datos', isError: true);
        return;
      }

      final fecha = DateTime.now();
      final nombreBackup =
          'backup_${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}_${fecha.hour}${fecha.minute}.db';

      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/$nombreBackup');
      await dbFile.copy(backupFile.path);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        text:
            '📦 Respaldo de Pedidos App\nFecha: ${fecha.toString().substring(0, 16)}\n\nGuarda este archivo en un lugar seguro.',
      );

      _mostrarMensaje('✅ Respaldo exportado correctamente');
    } catch (e) {
      _mostrarMensaje('Error al exportar: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============ IMPORTAR RESPALDO ============
  Future<void> _importarBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mostrar instrucciones
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📥 Importar Respaldo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Para importar un respaldo, sigue estos pasos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('1. Conecta tu teléfono a la computadora'),
              const Text('2. Busca la carpeta:'),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Android/data/com.example.pedidos_app/files/',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
              const Text('3. Copia tu archivo .db como "pedidos_app.db"'),
              const Text('4. Reemplaza el archivo existente'),
              const Text('5. Reinicia la app'),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Asegúrate de tener un respaldo antes de hacerlo.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        _mostrarMensaje('Reinicia la app para aplicar los cambios');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo de Datos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              '¿Qué es un respaldo?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Un respaldo guarda una copia de todos tus productos, clientes y pedidos.\n\n'
                          '📤 Exportar: Guarda una copia en tu teléfono\n'
                          '📥 Importar: Restaura una copia (requiere copiar manualmente)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Exportar
                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.backup,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    title: const Text(
                      'Exportar Respaldo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Guarda una copia de seguridad de tus datos',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _exportarBackup,
                  ),
                ),
                const SizedBox(height: 12),

                // Botón Importar
                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restore,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                    title: const Text(
                      'Importar Respaldo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Ver instrucciones para restaurar datos',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _importarBackup,
                  ),
                ),
                const SizedBox(height: 24),

                // Recomendación
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recomendación: Exporta un respaldo cada semana y guárdalo en Drive o WhatsApp.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Procesando...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
