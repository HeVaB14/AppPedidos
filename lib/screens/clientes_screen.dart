import 'package:flutter/material.dart';
import '../models/clientes.dart';
import '../database/database_helper.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Clientes> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final clientes = await DatabaseHelper.instance.getClientes();
    setState(() {
      _clientes = clientes;
    });
  }

  Future<void> _agregarEditarCliente({Clientes? cliente}) async {
    final isEditing = cliente != null;
    final nombreController = TextEditingController(
      text: cliente?.nombrecliente ?? '',
    );
    final apellido1Controller = TextEditingController(
      text: cliente?.apellido1 ?? '',
    );
    final apellido2Controller = TextEditingController(
      text: cliente?.apellido2 ?? '',
    );
    final telefonoController = TextEditingController(
      text: cliente?.telefono ?? '',
    );
    final direccionController = TextEditingController(
      text: cliente?.direccion ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apellido1Controller,
                decoration: const InputDecoration(
                  labelText: 'Primer Apellido *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apellido2Controller,
                decoration: const InputDecoration(
                  labelText: 'Segundo Apellido',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
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
                  apellido1Controller.text.isNotEmpty &&
                  telefonoController.text.isNotEmpty &&
                  direccionController.text.isNotEmpty) {
                final nuevoCliente = Clientes(
                  idcliente: cliente?.idcliente,
                  nombrecliente: nombreController.text,
                  apellido1: apellido1Controller.text,
                  apellido2: apellido2Controller.text.isNotEmpty
                      ? apellido2Controller.text
                      : '',
                  telefono: telefonoController.text,
                  direccion: direccionController.text,
                );

                if (isEditing) {
                  await DatabaseHelper.instance.updateCliente(nuevoCliente);
                } else {
                  await DatabaseHelper.instance.insertCliente(nuevoCliente);
                }

                Navigator.pop(context);
                _cargarClientes();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing ? 'Cliente actualizado' : 'Cliente agregado',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCliente(int id, String nombreCompleto) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a "$nombreCompleto" permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCliente(id);
              Navigator.pop(context);
              _cargarClientes();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente eliminado')),
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
        title: const Text('Clientes'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _clientes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay clientes', style: TextStyle(fontSize: 18)),
                  Text('Presiona + para agregar'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.person, color: Colors.green),
                    ),
                    title: Text(
                      cliente.nombrecliente,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(cliente.telefono),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dirección:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(cliente.direccion),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _agregarEditarCliente(cliente: cliente),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _eliminarCliente(
                                    cliente.idcliente!,
                                    cliente.nombrecliente,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agregarEditarCliente(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
