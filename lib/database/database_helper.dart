// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import '../models/producto.dart';
// import '../models/clientes.dart';

// class DatabaseHelper {
//   static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
//   DatabaseHelper._privateConstructor();

//   static Database? _database;

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     String path = join(await getDatabasesPath(), 'pedidos_app.db');
//     return await openDatabase(
//       path,
//       version: 3, // 👈 Cambia a versión 3
//       onCreate: _onCreate,
//       onUpgrade: _onUpgrade,
//     );
//   }

//   // Para instalaciones nuevas
//   Future<void> _onCreate(Database db, int version) async {
//     print("📱 Creando tablas versión $version...");
//     await _crearTablas(db);
//     await _insertarDatosEjemplo(db);
//   }

//   // Para actualizar apps existentes
//   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//     print("🔄 Actualizando BD de versión $oldVersion a $newVersion");

//     if (oldVersion < 2) {
//       try {
//         await db.execute(
//           'ALTER TABLE productos ADD COLUMN precioproveedor REAL DEFAULT 0',
//         );
//         await db.execute(
//           'ALTER TABLE productos ADD COLUMN ganancia REAL DEFAULT 0',
//         );
//         await db.execute(
//           'ALTER TABLE productos RENAME COLUMN precio TO precioventa',
//         );
//       } catch (e) {
//         print("Error en migración: $e");
//       }
//     }

//     if (oldVersion < 3) {
//       try {
//         await db.execute(
//           'ALTER TABLE pedidos ADD COLUMN status TEXT DEFAULT "PENDIENTE"',
//         );
//         await db.execute(
//           'ALTER TABLE detalle_pedido ADD COLUMN costoUnitario REAL DEFAULT 0',
//         );
//         await db.execute(
//           'ALTER TABLE detalle_pedido ADD COLUMN ganancia REAL DEFAULT 0',
//         );
//       } catch (e) {
//         print("Error en migración a versión 3: $e");
//       }
//     }
//   }

//   Future<void> _crearTablas(Database db) async {
//     // Tabla de productos actualizada
//     await db.execute('''
//       CREATE TABLE productos(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         codigo TEXT NOT NULL UNIQUE,
//         nombreproducto TEXT NOT NULL,
//         descripcion TEXT,
//         cantidad REAL NOT NULL,
//         unidadmedida TEXT NOT NULL,
//         precioproveedor REAL NOT NULL,
//         precioventa REAL NOT NULL,
//         ganancia REAL NOT NULL
//       )
//     ''');

//     // Tabla de clientes
//     await db.execute('''
//       CREATE TABLE clientes(
//         idcliente INTEGER PRIMARY KEY AUTOINCREMENT,
//         nombrecliente TEXT NOT NULL,
//         apellido1 TEXT NOT NULL,
//         apellido2 TEXT NOT NULL,
//         telefono TEXT NOT NULL,
//         direccion TEXT NOT NULL
//       )
//     ''');

//     // Tabla de pedidos
//     await db.execute('''
//       CREATE TABLE pedidos(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         idcliente INTEGER NOT NULL,
//         fecha TEXT NOT NULL,
//         total REAL NOT NULL,
//         status TEXT DEFAULT 'PENDIENTE',
//         FOREIGN KEY (idcliente) REFERENCES clientes (idcliente)
//       )
//     ''');

//     // Tabla de detalles de pedido
//     await db.execute('''
//       CREATE TABLE detalle_pedido(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         idPedido INTEGER NOT NULL,
//         idProducto INTEGER NOT NULL,
//         cantidad REAL NOT NULL,
//         precioUnitario REAL NOT NULL,
//         costoUnitario REAL NOT NULL,
//         subtotal REAL NOT NULL,
//         ganancia REAL NOT NULL,
//         FOREIGN KEY (idPedido) REFERENCES pedidos (id),
//         FOREIGN KEY (idProducto) REFERENCES productos (id)
//       )
//     ''');
//   }

//   Future<void> _insertarDatosEjemplo(Database db) async {
//     // Productos de ejemplo
//     await db.insert('productos', {
//       'codigo': 'LAP-001',
//       'nombreproducto': 'Laptop Gaming',
//       'descripcion': '16GB RAM, 512GB SSD, RTX 3060',
//       'cantidad': 10,
//       'unidadmedida': 'pza',
//       'precioproveedor': 12000,
//       'precioventa': 15999.99,
//       'ganancia': 3999.99,
//     });

//     await db.insert('productos', {
//       'codigo': 'MOU-002',
//       'nombreproducto': 'Mouse Inalámbrico',
//       'descripcion': 'Logitech MX Master 3',
//       'cantidad': 25,
//       'unidadmedida': 'pza',
//       'precioproveedor': 600,
//       'precioventa': 899.99,
//       'ganancia': 299.99,
//     });

//     await db.insert('productos', {
//       'codigo': 'TEC-003',
//       'nombreproducto': 'Teclado Mecánico',
//       'descripcion': 'RGB, switches azules',
//       'cantidad': 15,
//       'unidadmedida': 'pza',
//       'precioproveedor': 800,
//       'precioventa': 1299.99,
//       'ganancia': 499.99,
//     });

//     await db.insert('productos', {
//       'codigo': 'MON-004',
//       'nombreproducto': 'Monitor 24"',
//       'descripcion': '1080p, 144Hz',
//       'cantidad': 8,
//       'unidadmedida': 'pza',
//       'precioproveedor': 2500,
//       'precioventa': 3499.99,
//       'ganancia': 999.99,
//     });

//     // Clientes de ejemplo
//     await db.insert('clientes', {
//       'nombrecliente': 'Juan',
//       'apellido1': 'Pérez',
//       'apellido2': 'García',
//       'telefono': '555-1234',
//       'direccion': 'Av. Principal 123, Colonia Centro',
//     });

//     await db.insert('clientes', {
//       'nombrecliente': 'María',
//       'apellido1': 'García',
//       'apellido2': 'López',
//       'telefono': '555-5678',
//       'direccion': 'Calle Secundaria 456, Colonia Reforma',
//     });

//     await db.insert('clientes', {
//       'nombrecliente': 'Carlos',
//       'apellido1': 'Rodríguez',
//       'apellido2': 'Martínez',
//       'telefono': '555-9012',
//       'direccion': 'Boulevard Principal 789, Colonia Industrial',
//     });

//     print("✅ Datos de ejemplo insertados");
//   }

//   // ============ CRUD PRODUCTOS ============
//   Future<List<Producto>> getProductos() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('productos');
//     return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
//   }

//   Future<int> insertProducto(Producto producto) async {
//     final db = await database;
//     return await db.insert('productos', producto.toMap());
//   }

//   Future<int> updateProducto(Producto producto) async {
//     final db = await database;
//     return await db.update(
//       'productos',
//       producto.toMap(),
//       where: 'id = ?',
//       whereArgs: [producto.id],
//     );
//   }

//   Future<int> deleteProducto(int id) async {
//     final db = await database;
//     return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
//   }

//   Future<Producto?> getProductoByCodigo(String codigo) async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'productos',
//       where: 'codigo = ?',
//       whereArgs: [codigo],
//     );
//     if (maps.isNotEmpty) {
//       return Producto.fromMap(maps.first);
//     }
//     return null;
//   }

//   // ============ CRUD CLIENTES ============
//   Future<List<Clientes>> getClientes() async {
//     final db = await database;
//     final List<Map<String, dynamic>> maps = await db.query('clientes');
//     return List.generate(maps.length, (i) => Clientes.fromMap(maps[i]));
//   }

//   Future<int> insertCliente(Clientes cliente) async {
//     final db = await database;
//     return await db.insert('clientes', cliente.toMap());
//   }

//   Future<int> updateCliente(Clientes cliente) async {
//     final db = await database;
//     return await db.update(
//       'clientes',
//       cliente.toMap(),
//       where: 'idcliente = ?',
//       whereArgs: [cliente.idcliente],
//     );
//   }

//   Future<int> deleteCliente(int idcliente) async {
//     final db = await database;
//     return await db.delete(
//       'clientes',
//       where: 'idcliente = ?',
//       whereArgs: [idcliente],
//     );
//   }

//   // ============ CRUD PEDIDOS ============
//   Future<int> insertPedido(Map<String, dynamic> pedidoMap) async {
//     final db = await database;
//     return await db.insert('pedidos', pedidoMap);
//   }

//   Future<int> insertDetallePedido(Map<String, dynamic> detalleMap) async {
//     final db = await database;
//     return await db.insert('detalle_pedido', detalleMap);
//   }

//   Future<void> actualizarStockProducto(
//     int idProducto,
//     double nuevaCantidad,
//   ) async {
//     final db = await database;
//     await db.update(
//       'productos',
//       {'cantidad': nuevaCantidad},
//       where: 'id = ?',
//       whereArgs: [idProducto],
//     );
//   }

//   Future<List<Map<String, dynamic>>> getHistorialPedidos() async {
//     final db = await database;
//     return await db.rawQuery('''
//       SELECT p.*, c.nombrecliente, c.apellido1, c.apellido2
//       FROM pedidos p
//       JOIN clientes c ON p.idcliente = c.idcliente
//       ORDER BY p.fecha DESC
//     ''');
//   }

//   Future<List<Map<String, dynamic>>> getPedidosConDetalles() async {
//     final db = await database;
//     return await db.rawQuery('''
//       SELECT
//         p.id as pedido_id,
//         p.fecha,
//         p.total,
//         p.status,
//         c.idcliente,
//         c.nombrecliente,
//         c.apellido1,
//         c.apellido2,
//         c.telefono,
//         c.direccion,
//         COALESCE(SUM(d.ganancia), 0) as ganancia
//       FROM pedidos p
//       JOIN clientes c ON p.idcliente = c.idcliente
//       LEFT JOIN detalle_pedido d ON p.id = d.idPedido
//       GROUP BY p.id
//       ORDER BY p.fecha DESC
//     ''');
//   }

//   Future<List<Map<String, dynamic>>> getDetallesPedido(int pedidoId) async {
//     final db = await database;
//     return await db.rawQuery(
//       '''
//       SELECT
//         d.idPedido,
//         d.idProducto,
//         d.cantidad,
//         d.precioUnitario,
//         d.costoUnitario,
//         d.subtotal,
//         d.ganancia,
//         pr.codigo,
//         pr.nombreproducto,
//         pr.descripcion,
//         pr.unidadmedida
//       FROM detalle_pedido d
//       JOIN productos pr ON d.idProducto = pr.id
//       WHERE d.idPedido = ?
//     ''',
//       [pedidoId],
//     );
//   }

//   // Obtener corte de ventas por fecha
//   Future<Map<String, dynamic>> getCorteVentas(DateTime fecha) async {
//     final db = await database;

//     final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
//     final finDia = inicioDia.add(const Duration(days: 1));

//     final pedidos = await db.query(
//       'pedidos',
//       where: 'fecha >= ? AND fecha < ?',
//       whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
//     );

//     double ventasTotales = 0;
//     double costoTotal = 0;
//     double gananciaTotal = 0;
//     int totalProductos = 0;

//     List<Map<String, dynamic>> pedidosDetalle = [];

//     for (var pedido in pedidos) {
//       final detalles = await db.query(
//         'detalle_pedido',
//         where: 'idPedido = ?',
//         whereArgs: [pedido['id']],
//       );

//       double pedidoTotal = 0;
//       double pedidoGanancia = 0;
//       int pedidoProductos = 0;

//       for (var detalle in detalles) {
//         pedidoTotal += (detalle['subtotal'] as num).toInt();
//         pedidoGanancia += (detalle['ganancia'] as num).toInt();
//         pedidoProductos += (detalle['cantidad'] as num).toInt();
//       }

//       final cliente = await db.query(
//         'clientes',
//         where: 'idcliente = ?',
//         whereArgs: [pedido['idcliente']],
//       );

//       ventasTotales += pedidoTotal;
//       gananciaTotal += pedidoGanancia;
//       totalProductos += pedidoProductos;

//       pedidosDetalle.add({
//         'id': pedido['id'],
//         'cliente': cliente.isNotEmpty
//             ? '${cliente.first['nombrecliente']} ${cliente.first['apellido1']}'
//             : 'Cliente no encontrado',
//         'total': pedidoTotal,
//         'ganancia': pedidoGanancia,
//         'status': pedido['status'],
//       });
//     }

//     costoTotal = ventasTotales - gananciaTotal;
//     double margenGanancia = ventasTotales > 0
//         ? (gananciaTotal / ventasTotales) * 100
//         : 0;

//     return {
//       'totalPedidos': pedidos.length,
//       'totalProductos': totalProductos,
//       'ventasTotales': ventasTotales,
//       'costoTotal': costoTotal,
//       'gananciaTotal': gananciaTotal,
//       'margenGanancia': margenGanancia,
//       'pedidos': pedidosDetalle,
//     };
//   }

//   // Cerrar pedidos del día
//   Future<void> cerrarPedidosDia(DateTime fecha) async {
//     final db = await database;

//     final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
//     final finDia = inicioDia.add(const Duration(days: 1));

//     await db.update(
//       'pedidos',
//       {'status': 'CERRADO'},
//       where: 'fecha >= ? AND fecha < ? AND status = "PENDIENTE"',
//       whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
//     );
//   }
// }
import 'package:flutter_application_1/models/clientes.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/clientes.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  static Database? _database;

  // VERSIÓN ACTUAL - Cambia según tus necesidades
  static const int DATABASE_VERSION = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pedidos_app.db');
    return await openDatabase(
      path,
      version: DATABASE_VERSION,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============ NUEVA INSTALACIÓN ============
  Future<void> _onCreate(Database db, int version) async {
    print("📱 Creando base de datos NUEVA versión $version...");
    await _crearTodasLasTablas(db);
    await _insertarDatosEjemplo(db);
  }

  // ============ ACTUALIZACIÓN (USUARIOS EXISTENTES) ============
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("🔄 ACTUALIZANDO BD de versión $oldVersion a $newVersion");

    // Para cada versión anterior, aplicar migraciones
    if (oldVersion < 2) {
      await _migracionVersion2(db);
    }
    if (oldVersion < 3) {
      await _migracionVersion3(db);
    }
    if (oldVersion < 4) {
      await _migracionVersion4(db);
    }
  }

  // ============ MIGRACIÓN VERSIÓN 2 ============
  Future<void> _migracionVersion2(Database db) async {
    print("📌 Migrando a versión 2: Agregando precioproveedor y ganancia");

    try {
      // Verificar tabla productos
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='productos'",
      );

      if (tables.isEmpty) {
        // Si no existe tabla productos, crearla completa
        print("   ⚠️ Tabla productos no existe, creando...");
        await db.execute('''
          CREATE TABLE productos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            codigo TEXT NOT NULL UNIQUE,
            nombreproducto TEXT NOT NULL,
            descripcion TEXT,
            cantidad REAL NOT NULL,
            unidadmedida TEXT NOT NULL,
            precioproveedor REAL NOT NULL,
            precioventa REAL NOT NULL,
            ganancia REAL NOT NULL
          )
        ''');
        return;
      }

      // Obtener columnas existentes
      final columns = await db.rawQuery("PRAGMA table_info(productos)");
      final columnNames = columns.map((col) => col['name'] as String).toList();

      // Agregar columnas faltantes una por una
      if (!columnNames.contains('precioproveedor')) {
        await db.execute(
          'ALTER TABLE productos ADD COLUMN precioproveedor REAL DEFAULT 0',
        );
        print("   ✅ Columna 'precioproveedor' agregada");
      }

      if (!columnNames.contains('ganancia')) {
        await db.execute(
          'ALTER TABLE productos ADD COLUMN ganancia REAL DEFAULT 0',
        );
        print("   ✅ Columna 'ganancia' agregada");
      }

      // Manejar columna precio vs precioventa
      if (columnNames.contains('precio') &&
          !columnNames.contains('precioventa')) {
        await db.execute(
          'ALTER TABLE productos RENAME COLUMN precio TO precioventa',
        );
        print("   ✅ Columna 'precio' renombrada a 'precioventa'");
      } else if (!columnNames.contains('precioventa')) {
        await db.execute(
          'ALTER TABLE productos ADD COLUMN precioventa REAL DEFAULT 0',
        );
        print("   ✅ Columna 'precioventa' agregada");
      }

      // Actualizar datos existentes
      await db.execute('''
        UPDATE productos 
        SET precioproveedor = CASE 
          WHEN precioproveedor = 0 AND precioventa > 0 THEN precioventa * 0.7 
          ELSE precioproveedor 
        END,
        ganancia = precioventa - precioproveedor
        WHERE ganancia = 0 AND precioventa > 0
      ''');
    } catch (e) {
      print("   ❌ Error en migración v2: $e");
    }
  }

  // ============ MIGRACIÓN VERSIÓN 3 ============
  Future<void> _migracionVersion3(Database db) async {
    print("📌 Migrando a versión 3: Agregando status y nuevas columnas");

    try {
      // Verificar tabla pedidos
      var tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='pedidos'",
      );

      if (tables.isNotEmpty) {
        var columns = await db.rawQuery("PRAGMA table_info(pedidos)");
        var columnNames = columns.map((col) => col['name'] as String).toList();

        if (!columnNames.contains('status')) {
          await db.execute(
            'ALTER TABLE pedidos ADD COLUMN status TEXT DEFAULT "PENDIENTE"',
          );
          print("   ✅ Columna 'status' agregada a pedidos");

          // Actualizar pedidos existentes
          await db.execute(
            'UPDATE pedidos SET status = "CERRADO" WHERE status IS NULL',
          );
        }
      } else {
        // Crear tabla pedidos si no existe
        await db.execute('''
          CREATE TABLE pedidos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idcliente INTEGER NOT NULL,
            fecha TEXT NOT NULL,
            total REAL NOT NULL,
            status TEXT DEFAULT 'PENDIENTE'
          )
        ''');
        print("   ✅ Tabla pedidos creada");
      }

      // Verificar tabla detalle_pedido
      tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='detalle_pedido'",
      );

      if (tables.isNotEmpty) {
        var columns = await db.rawQuery("PRAGMA table_info(detalle_pedido)");
        var columnNames = columns.map((col) => col['name'] as String).toList();

        if (!columnNames.contains('costoUnitario')) {
          await db.execute(
            'ALTER TABLE detalle_pedido ADD COLUMN costoUnitario REAL DEFAULT 0',
          );
          print("   ✅ Columna 'costoUnitario' agregada");
        }

        if (!columnNames.contains('ganancia')) {
          await db.execute(
            'ALTER TABLE detalle_pedido ADD COLUMN ganancia REAL DEFAULT 0',
          );
          print("   ✅ Columna 'ganancia' agregada a detalle_pedido");
        }

        // Actualizar datos existentes
        await db.execute('''
          UPDATE detalle_pedido 
          SET costoUnitario = (
            SELECT COALESCE(precioproveedor, precioventa * 0.7) 
            FROM productos 
            WHERE productos.id = detalle_pedido.idProducto
          ),
          ganancia = subtotal - costoUnitario
          WHERE costoUnitario = 0
        ''');
      } else {
        // Crear tabla detalle_pedido si no existe
        await db.execute('''
          CREATE TABLE detalle_pedido(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idPedido INTEGER NOT NULL,
            idProducto INTEGER NOT NULL,
            cantidad REAL NOT NULL,
            precioUnitario REAL NOT NULL,
            costoUnitario REAL NOT NULL,
            subtotal REAL NOT NULL,
            ganancia REAL NOT NULL
          )
        ''');
        print("   ✅ Tabla detalle_pedido creada");
      }
    } catch (e) {
      print("   ❌ Error en migración v3: $e");
    }
  }

  // ============ MIGRACIÓN VERSIÓN 4 ============
  Future<void> _migracionVersion4(Database db) async {
    print("📌 Migrando a versión 4: Verificación y corrección de datos");

    try {
      // Asegurar que todos los productos tengan valores válidos
      await db.execute('''
        UPDATE productos 
        SET precioproveedor = CASE 
          WHEN precioproveedor IS NULL OR precioproveedor = 0 THEN precioventa * 0.7 
          ELSE precioproveedor 
        END,
        ganancia = precioventa - precioproveedor,
        unidadmedida = CASE 
          WHEN unidadmedida IS NULL OR unidadmedida = '' THEN 'pza' 
          ELSE unidadmedida 
        END
      ''');
      print("   ✅ Datos de productos normalizados");
    } catch (e) {
      print("   ❌ Error en migración v4: $e");
    }
  }

  // ============ CREACIÓN DE TABLAS (NUEVA INSTALACIÓN) ============
  Future<void> _crearTodasLasTablas(Database db) async {
    print("📌 Creando todas las tablas");

    // Tabla productos
    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombreproducto TEXT NOT NULL,
        descripcion TEXT,
        cantidad REAL NOT NULL,
        unidadmedida TEXT NOT NULL,
        precioproveedor REAL NOT NULL,
        precioventa REAL NOT NULL,
        ganancia REAL NOT NULL
      )
    ''');

    // Tabla clientes
    await db.execute('''
      CREATE TABLE clientes(
        idcliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombrecliente TEXT NOT NULL,
        apellido1 TEXT NOT NULL,
        apellido2 TEXT NOT NULL,
        telefono TEXT NOT NULL,
        direccion TEXT NOT NULL
      )
    ''');

    // Tabla pedidos
    await db.execute('''
      CREATE TABLE pedidos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idcliente INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT DEFAULT 'PENDIENTE',
        FOREIGN KEY (idcliente) REFERENCES clientes (idcliente)
      )
    ''');

    // Tabla detalle_pedido
    await db.execute('''
      CREATE TABLE detalle_pedido(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idPedido INTEGER NOT NULL,
        idProducto INTEGER NOT NULL,
        cantidad REAL NOT NULL,
        precioUnitario REAL NOT NULL,
        costoUnitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        ganancia REAL NOT NULL,
        FOREIGN KEY (idPedido) REFERENCES pedidos (id),
        FOREIGN KEY (idProducto) REFERENCES productos (id)
      )
    ''');

    print("✅ Tablas creadas correctamente");
  }

  // ============ DATOS DE EJEMPLO ============
  Future<void> _insertarDatosEjemplo(Database db) async {
    print("📌 Insertando datos de ejemplo");

    await db.insert('productos', {
      'codigo': 'LAP-001',
      'nombreproducto': 'Laptop Gaming',
      'descripcion': '16GB RAM, 512GB SSD',
      'cantidad': 10,
      'unidadmedida': 'pza',
      'precioproveedor': 12000,
      'precioventa': 15999.99,
      'ganancia': 3999.99,
    });

    await db.insert('productos', {
      'codigo': 'MOU-002',
      'nombreproducto': 'Mouse Inalámbrico',
      'descripcion': 'Logitech MX Master 3',
      'cantidad': 25,
      'unidadmedida': 'pza',
      'precioproveedor': 600,
      'precioventa': 899.99,
      'ganancia': 299.99,
    });

    await db.insert('clientes', {
      'nombrecliente': 'Juan',
      'apellido1': 'Pérez',
      'apellido2': 'García',
      'telefono': '555-1234',
      'direccion': 'Av. Principal 123',
    });

    await db.insert('clientes', {
      'nombrecliente': 'María',
      'apellido1': 'García',
      'apellido2': 'López',
      'telefono': '555-5678',
      'direccion': 'Calle Secundaria 456',
    });

    print("✅ Datos de ejemplo insertados");
  }

  // ============ CRUD PRODUCTOS ============
  Future<List<Producto>> getProductos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos');
    return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
  }

  Future<int> insertProducto(Producto producto) async {
    final db = await database;
    return await db.insert('productos', producto.toMap());
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<Producto?> getProductoByCodigo(String codigo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );
    if (maps.isNotEmpty) {
      return Producto.fromMap(maps.first);
    }
    return null;
  }

  // ============ CRUD CLIENTES ============
  Future<List<Clientes>> getClientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clientes');
    return List.generate(maps.length, (i) => Clientes.fromMap(maps[i]));
  }

  Future<int> insertCliente(Clientes cliente) async {
    final db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<int> updateCliente(Clientes cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'idcliente = ?',
      whereArgs: [cliente.idcliente],
    );
  }

  Future<int> deleteCliente(int idcliente) async {
    final db = await database;
    return await db.delete(
      'clientes',
      where: 'idcliente = ?',
      whereArgs: [idcliente],
    );
  }

  // ============ CRUD PEDIDOS ============
  Future<int> insertPedido(Map<String, dynamic> pedidoMap) async {
    final db = await database;
    return await db.insert('pedidos', pedidoMap);
  }

  Future<int> insertDetallePedido(Map<String, dynamic> detalleMap) async {
    final db = await database;
    return await db.insert('detalle_pedido', detalleMap);
  }

  Future<void> actualizarStockProducto(
    int idProducto,
    double nuevaCantidad,
  ) async {
    final db = await database;
    await db.update(
      'productos',
      {'cantidad': nuevaCantidad},
      where: 'id = ?',
      whereArgs: [idProducto],
    );
  }

  Future<List<Map<String, dynamic>>> getHistorialPedidos() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, c.nombrecliente, c.apellido1, c.apellido2 
      FROM pedidos p
      JOIN clientes c ON p.idcliente = c.idcliente
      ORDER BY p.fecha DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPedidosConDetalles() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      p.id as pedido_id,
      p.fecha,
      p.total,
      p.status,
      c.idcliente,
      c.nombrecliente,
      c.apellido1,
      c.apellido2,
      c.telefono,
      c.direccion,
      COALESCE(SUM(d.ganancia), 0) as ganancia_total
    FROM pedidos p
    JOIN clientes c ON p.idcliente = c.idcliente
    LEFT JOIN detalle_pedido d ON p.id = d.idPedido
    GROUP BY p.id
    ORDER BY p.fecha DESC
  ''');
  }

  Future<List<Map<String, dynamic>>> getDetallesPedido(int pedidoId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      d.id,
      d.idPedido,
      d.idProducto,
      d.cantidad,
      d.precioUnitario,
      d.costoUnitario,
      d.subtotal,
      d.ganancia,
      pr.codigo,
      pr.nombreproducto,
      pr.descripcion,
      pr.unidadmedida
    FROM detalle_pedido d
    JOIN productos pr ON d.idProducto = pr.id
    WHERE d.idPedido = ?
  ''',
      [pedidoId],
    );
  }

  // ============ CORTE DE VENTAS ============
  Future<Map<String, dynamic>> getCorteVentas(DateTime fecha) async {
    final db = await database;

    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    final pedidos = await db.query(
      'pedidos',
      where: 'fecha >= ? AND fecha < ?',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
    );

    double ventasTotales = 0;
    double costoTotal = 0;
    double gananciaTotal = 0;
    int totalProductos = 0;
    List<Map<String, dynamic>> pedidosDetalle = [];

    for (var pedido in pedidos) {
      final detalles = await db.query(
        'detalle_pedido',
        where: 'idPedido = ?',
        whereArgs: [pedido['id']],
      );

      double pedidoTotal = 0;
      double pedidoGanancia = 0;
      int pedidoProductos = 0;

      for (var detalle in detalles) {
        pedidoTotal += (detalle['subtotal'] as num).toInt();
        pedidoGanancia += (detalle['ganancia'] as num).toInt();
        pedidoProductos += (detalle['cantidad'] as num).toInt();
      }

      final cliente = await db.query(
        'clientes',
        where: 'idcliente = ?',
        whereArgs: [pedido['idcliente']],
      );

      ventasTotales += pedidoTotal;
      gananciaTotal += pedidoGanancia;
      totalProductos += pedidoProductos;

      pedidosDetalle.add({
        'id': pedido['id'],
        'cliente': cliente.isNotEmpty
            ? '${cliente.first['nombrecliente']} ${cliente.first['apellido1']}'
            : 'Cliente no encontrado',
        'total': pedidoTotal,
        'ganancia': pedidoGanancia,
        'status': pedido['status'],
      });
    }

    costoTotal = ventasTotales - gananciaTotal;
    double margenGanancia = ventasTotales > 0
        ? (gananciaTotal / ventasTotales) * 100
        : 0;

    return {
      'totalPedidos': pedidos.length,
      'totalProductos': totalProductos,
      'ventasTotales': ventasTotales,
      'costoTotal': costoTotal,
      'gananciaTotal': gananciaTotal,
      'margenGanancia': margenGanancia,
      'pedidos': pedidosDetalle,
    };
  }

  // Cerrar pedidos del día
  Future<void> cerrarPedidosDia(DateTime fecha) async {
    final db = await database;

    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    await db.update(
      'pedidos',
      {'status': 'CERRADO'},
      where: 'fecha >= ? AND fecha < ? AND status = "PENDIENTE"',
      whereArgs: [inicioDia.toIso8601String(), finDia.toIso8601String()],
    );
  }

  // Eliminar un producto específico del pedido y restaurar stock
  Future<void> eliminarProductoDelPedido(
    int detalleId,
    int productoId,
    int cantidad,
    int pedidoId,
  ) async {
    final db = await database;

    await db.delete('detalle_pedido', where: 'id = ?', whereArgs: [detalleId]);

    await db.execute(
      'UPDATE productos SET cantidad = cantidad + $cantidad WHERE id = $productoId',
    );

    final detallesRestantes = await db.query(
      'detalle_pedido',
      where: 'idPedido = ?',
      whereArgs: [pedidoId],
    );

    if (detallesRestantes.isEmpty) {
      await db.delete('pedidos', where: 'id = ?', whereArgs: [pedidoId]);
    } else {
      final nuevoTotal = await db.rawQuery(
        'SELECT SUM(subtotal) as total FROM detalle_pedido WHERE idPedido = ?',
        [pedidoId],
      );
      final total = nuevoTotal.first['total'] as double? ?? 0.0;
      await db.update(
        'pedidos',
        {'total': total},
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
    }
  }

  // Cancelar pedido completo y restaurar stock
  Future<void> cancelarPedido(int pedidoId) async {
    final db = await database;

    final detalles = await db.query(
      'detalle_pedido',
      where: 'idPedido = ?',
      whereArgs: [pedidoId],
    );

    for (var detalle in detalles) {
      await db.execute(
        'UPDATE productos SET cantidad = cantidad + ${detalle['cantidad']} WHERE id = ${detalle['idProducto']}',
      );
    }

    await db.delete(
      'detalle_pedido',
      where: 'idPedido = ?',
      whereArgs: [pedidoId],
    );
    await db.delete('pedidos', where: 'id = ?', whereArgs: [pedidoId]);
  }
}
