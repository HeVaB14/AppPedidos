import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class CorteVentasScreen extends StatefulWidget {
  const CorteVentasScreen({super.key});

  @override
  State<CorteVentasScreen> createState() => _CorteVentasScreenState();
}

class _CorteVentasScreenState extends State<CorteVentasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  Map<String, dynamic> _corteData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCorte();
  }

  Future<void> _cargarCorte() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.getCorteVentas(
        _fechaSeleccionada,
      );
      setState(() {
        _corteData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar corte: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _fechaSeleccionada = date;
      });
      _cargarCorte();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corte de Ventas'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _cambiarFecha,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarCorte),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fecha
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              'Fecha del corte',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaSeleccionada),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resumen de ventas
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'RESUMEN DEL DÍA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildResumenItem(
                            'Total de Pedidos:',
                            '${_corteData['totalPedidos'] ?? 0}',
                            Icons.receipt,
                          ),
                          _buildResumenItem(
                            'Productos Vendidos:',
                            '${_corteData['totalProductos'] ?? 0}',
                            Icons.shopping_cart,
                          ),
                          const Divider(),
                          _buildResumenItem(
                            'Ventas Totales:',
                            '\$${(_corteData['ventasTotales'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.attach_money,
                            isMoney: true,
                          ),
                          _buildResumenItem(
                            'Costo de Mercancía:',
                            '\$${(_corteData['costoTotal'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.shopping_bag,
                            isMoney: true,
                          ),
                          const Divider(),
                          _buildResumenItem(
                            'GANANCIA NETA:',
                            '\$${(_corteData['gananciaTotal'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.trending_up,
                            isMoney: true,
                            isBold: true,
                            color: Colors.green,
                          ),
                          _buildResumenItem(
                            'Margen de Ganancia:',
                            '${(_corteData['margenGanancia'] ?? 0.0).toStringAsFixed(1)}%',
                            Icons.percent,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de pedidos del día
                  if (_corteData['pedidos'] != null &&
                      _corteData['pedidos'].isNotEmpty)
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PEDIDOS DEL DÍA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _corteData['pedidos'].length,
                              itemBuilder: (context, index) {
                                final pedido = _corteData['pedidos'][index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        pedido['status'] == 'CERRADO'
                                        ? Colors.green
                                        : Colors.orange,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text('Pedido #${pedido['id']}'),
                                  subtitle: Text(
                                    'Cliente: ${pedido['cliente']}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${pedido['total'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Ganancia: \$${pedido['ganancia'].toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Botón para cerrar/abrir pedidos
                  ElevatedButton.icon(
                    onPressed: () => _cerrarDia(),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('CERRAR DÍA Y CALCULAR GANANCIAS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResumenItem(
    String label,
    String value,
    IconData icon, {
    bool isMoney = false,
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isMoney ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarDia() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Día'),
        content: Text(
          '¿Estás seguro de cerrar el día ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}?\n\n'
          'Esto marcará todos los pedidos pendientes como cerrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Cerrar Día'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.cerrarPedidosDia(_fechaSeleccionada);
      _cargarCorte();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Día cerrado exitosamente')),
        );
      }
    }
  }
}
