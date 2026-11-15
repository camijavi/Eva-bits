# Especificación Funcional: Topología de Grafo para Lotes y Sublotes

## 1. Propósito y Fundamento Agroecológico
En una finca agrícola, las parcelas contiguas no funcionan como sistemas cerrados ni aislados. Los flujos de agua por gravedad, la dispersión de plagas y hongos por el viento, el polen y los microclimas generados por barreras vivas conectan biológicamente a los sublotes vecinos.

Esta funcionalidad modela la división interna de la finca como un **Grafo Espacial Atribuido**, donde los **sublotes son Nodos** y las relaciones físicas y ambientales entre ellos son **Aristas**. Esto permite aplicar algoritmos de diversificación espacial, control de plagas y manejo de escorrentía que superan la visión tradicional de parcelas independientes.

---

## 2. Definición del Grafo

### 2.1 Los Nodos (Sublotes)
Cada nodo $V_i$ representa una unidad mínima de manejo agronómico dentro de un lote y posee los siguientes atributos:
* **Identificador y Nombre:** (ej. *Sublote 1A - Ladera Alta*).
* **Superficie:** Tamaño en hectáreas, manzanas o metros cuadrados.
* **Cultivo Actual y Familia Botánica:** (ej. Maíz $\to$ *Poaceae*; Frijol $\to$ *Fabaceae*; Tomate $\to$ *Solanaceae*).
* **Cultivo del Ciclo Previo:** Historial agronómico inmediato.
* **Tipo y Textura de Suelo:** (Arcilloso, franco, arenoso).
* **Elevación Media / Cota Topográfica:** Altitud en metros sobre el nivel del mar para determinar pendientes relativas.
* **Estado Hídrico Satelital:** Valor localizado de humedad de raíz (`GWETROOT`).

### 2.2 Las Aristas (Relaciones de Vecindad)
Cada arista $E_{ij}$ conecta dos sublotes vecinos y define el tipo de interacción entre ellos:
1. **Adyacencia Física / Lindero Directo (`neighbor`):**
   * Indica que comparten un límite territorial sin barreras físicas intermedias.
2. **Dirección Hidrológica / Escorrentía (`downhill_flow` - Grafo Dirigido):**
   * Se establece con dirección $V_A \to V_B$ cuando la cota de $V_A$ es significativamente superior a la de $V_B$.
   * *Implicación funcional:* El agua de exceso, los lixiviados de fertilizantes y los sedimentos escurrirán de $V_A$ hacia $V_B$.
3. **Barrera Bioprotectora (`buffer_protected`):**
   * Indica que entre los dos sublotes existe una cerca viva, franja forestal o zanja de infiltración.
   * *Implicación funcional:* Reduce la velocidad del viento, mitiga la deriva de agroquímicos y bloquea el avance terrestre de insectos plaga.

---

## 3. Casos de Uso y Reglas de Negocio del Grafo

### Caso 1: Rotación Espacial Simultánea (Evitar Monocultivos Expansivos)
* **Regla:** Ningún par de nodos adyacentes conectados por una arista simple (`neighbor`) debe compartir cultivos de la misma familia botánica durante el mismo ciclo agrícola.
* **Beneficio:** Siembra en mosaico o policultivo espacial, lo que confunde a las plagas especialistas y reduce la presión de insectos sin necesidad de pesticidas.

### Caso 2: Contención y Simulación de Propagación de Plagas (Epidemiología)
* **Regla:** Si en el nodo $V_A$ se reporta una plaga o enfermedad (ej. Roya o Barrenador) y su arista con $V_B$ no tiene atributo `buffer_protected`, el sistema calcula un índice de vulnerabilidad elevado para $V_B$.
* **Acción:** Recomienda una franja trampa o aspersión preventiva biológica en el borde compartido antes de que la plaga colonice $V_B$.

### Caso 3: Manejo de Escorrentía y Protección de Cuencas Internas
* **Regla:** En una cadena de aristas dirigidas por pendiente ($V_{arriba} \to V_{medio} \to V_{abajo}$), los cultivos en los nodos superiores deben tener sistemas radiculares densos o coberturas permanentes para evitar la erosión del suelo y el lavado de nutrientes hacia los nodos inferiores.
* **Acción:** Si el nodo superior está en barbecho o suelo desnudo, se emite una alerta de erosión severa ante alertas de lluvia de la NASA (`PRECTOTCORR`).

---

## 4. Estructura de Datos y Persistencia

### Modelo Relacional en SQLite
Para garantizar funcionamiento sin conexión a internet en la app móvil, el grafo se persiste mediante dos tablas relacionales vinculadas:

```sql
-- Sublotes (Nodos)
CREATE TABLE IF NOT EXISTS subplots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lot_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  surface REAL NOT NULL,
  soil_type TEXT,
  crop TEXT,
  elevation REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (lot_id) REFERENCES lots (id) ON DELETE CASCADE
);

-- Relaciones de Vecindad (Aristas)
CREATE TABLE IF NOT EXISTS subplot_adjacencies (
  source_subplot_id INTEGER NOT NULL,
  target_subplot_id INTEGER NOT NULL,
  relationship_type TEXT NOT NULL DEFAULT 'neighbor', -- 'neighbor', 'downhill_flow', 'buffer_protected'
  PRIMARY KEY (source_subplot_id, target_subplot_id),
  FOREIGN KEY (source_subplot_id) REFERENCES subplots (id) ON DELETE CASCADE,
  FOREIGN KEY (target_subplot_id) REFERENCES subplots (id) ON DELETE CASCADE
);
```

### Serialización en Memoria (Dart)
En tiempo de ejecución, la topología se carga en una lista de adyacencia:
`Map<int, List<SubplotEdge>>`, permitiendo recorridos rápidos (BFS/DFS) para validar la idoneidad espacial de las rotaciones en menos de 5 milisegundos.
