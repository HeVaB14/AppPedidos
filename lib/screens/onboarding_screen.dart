import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nombreEmpresaController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  int _selectedColor = 0;
  bool _isLoading = false;

  final List<ColorOption> _colorOptions = [
    ColorOption(name: 'Azul', color: Colors.blue, value: 0),
    ColorOption(name: 'Verde', color: Colors.green, value: 1),
    ColorOption(name: 'Naranja', color: Colors.orange, value: 2),
    ColorOption(name: 'Rojo', color: Colors.red, value: 3),
    ColorOption(name: 'Morado', color: Colors.purple, value: 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo o icono
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, size: 50, color: Colors.blue),
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  '¡Bienvenido!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Personaliza tu negocio',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Formulario
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Nombre de la empresa
                        TextField(
                          controller: _nombreEmpresaController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de tu negocio *',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                            hintText: 'Ej: Ferretería Don Juan',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Teléfono
                        TextField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            hintText: 'Ej: 55 1234 5678',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Dirección
                        TextField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                            hintText: 'Ej: Av. Principal #123',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Color principal
                        const Text(
                          'Color principal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _colorOptions.map((option) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = option.value;
                                });
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: option.color,
                                  shape: BoxShape.circle,
                                  border: _selectedColor == option.value
                                      ? Border.all(
                                          color: Colors.black,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón continuar
                ElevatedButton(
                  onPressed: _isLoading ? null : _guardarConfiguracion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getSelectedColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('COMENZAR', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),

                // Texto informativo
                Text(
                  'Puedes cambiar estos datos después en Configuración',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSelectedColor() {
    switch (_selectedColor) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Future<void> _guardarConfiguracion() async {
    if (_nombreEmpresaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del negocio es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar configuración
      await prefs.setBool('onboarding_completado', true);
      await prefs.setString(
        'empresa_nombre',
        _nombreEmpresaController.text.trim(),
      );
      await prefs.setString(
        'empresa_telefono',
        _telefonoController.text.trim(),
      );
      await prefs.setString(
        'empresa_direccion',
        _direccionController.text.trim(),
      );
      await prefs.setInt('empresa_color', _selectedColor);

      // Navegar a la pantalla principal
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class ColorOption {
  final String name;
  final Color color;
  final int value;

  ColorOption({required this.name, required this.color, required this.value});
}
