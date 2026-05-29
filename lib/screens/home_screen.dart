import 'package:flutter/material.dart';
import 'pedido_screen.dart';
import 'productos_screen.dart';
import 'clientes_screen.dart';
import 'historial_pedidos_screen.dart';
import 'corte_ventas_screen.dart'; // Nueva importación
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PedidoScreen(),
    const ProductosScreen(),
    const ClientesScreen(),
    const HistorialPedidosScreen(),
    const CorteVentasScreen(), // Nueva pestaña
    const BackupScreen(), // Nueva pestaña
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          NavigationDestination(icon: Icon(Icons.backup), label: 'Backup'),
        ],
      ),
    );
  }
}
