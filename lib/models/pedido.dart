import 'clientes.dart';
import 'item_pedido.dart';

class Pedido {
  int? id;
  Clientes cliente;
  List<ItemPedido> items;
  DateTime fecha;
  double total;

  Pedido({
    this.id,
    required this.cliente,
    required this.items,
    required this.fecha,
    required this.total,
  });

  String get numeroPedido => 'PED-${id ?? 0}-${fecha.month}${fecha.day}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idcliente': cliente.idcliente,
      'fecha': fecha.toIso8601String(),
      'total': total,
    };
  }

  factory Pedido.fromMap(
    Map<String, dynamic> map,
    Clientes cliente,
    List<ItemPedido> items,
  ) {
    return Pedido(
      id: map['id'],
      cliente: cliente,
      items: items,
      fecha: DateTime.parse(map['fecha']),
      total: map['total'],
    );
  }
}

class DetallePedido {
  int? id;
  int idPedido;
  int idProducto;
  int cantidad;
  double precioUnitario;
  double subtotal;

  DetallePedido({
    this.id,
    required this.idPedido,
    required this.idProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idPedido': idPedido,
      'idProducto': idProducto,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}
