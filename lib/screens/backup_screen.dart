import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  // ==================== EXPORTAR RESPALDO ====================
  Future<void> _exportarBackup() async {
    setState(() => _isLoading = true);

    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/pedidos_app.db');

      if (!await dbFile.exists()) {
        _mostrarMensaje('No se encontró la base de datos', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final fecha = DateTime.now();
      final nombreBackup =
          'backup_${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}.db';

      // Guardar en Descargas (accesible para el usuario)
      final downloadsDir = await getDownloadsDirectory();
      final backupFile = File('${downloadsDir?.path}/$nombreBackup');
      await dbFile.copy(backupFile.path);

      // Compartir también por si acaso
      await Share.shareXFiles([
        XFile(backupFile.path),
      ], text: '📦 Respaldo - ${fecha.toString().substring(0, 16)}');

      _mostrarMensaje('✅ Respaldo guardado en: Descargas');
    } catch (e) {
      _mostrarMensaje('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== IMPORTAR RESPALDO ====================
  Future<void> _importarBackup() async {
    setState(() => _isLoading = true);

    try {
      // 1. Seleccionar archivo .db
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String backupPath = result.files.single.path!;
      final File backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        _mostrarMensaje('El archivo no existe', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // 2. Confirmar restauración
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Restaurar Respaldo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción BORRARÁ todos los datos actuales.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Los datos actuales serán reemplazados.'),
              const SizedBox(height: 16),
              Text(
                '📅 Archivo: ${result.files.single.name}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('¿Estás seguro?', style: TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );

      if (confirmar != true) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Cerrar la base de datos actual
      await DatabaseHelper.instance.closeDatabase();

      // 4. Copiar el respaldo
      final dbPath = await getDatabasesPath();
      final destinoFile = File('$dbPath/pedidos_app.db');

      if (await destinoFile.exists()) {
        await destinoFile.delete();
      }

      await backupFile.copy(destinoFile.path);

      _mostrarMensaje('✅ Respaldo restaurado correctamente');

      // 5. Forzar reinicio de la app
      await Future.delayed(const Duration(seconds: 1));
      exit(0);
    } catch (e) {
      _mostrarMensaje('Error al importar: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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
                              'Respaldo de Datos',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '📤 Exportar: Guarda copia en Descargas\n'
                          '📥 Importar: Selecciona un archivo .db guardado',
                          style: TextStyle(fontSize: 12),
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
                    subtitle: const Text('Guarda en Descargas'),
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
                    subtitle: const Text('Selecciona un archivo .db'),
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
                          '💡 Exporta un respaldo cada semana y guárdalo en Drive o WhatsApp.',
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
