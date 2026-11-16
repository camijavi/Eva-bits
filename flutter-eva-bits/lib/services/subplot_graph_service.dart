import '../database/database_manager.dart';

/// Supported relationship types between adjacent subplots (Graph Edges).
class SubplotRelationshipType {
  static const String neighbor = 'neighbor'; // Lindero directo contiguo
  static const String downhillFlow = 'downhill_flow'; // Escorrentía / Pendiente abajo
  static const String bufferProtected = 'buffer_protected'; // Cerca viva o barrera cortaviento

  static String getLabel(String type) {
    switch (type) {
      case downhillFlow:
        return 'Pendiente abajo (Recibe escorrentía)';
      case bufferProtected:
        return 'Barrera viva (Cerca / Franja protectora)';
      case neighbor:
      default:
        return 'Lindero directo (Parcela contigua)';
    }
  }
}

/// Represents a node (Vértice) in the agricultural field graph.
class SubplotNode {
  final int id;
  final int lotId;
  final String name;
  final double surface;
  final String? crop;
  final String? soilType;
  final String? lotName;

  const SubplotNode({
    required this.id,
    required this.lotId,
    required this.name,
    required this.surface,
    this.crop,
    this.soilType,
    this.lotName,
  });

  factory SubplotNode.fromMap(Map<String, dynamic> map) {
    return SubplotNode(
      id: map['id'] as int,
      lotId: map['lot_id'] as int? ?? 0,
      name: map['name']?.toString() ?? '',
      surface: (map['surface'] as num?)?.toDouble() ?? 0.0,
      crop: map['crop']?.toString(),
      soilType: map['soil_type']?.toString(),
      lotName: map['lot_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lot_id': lotId,
      'name': name,
      'surface': surface,
      'crop': crop,
      'soil_type': soilType,
      if (lotName != null) 'lot_name': lotName,
    };
  }
}

/// Represents an edge (Arista) connecting two adjacent subplots.
class SubplotEdge {
  final int sourceId;
  final int targetId;
  final String relationshipType;

  const SubplotEdge({
    required this.sourceId,
    required this.targetId,
    this.relationshipType = SubplotRelationshipType.neighbor,
  });

  factory SubplotEdge.fromMap(Map<String, dynamic> map) {
    return SubplotEdge(
      sourceId: map['source_subplot_id'] as int,
      targetId: map['target_subplot_id'] as int,
      relationshipType: map['relationship_type']?.toString() ??
          SubplotRelationshipType.neighbor,
    );
  }
}

/// In-memory Spatial Graph representation for subplots.
class SubplotGraph {
  final Map<int, SubplotNode> nodes;
  final Map<int, List<SubplotEdge>> adjacencyMap;

  SubplotGraph({
    required this.nodes,
    required this.adjacencyMap,
  });

  /// Returns all neighbors connected to [subplotId].
  List<SubplotNode> getNeighbors(int subplotId) {
    final edges = adjacencyMap[subplotId] ?? [];
    final List<SubplotNode> neighbors = [];
    for (final edge in edges) {
      final neighborNode = nodes[edge.targetId];
      if (neighborNode != null) {
        neighbors.add(neighborNode);
      }
    }
    return neighbors;
  }

  /// Checks if two subplots are directly adjacent.
  bool areAdjacent(int id1, int id2) {
    final edges = adjacencyMap[id1] ?? [];
    return edges.any((e) => e.targetId == id2);
  }

  /// Detects if planting [candidateCrop] in [subplotId] creates a contiguous monoculture corridor.
  bool hasMonocultureRisk(int subplotId, String candidateCrop) {
    if (candidateCrop.trim().isEmpty) return false;
    final neighbors = getNeighbors(subplotId);
    return neighbors.any((neighbor) {
      final neighborCrop = neighbor.crop?.toLowerCase().trim();
      return neighborCrop != null &&
          neighborCrop.isNotEmpty &&
          neighborCrop == candidateCrop.toLowerCase().trim();
    });
  }

  /// Evaluates risk of pest/disease dispersion from [infectedSubplotId] to adjacent plots.
  List<SubplotNode> getVulnerableNeighbors(int infectedSubplotId) {
    final edges = adjacencyMap[infectedSubplotId] ?? [];
    final List<SubplotNode> vulnerable = [];

    for (final edge in edges) {
      // Buffer protected edges reduce or block pest dispersion
      if (edge.relationshipType != SubplotRelationshipType.bufferProtected) {
        final node = nodes[edge.targetId];
        if (node != null) {
          vulnerable.add(node);
        }
      }
    }
    return vulnerable;
  }

  /// Generates a readable topological summary designed for LLM (Ivy / gpt-5-mini) grounding.
  List<Map<String, dynamic>> toIvyTopologyContext() {
    final List<Map<String, dynamic>> topology = [];

    for (final entry in nodes.entries) {
      final node = entry.value;
      final edges = adjacencyMap[node.id] ?? [];
      final neighborSummaries = edges.map((e) {
        final target = nodes[e.targetId];
        return {
          'neighbor_id': e.targetId,
          'neighbor_name': target?.name ?? 'Sublote #${e.targetId}',
          'neighbor_crop': target?.crop ?? 'Sin cultivo',
          'relationship': SubplotRelationshipType.getLabel(e.relationshipType),
        };
      }).toList();

      topology.add({
        'subplot_id': node.id,
        'name': node.name,
        'current_crop': node.crop ?? 'Sin cultivo asignado',
        'surface_ha': node.surface,
        'neighbors_count': neighborSummaries.length,
        'adjacent_plots': neighborSummaries,
      });
    }

    return topology;
  }
}

/// Service to construct and query Subplot Graphs from Database.
class SubplotGraphService {
  static final DatabaseManager _dbManager = DatabaseManager();

  /// Builds a full [SubplotGraph] for all subplots within [farmId].
  static Future<SubplotGraph> getGraphForFarm(int farmId) async {
    final db = await _dbManager.database;

    // 1. Fetch all subplots for this farm
    final subplotsRows = await db.rawQuery('''
      SELECT s.id, s.lot_id, s.name, s.surface, s.soil_type, s.crop, l.name as lot_name
      FROM subplots s
      JOIN lots l ON s.lot_id = l.id
      WHERE l.farm_id = ?
      ORDER BY s.id ASC
    ''', [farmId]);

    final Map<int, SubplotNode> nodes = {};
    for (final row in subplotsRows) {
      final node = SubplotNode.fromMap(row);
      nodes[node.id] = node;
    }

    // 2. Fetch all adjacencies for these subplots
    final edgesRows = await db.rawQuery('''
      SELECT a.source_subplot_id, a.target_subplot_id, a.relationship_type
      FROM subplot_adjacencies a
      JOIN subplots s ON a.source_subplot_id = s.id
      JOIN lots l ON s.lot_id = l.id
      WHERE l.farm_id = ?
    ''', [farmId]);

    final Map<int, List<SubplotEdge>> adjacencyMap = {};
    for (final row in edgesRows) {
      final edge = SubplotEdge.fromMap(row);
      adjacencyMap.putIfAbsent(edge.sourceId, () => []).add(edge);
    }

    return SubplotGraph(nodes: nodes, adjacencyMap: adjacencyMap);
  }

  /// Builds a [SubplotGraph] restricted to a specific [lotId].
  static Future<SubplotGraph> getGraphForLot(int lotId) async {
    final db = await _dbManager.database;

    final subplotsRows = await db.query(
      'subplots',
      where: 'lot_id = ?',
      whereArgs: [lotId],
      orderBy: 'id ASC',
    );

    final Map<int, SubplotNode> nodes = {};
    for (final row in subplotsRows) {
      final node = SubplotNode.fromMap(row);
      nodes[node.id] = node;
    }

    final edgesRows = await db.rawQuery('''
      SELECT a.source_subplot_id, a.target_subplot_id, a.relationship_type
      FROM subplot_adjacencies a
      JOIN subplots s ON a.source_subplot_id = s.id
      WHERE s.lot_id = ?
    ''', [lotId]);

    final Map<int, List<SubplotEdge>> adjacencyMap = {};
    for (final row in edgesRows) {
      final edge = SubplotEdge.fromMap(row);
      adjacencyMap.putIfAbsent(edge.sourceId, () => []).add(edge);
    }

    return SubplotGraph(nodes: nodes, adjacencyMap: adjacencyMap);
  }
}
