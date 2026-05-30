import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clientes.dart';
import '../models/item_pedido.dart';

class ResumenPedidoScreen extends StatefulWidget {
  final Clientes cliente;
  final List<ItemPedido> items;
  final double total;
  final DateTime fecha;
  final double montoRecibido;
  final double cambio;

  const ResumenPedidoScreen({
    super.key,
    required this.cliente,
    required this.items,
    required this.total,
    required this.fecha,
    this.montoRecibido = 0,
    this.cambio = 0,
  });

  @override
  State<ResumenPedidoScreen> createState() => _ResumenPedidoScreenState();
}

class _ResumenPedidoScreenState extends State<ResumenPedidoScreen> {
  String _empresaNombre = 'Pedidos App';
  String _empresaTelefono = '';
  String _empresaDireccion = '';
  String _empresaSitio = 'pedidosapp.com';

  @override
  void initState() {
    super.initState();
    _cargarDatosEmpresa();
  }

  Future<void> _cargarDatosEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _empresaNombre = prefs.getString('empresa_nombre') ?? 'Pedidos App';
      _empresaTelefono = prefs.getString('empresa_telefono') ?? '';
      _empresaDireccion = prefs.getString('empresa_direccion') ?? '';
    });
  }

  Future<pw.Document> _generarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      _empresaNombre,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (_empresaTelefono.isNotEmpty)
                      pw.Text(
                        'Tel: $_empresaTelefono',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    if (_empresaDireccion.isNotEmpty)
                      pw.Text(
                        _empresaDireccion,
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Ticket de Venta',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Folio: ${widget.fecha.millisecondsSinceEpoch}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              pw.Text(
                'DATOS DEL CLIENTE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Nombre: ${widget.cliente.nombrecliente} ${widget.cliente.apellido1} ${widget.cliente.apellido2}',
              ),
              pw.Text('Teléfono: ${widget.cliente.telefono}'),
              pw.Text('Dirección: ${widget.cliente.direccion}'),
              pw.SizedBox(height: 20),

              pw.Text('Fecha: ${widget.fecha.toString().substring(0, 16)}'),
              pw.SizedBox(height: 20),

              pw.Text(
                'PRODUCTOS',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(60),
                  3: const pw.FixedColumnWidth(80),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _celda('#', alinearCentro: true),
                      _celda('Producto'),
                      _celda('Cant.', alinearCentro: true),
                      _celda('Subtotal', alinearDerecha: true),
                    ],
                  ),
                  ...widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _celda('${index + 1}', alinearCentro: true),
                        _celda(item.producto.nombreproducto),
                        _celda('${item.cantidad}', alinearCentro: true),
                        _celda(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          alinearDerecha: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$${widget.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              if (widget.montoRecibido > 0) ...[
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Monto recibido:',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      '\$${widget.montoRecibido.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CAMBIO:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${widget.cambio.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '¡Gracias por su compra!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tel: $_empresaTelefono - $_empresaSitio',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  pw.Widget _celda(
    String texto, {
    bool alinearCentro = false,
    bool alinearDerecha = false,
  }) {
    pw.TextAlign alinear = pw.TextAlign.left;
    if (alinearCentro) alinear = pw.TextAlign.center;
    if (alinearDerecha) alinear = pw.TextAlign.right;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(texto, textAlign: alinear),
    );
  }

  Future<void> _compartirPDF(pw.Document pdf) async {
    try {
      final pdfBytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/ticket_${widget.fecha.millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Ticket de venta - $_empresaNombre');
    } catch (e) {
      debugPrint('Error al compartir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket de Venta'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final pdf = await _generarPDF();
              await _compartirPDF(pdf);
            },
            tooltip: 'Compartir ticket',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final pdf = await _generarPDF();
              await Printing.layoutPdf(onLayout: (format) async => pdf.save());
            },
            tooltip: 'Imprimir',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ticket visual
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.store, size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          _empresaNombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_empresaTelefono.isNotEmpty)
                          Text(
                            'Tel: $_empresaTelefono',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (_empresaDireccion.isNotEmpty)
                          Text(
                            _empresaDireccion,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Ticket de Venta',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Divider(),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(widget.fecha),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cliente: ${widget.cliente.nombrecliente} ${widget.cliente.apellido1} ${widget.cliente.apellido2}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PRODUCTOS',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Divider(thickness: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.cantidad}x ${item.producto.nombreproducto}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '\$${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${widget.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (widget.montoRecibido > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monto recibido:',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                '\$${widget.montoRecibido.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CAMBIO:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${widget.cambio.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '¡Gracias por su compra!',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tel: $_empresaTelefono - $_empresaSitio',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón para cerrar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle),
                label: const Text('ACEPTAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
