//crecion de la clase clientes
class Clientes {
  //inicializamos los valores
  int? idcliente;
  String nombrecliente;
  String apellido1;
  String apellido2;
  String telefono;
  String direccion;

  ///declaramos los valores es neceasrio usar el this para declarar los valores
  ///this.variable
  Clientes({
    this.idcliente,
    required this.nombrecliente,
    required this.apellido1,
    required this.apellido2,
    required this.telefono,
    required this.direccion,
  });

  ///convertimos el mapa
  ///
  Map<String, dynamic> toMap() {
    return {
      'idcliente': idcliente,
      'nombrecliente': nombrecliente,
      'apellido1': apellido1,
      'apellido2': apellido2,
      'telefono': telefono,
      'direccion': direccion,
    };
  }

  //crear un objeto desde un mapa(es como consultar)

  factory Clientes.fromMap(Map<String, dynamic> map) {
    return Clientes(
      idcliente: map['idcliente'],
      nombrecliente: map['nombrecliente'],
      apellido1: map['apellido1'],
      apellido2: map['apellido2'],
      telefono: map['telefono'],
      direccion: map['direccion'],
    );
  }
}
