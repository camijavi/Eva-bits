# Especificación Funcional: Motor de Predicciones Agroclimáticas

## 1. Propósito y Alcance
El **Motor de Predicciones Agroclimáticas** es el núcleo analítico de Eva-Bits para el reto *Field Shift: Adapting Farms with NASA Data*. Transforma series temporales satelitales, características edáficas y el historial de manejo de la finca en 6 predicciones concretas para la toma de decisiones agrícolas.

A diferencia de un modelo de lenguaje que genera texto abierto, este motor opera mediante reglas biofísicas, balances hídricos y modelos fenológicos deterministas, garantizando rigor agronómico.

---

## 2. Las 6 Predicciones Clave

### Predicción 1: Simulador de Rotación de Cultivos (Multianual)
* **Objetivo:** Determinar la secuencia óptima de cultivos para las siguientes 1 a 3 temporadas, maximizando la resiliencia climática y la fertilidad del suelo.
* **Entradas:**
  * Cultivo actual y anterior en el sublote.
  * Tendencias de precipitación y humedad radicular (`GWETROOT`).
  * Familia botánica y demanda nutricional de la especie candidata.
* **Lógica de Decisión:**
  * Si el cultivo previo fue una gramínea extractora (maíz, sorgo) y la humedad radicular proyectada es baja (< 0.40), el motor penaliza cultivos de alto requerimiento de agua y nitrógeno.
  * Prioriza leguminosas (frijol, gandul) o abonos verdes (crotalaria, canavalia) para fijar nitrógeno atmosférico y reducir la necesidad de fertilizantes químicos.
* **Salida al Usuario:** Secuencia recomendada ordenada por un índice de compatibilidad agroecológica (0 a 100%), detallando el beneficio en ahorro de agua y fertilizante.

---

### Predicción 2: Gestor de Riego y Déficit Hídrico (Corto Plazo: 7 Días)
* **Objetivo:** Predecir el momento exacto y volumen necesario de riego para prevenir estrés hídrico sin desperdiciar agua.
* **Entradas:**
  * Humedad radicular satelital (`GWETROOT` de SMAP).
  * Evapotranspiración real del cultivo ($ET_a$) y potencial ($ET_0$) calculada a partir de radiación solar (`ALLSKY_SFC_SW_DWN`), temperatura (`T2M`) y humedad relativa (`RH2M`).
  * Precipitación acumulada reciente y pronosticada (`PRECTOTCORR`).
* **Lógica de Decisión:**
  * Balance hídrico diario: $\Delta S = \text{Precipitación} - ET_a$.
  * Umbral de estrés: Si la humedad desciende por debajo del punto de marchitez temporal específico para la textura del suelo (arcilloso vs arenoso), se dispara una alerta de riego urgente.
* **Salida al Usuario:** Indicador de *"Días hasta estrés hídrico"* y recomendación de lámina de riego en milímetros ($mm$).

---

### Predicción 3: Calendario Agrícola y Ventanas Óptimas (Táctico)
* **Objetivo:** Determinar la fecha ideal de siembra y estimar los hitos fenológicos críticos (floración, madurez de cosecha).
* **Entradas:**
  * Acumulación térmica diaria: Días Grado de Crecimiento ($GDD = \frac{T_{max} + T_{min}}{2} - T_{base}$).
  * Probabilidad de heladas tempranas/tardías ($T_{min} \le 0^\circ\text{C}$ o umbrales de frío).
  * Humedad en capa arable superficial (`GWETTOP` de 0-5 cm).
* **Lógica de Decisión:**
  * Ventana de siembra: Requiere al menos 3 días consecutivos con `GWETTOP` $\ge 0.45$ y temperatura media adecuada para germinación sin riesgo de heladas en los siguientes 15 días.
  * Estimación de floración: Proyección de cuándo se alcanzará la suma térmica requerida por la variedad.
* **Salida al Usuario:** Fechas recomendadas de inicio de siembra y advertencia si la floración proyectada coincidirá con periodos estadísticos de canícula o golpes de calor.

---

### Predicción 4: Salud del Cultivo y Vigor Vegetativo (Monitoreo)
* **Objetivo:** Evaluar la biomasa verde acumulada y detectar anomalías de crecimiento en relación con el histórico de la zona.
* **Entradas:**
  * Índices de vegetación (NDVI, EVI) derivados de misiones ópticas (Landsat/MODIS vía AppEEARS/Earthdata).
  * Contenido de agua en el follaje (NDWI).
* **Lógica de Decisión:**
  * Comparación de la curva de desarrollo actual contra la curva media histórica de la parcela para la misma fecha del año (anomalía de NDVI).
* **Salida al Usuario:** Semáforo de salud del lote (Vigor Excelente, Normal, Deprimido) y porcentaje estimado de rendimiento relativo respecto al potencial máximo zonal.

---

### Predicción 5: Alerta Temprana de Sequía Relámpago y Encharcamiento (Riesgos Extremos)
* **Objetivo:** Advertir con 3 a 10 días de anticipación sobre eventos hidroclimáticos extremos que amenacen la supervivencia del cultivo.
* **Entradas:**
  * Tasa de pérdida de humedad en el suelo ($\frac{d}{dt} GWETROOT$).
  * Pico de precipitación torrencial (`PRECTOTCORR > 50 mm/día`) proveniente de GPM IMERG.
  * Demanda evaporativa atmosférica acelerada.
* **Lógica de Decisión:**
  * *Sequía relámpago (Flash Drought):* Disminución abrupta de humedad combinada con radiación extrema en menos de 10 días.
  * *Riesgo de asfixia radicular/encharcamiento:* Precipitación torrencial sobre suelo ya saturado ($GWETROOT > 0.85$).
* **Salida al Usuario:** Notificación de alta prioridad con sugerencias inmediatas de mitigación (ej. apertura de zanjas de drenaje o aplicación de acolchado/mulch protector).

---

### Predicción 6: Balance Nutricional y Regeneración de Suelo
* **Objetivo:** Cuantificar el impacto a largo plazo de las prácticas agrícolas sobre la fertilidad orgánica del suelo.
* **Entradas:**
  * Historial de rotaciones en el lote.
  * Capacidad de fijación biológica de nitrógeno del cultivo actual (ej. leguminosas: 40-120 kg N/ha).
  * Niveles de erosión hídrica estimados por pendiente y cobertura vegetal.
* **Lógica de Decisión:**
  * Modelo simplificado de balance de materia orgánica y balance de macronutrientes (Extracción por cosecha vs. Aporte por biomasa y fijación).
* **Salida al Usuario:** Puntuación de *"Salud y Vitalidad del Suelo"* (0-100 pts) y estimación del ahorro económico en fertilizantes químicos nitrogenados para el siguiente ciclo.
