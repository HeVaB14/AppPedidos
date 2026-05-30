import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/export_utils.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CorteVentasScreen extends StatefulWidget {
  const CorteVentasScreen({super.key});

  @override
  State<CorteVentasScreen> createState() => _CorteVentasScreenState();
}

class _CorteVentasScreenState extends State<CorteVentasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  Map<String, dynamic> _corteData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresa();
    _cargarCorte();
  }

  String _empresaNombre = 'Pedidos App';
  Future<void> _cargarEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _empresaNombre = prefs.getString('empresa_nombre') ?? 'Pedidos App';
    });
  }

  Future<void> _cargarCorte() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.getCorteVentas(
        _fechaSeleccionada,
      );
      setState(() {
        _corteData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar corte: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _fechaSeleccionada = date;
      });
      _cargarCorte();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corte de Ventas'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _cambiarFecha,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportarPDF(),
            tooltip: 'Exportar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () => ExportUtils.exportCorteVentasToExcel(
              context,
              _corteData,
              _fechaSeleccionada,
            ),
            tooltip: 'Exportar a Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCorte,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fecha
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              'Fecha del corte',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaSeleccionada),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resumen de ventas
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'RESUMEN DEL DÍA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildResumenItem(
                            'Total de Pedidos:',
                            '${_corteData['totalPedidos'] ?? 0}',
                            Icons.receipt,
                          ),
                          _buildResumenItem(
                            'Productos Vendidos:',
                            '${_corteData['totalProductos'] ?? 0}',
                            Icons.shopping_cart,
                          ),
                          const Divider(),
                          _buildResumenItem(
                            'Ventas Totales:',
                            '\$${(_corteData['ventasTotales'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.attach_money,
                            isMoney: true,
                          ),
                          _buildResumenItem(
                            'Costo de Mercancía:',
                            '\$${(_corteData['costoTotal'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.shopping_bag,
                            isMoney: true,
                          ),
                          const Divider(),
                          _buildResumenItem(
                            'GANANCIA NETA:',
                            '\$${(_corteData['gananciaTotal'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.trending_up,
                            isMoney: true,
                            isBold: true,
                            color: Colors.green,
                          ),
                          _buildResumenItem(
                            'Margen de Ganancia:',
                            '${(_corteData['margenGanancia'] ?? 0.0).toStringAsFixed(1)}%',
                            Icons.percent,
                            isBold: true,
                          ),
                          // Dentro del Column en build, después del resumen:
                          _buildGraficaVentas(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de pedidos del día
                  if (_corteData['pedidos'] != null &&
                      _corteData['pedidos'].isNotEmpty)
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PEDIDOS DEL DÍA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _corteData['pedidos'].length,
                              itemBuilder: (context, index) {
                                final pedido = _corteData['pedidos'][index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        pedido['status'] == 'CERRADO'
                                        ? Colors.green
                                        : Colors.orange,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text('Pedido #${pedido['id']}'),
                                  subtitle: Text(
                                    'Cliente: ${pedido['cliente']}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${pedido['total'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Ganancia: \$${pedido['ganancia'].toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Botón para cerrar/abrir pedidos
                  ElevatedButton.icon(
                    onPressed: () => _cerrarDia(),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('CERRAR DÍA Y CALCULAR GANANCIAS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResumenItem(
    String label,
    String value,
    IconData icon, {
    bool isMoney = false,
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isMoney ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficaVentas() {
    final pedidos = _corteData['pedidos'] ?? [];
    if (pedidos.isEmpty) return const SizedBox.shrink();

    // Agrupar ventas por día (últimos 7 días)
    Map<String, double> ventasPorDia = {};

    for (var pedido in pedidos) {
      String fecha = pedido['fecha']?.substring(0, 10) ?? '';
      double total = pedido['total'] ?? 0;
      ventasPorDia[fecha] = (ventasPorDia[fecha] ?? 0) + total;
    }

    final List<BarChartGroupData> barGroups = [];
    int index = 0;
    ventasPorDia.forEach((fecha, total) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(toY: total, color: Colors.orange, width: 20),
          ],
        ),
      );
      index++;
    });

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Ventas por día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: ventasPorDia.values.isEmpty
                      ? 100
                      : ventasPorDia.values.reduce((a, b) => a > b ? a : b) +
                            100,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final keys = ventasPorDia.keys.toList();
                          if (value.toInt() < keys.length) {
                            return Text(
                              keys[value.toInt()].substring(8, 10),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarDia() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Día'),
        content: Text(
          '¿Estás seguro de cerrar el día ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}?\n\n'
          'Esto marcará todos los pedidos pendientes como cerrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Cerrar Día'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.cerrarPedidosDia(_fechaSeleccionada);
      _cargarCorte();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Día cerrado exitosamente')),
        );
      }
    }
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          children: [
            pw.Text(
              _empresaNombre,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
            ),
            pw.Divider(),
            pw.Row(
              children: [
                pw.Text(
                  'Total Ventas: \$${(_corteData['ventasTotales'] ?? 0).toStringAsFixed(2)}',
                ),
                pw.Spacer(),
                pw.Text(
                  'Ganancia: \$${(_corteData['gananciaTotal'] ?? 0).toStringAsFixed(2)}',
                ),
              ],
            ),
            pw.Divider(),
            pw.Text('Productos vendidos: ${_corteData['totalProductos'] ?? 0}'),
            pw.Text('Pedidos: ${_corteData['totalPedidos'] ?? 0}'),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'corte_${DateFormat('yyyyMMdd').format(_fechaSeleccionada)}.pdf',
    );
  }

  Future<void> _compartirPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              pw.Text(
                _empresaNombre,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
              ),
              // ... más contenido
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/corte_${DateFormat('yyyyMMdd').format(_fechaSeleccionada)}.pdf',
      );
      await file.writeAsBytes(pdfBytes);

      // Usar SharePlus para compartir
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '📊 Reporte de ventas - ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
      );
    } catch (e) {
      print('Error: $e');
    }
  }
}
