import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../database/database_helper.dart';
import 'scanner_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    final productos = await DatabaseHelper.instance.getProductos();
    setState(() {
      _productos = productos;
      _productosFiltrados = productos;
    });
  }

  void _filtrarProductos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _productosFiltrados = _productos;
      } else {
        _productosFiltrados = _productos
            .where(
              (p) =>
                  p.codigo.toLowerCase().contains(query.toLowerCase()) ||
                  p.nombreproducto.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _escanearCodigo() async {
    final codigoEscanado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          titulo: 'Escanear código de producto',
          onCodeScanned: (codigo) {
            _buscarProductoPorCodigo(codigo);
          },
        ),
      ),
    );
  }

  Future<void> _buscarProductoPorCodigo(String codigo) async {
    // Buscar si el producto ya existe
    final productoExistente = _productos.firstWhere(
      (p) => p.codigo.toLowerCase() == codigo.toLowerCase(),
      orElse: () => Producto(
        codigo: codigo,
        nombreproducto: '',
        cantidad: 0,
        unidadmedida: 'pza',
        precioproveedor: 0,
        precioventa: 0,
        ganancia: 0,
      ),
    );

    if (productoExistente.nombreproducto.isNotEmpty) {
      // Producto existe, preguntar si quiere editar
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Producto encontrado'),
          content: Text(
            '${productoExistente.nombreproducto} ya existe. ¿Deseas editarlo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _agregarEditarProducto(producto: productoExistente);
              },
              child: const Text('Editar'),
            ),
          ],
        ),
      );
    } else {
      // Producto nuevo, crear con validaciones
      _crearProductoConCodigo(codigo);
    }
  }

  Future<void> _crearProductoConCodigo(String codigo) async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final cantidadController = TextEditingController(
      text: '1',
    ); // Stock por defecto 1
    final precioProveedorController =
        TextEditingController(); // Vacío para obligar
    final precioVentaController = TextEditingController(); // Vacío para obligar

    final unidades = ['pza', 'kg', 'lts', 'doc', 'caja', 'paquete'];
    String unidadSeleccionada = 'pza';
    double gananciaCalculada = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Nuevo Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Código (solo lectura)
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

                  // Nombre (requerido)
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto *',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),

                  // Descripción (opcional)
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Stock y unidad
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cantidadController,
                          decoration: const InputDecoration(
                            labelText: 'Stock *',
                            border: OutlineInputBorder(),
                            hintText: 'Mínimo 1',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unidadSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Unidad *',
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

                  // Precio Proveedor y Precio Venta
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: precioProveedorController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Proveedor *',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                            hintText: 'Lo que te cuesta',
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
                            hintText: 'Precio al público',
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

                  // Mostrar ganancia calculada
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
                          gananciaCalculada >= 0
                              ? '\$${gananciaCalculada.toStringAsFixed(2)}'
                              : 'Pérdida: \$${(-gananciaCalculada).toStringAsFixed(2)}',
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
                  const SizedBox(height: 8),
                  Text(
                    '* Campos obligatorios',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
                  // Validaciones
                  if (nombreController.text.trim().isEmpty) {
                    _mostrarMensaje(
                      'El nombre del producto es requerido',
                      isError: true,
                    );
                    return;
                  }

                  final int stock = int.tryParse(cantidadController.text) ?? 0;
                  if (stock <= 0) {
                    _mostrarMensaje(
                      'El stock debe ser mayor a 0',
                      isError: true,
                    );
                    return;
                  }

                  final double precioProveedor =
                      double.tryParse(precioProveedorController.text) ?? 0;
                  if (precioProveedor <= 0) {
                    _mostrarMensaje(
                      'El precio proveedor debe ser mayor a 0',
                      isError: true,
                    );
                    return;
                  }

                  final double precioVenta =
                      double.tryParse(precioVentaController.text) ?? 0;
                  if (precioVenta <= 0) {
                    _mostrarMensaje(
                      'El precio venta debe ser mayor a 0',
                      isError: true,
                    );
                    return;
                  }

                  final double ganancia = precioVenta - precioProveedor;

                  final nuevoProducto = Producto(
                    codigo: codigo,
                    nombreproducto: nombreController.text.trim(),
                    descripcion: descripcionController.text.trim().isNotEmpty
                        ? descripcionController.text.trim()
                        : null,
                    cantidad: stock.toDouble(),
                    unidadmedida: unidadSeleccionada,
                    precioproveedor: precioProveedor,
                    precioventa: precioVenta,
                    ganancia: ganancia,
                  );

                  await DatabaseHelper.instance.insertProducto(nuevoProducto);
                  _cargarProductos();

                  if (mounted) {
                    Navigator.pop(context);
                    _mostrarMensaje('Producto creado exitosamente');
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

  Future<void> _agregarEditarProducto({Producto? producto}) async {
    final isEditing = producto != null;
    final codigoController = TextEditingController(
      text: producto?.codigo ?? '',
    );
    final nombreController = TextEditingController(
      text: producto?.nombreproducto ?? '',
    );
    final descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );
    final cantidadController = TextEditingController(
      text: producto?.cantidad != null && producto!.cantidad > 0
          ? producto.cantidad.toString()
          : '1', // 👈 Stock por defecto: 1 (no 0)
    );
    final precioProveedorController = TextEditingController(
      text: producto?.precioproveedor != null && producto!.precioproveedor > 0
          ? producto.precioproveedor.toString()
          : '', // 👈 Vacío para obligar a llenar
    );
    final precioVentaController = TextEditingController(
      text: producto?.precioventa != null && producto!.precioventa > 0
          ? producto.precioventa.toString()
          : '', // 👈 Vacío para obligar a llenar
    );

    final unidades = ['pza', 'kg', 'lts', 'doc', 'caja', 'paquete'];
    String unidadSeleccionada = producto?.unidadmedida ?? 'pza';
    double gananciaCalculada =
        (producto?.precioventa ?? 0) - (producto?.precioproveedor ?? 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código *',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: LAP-001',
                    ),
                    readOnly: isEditing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto *',
                      border: OutlineInputBorder(),
                    ),
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
                  // Validaciones
                  if (codigoController.text.trim().isEmpty) {
                    _mostrarMensaje('El código es requerido', isError: true);
                    return;
                  }
                  if (nombreController.text.trim().isEmpty) {
                    _mostrarMensaje(
                      'El nombre del producto es requerido',
                      isError: true,
                    );
                    return;
                  }
                  if (cantidadController.text.trim().isEmpty) {
                    _mostrarMensaje('La cantidad es requerida', isError: true);
                    return;
                  }
                  if (precioProveedorController.text.trim().isEmpty) {
                    _mostrarMensaje(
                      'El precio proveedor es requerido',
                      isError: true,
                    );
                    return;
                  }
                  if (precioVentaController.text.trim().isEmpty) {
                    _mostrarMensaje(
                      'El precio venta es requerido',
                      isError: true,
                    );
                    return;
                  }

                  final double cantidad =
                      double.tryParse(cantidadController.text) ?? 0;
                  if (cantidad <= 0) {
                    _mostrarMensaje(
                      'La cantidad debe ser mayor a 0',
                      isError: true,
                    );
                    return;
                  }

                  final double precioProveedor =
                      double.tryParse(precioProveedorController.text) ?? 0;
                  if (precioProveedor <= 0) {
                    _mostrarMensaje(
                      'El precio proveedor debe ser mayor a 0',
                      isError: true,
                    );
                    return;
                  }

                  final double precioVenta =
                      double.tryParse(precioVentaController.text) ?? 0;
                  if (precioVenta <= 0) {
                    _mostrarMensaje(
                      'El precio venta debe ser mayor a 0',
                      isError: true,
                    );
                    return;
                  }

                  // Crear producto
                  final nuevoProducto = Producto(
                    id: producto?.id,
                    codigo: codigoController.text.trim(),
                    nombreproducto: nombreController.text.trim(),
                    descripcion: descripcionController.text.trim().isEmpty
                        ? null
                        : descripcionController.text.trim(),
                    cantidad: cantidad,
                    unidadmedida: unidadSeleccionada,
                    precioproveedor: precioProveedor,
                    precioventa: precioVenta,
                    ganancia: precioVenta - precioProveedor,
                  );

                  if (isEditing) {
                    await DatabaseHelper.instance.updateProducto(nuevoProducto);
                    _mostrarMensaje('Producto actualizado');
                  } else {
                    await DatabaseHelper.instance.insertProducto(nuevoProducto);
                    _mostrarMensaje('Producto agregado');
                  }

                  Navigator.pop(context);
                  _cargarProductos();
                },
                child: Text(isEditing ? 'Actualizar' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
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

  Future<void> _eliminarProducto(int id, String nombre) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "$nombre" permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteProducto(id);
              Navigator.pop(context);
              _cargarProductos();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto eliminado')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _escanearCodigo,
            tooltip: 'Escanear código',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filtrarProductos,
              decoration: InputDecoration(
                hintText: 'Buscar por código o nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filtrarProductos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          Expanded(
            child: _productosFiltrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay productos',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text('Presiona + para agregar'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _productosFiltrados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            producto.nombreproducto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Código: ${producto.codigo}'),
                              Text(
                                'Precio Venta: \$${producto.precioventa.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (producto.descripcion != null) ...[
                                    const Text(
                                      'Descripción:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(producto.descripcion!),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Stock:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${producto.cantidad} ${producto.unidadmedida}',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Precio Proveedor:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${producto.precioproveedor.toStringAsFixed(2)}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Precio Venta:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${producto.precioventa.toStringAsFixed(2)}',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Ganancia:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${producto.ganancia.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _agregarEditarProducto(
                                          producto: producto,
                                        ),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Editar'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _eliminarProducto(
                                          producto.id!,
                                          producto.nombreproducto,
                                        ),
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Eliminar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agregarEditarProducto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
