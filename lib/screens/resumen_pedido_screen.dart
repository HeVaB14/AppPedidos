import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/clientes.dart';
import '../models/item_pedido.dart';

class ResumenPedidoScreen extends StatelessWidget {
  final Clientes cliente;
  final List<ItemPedido> items;
  final double total;
  final DateTime fecha;

  const ResumenPedidoScreen({
    super.key,
    required this.cliente,
    required this.items,
    required this.total,
    required this.fecha,
  });

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
                      'PEDIDO DE VENTA',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Folio: PED-${fecha.millisecondsSinceEpoch}',
                      style: const pw.TextStyle(fontSize: 14),
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
                'Nombre: ${cliente.nombrecliente} ${cliente.apellido1} ${cliente.apellido2}',
              ),
              pw.Text('Teléfono: ${cliente.telefono}'),
              pw.Text('Dirección: ${cliente.direccion}'),
              pw.SizedBox(height: 20),

              pw.Text('Fecha: ${fecha.toString().substring(0, 16)}'),
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
                  4: const pw.FixedColumnWidth(100),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _celda('#', esEncabezado: true, alinearCentro: true),
                      _celda('Producto', esEncabezado: true),
                      _celda('Cant.', esEncabezado: true, alinearCentro: true),
                      _celda(
                        'Precio',
                        esEncabezado: true,
                        alinearDerecha: true,
                      ),
                      _celda(
                        'Subtotal',
                        esEncabezado: true,
                        alinearDerecha: true,
                      ),
                    ],
                  ),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _celda('${index + 1}', alinearCentro: true),
                        _celda(item.producto.nombreproducto),
                        _celda('${item.cantidad}', alinearCentro: true),
                        _celda(
                          '\$${item.producto.precioventa.toStringAsFixed(2)}',
                          alinearDerecha: true,
                        ),
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
                    '\$${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Gracias por su compra',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
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
    bool esEncabezado = false,
    bool alinearCentro = false,
    bool alinearDerecha = false,
  }) {
    pw.TextAlign alinear = pw.TextAlign.left;
    if (alinearCentro) alinear = pw.TextAlign.center;
    if (alinearDerecha) alinear = pw.TextAlign.right;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        textAlign: alinear,
        style: esEncabezado
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Pedido'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<pw.Document>(
        future: _generarPDF(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          final pdf = snapshot.data!;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Compartir',
                      color: Colors.blue,
                      onPressed: () async {
                        try {
                          final pdfBytes = await pdf.save();
                          final timestamp =
                              DateTime.now().millisecondsSinceEpoch;
                          final tempDir = await getTemporaryDirectory();
                          final file = File(
                            '${tempDir.path}/pedido_$timestamp.pdf',
                          );
                          await file.writeAsBytes(pdfBytes);

                          await Share.shareXFiles(
                            [XFile(file.path)],
                            text:
                                'Pedido para ${cliente.nombrecliente}\nTotal: \$${total.toStringAsFixed(2)}',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al compartir: $e')),
                          );
                        }
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.print,
                      label: 'Imprimir',
                      color: Colors.green,
                      onPressed: () async {
                        try {
                          await Printing.layoutPdf(
                            onLayout: (format) async => pdf.save(),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al imprimir: $e')),
                          );
                        }
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.save_alt,
                      label: 'Guardar',
                      color: Colors.orange,
                      onPressed: () async {
                        try {
                          await Printing.sharePdf(
                            bytes: await pdf.save(),
                            filename:
                                'pedido_${DateTime.now().millisecondsSinceEpoch}.pdf',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al guardar: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: PdfPreview(build: (format) => pdf.save())),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 32, color: color),
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
