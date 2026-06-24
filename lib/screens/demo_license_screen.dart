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
  String _nombreEmpresa = '';
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();

  // 🔐 INICIALES SECRETAS
  static const String _iniciales = 'MMB';
  static const String _codigoMaestro = 'MMBMASTER2026';

  @override
  void initState() {
    super.initState();
    _verificarLicencia();
    _cargarNombreEmpresa();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<void> _cargarNombreEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreEmpresa = prefs.getString('empresa_nombre') ?? '';
    });
  }

  void launchUrlString(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede abrir el enlace'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    bool demoExpirada = prefs.getBool('demo_expirada') ?? false;
    if (demoExpirada) {
      setState(() {
        _isValid = false;
        _isLoading = false;
        _mensaje =
            '❌ El período de prueba ha expirado.\n\n'
            'Para activar tu licencia, necesito el nombre exacto de tu negocio.\n'
            'Escríbelo abajo y contáctame para generarte tu código.';
      });
      return;
    }

    int? fechaInstalacion = prefs.getInt('fecha_instalacion');
    int ahora = DateTime.now().millisecondsSinceEpoch;

    if (fechaInstalacion == null) {
      fechaInstalacion = ahora;
      await prefs.setInt('fecha_instalacion', fechaInstalacion);
      await prefs.setInt('fecha_instalacion_segura', ahora);
    }

    int diasTranscurridos = (ahora - fechaInstalacion) ~/ (1000 * 60 * 60 * 24);
    int diasRestantes = 15 - diasTranscurridos;

    int fechaSegura =
        prefs.getInt('fecha_instalacion_segura') ?? fechaInstalacion;
    int posibleManipulacion = (ahora - fechaSegura) ~/ (1000 * 60 * 60 * 24);

    if (posibleManipulacion > diasTranscurridos + 1) {
      await prefs.setBool('demo_expirada', true);
      setState(() {
        _isValid = false;
        _isLoading = false;
        _mensaje =
            '❌ Se ha detectado manipulación de fecha.\n'
            'Licencia bloqueada permanentemente.';
      });
      return;
    }

    if (diasRestantes <= 0) {
      await prefs.setBool('demo_expirada', true);
      setState(() {
        _isValid = false;
        _isLoading = false;
        _mensaje =
            '❌ El período de prueba ha expirado.\n\n'
            'Para activar tu licencia, necesito el nombre exacto de tu negocio.\n'
            'Escríbelo abajo y contáctame para generarte tu código.';
      });
    } else {
      setState(() {
        _isValid = true;
        _isLoading = false;
        _mensaje =
            '✅ Período de prueba activo\n'
            'Días restantes: $diasRestantes\n\n📱 Versión DEMO';
      });
    }
  }

  String generarCodigoDesdeNombre(String nombreEmpresa) {
    String nombreLimpio = nombreEmpresa
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N');

    int anioActual = DateTime.now().year;
    return '$_iniciales$nombreLimpio$anioActual';
  }

  bool _validarCodigo(String codigo) {
    if (codigo == _codigoMaestro) return true;

    if (!codigo.startsWith(_iniciales)) return false;

    String resto = codigo.substring(_iniciales.length);

    int anioActual = DateTime.now().year;
    String anioStr = anioActual.toString();
    if (!resto.endsWith(anioStr)) return false;

    String nombreEmpresa = resto.substring(0, resto.length - anioStr.length);
    if (nombreEmpresa.length < 3) return false;

    return true;
  }

  Future<void> _activarLicencia() async {
    String codigo = _codigoController.text.trim().toUpperCase();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el código de activación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_validarCodigo(codigo)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('licencia_activada', true);
      await prefs.setString('tipo_licencia', 'Licencia Comercial');
      await prefs.setString('codigo_activacion', codigo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Licencia activada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _verificarLicencia();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Código inválido. Contacta al desarrollador.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              const Text(
                'PEDIDOS APP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
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

              // 👈 SECCIÓN PARA DEMO EXPIRADA (mostrar nombre de empresa)
              if (!_isValid && !_isLoading && _nombreEmpresa.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📋 Tu negocio registrado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nombreEmpresa,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usa este nombre para que te genere tu código de activación',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // 👈 CAMPO PARA INGRESAR NOMBRE DE EMPRESA (si no está guardado)
              if (!_isValid && !_isLoading && _nombreEmpresa.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TextField(
                    controller: _empresaController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de tu negocio *',
                      hintText: 'Ej: Ferretería Don Juan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ),

              if (!_isValid && !_isLoading && _nombreEmpresa.isEmpty)
                ElevatedButton(
                  onPressed: () async {
                    if (_empresaController.text.trim().isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        'empresa_nombre',
                        _empresaController.text.trim(),
                      );
                      _cargarNombreEmpresa();
                      setState(() {
                        _nombreEmpresa = _empresaController.text.trim();
                      });
                      _mostrarMensaje(
                        'Nombre guardado. Contacta al desarrollador para tu código.',
                      );
                    } else {
                      _mostrarMensaje(
                        'Ingresa el nombre de tu negocio',
                        isError: true,
                      );
                    }
                  },
                  child: const Text('Guardar nombre'),
                ),

              // Sección de activación
              if (!_isValid && !_isLoading)
                Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      '¿Ya tienes tu código? Activa tu licencia:',
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
                    InkWell(
                      onTap: () async {
                        final String phone = '526635137212';
                        final String message =
                            'Hola, necesito activar la licencia de Pedidos APP. Mi negocio se llama: $_nombreEmpresa';
                        final String url =
                            'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}';

                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // Si no tiene WhatsApp, mostrar número
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contáctame al WhatsApp: +52 6635137212',
                              ),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
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

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
