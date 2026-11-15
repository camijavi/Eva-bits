import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  static Database? _database;

  factory DatabaseManager() {
    return _instance;
  }

  DatabaseManager._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'eva_bits.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureSubplotColumns(db);
      },
    );
  }

  Future<void> _ensureSubplotColumns(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(subplots)');
      final hasSoilType = info.any((col) => col['name'] == 'soil_type');
      if (!hasSoilType) {
        await db.execute('ALTER TABLE subplots ADD COLUMN soil_type TEXT');
      }
    } catch (_) {}
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS subplots');
      await db.execute('DROP TABLE IF EXISTS lots');
      await db.execute('DROP TABLE IF EXISTS farms');
      await _createTables(db, newVersion);
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Farms Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        country TEXT NOT NULL,
        surface_unit TEXT NOT NULL,
        total_surface REAL NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Lots Table (children of farms)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farm_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        surface REAL NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (farm_id) REFERENCES farms (id) ON DELETE CASCADE
      )
    ''');

    // Subplots Table (children of lots)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subplots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lot_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        surface REAL NOT NULL,
        soil_type TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (lot_id) REFERENCES lots (id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // Farm Operations (Transaction-based insertion for farm, lots & subplots)
  // ---------------------------------------------------------------------------

  /// Inserts a farm along with its lots and nested subplots in a single transaction.
  Future<int> insertFarm({
    required Map<String, dynamic> farm,
    required List<Map<String, dynamic>> lots,
  }) async {
    final Database db = await database;

    return await db.transaction((txn) async {
      // 1. Insert farm
      final farmId = await txn.insert('farms', farm);

      // 2. Insert each lot and its subplots
      for (final lot in lots) {
        final subplots =
            (lot['subplots'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                [];

        final lotMap = Map<String, dynamic>.from(lot)..remove('subplots');
        lotMap['farm_id'] = farmId;

        final lotId = await txn.insert('lots', lotMap);

        // 3. Insert each subplot under this lot
        for (final subplot in subplots) {
          final subplotMap = Map<String, dynamic>.from(subplot);
          subplotMap['lot_id'] = lotId;
          await txn.insert('subplots', subplotMap);
        }
      }

      return farmId;
    });
  }

  /// Retrieves a farm by its ID, including its lots and nested subplots.
  Future<Map<String, dynamic>?> getFarmDetails(int farmId) async {
    final Database db = await database;

    final farmResults = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [farmId],
      limit: 1,
    );

    if (farmResults.isEmpty) return null;

    final farmData = Map<String, dynamic>.from(farmResults.first);

    // Get lots for this farm
    final lotsResults = await db.query(
      'lots',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'id ASC',
    );

    final List<Map<String, dynamic>> lotsWithSubplots = [];

    for (final lot in lotsResults) {
      final lotData = Map<String, dynamic>.from(lot);
      final subplotsResults = await db.query(
        'subplots',
        where: 'lot_id = ?',
        whereArgs: [lotData['id']],
        orderBy: 'id ASC',
      );
      lotData['subplots'] = subplotsResults;
      lotsWithSubplots.add(lotData);
    }

    farmData['lots'] = lotsWithSubplots;
    return farmData;
  }

  /// Retrieves the most recent farm saved with full details (lots & subplots).
  Future<Map<String, dynamic>?> getLatestFarm() async {
    final Database db = await database;

    final results = await db.query(
      'farms',
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return await getFarmDetails(results.first['id'] as int);
  }

  /// Retrieves all farms stored in the database.
  Future<List<Map<String, dynamic>>> getAllFarms() async {
    final Database db = await database;
    return await db.query('farms', orderBy: 'created_at DESC');
  }

  /// Updates farm general information.
  Future<int> updateFarm(Map<String, dynamic> farm) async {
    final Database db = await database;
    final farmMap = Map<String, dynamic>.from(farm);
    farmMap.remove('lots');
    farmMap['updated_at'] = DateTime.now().toIso8601String();

    return await db.update(
      'farms',
      farmMap,
      where: 'id = ?',
      whereArgs: [farm['id']],
    );
  }

  /// Deletes a farm and cascades deletion to all associated lots and subplots.
  Future<int> deleteFarm(int farmId) async {
    final Database db = await database;
    return await db.delete(
      'farms',
      where: 'id = ?',
      whereArgs: [farmId],
    );
  }

  /// Updates only the surface unit of the current farm.
  Future<void> updateFarmSurfaceUnit(String newUnit) async {
    final Database db = await database;
    final latestFarm = await getLatestFarm();
    if (latestFarm != null && latestFarm['id'] != null) {
      await db.update(
        'farms',
        {
          'surface_unit': newUnit,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [latestFarm['id']],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Lot Operations
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getLotsByFarm(int farmId) async {
    final Database db = await database;
    return await db.query(
      'lots',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, dynamic>?> getLotById(int lotId) async {
    final Database db = await database;
    final results = await db.query(
      'lots',
      where: 'id = ?',
      whereArgs: [lotId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> insertLot(Map<String, dynamic> lot) async {
    final Database db = await database;
    return await db.insert('lots', lot);
  }

  Future<int> updateLot(Map<String, dynamic> lot) async {
    final Database db = await database;
    final lotMap = Map<String, dynamic>.from(lot);
    lotMap.remove('subplots');
    return await db.update(
      'lots',
      lotMap,
      where: 'id = ?',
      whereArgs: [lot['id']],
    );
  }

  Future<int> deleteLot(int lotId) async {
    final Database db = await database;
    return await db.delete(
      'lots',
      where: 'id = ?',
      whereArgs: [lotId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllLotsWithSubplots({int? farmId}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> lotsResults;
    if (farmId != null) {
      lotsResults = await db.query(
        'lots',
        where: 'farm_id = ?',
        whereArgs: [farmId],
        orderBy: 'id ASC',
      );
    } else {
      lotsResults = await db.query('lots', orderBy: 'id ASC');
    }

    final List<Map<String, dynamic>> lotsWithSubplots = [];
    for (final lot in lotsResults) {
      final lotData = Map<String, dynamic>.from(lot);
      final subplotsResults = await db.query(
        'subplots',
        where: 'lot_id = ?',
        whereArgs: [lotData['id']],
        orderBy: 'id ASC',
      );
      lotData['subplots'] = subplotsResults;
      lotsWithSubplots.add(lotData);
    }
    return lotsWithSubplots;
  }

  Future<int> getOrCreateDefaultFarmId() async {
    final latestFarm = await getLatestFarm();
    if (latestFarm != null && latestFarm['id'] != null) {
      return latestFarm['id'] as int;
    }
    final Database db = await database;
    return await db.insert('farms', {
      'name': 'Mi Finca',
      'country': 'Nicaragua',
      'surface_unit': 'ha',
      'total_surface': 7.3,
    });
  }

  Future<void> seedInitialLotsIfEmpty(int farmId) async {
    final existingLots = await getLotsByFarm(farmId);
    if (existingLots.isNotEmpty) return;

    final Database db = await database;
    await db.transaction((txn) async {
      final lot1Id = await txn.insert('lots', {
        'farm_id': farmId,
        'name': 'Lote 1 - Norte (Maíz y Frijol)',
        'surface': 2.5,
      });
      await txn.insert('subplots', {
        'lot_id': lot1Id,
        'name': 'Subparcela A - Maíz blanco',
        'surface': 1.5,
        'soil_type': 'franco',
      });
      await txn.insert('subplots', {
        'lot_id': lot1Id,
        'name': 'Subparcela B - Frijol rojo',
        'surface': 1.0,
        'soil_type': 'arenoso',
      });

      final lot2Id = await txn.insert('lots', {
        'farm_id': farmId,
        'name': 'Lote 2 - Sur (Frijolar)',
        'surface': 1.8,
      });
      await txn.insert('subplots', {
        'lot_id': lot2Id,
        'name': 'Subparcela Principal',
        'surface': 1.8,
        'soil_type': 'arcilloso',
      });

      await txn.insert('lots', {
        'farm_id': farmId,
        'name': 'Lote 3 - Este (Rotación Crotalaria)',
        'surface': 3.0,
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Subplot Operations
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getSubplotsByLot(int lotId) async {
    final Database db = await database;
    return await db.query(
      'subplots',
      where: 'lot_id = ?',
      whereArgs: [lotId],
      orderBy: 'id ASC',
    );
  }

  Future<int> insertSubplot(Map<String, dynamic> subplot) async {
    final Database db = await database;
    return await db.insert('subplots', subplot);
  }

  Future<int> updateSubplot(Map<String, dynamic> subplot) async {
    final Database db = await database;
    final subplotMap = Map<String, dynamic>.from(subplot);
    return await db.update(
      'subplots',
      subplotMap,
      where: 'id = ?',
      whereArgs: [subplot['id']],
    );
  }

  Future<int> deleteSubplot(int subplotId) async {
    final Database db = await database;
    return await db.delete(
      'subplots',
      where: 'id = ?',
      whereArgs: [subplotId],
    );
  }

  // ---------------------------------------------------------------------------
  // Statistics and Summaries
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getFarmStats(int farmId) async {
    final Database db = await database;

    final lotStats = await db.rawQuery('''
      SELECT 
        COUNT(id) as total_lots,
        COALESCE(SUM(surface), 0.0) as total_lot_surface
      FROM lots
      WHERE farm_id = ?
    ''', [farmId]);

    final subplotStats = await db.rawQuery('''
      SELECT 
        COUNT(s.id) as total_subplots,
        COALESCE(SUM(s.surface), 0.0) as total_subplot_surface
      FROM subplots s
      JOIN lots l ON s.lot_id = l.id
      WHERE l.farm_id = ?
    ''', [farmId]);

    return {
      'total_lots': lotStats.first['total_lots'] ?? 0,
      'total_lot_surface': lotStats.first['total_lot_surface'] ?? 0.0,
      'total_subplots': subplotStats.first['total_subplots'] ?? 0,
      'total_subplot_surface': subplotStats.first['total_subplot_surface'] ?? 0.0,
    };
  }

  /// Closes database connection (useful for testing or cleanup).
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}

