import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/clientes.dart';
import '../models/item_pedido.dart';
import '../models/producto.dart';
import 'detalle_pedido_screen.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;
  String _filtroStatus = 'TODOS'; // TODOS, PENDIENTE, CERRADO

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pedidos = await DatabaseHelper.instance.getPedidosConDetalles();
      setState(() {
        _pedidos = pedidos;
        _isLoading = false;
      });
      print('Pedidos cargados: ${pedidos.length}');
    } catch (e) {
      print('Error al cargar pedidos: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarMensaje('Error al cargar pedidos', isError: true);
    }
  }

  List<Map<String, dynamic>> get _pedidosFiltrados {
    if (_filtroStatus == 'TODOS') {
      return _pedidos;
    }
    return _pedidos.where((p) => p['status'] == _filtroStatus).toList();
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatearFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (e) {
      return fechaISO;
    }
  }

  Future<void> _verDetallePedido(Map<String, dynamic> pedido) async {
    try {
      // Obtener detalles del pedido
      final detalles = await DatabaseHelper.instance.getDetallesPedido(
        pedido['pedido_id'],
      );

      // Crear cliente
      final cliente = Clientes(
        idcliente: pedido['idcliente'],
        nombrecliente: pedido['nombrecliente'],
        apellido1: pedido['apellido1'],
        apellido2: pedido['apellido2'],
        telefono: pedido['telefono'],
        direccion: pedido['direccion'],
      );

      // Crear items del pedido
      final items = <ItemPedido>[];
      for (var detalle in detalles) {
        final producto = Producto(
          id: detalle['idProducto'],
          codigo: detalle['codigo'],
          nombreproducto: detalle['nombreproducto'],
          descripcion: detalle['descripcion'],
          cantidad: detalle['cantidad'].toDouble(),
          unidadmedida: detalle['unidadmedida'],
          precioproveedor: detalle['costoUnitario'].toDouble(),
          precioventa: detalle['precioUnitario'].toDouble(),
          ganancia: detalle['ganancia'].toDouble(),
        );
        items.add(
          ItemPedido(producto: producto, cantidad: detalle['cantidad'].toInt()),
        );
      }

      // Navegar a detalle
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallePedidoScreen(
            pedidoId: pedido['pedido_id'],
            cliente: cliente,
            items: items,
            fecha: DateTime.parse(pedido['fecha']),
            total: pedido['total'].toDouble(),
            status: pedido['status'],
          ),
        ),
      ).then((_) => _cargarPedidos()); // Recargar al regresar
    } catch (e) {
      print('Error al ver detalle: $e');
      _mostrarMensaje('Error al cargar detalles', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPedidos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFiltroChip('TODOS', 'TODOS'),
                const SizedBox(width: 8),
                _buildFiltroChip('PENDIENTE', 'PENDIENTE'),
                const SizedBox(width: 8),
                _buildFiltroChip('CERRADO', 'CERRADO'),
              ],
            ),
          ),

          // Lista de pedidos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pedidosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtroStatus == 'TODOS'
                              ? 'No hay pedidos registrados'
                              : 'No hay pedidos $_filtroStatus',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_filtroStatus != 'TODOS')
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus = 'TODOS';
                              });
                            },
                            child: const Text('Ver todos los pedidos'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _pedidosFiltrados.length,
                    itemBuilder: (context, index) {
                      final pedido = _pedidosFiltrados[index];
                      final nombreCompleto =
                          '${pedido['nombrecliente']} ${pedido['apellido1']} ${pedido['apellido2']}';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 3,
                        child: InkWell(
                          onTap: () => _verDetallePedido(pedido),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status y número de pedido
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pedido['status'] == 'CERRADO'
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                pedido['status'] == 'CERRADO'
                                                    ? Icons.check_circle
                                                    : Icons.pending,
                                                size: 16,
                                                color:
                                                    pedido['status'] ==
                                                        'CERRADO'
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                pedido['status'] ?? 'PENDIENTE',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      pedido['status'] ==
                                                          'CERRADO'
                                                      ? Colors.green.shade900
                                                      : Colors.orange.shade900,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pedido #${pedido['pedido_id']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatearFecha(pedido['fecha']),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Cliente
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        nombreCompleto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Teléfono
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(pedido['telefono']),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${pedido['total'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),

                                // ✅ GANANCIA CORREGIDA - Usa 'ganancia_total'
                                if (pedido['ganancia_total'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Ganancia:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '\$${(pedido['ganancia_total'] ?? 0.0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final isSelected = _filtroStatus == valor;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroStatus = valor;
          });
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange,
    );
  }
}
