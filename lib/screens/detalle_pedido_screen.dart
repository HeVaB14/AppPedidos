import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/clientes.dart';
import '../models/item_pedido.dart';

class DetallePedidoScreen extends StatelessWidget {
  final int pedidoId;
  final Clientes cliente;
  final List<ItemPedido> items;
  final DateTime fecha;
  final double total;
  final String status;

  const DetallePedidoScreen({
    super.key,
    required this.pedidoId,
    required this.cliente,
    required this.items,
    required this.fecha,
    required this.total,
    required this.status,
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
              // Encabezado
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
                      'Pedido #$pedidoId',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Status: $status',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: status == 'CERRADO'
                            ? PdfColors.green
                            : PdfColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Datos del cliente
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

              // Fecha
              pw.Text('Fecha: ${fecha.toString().substring(0, 16)}'),
              pw.SizedBox(height: 20),

              // Tabla de productos
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

              // Resumen de ganancias
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal:',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Costo de productos:',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          '\$${items.fold(0.0, (sum, item) => sum + item.costoTotal).toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'GANANCIA TOTAL:',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '\$${items.fold(0.0, (sum, item) => sum + ((item.producto.precioventa - item.producto.precioproveedor) * item.cantidad)).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Total final
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL DEL PEDIDO:',
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
                      color: PdfColors.blue,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Pie de página
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

  Future<void> _compartirPDF(pw.Document pdf) async {
    try {
      final pdfBytes = await pdf.save();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pedido_$pedidoId.pdf');

      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Pedido #$pedidoId - ${cliente.nombrecliente}\nTotal: \$${total.toStringAsFixed(2)}\nStatus: $status',
      );
    } catch (e) {
      debugPrint('Error al compartir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double gananciaTotal = items.fold(
      0.0,
      (sum, item) =>
          sum +
          ((item.producto.precioventa - item.producto.precioproveedor) *
              item.cantidad),
    );
    final double costoTotal = items.fold(
      0.0,
      (sum, item) => sum + (item.producto.precioproveedor * item.cantidad),
    );
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Pedido #$pedidoId'),
            Text(status, style: const TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        backgroundColor: status == 'CERRADO' ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final pdf = await _generarPDF();
              await _compartirPDF(pdf);
            },
            tooltip: 'Compartir PDF',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datos del cliente
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'DATOS DEL CLIENTE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Nombre completo'),
                      subtitle: Text(
                        '${cliente.nombrecliente} ${cliente.apellido1} ${cliente.apellido2}',
                      ),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Teléfono'),
                      subtitle: Text(cliente.telefono),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Dirección'),
                      subtitle: Text(cliente.direccion),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Fecha del pedido:'),
                      ],
                    ),
                    Text(
                      '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de productos
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'PRODUCTOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final gananciaReal =
                            (item.producto.precioventa -
                                item.producto.precioproveedor) *
                            item.cantidad;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.cantidad}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.producto.nombreproducto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.cantidad} x \$${item.producto.precioventa.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),

                                          child: Text(
                                            'Ganancia: \$${gananciaReal.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    // Resumen de costos y ganancias
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Costo de productos:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '\$${costoTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'GANANCIA TOTAL:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${gananciaTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total final
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL DEL PEDIDO:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
