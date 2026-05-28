import 'producto.dart';

class ItemPedido {
  Producto producto;
  int cantidad;
  double costoUnitario; // Nuevo
  double gananciaUnitaria; // Nuevo

  ItemPedido({required this.producto, required this.cantidad})
    : costoUnitario = producto.precioproveedor,
      gananciaUnitaria = producto.ganancia;

  double get subtotal => producto.precioventa * cantidad;
  double get costoTotal => costoUnitario * cantidad;
  double get gananciaTotal => gananciaUnitaria * cantidad;

  bool get hayStock => cantidad <= producto.cantidad;

  String get advertenciaStock {
    if (!hayStock) {
      return '⚠️ Stock insuficiente: Solo ${producto.cantidad.toStringAsFixed(0)} ${producto.unidadmedida} disponibles';
    }
    return '';
  }
}
