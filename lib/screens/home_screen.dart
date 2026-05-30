// import 'package:flutter/material.dart';
// import 'pedido_screen.dart';
// import 'productos_screen.dart';
// import 'clientes_screen.dart';
// import 'historial_pedidos_screen.dart';
// import 'corte_ventas_screen.dart';
// import 'backup_screen.dart';
// import 'reportes_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   final List<Widget> _screens = [
//     const PedidoScreen(),
//     const ProductosScreen(),
//     const ClientesScreen(),
//     const HistorialPedidosScreen(),
//     const CorteVentasScreen(),
//   ];

//   final List<String> _titles = [
//     'Pedidos',
//     'Productos',
//     'Clientes',
//     'Historial',
//     'Corte de Ventas',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: null, //Text(_titles[_selectedIndex]),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         foregroundColor: Colors.green,
//       ),
//       drawer: Drawer(
//         child: Column(
//           children: [
//             // Encabezado del menú
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               color: Colors.blue,
//               child: Column(
//                 children: [
//                   const CircleAvatar(
//                     radius: 40,
//                     backgroundColor: Colors.white,
//                     child: Icon(Icons.store, size: 50, color: Colors.blue),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Pedidos App',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Versión 1.0.0',
//                     style: TextStyle(color: Colors.white70, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Opciones principales (navegación)
//             ListTile(
//               leading: const Icon(Icons.shopping_cart, color: Colors.blue),
//               title: const Text('Pedidos'),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 0;
//                 });
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.inventory, color: Colors.blue),
//               title: const Text('Productos'),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 1;
//                 });
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.people, color: Colors.blue),
//               title: const Text('Clientes'),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 2;
//                 });
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.history, color: Colors.blue),
//               title: const Text('Historial'),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 3;
//                 });
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.assessment, color: Colors.blue),
//               title: const Text('Corte de Ventas'),
//               onTap: () {
//                 setState(() {
//                   _selectedIndex = 4;
//                 });
//                 Navigator.pop(context);
//               },
//             ),
//             const Divider(),

//             // Opciones secundarias
//             ListTile(
//               leading: const Icon(Icons.backup, color: Colors.orange),
//               title: const Text('Respaldos'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const BackupScreen()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.bar_chart, color: Colors.orange),
//               title: const Text('Reportes'),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => const ReportesScreen()),
//                 );
//               },
//             ),
//             const Divider(),

//             // Información de la app
//             const Spacer(),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Text(
//                 '© 2024 Pedidos App\nTodos los derechos reservados',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.shopping_cart),
//             label: 'Pedido',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.inventory),
//             label: 'Productos',
//           ),
//           NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
//           NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
//           NavigationDestination(icon: Icon(Icons.assessment), label: 'Corte'),
//         ],
//       ),
//     );
//   }

// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pedido_screen.dart';
import 'productos_screen.dart';
import 'clientes_screen.dart';
import 'historial_pedidos_screen.dart';
import 'corte_ventas_screen.dart';
import 'backup_screen.dart';
import 'reportes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _empresaNombre = 'Mi Negocio';
  Color _colorPrimario = Colors.blue;

  final List<Widget> _screens = [
    const PedidoScreen(),
    const ProductosScreen(),
    const ClientesScreen(),
    const HistorialPedidosScreen(),
    const CorteVentasScreen(),
  ];

  final List<String> _titles = [
    'Pedidos',
    'Productos',
    'Clientes',
    'Historial',
    'Corte de Ventas',
  ];

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _empresaNombre = prefs.getString('empresa_nombre') ?? 'Mi Negocio';
      final colorValue = prefs.getInt('empresa_color') ?? 0;
      _colorPrimario = _getColorFromValue(colorValue);
    });
  }

  Color _getColorFromValue(int value) {
    switch (value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // 👈 Título dinámico
        centerTitle: true,
        backgroundColor: _colorPrimario, // 👈 Color personalizado
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Encabezado del menú
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: _colorPrimario, // 👈 Color personalizado
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.store, size: 50, color: _colorPrimario),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _empresaNombre, // 👈 Nombre personalizado
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Opciones principales (navegación)
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.blue),
              title: const Text('Pedidos'),
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: const Text('Productos'),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text('Clientes'),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Historial'),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment, color: Colors.blue),
              title: const Text('Corte de Ventas'),
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),

            // Opciones secundarias
            ListTile(
              leading: const Icon(Icons.backup, color: Colors.orange),
              title: const Text('Respaldos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.orange),
              title: const Text('Reportes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportesScreen()),
                );
              },
            ),
            const Divider(),

            // Información de la app
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '© 2026 $_empresaNombre\nTodos los derechos reservados',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Pedido',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.assessment), label: 'Corte'),
        ],
      ),
    );
  }
}
