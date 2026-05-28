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
  List<Map<String, dynamic>> _pedidosFiltrados = [];
  bool _isLoading = true;
  String _filtroStatus = 'TODOS';

  // Filtros de fecha
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

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
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar pedidos: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarMensaje('Error al cargar pedidos', isError: true);
    }
  }

  void _aplicarFiltros() {
    DateTime ahora = DateTime.now();
    DateTime inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);

    _pedidosFiltrados = _pedidos.where((pedido) {
      // Filtrar por status
      if (_filtroStatus != 'TODOS' && pedido['status'] != _filtroStatus) {
        return false;
      }

      // Filtrar por fecha de inicio
      if (_fechaInicio != null) {
        final fechaPedido = DateTime.parse(pedido['fecha']);
        if (fechaPedido.isBefore(_fechaInicio!)) {
          return false;
        }
      }

      // Filtrar por fecha de fin
      if (_fechaFin != null) {
        final fechaPedido = DateTime.parse(pedido['fecha']);
        final finDelDia = DateTime(
          _fechaFin!.year,
          _fechaFin!.month,
          _fechaFin!.day,
          23,
          59,
          59,
        );
        if (fechaPedido.isAfter(finDelDia)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Ordenar por fecha descendente (más reciente primero)
    _pedidosFiltrados.sort((a, b) => b['fecha'].compareTo(a['fecha']));

    setState(() {});
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

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'), // Idioma español
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // color del encabezado
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
      _aplicarFiltros();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'), // Idioma español
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange, // color del encabezado
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
      _aplicarFiltros();
    }
  }

  void _limpiarFiltrosFecha() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
    _aplicarFiltros();
    _mostrarMensaje('Filtros de fecha eliminados');
  }

  String _getRangoFechaTexto() {
    if (_fechaInicio != null && _fechaFin != null) {
      return '${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
    } else if (_fechaInicio != null) {
      return 'Desde ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}';
    } else if (_fechaFin != null) {
      return 'Hasta ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
    }
    return 'Todas las fechas';
  }

  Future<void> _verDetallePedido(Map<String, dynamic> pedido) async {
    try {
      final detalles = await DatabaseHelper.instance.getDetallesPedido(
        pedido['pedido_id'],
      );

      final cliente = Clientes(
        idcliente: pedido['idcliente'],
        nombrecliente: pedido['nombrecliente'],
        apellido1: pedido['apellido1'],
        apellido2: pedido['apellido2'] ?? '',
        telefono: pedido['telefono'],
        direccion: pedido['direccion'],
      );

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
          ItemPedido(
            producto: producto,
            cantidad: detalle['cantidad'].toInt(),
            detalleId: detalle['id'],
          ),
        );
      }

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
      ).then((_) => _cargarPedidos());
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
          // Filtros de estado
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

          // Filtros de fecha
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrar por fecha',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (_fechaInicio != null || _fechaFin != null)
                      TextButton(
                        onPressed: _limpiarFiltrosFecha,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Limpiar'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarFechaInicio,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaInicio != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                              : 'Fecha inicio',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarFechaFin,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaFin != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                              : 'Fecha fin',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getRangoFechaTexto(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
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
                          'No hay pedidos con los filtros seleccionados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_filtroStatus != 'TODOS' ||
                            _fechaInicio != null ||
                            _fechaFin != null)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _filtroStatus = 'TODOS';
                                _fechaInicio = null;
                                _fechaFin = null;
                              });
                              _aplicarFiltros();
                            },
                            child: const Text('Mostrar todos'),
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
          _aplicarFiltros();
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange,
    );
  }
}
