import 'dart:io';
import 'package:flutter_application_1/database/database_helper.dart';
import 'package:flutter_application_1/models/producto.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';

class ExportUtils {
  // Exportar corte de ventas a EXCEL (.xlsx) - 3 hojas completas
  static Future<void> exportCorteVentasToExcel(
    BuildContext context,
    Map<String, dynamic> corteData,
    DateTime fecha,
  ) async {
    try {
      var excel = Excel.createExcel();

      // ========== HOJA 1: RESUMEN ==========
      Sheet sheetResumen = excel['RESUMEN'];

      sheetResumen.appendRow([TextCellValue('CORTE DE VENTAS')]);
      sheetResumen.appendRow([
        TextCellValue('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
      ]);
      sheetResumen.appendRow([TextCellValue('')]);
      sheetResumen.appendRow([
        TextCellValue('INDICADOR'),
        TextCellValue('VALOR'),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Total Pedidos'),
        IntCellValue(corteData['totalPedidos'] ?? 0),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Total Productos Vendidos'),
        IntCellValue(corteData['totalProductos'] ?? 0),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Ventas Totales'),
        DoubleCellValue(corteData['ventasTotales'] ?? 0),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Costo Total'),
        DoubleCellValue(corteData['costoTotal'] ?? 0),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Ganancia Total'),
        DoubleCellValue(corteData['gananciaTotal'] ?? 0),
      ]);
      sheetResumen.appendRow([
        TextCellValue('Margen de Ganancia'),
        TextCellValue(
          '${(corteData['margenGanancia'] ?? 0).toStringAsFixed(1)}%',
        ),
      ]);

      sheetResumen.setColumnWidth(0, 25);
      sheetResumen.setColumnWidth(1, 20);

      // ========== HOJA 2: DETALLE DE PEDIDOS ==========
      Sheet sheetDetalle = excel['DETALLE DE PEDIDOS'];

      sheetDetalle.appendRow([
        TextCellValue('ID'),
        TextCellValue('FECHA'),
        TextCellValue('CLIENTE'),
        TextCellValue('TOTAL'),
        TextCellValue('GANANCIA'),
        TextCellValue('STATUS'),
      ]);

      final pedidos = corteData['pedidos'] ?? [];
      for (var pedido in pedidos) {
        sheetDetalle.appendRow([
          IntCellValue(pedido['id'] ?? 0),
          TextCellValue(pedido['fecha']?.substring(0, 10) ?? ''),
          TextCellValue(pedido['cliente'] ?? ''),
          DoubleCellValue(pedido['total'] ?? 0),
          DoubleCellValue(pedido['ganancia'] ?? 0),
          TextCellValue(pedido['status'] ?? ''),
        ]);
      }

      sheetDetalle.setColumnWidth(0, 8);
      sheetDetalle.setColumnWidth(1, 12);
      sheetDetalle.setColumnWidth(2, 30);
      sheetDetalle.setColumnWidth(3, 12);
      sheetDetalle.setColumnWidth(4, 12);
      sheetDetalle.setColumnWidth(5, 10);

      // ========== HOJA 3: GANANCIA POR PRODUCTO ==========
      Sheet sheetProductos = excel['GANANCIA POR PRODUCTO'];

      final productos = await DatabaseHelper.instance.getProductos();
      for (var p in productos) {
        sheetProductos.appendRow([
          TextCellValue(p.codigo),
          TextCellValue(p.nombreproducto),
          DoubleCellValue(p.precioproveedor),
          DoubleCellValue(p.precioventa),
          DoubleCellValue(p.ganancia),
        ]);
      }

      sheetProductos.setColumnWidth(0, 15);
      sheetProductos.setColumnWidth(1, 30);
      sheetProductos.setColumnWidth(2, 18);
      sheetProductos.setColumnWidth(3, 15);
      sheetProductos.setColumnWidth(4, 18);

      // Guardar archivo
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final fileName =
            'corte_${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}.xlsx';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        // 👈 SIN mimeTypes
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              '📊 Reporte de ventas - ${fecha.day}/${fecha.month}/${fecha.year}',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Excel generado: Resumen + Detalle + Ganancias'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Exportar productos a EXCEL (.xlsx)
  static Future<void> exportProductosToExcel(
    BuildContext context,
    List<Producto> productos,
  ) async {
    try {
      var excel = Excel.createExcel();

      Sheet sheet = excel['PRODUCTOS'];

      sheet.appendRow([
        TextCellValue('Código'),
        TextCellValue('Nombre'),
        TextCellValue('Stock'),
        TextCellValue('Unidad'),
        TextCellValue('Precio Proveedor'),
        TextCellValue('Precio Venta'),
        TextCellValue('Ganancia'),
      ]);

      for (var p in productos) {
        sheet.appendRow([
          TextCellValue(p.codigo),
          TextCellValue(p.nombreproducto),
          DoubleCellValue(p.cantidad),
          TextCellValue(p.unidadmedida),
          DoubleCellValue(p.precioproveedor),
          DoubleCellValue(p.precioventa),
          DoubleCellValue(p.ganancia),
        ]);
      }

      sheet.setColumnWidth(0, 15);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 10);
      sheet.setColumnWidth(3, 10);
      sheet.setColumnWidth(4, 18);
      sheet.setColumnWidth(5, 15);
      sheet.setColumnWidth(6, 15);

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/productos.xlsx');
        await file.writeAsBytes(fileBytes);

        await Share.shareXFiles([
          XFile(file.path),
        ], text: '📦 Reporte de productos');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Productos exportados correctamente'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
