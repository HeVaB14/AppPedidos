import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

class DemoLicenseScreen extends StatefulWidget {
  const DemoLicenseScreen({super.key});

  @override
  State<DemoLicenseScreen> createState() => _DemoLicenseScreenState();
}

class _DemoLicenseScreenState extends State<DemoLicenseScreen> {
  bool _isLoading = true;
  bool _isValid = false;
  String _mensaje = '';
  final TextEditingController _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verificarLicencia();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  void launchUrlString(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir el enlace'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verificarLicencia() async {
    final prefs = await SharedPreferences.getInstance();

    bool esPagada = prefs.getBool('licencia_activada') ?? false;

    if (esPagada) {
      setState(() {
        _isValid = true;
        _isLoading = false;
        _mensaje = '✅ Licencia activa. Acceso completo.';
      });
      return;
    }

    int? fechaInstalacion = prefs.getInt('fecha_instalacion');
    int ahora = DateTime.now().millisecondsSinceEpoch;

    if (fechaInstalacion == null) {
      fechaInstalacion = ahora;
      await prefs.setInt('fecha_instalacion', fechaInstalacion);
    }

    int diasTranscurridos = (ahora - fechaInstalacion) ~/ (1000 * 60 * 60 * 24);
    int diasRestantes = 15 - diasTranscurridos;

    if (diasRestantes <= 0) {
      setState(() {
        _isValid = false;
        _isLoading = false;
        _mensaje =
            '❌ El período de prueba ha expirado.\n\nContacta al desarrollador para activar la licencia.';
      });
    } else {
      setState(() {
        _isValid = true;
        _isLoading = false;
        _mensaje =
            '✅ Período de prueba activo\nDías restantes: $diasRestantes\n\n📱 Versión DEMO';
      });
    }
  }

  Future<void> _activarLicencia() async {
    String codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el código de activación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, String> codigosValidos = {
      'FARMACIAJB2026HV': 'Licencia Comercial',
      'TIMABH2026': 'Feterias',
      'CLIENTET29580': 'Licencia Comercial',
    };

    if (codigosValidos.containsKey(codigo)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('licencia_activada', true);
      await prefs.setString('tipo_licencia', codigosValidos[codigo]!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Licencia activada: ${codigosValidos[codigo]}'),
          backgroundColor: Colors.green,
        ),
      );
      _verificarLicencia();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Código inválido. Contacta al desarrollador.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  size: 50,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 30),

              // Título
              const Text(
                'PEDIDOS APP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),

              // Badge demo
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'VERSIÓN DEMO',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),

              // Mensaje de estado
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  _mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _isValid ? Colors.green : Colors.red,
                  ),
                ),

              const SizedBox(height: 30),

              // Botón continuar
              if (_isValid && !_isLoading)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              // Sección de activación
              if (!_isValid && !_isLoading)
                Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      '¿Ya pagaste? Activa tu licencia:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codigoController,
                            decoration: const InputDecoration(
                              hintText: 'Código de activación',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.vpn_key, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _activarLicencia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Activar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Contacta al desarrollador para obtener tu código',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // ========== SECCIÓN DE CONTACTO ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📞 Contacto para activar licencia:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'hvbrayan@hotmail.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Teléfono
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Tel: +52 6635137212',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Botón WhatsApp
                    InkWell(
                      onTap: () {
                        final String url = '';
                        // 'https://api.whatsapp.com/send?phone=526635137212&text=Hola%2C%20me%20interesa%20adquirir%20la%20licencia%20de%20la%20app';
                        // launchUrlString(url);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
