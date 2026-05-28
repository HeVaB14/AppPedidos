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
  List<ItemPedido> _items = [];
  List<Producto> _productos = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await DatabaseHelper.instance.getProductos();
      setState(() {
        _productos = productos;
      });
      print('Productos cargados: ${productos.length}');
    } catch (e) {
      print('Error al cargar productos: $e');
      _mostrarMensaje('Error al cargar productos', isError: true);
    }
  }

  double get _total => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> _seleccionarCliente() async {
    try {
      final clientes = await DatabaseHelper.instance.getClientes();

      if (clientes.isEmpty) {
        _mostrarMensaje('No hay clientes registrados', isError: true);
        return;
      }

      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          '${cliente.nombrecliente} ${cliente.apellido1} ${cliente.apellido2}',
                        ),
                        subtitle: Text(cliente.telefono),
                        onTap: () {
                          setState(() {
                            _clienteSeleccionado = cliente;
                          });
                          Navigator.pop(context);
                          _mostrarMensaje(
                            'Cliente seleccionado: ${cliente.nombrecliente} ${cliente.apellido1}',
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error al seleccionar cliente: $e');
      _mostrarMensaje('Error al cargar clientes', isError: true);
    }
  }

  Future<void> _abrirScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          titulo: 'Escanear producto',
          onCodeScanned: (codigo) async {
            await _procesarProductoEscaneado(codigo);
          },
        ),
      ),
    );
  }

  Future<void> _procesarProductoEscaneado(String codigo) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final productos = await DatabaseHelper.instance.getProductos();

      Producto? productoEncontrado;
      for (var producto in productos) {
        if (producto.codigo.toLowerCase() == codigo.toLowerCase()) {
          productoEncontrado = producto;
          break;
        }
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (productoEncontrado != null) {
        _mostrarDialogoCantidad(productoEncontrado);
      } else {
        _mostrarProductoNoEncontrado(codigo);
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _mostrarMensaje(
        'Error al buscar producto: ${e.toString()}',
        isError: true,
      );
      print('Error en escaneo: $e');
    }
  }

  void _mostrarProductoNoEncontrado(String codigo) {
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
              'El código "$codigo" no está registrado en el catálogo.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Qué deseas hacer?',
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
              _crearProductoConCodigo(codigo);
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

  void _crearProductoConCodigo(String codigo) async {
    final nuevoProducto = Producto(
      codigo: codigo,
      nombreproducto: '',
      cantidad: 0,
      unidadmedida: 'pza',
      precioproveedor: 0,
      precioventa: 0,
      ganancia: 0,
    );

    await _agregarEditarProductoConCodigo(nuevoProducto);
  }

  Future<void> _agregarEditarProductoConCodigo(
    Producto productoConCodigo,
  ) async {
    final nombreController = TextEditingController(
      text: productoConCodigo.nombreproducto,
    );
    final descripcionController = TextEditingController(
      text: productoConCodigo.descripcion ?? '',
    );
    final cantidadController = TextEditingController(
      text: productoConCodigo.cantidad.toString(),
    );
    final precioProveedorController = TextEditingController(
      text: productoConCodigo.precioproveedor.toString(),
    );
    final precioVentaController = TextEditingController(
      text: productoConCodigo.precioventa.toString(),
    );

    final unidades = ['pza', 'kg', 'lts', 'doc', 'caja', 'paquete'];
    String unidadSeleccionada = productoConCodigo.unidadmedida;
    double gananciaCalculada = 0;

    showDialog(
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
                    controller: TextEditingController(
                      text: productoConCodigo.codigo,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Código *',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
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
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Stock *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unidadSeleccionada,
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
                  if (nombreController.text.isNotEmpty) {
                    final nuevoProducto = Producto(
                      codigo: productoConCodigo.codigo,
                      nombreproducto: nombreController.text,
                      descripcion: descripcionController.text.isNotEmpty
                          ? descripcionController.text
                          : null,
                      cantidad: double.parse(cantidadController.text),
                      unidadmedida: unidadSeleccionada,
                      precioproveedor: double.parse(
                        precioProveedorController.text,
                      ),
                      precioventa: double.parse(precioVentaController.text),
                      ganancia: gananciaCalculada,
                    );

                    await DatabaseHelper.instance.insertProducto(nuevoProducto);
                    Navigator.pop(context);
                    _cargarProductos();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto creado exitosamente'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _agregarProducto() async {
    print('Botón agregar producto presionado');
    print('Productos disponibles: ${_productos.length}');

    if (_productos.isEmpty) {
      _mostrarMensaje(
        'No hay productos registrados. Agrega productos primero.',
        isError: true,
      );
      return;
    }

    List<Producto> productosFiltrados = _productos;
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
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Agregar Producto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setStateModal(() {
                      searchQuery = value;
                      if (value.isEmpty) {
                        productosFiltrados = _productos;
                      } else {
                        productosFiltrados = _productos
                            .where(
                              (p) =>
                                  p.nombreproducto.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ) ||
                                  p.codigo.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                            )
                            .toList();
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: productosFiltrados.isEmpty
                      ? const Center(child: Text('No se encontraron productos'))
                      : ListView.builder(
                          itemCount: productosFiltrados.length,
                          itemBuilder: (context, index) {
                            final producto = productosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(producto.codigo.substring(0, 1)),
                                ),
                                title: Text(producto.nombreproducto),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Código: ${producto.codigo}'),
                                    Text(
                                      'Stock: ${producto.cantidad.toStringAsFixed(0)} ${producto.unidadmedida}',
                                    ),
                                    Text(
                                      'Precio: \$${producto.precioventa.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _mostrarDialogoCantidad(producto);
                                  },
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
    int cantidad = 1;
    final stockDisponible = producto.cantidad;

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
                  'Stock disponible: ${stockDisponible.toStringAsFixed(0)} ${producto.unidadmedida}',
                ),
                const SizedBox(height: 16),
                Text(
                  'Precio unitario: \$${producto.precioventa.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (cantidad > 1) {
                          setStateDialog(() => cantidad--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle),
                      iconSize: 40,
                    ),
                    Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: TextEditingController(
                          text: cantidad.toString(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue != null && newValue > 0) {
                            setStateDialog(() => cantidad = newValue);
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (cantidad < stockDisponible) {
                          setStateDialog(() => cantidad++);
                        }
                      },
                      icon: const Icon(Icons.add_circle),
                      iconSize: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Subtotal: \$${(producto.precioventa * cantidad).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cantidad > stockDisponible)
                  const Text(
                    '⚠️ Cantidad excede el stock disponible',
                    style: TextStyle(color: Colors.red),
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
                  if (cantidad <= stockDisponible && cantidad > 0) {
                    setState(() {
                      _items.add(
                        ItemPedido(producto: producto, cantidad: cantidad),
                      );
                    });
                    Navigator.pop(context);
                    _mostrarMensaje('${producto.nombreproducto} agregado');
                  } else {
                    _mostrarMensaje(
                      'Cantidad no válida o excede stock',
                      isError: true,
                    );
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

    for (var item in _items) {
      if (!item.hayStock) {
        _mostrarMensaje(item.advertenciaStock, isError: true);
        return;
      }
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${_clienteSeleccionado!.nombrecliente} ${_clienteSeleccionado!.apellido1}',
            ),
            const SizedBox(height: 8),
            Text('Productos: ${_items.length}'),
            const SizedBox(height: 8),
            Text('Total: \$${_total.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _guardarPedido();
    }
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumenPedidoScreen(
            cliente: _clienteSeleccionado!,
            items: _items,
            total: _total,
            fecha: DateTime.now(),
          ),
        ),
      ).then((_) {
        setState(() {
          _clienteSeleccionado = null;
          _items.clear();
          _cargarProductos();
        });
      });
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
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.business, color: Colors.blue),
              ),
              title: Text(
                _clienteSeleccionado != null
                    ? '${_clienteSeleccionado!.nombrecliente} ${_clienteSeleccionado!.apellido1}'
                    : 'Cliente no seleccionado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _clienteSeleccionado?.direccion ?? 'Toca para seleccionar',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _seleccionarCliente,
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.cantidad} x \$${item.producto.precioventa.toStringAsFixed(2)}',
                              ),
                              if (!item.hayStock)
                                Text(
                                  item.advertenciaStock,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // evita que el Row ocupe todo el ancho
                            children: [
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // espacio entre texto y botón
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                                label: const Text('Eliminar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
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
                  color: Colors.grey.withOpacity(0.3),
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
                    onPressed: _confirmarPedido,
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'CONFIRMAR PEDIDO',
                      style: TextStyle(fontSize: 18),
                    ),
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
        child: const Icon(Icons.add),
        tooltip: 'Agregar Producto',
      ),
    );
  }
}
