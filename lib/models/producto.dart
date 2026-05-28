class Producto {
  int? id;
  String codigo;
  String nombreproducto;
  String? descripcion;
  double cantidad;
  String unidadmedida;
  double precioproveedor; // Nuevo: precio de compra
  double precioventa; // Renombrado: precio de venta al público
  double ganancia; // Nuevo: ganancia por unidad

  Producto({
    this.id,
    required this.codigo,
    required this.nombreproducto,
    this.descripcion,
    required this.cantidad,
    required this.unidadmedida,
    required this.precioproveedor,
    required this.precioventa,
    required this.ganancia,
  });

  // Getter para calcular ganancia automáticamente
  void calcularGanancia() {
    ganancia = precioventa - precioproveedor;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombreproducto': nombreproducto,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'unidadmedida': unidadmedida,
      'precioproveedor': precioproveedor,
      'precioventa': precioventa,
      'ganancia': ganancia,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      codigo: map['codigo'],
      nombreproducto: map['nombreproducto'],
      descripcion: map['descripcion'],
      cantidad: map['cantidad'],
      unidadmedida: map['unidadmedida'],
      precioproveedor: map['precioproveedor'],
      precioventa: map['precioventa'],
      ganancia: map['ganancia'],
    );
  }
}
