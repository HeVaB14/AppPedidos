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
                  apellido1Controller.text.isNotEmpty) {
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
                  _mostrarMensaje('Cliente actualizado');
                } else {
                  await DatabaseHelper.instance.insertCliente(nuevoCliente);
                  _mostrarMensaje('Cliente agregado');
                }
                Navigator.pop(context);
                _cargarClientes();
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCliente(int id, String nombre, String apellido) async {
    // 🔒 VERIFICAR SI ES EL CLIENTE MOSTRADOR
    if (nombre == 'MOSTRADOR') {
      _mostrarMensaje(
        '⚠️ El cliente MOSTRADOR no se puede eliminar porque es necesario para ventas rápidas.',
        isError: true,
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a "$nombre $apellido" permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.deleteCliente(id);
      _cargarClientes();
      _mostrarMensaje('Cliente eliminado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
                final esMostrador = cliente.nombrecliente == 'MOSTRADOR';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: esMostrador
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        esMostrador ? Icons.store : Icons.person,
                        color: esMostrador ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(
                      esMostrador
                          ? 'MOSTRADOR (Venta directa)'
                          : cliente.nombrecliente + ' ' + cliente.apellido1,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(cliente.telefono),
                    trailing: esMostrador
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PROTEGIDO',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _eliminarCliente(
                              cliente.idcliente!,
                              cliente.nombrecliente,
                              cliente.apellido1,
                            ),
                          ),
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
                            const SizedBox(height: 8),
                            if (!esMostrador)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _agregarEditarCliente(cliente: cliente),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Editar'),
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
