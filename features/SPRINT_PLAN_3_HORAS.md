# Plan de Sprint Rápido: 3 Horas para Eva-Bits
**Objetivo:** Pasar de una interfaz con datos de prueba a una aplicación conectada en vivo a las APIs de la NASA, con topología de grafo para sublotes y recomendaciones dinámicas asistidas por `gpt-5-mini`.

---

## Cronograma del Sprint (180 Minutos)

| Bloque | Tiempo | Tarea | Entregable Clave |
| :--- | :--- | :--- | :--- |
| **01** | 00 - 35 min | **Conexión en Vivo de NASA POWER API** | Métricas reales (temperatura, lluvia, humedad SMAP) en UI. |
| **02** | 35 - 75 min | **Topología de Grafo en Base de Datos y UI** | Tabla de adyacencias y selector de sublotes vecinos. |
| **03** | 75 - 115 min | **Motor de las 6 Predicciones Agroclimáticas** | Servicio Dart calculando rotación, riego y alertas. |
| **04** | 115 - 155 min | **Orquestación de Ivy con `gpt-5-mini`** | Asistente inteligente razonando con datos satelitales + grafo. |
| **05** | 155 - 180 min | **Prueba Integral y Flujo de Demostración** | Demo fluida lista para evaluación y video del hackathon. |

---

## Detalle de Tareas

### TAREA 1: Vincular Datos Satelitales en Vivo en la Interfaz (00:00 - 00:35)
* **Objetivo:** Eliminar los datos fijos (`28 °C`, `14 mm`, `33%`) y mostrar observaciones satelitales reales de la NASA para la ubicación de la finca.
* **Acciones:**
  1. En `lib/screens/farm_info.dart`, invocar `NasaPowerService.fetchClimateData()` pasando `farm['latitude']` y `farm['longitude']`.
  2. Implementar un estado de carga mientras la API responde.
  3. Vincular los 4 cuadros de métricas a los valores devueltos en `summary`:
     * Temperatura real (`avg_temp_c`).
     * Radiación solar real (`avg_solar_kwh`).
     * Precipitación acumulada 7 días (`avg_rain_mm`).
     * Humedad del suelo en raíces (`soil_moisture_index`).
* **Criterio de Aceptación:** Al abrir la finca, se observa una insignia verde *"NASA POWER & SMAP Live"* con los valores reales del satélite.

---

### TAREA 2: Implementar el Grafo de Sublotes Vecinos (00:35 - 01:15)
* **Objetivo:** Permitir que los sublotes se conecten espacialmente para identificar vecinos y dirección de pendiente.
* **Acciones:**
  1. En `lib/database/database_manager.dart`, crear la tabla `subplot_adjacencies` para guardar `(source_subplot_id, target_subplot_id, relationship_type)`.
  2. Agregar métodos `addSubplotNeighbor(int sub1, int sub2, String type)` y `getSubplotAdjacencies(int farmId)`.
  3. En `lib/widgets/new_edit_subplot.dart`, agregar un campo desplegable simple: *"Sublote vecino colindante"*.
* **Criterio de Aceptación:** Guardar dos sublotes y poder consultar qué sublote es vecino de cuál desde la base de datos local.

---

### TAREA 3: Crear el Motor de Reglas de las 6 Predicciones (01:15 - 01:55)
* **Objetivo:** Construir la lógica de cálculo agronómico que produce las 6 predicciones sin depender de alucinaciones del LLM.
* **Acciones:**
  1. Crear `lib/services/agro_prediction_engine.dart`.
  2. Implementar funciones deterministas:
     * `predictRotation(currentCrop, previousCrop, soilMoisture, neighbors)` $\to$ Lista ponderada de cultivos.
     * `predictIrrigationNeed(gwetroot, rainRecentMm)` $\to$ Semáforo de riego (Crítico, Moderado, Óptimo).
     * `predictPlantingWindow(tempMin, soilMoistureTop)` $\to$ Fechas recomendadas.
     * `predictCropVigor(ndviEstimated)` $\to$ Salud del cultivo.
     * `detectExtremeRisks(gwetrootTrend, rainMm)` $\to$ Alerta de sequía relámpago o encharcamiento.
     * `predictSoilRegeneration(rotationPlan)` $\to$ Balance estimado de Nitrógeno ($kg/ha$).
* **Criterio de Aceptación:** Una función central `generateFarmPredictions()` que devuelve un mapa con las 6 predicciones listas para la UI y para el LLM.

---

### TAREA 4: Orquestar Ivy con `gpt-5-mini` y Grounding Enriquecido (01:55 - 02:35)
* **Objetivo:** Configurar el asistente conversacional para que brinde consejos contextualizados usando las predicciones y el grafo.
* **Acciones:**
  1. En `lib/services/azure_ai_service.dart`, actualizar `modelDeployment = "gpt-5-mini"`.
  2. Enriquecer `_buildSystemPrompt()` para que reciba:
     * El perfil de la finca.
     * Las métricas en vivo de NASA POWER / SMAP.
     * Los resultados del motor de predicciones.
     * La lista de adyacencias del grafo de sublotes.
  3. Agregar un botón de acceso rápido *"Consultar a Ivy"* en el detalle de la finca o dashboard que abra un diálogo o pantalla de chat con la recomendación explicada.
* **Criterio de Aceptación:** Ivy responde explicando por qué rotar determinado cultivo citando los datos de la NASA y la ubicación del sublote vecino.

---

### TAREA 5: Verificación Integral y Demo Hackathon (02:35 - 03:00)
* **Objetivo:** Probar el circuito completo y asegurar estabilidad para la presentación.
* **Acciones:**
  1. Crear una finca demo (ej. en Estelí, Nicaragua) con 2 sublotes: uno con Maíz y otro con Frijol colindantes.
  2. Validar que al abrir la app se obtengan los datos satelitales en vivo.
  3. Comprobar que al activar el modo avión, la app use los datos cacheados sin cerrarse abruptamente.
  4. Realizar una consulta de prueba a Ivy para verificar la fluidez de respuesta de `gpt-5-mini`.
* **Criterio de Aceptación:** Flujo continuo desde la finca hasta la recomendación con datos satelitales demostrables frente al jurado.
