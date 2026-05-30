import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<Map<String, dynamic>> _masVendidos = [];
  List<Map<String, dynamic>> _noVendidos = [];
  bool _isLoading = true;
  String _empresaNombre = 'Mi Negocio';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    final masVendidos = await DatabaseHelper.instance.getProductosMasVendidos();
    final noVendidos = await DatabaseHelper.instance.getProductosNoVendidos();

    // Cargar nombre de empresa
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _masVendidos = masVendidos;
      _noVendidos = noVendidos;
      _empresaNombre = prefs.getString('empresa_nombre') ?? 'Mi Negocio';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes - $_empresaNombre'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Más Vendidos', icon: Icon(Icons.trending_up)),
                      Tab(text: 'Sin Ventas', icon: Icon(Icons.inventory)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildMasVendidos(), _buildNoVendidos()],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============ GRÁFICA DE MÁS VENDIDOS ============
  Widget _buildMasVendidos() {
    if (_masVendidos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_down, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay datos de ventas',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Tomar top 5
    final top5 = _masVendidos.take(5).toList();
    final double maxVentas = top5
        .map((e) => (e['total_vendido'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 📊 GRÁFICA DE BARRAS
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Top 5 Productos Más Vendidos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxVentas + 2,
                        barGroups: top5.asMap().entries.map((entry) {
                          final index = entry.key;
                          final producto = entry.value;
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: (producto['total_vendido'] ?? 0)
                                    .toDouble(),
                                color: Colors.blue,
                                width: 35,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < top5.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      top5[value.toInt()]['nombreproducto']
                                                  .toString()
                                                  .length >
                                              12
                                          ? '${top5[value.toInt()]['nombreproducto'].toString().substring(0, 10)}...'
                                          : top5[value
                                                    .toInt()]['nombreproducto']
                                                .toString(),
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 📋 LISTA DETALLADA
          Card(
            elevation: 2,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _masVendidos.length,
              itemBuilder: (context, index) {
                final item = _masVendidos[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  title: Text(item['nombreproducto']),
                  subtitle: Text('Código: ${item['codigo']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item['total_vendido']} ventas',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '\$${item['total_venta']?.toStringAsFixed(2) ?? '0'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============ LISTA DE PRODUCTOS NO VENDIDOS ============
  Widget _buildNoVendidos() {
    if (_noVendidos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              '¡Todos los productos han sido vendidos!',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _noVendidos.length,
      itemBuilder: (context, index) {
        final item = _noVendidos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.red.shade50,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.inventory, color: Colors.red, size: 20),
            ),
            title: Text(item['nombreproducto']),
            subtitle: Text(
              'Código: ${item['codigo']} | Stock: ${item['stock']}',
            ),
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
        );
      },
    );
  }
}
