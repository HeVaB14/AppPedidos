import 'package:flutter/material.dart';
import '../models/clientes.dart';
import '../models/producto.dart';
import '../models/item_pedido.dart';
import '../database/database_helper.dart';
import 'resumen_pedido_screen.dart';
import 'scanner_screen.dart';

class PedidoScreen extends StatefulWidget {
  const PedidoScreen({super.key});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  Clientes? _clienteSeleccionado;
  final List<ItemPedido> _items = [];
  List<Producto> _productos = [];
  double _montoRecibido = 0;
  double _cambio = 0;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarClienteMostrador();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await DatabaseHelper.instance.getProductos();
      if (mounted) {
        setState(() {
          _productos = productos;
        });
      }
    } catch (e) {
      print('Error al cargar productos: $e');
    }
  }

  Future<void> _cargarClienteMostrador() async {
    try {
      final clientes = await DatabaseHelper.instance.getClientes();

      for (var c in clientes) {
        if (c.nombrecliente == 'MOSTRADOR') {
          if (mounted) {
            setState(() {
              _clienteSeleccionado = c;
            });
          }
          return;
        }
      }

      final mostrador = Clientes(
        nombrecliente: 'MOSTRADOR',
        apellido1: '',
        apellido2: '',
        telefono: '000-0000',
        direccion: 'Venta en tienda',
      );
      final id = await DatabaseHelper.instance.insertCliente(mostrador);
      if (mounted) {
        setState(() {
          _clienteSeleccionado = Clientes(
            idcliente: id,
            nombrecliente: 'MOSTRADOR',
            apellido1: '',
            apellido2: '',
            telefono: '000-0000',
            direccion: 'Venta en tienda',
          );
        });
      }
    } catch (e) {
      print('Error al cargar cliente mostrador: $e');
    }
  }

  double get _total => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  void _mostrarPantallaPago() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('PAGO'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total: \$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto recibido',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  onChanged: (value) {
                    double recibido = double.tryParse(value) ?? 0;
                    setStateDialog(() {
                      _montoRecibido = recibido;
                      _cambio = recibido - _total;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_cambio > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CAMBIO:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${_cambio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_cambio < 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FALTAN:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${(-_cambio).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _cambio >= 0
                    ? () {
                        Navigator.pop(context);
                        _confirmarPedido();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar Pago'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _seleccionarCliente() async {
    final clientes = await DatabaseHelper.instance.getClientes();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Seleccionar Cliente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      '${cliente.nombrecliente} ${cliente.apellido1}',
                    ),
                    subtitle: Text(cliente.telefono),
                    onTap: () {
                      setState(() {
                        _clienteSeleccionado = cliente;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          titulo: 'Escanear producto',
          onCodeScanned: (codigo) async {
            print('Código escaneado: $codigo');

            Producto? productoEncontrado;
            for (var p in _productos) {
              if (p.codigo.toLowerCase() == codigo.toLowerCase()) {
                productoEncontrado = p;
                break;
              }
            }

            if (productoEncontrado != null) {
              _mostrarDialogoCantidad(productoEncontrado);
            } else {
              _mostrarDialogoCrearProducto(codigo);
            }
          },
        ),
      ),
    );
  }

  void _mostrarDialogoCrearProducto(String codigo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Producto no encontrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.qr_code_scanner, size: 50, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'El código "$codigo" no está registrado.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas crear un nuevo producto con este código?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirScanner();
            },
            child: const Text('Escanear otro'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _crearProductoDesdeEscaneo(codigo);
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear producto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crearProductoDesdeEscaneo(String codigo) async {
    final nombreController = TextEditingController();
    final precioProveedorController = TextEditingController();
    final precioVentaController = TextEditingController();
    final stockController = TextEditingController(text: '0');

    final unidades = ['pza', 'kg', 'lts', 'doc', 'caja', 'paquete'];
    String unidadSeleccionada = 'pza';
    double gananciaCalculada = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nuevo Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: codigo),
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto *',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock inicial',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: unidadSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                            border: OutlineInputBorder(),
                          ),
                          items: unidades.map((unidad) {
                            return DropdownMenuItem<String>(
                              value: unidad,
                              child: Text(unidad),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setStateDialog(() {
                                unidadSeleccionada = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: precioProveedorController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Proveedor *',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            double proveedor = double.tryParse(value) ?? 0;
                            double venta =
                                double.tryParse(precioVentaController.text) ??
                                0;
                            setStateDialog(() {
                              gananciaCalculada = venta - proveedor;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: precioVentaController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Venta *',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            double venta = double.tryParse(value) ?? 0;
                            double proveedor =
                                double.tryParse(
                                  precioProveedorController.text,
                                ) ??
                                0;
                            setStateDialog(() {
                              gananciaCalculada = venta - proveedor;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gananciaCalculada >= 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gananciaCalculada >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ganancia por unidad:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${gananciaCalculada.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gananciaCalculada >= 0
                                ? Colors.green
                                : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nombreController.text.isNotEmpty &&
                      precioVentaController.text.isNotEmpty &&
                      precioProveedorController.text.isNotEmpty) {
                    final double precioProveedor = double.parse(
                      precioProveedorController.text,
                    );
                    final double precioVenta = double.parse(
                      precioVentaController.text,
                    );
                    final double ganancia = precioVenta - precioProveedor;

                    final nuevoProducto = Producto(
                      codigo: codigo,
                      nombreproducto: nombreController.text,
                      descripcion: null,
                      cantidad: double.tryParse(stockController.text) ?? 0,
                      unidadmedida: unidadSeleccionada,
                      precioproveedor: precioProveedor,
                      precioventa: precioVenta,
                      ganancia: ganancia,
                    );

                    await DatabaseHelper.instance.insertProducto(nuevoProducto);
                    await _cargarProductos();

                    if (mounted) {
                      Navigator.pop(context);
                      _mostrarMensaje('Producto creado exitosamente');

                      final productoAgregar = _productos.firstWhere(
                        (p) => p.codigo.toLowerCase() == codigo.toLowerCase(),
                      );
                      _mostrarDialogoCantidad(productoAgregar);
                    }
                  } else {
                    _mostrarMensaje('Complete todos los campos', isError: true);
                  }
                },
                child: const Text('Crear y agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== AGREGAR PRODUCTO CON BUSCADOR ====================
  Future<void> _agregarProducto() async {
    if (_productos.isEmpty) {
      _mostrarMensaje('No hay productos registrados', isError: true);
      return;
    }

    List<Producto> productosFiltrados = List.from(_productos);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Agregar Producto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 🔍 CAMPO DE BÚSQUEDA
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '🔍 Buscar por nombre o código...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setStateModal(() {
                                searchQuery = '';
                                productosFiltrados = List.from(_productos);
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setStateModal(() {
                      searchQuery = value.toLowerCase().trim();
                      if (searchQuery.isEmpty) {
                        productosFiltrados = List.from(_productos);
                      } else {
                        productosFiltrados = _productos
                            .where(
                              (p) =>
                                  p.nombreproducto.toLowerCase().contains(
                                    searchQuery,
                                  ) ||
                                  p.codigo.toLowerCase().contains(searchQuery),
                            )
                            .toList();
                      }
                    });
                  },
                ),

                // Contador de resultados
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${productosFiltrados.length} productos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        Text(
                          'Filtrado: "$searchQuery"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(),

                // Lista de productos
                Expanded(
                  child: productosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron productos',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Prueba con otra palabra',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: productosFiltrados.length,
                          itemBuilder: (context, index) {
                            final producto = productosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 1,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    producto.codigo
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  producto.nombreproducto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Código: ${producto.codigo}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Precio: \$${producto.precioventa.toStringAsFixed(2)} | Stock: ${producto.cantidad} ${producto.unidadmedida}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: producto.cantidad <= 5
                                            ? Colors.red.shade700
                                            : Colors.grey.shade600,
                                        fontWeight: producto.cantidad <= 5
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _mostrarDialogoCantidad(producto);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('Agregar'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoCantidad(Producto producto) {
    final itemExistente = _items.firstWhere(
      (item) => item.producto.id == producto.id,
      orElse: () => ItemPedido(producto: producto, cantidad: 0),
    );

    final int stockDisponible = producto.cantidad.toInt();
    final int yaEnPedido = itemExistente.cantidad;
    final int stockRestante = stockDisponible - yaEnPedido;

    int cantidad = 1;

    if (stockRestante <= 0) {
      _mostrarMensaje(
        'No hay suficiente stock.\n'
        'Stock disponible: $stockDisponible ${producto.unidadmedida}\n'
        'Ya tienes $yaEnPedido en el pedido.',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(producto.nombreproducto),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stock disponible: $stockDisponible ${producto.unidadmedida}',
                ),
                Text('Ya en pedido: $yaEnPedido ${producto.unidadmedida}'),
                Text('Puedes agregar: $stockRestante ${producto.unidadmedida}'),
                const SizedBox(height: 16),
                Text('Precio: \$${producto.precioventa.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setStateDialog(() {
                        if (cantidad > 1) cantidad--;
                      }),
                      icon: const Icon(Icons.remove_circle, size: 40),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: TextEditingController(
                          text: cantidad.toString(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue != null &&
                              newValue >= 1 &&
                              newValue <= stockRestante) {
                            setStateDialog(() => cantidad = newValue);
                          } else if (newValue != null &&
                              newValue > stockRestante) {
                            setStateDialog(() => cantidad = stockRestante);
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setStateDialog(() {
                        if (cantidad < stockRestante) cantidad++;
                      }),
                      icon: const Icon(Icons.add_circle, size: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total a pagar: \$${(producto.precioventa * (yaEnPedido + cantidad)).toStringAsFixed(2)}',
                ),
                Text(
                  'Subtotal esta compra: \$${(producto.precioventa * cantidad).toStringAsFixed(2)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (cantidad >= 1 && cantidad <= stockRestante) {
                    setState(() {
                      if (itemExistente.cantidad > 0) {
                        itemExistente.cantidad += cantidad;
                      } else {
                        _items.add(
                          ItemPedido(producto: producto, cantidad: cantidad),
                        );
                      }
                    });
                    Navigator.pop(context);
                    _mostrarMensaje(
                      'Se agregaron $cantidad ${producto.nombreproducto} al pedido',
                    );
                  } else {
                    _mostrarMensaje('Cantidad no válida', isError: true);
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _eliminarItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _mostrarMensaje('Producto eliminado del pedido');
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

  void _confirmarPedido() async {
    if (_clienteSeleccionado == null) {
      _mostrarMensaje('Debes seleccionar un cliente', isError: true);
      return;
    }
    if (_items.isEmpty) {
      _mostrarMensaje('Debes agregar al menos un producto', isError: true);
      return;
    }
    await _guardarPedido();
  }

  Future<void> _guardarPedido() async {
    try {
      final pedidoMap = {
        'idcliente': _clienteSeleccionado!.idcliente,
        'fecha': DateTime.now().toIso8601String(),
        'total': _total,
        'status': 'PENDIENTE',
      };
      final idPedido = await DatabaseHelper.instance.insertPedido(pedidoMap);

      for (var item in _items) {
        final detalleMap = {
          'idPedido': idPedido,
          'idProducto': item.producto.id,
          'cantidad': item.cantidad,
          'precioUnitario': item.producto.precioventa,
          'costoUnitario': item.producto.precioproveedor,
          'subtotal': item.subtotal,
          'ganancia': item.gananciaTotal,
        };
        await DatabaseHelper.instance.insertDetallePedido(detalleMap);

        final nuevoStock = item.producto.cantidad - item.cantidad;
        await DatabaseHelper.instance.actualizarStockProducto(
          item.producto.id!,
          nuevoStock,
        );
      }

      _mostrarMensaje('¡Pedido guardado exitosamente!');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResumenPedidoScreen(
              cliente: _clienteSeleccionado!,
              items: _items,
              total: _total,
              fecha: DateTime.now(),
              montoRecibido: _montoRecibido,
              cambio: _cambio,
            ),
          ),
        ).then((_) {
          setState(() {
            _clienteSeleccionado = null;
            _items.clear();
            _montoRecibido = 0;
            _cambio = 0;
            _cargarProductos();
            _cargarClienteMostrador();
          });
        });
      }
    } catch (e) {
      print('Error al guardar pedido: $e');
      _mostrarMensaje('Error al guardar pedido: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Pedido'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _abrirScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear producto',
          ),
          IconButton(
            onPressed: _seleccionarCliente,
            icon: const Icon(Icons.person_add),
            tooltip: 'Seleccionar Cliente',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    _clienteSeleccionado?.nombrecliente == 'MOSTRADOR'
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  _clienteSeleccionado?.nombrecliente == 'MOSTRADOR'
                      ? Icons.store
                      : Icons.business,
                  color: _clienteSeleccionado?.nombrecliente == 'MOSTRADOR'
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
              title: Text(
                _clienteSeleccionado?.nombrecliente == 'MOSTRADOR'
                    ? 'MOSTRADOR (Venta directa)'
                    : '${_clienteSeleccionado?.nombrecliente ?? "Sin cliente"} ${_clienteSeleccionado?.apellido1 ?? ""}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _clienteSeleccionado?.nombrecliente == 'MOSTRADOR'
                    ? 'Venta en tienda - No requiere datos'
                    : _clienteSeleccionado?.direccion ??
                          'Toca para seleccionar',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: _seleccionarCliente,
                tooltip: 'Cambiar cliente',
              ),
            ),
          ),

          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay productos en el pedido'),
                        SizedBox(height: 8),
                        Text('Presiona + para agregar productos'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text('${item.cantidad}'),
                          ),
                          title: Text(item.producto.nombreproducto),
                          subtitle: Text(
                            '${item.cantidad} x \$${item.producto.precioventa.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _eliminarItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _items.isEmpty ? null : _mostrarPantallaPago,
                    icon: const Icon(Icons.payment),
                    label: const Text('COBRAR', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarProducto,
        tooltip: 'Agregar Producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
