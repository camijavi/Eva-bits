# Especificación Funcional: Integración de Datos Satelitales NASA

## 1. Propósito y Alcance
Esta funcionalidad permite la ingesta, normalización y visualización en tiempo real de observaciones agroclimáticas satelitales provenientes de las misiones de la NASA (NASA POWER y SMAP), sincronizadas con las coordenadas geográficas de la finca del usuario.

Su objetivo es eliminar la necesidad de sensores físicos costosos en el campo, dotando al pequeño y mediano agricultor de información ambiental de precisión científica directamente en su dispositivo móvil.

---

## 2. Fuentes de Datos y Variables Técnicas

La aplicación consulta el servicio de agroclimatología de la NASA a través de su API pública (`https://power.larc.nasa.gov/api/temporal/daily/point`), utilizando el parámetro comunitario `community=AG`.

### Parámetros Ingeridos:
1. **Temperatura del Aire a 2 Metros (`T2M`, `T2M_MAX`, `T2M_MIN`):**
   * *Unidad:* Grados Celsius (°C).
   * *Utilidad funcional:* Detección de umbrales térmicos para desarrollo fenológico y alertas de heladas o golpes de calor.
2. **Precipitación Corregida (`PRECTOTCORR`):**
   * *Unidad:* Milímetros por día ($mm/\text{día}$).
   * *Utilidad funcional:* Medición de lluvia acumulada y base para el cálculo de balances hídricos.
3. **Radiación Solar Global en Superficie (`ALLSKY_SFC_SW_DWN`):**
   * *Unidad:* Megajulios por metro cuadrado ($MJ/m^2/\text{día}$) o $kWh/m^2$.
   * *Utilidad funcional:* Estimación de fotosíntesis potencial y cálculo de evapotranspiración de referencia ($ET_0$).
4. **Humedad Relativa a 2 Metros (`RH2M`):**
   * *Unidad:* Porcentaje (%).
   * *Utilidad funcional:* Presión de vapor ambiental y evaluación de condiciones para desarrollo de hongos foliares.
5. **Humedad del Suelo en Zona Radicular (`GWETROOT` de SMAP L4):**
   * *Unidad:* Adimensional normalizada (0.0 a 1.0, donde 0.0 es sequía extrema y 1.0 es saturación).
   * *Utilidad funcional:* Diagnóstico del agua real disponible para las raíces del cultivo.

---

## 3. Comportamiento y Flujo de Ingesta

1. **Resolución de Coordenadas:**
   * La app toma la latitud y longitud registradas en el perfil de la finca (mediante GPS del dispositivo o selección de municipio con coordenadas de referencia preconfiguradas).
2. **Gestión de Ventana Temporal (Desfase Satelital):**
   * Los productos diarios de NASA POWER tienen un retraso de procesamiento y validación de aproximadamente 3 a 5 días respecto a la fecha actual.
   * La solicitud calcula automáticamente una ventana de 7 días consecutivos finalizando 5 días antes de la fecha actual ($T - 5$ días).
3. **Agregación y Síntesis:**
   * El servicio extrae las series temporales y genera promedios y acumulados representativos:
     * Temperatura media representativa (°C).
     * Lluvia total acumulada en los últimos 7 días ($mm$).
     * Radiación solar promedio incidente ($kWh/m^2$).
     * Índice promedio de humedad en raíces (%).

---

## 4. Estrategia de Resiliencia y Modo Offline

En entornos agrícolas rurales la conectividad celular es intermitente o nula. El sistema implementa:

1. **Caché Local Persistente:**
   * Las lecturas satelitales exitosas se almacenan en la base de datos local SQLite asociadas al ID de la finca con una vigencia de 24 horas.
2. **Fallback Agroecológico Basado en Climatología Histórica:**
   * Si la consulta a la API de la NASA falla por tiempo de espera (timeout > 10s) o falta de conexión a internet, el sistema no bloquea la interfaz: carga automáticamente un perfil climatológico histórico calibrado para la zona geográfica seleccionada (ej. Corredor Seco vs. Trópico Húmedo de Nicaragua).
   * La interfaz muestra un distintivo que indica si la información es *"En vivo (NASA Live)"* o *"Climatología histórica de referencia"*.

---

## 5. Salida en la Interfaz de Usuario (UI)

* **En Dashboard (`DashboardScreen`):**
  * Widget de microclima en la cabecera con temperatura actual y condición general.
* **En Detalle de Finca (`FarmInfoScreen` / `NewFarmInfoScreen`):**
  * Cuadrícula de 4 tarjetas de métricas ambientales: Temperatura, Radiación solar, Precipitación acumulada 7 días, y Humedad radicular SMAP con semáforo cromático (verde = óptimo, amarillo = alerta moderada, rojo = estrés hídrico).
