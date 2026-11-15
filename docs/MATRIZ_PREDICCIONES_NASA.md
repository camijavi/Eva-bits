# Matriz de Predicciones Agrícolas con Datos NASA
**Proyecto:** Eva-Bits (NASA Space Apps Challenge — *Field Shift: Adapting Farms with NASA Data*)

Este documento detalla la matriz de predicciones agroclimáticas, los conjuntos de datos satelitales de la NASA correspondientes, sus variables técnicas y el resultado procesado para el agricultor.

---

## 1. Matriz Integral de Predicciones

| Módulo de la App | Tipo de Predicción | Dataset NASA / Satelital | Parámetros Técnicos Clave | Frecuencia / Horizonte | Salida / Acción para el Agricultor |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Simulador de Rotación** *(Estratégico)* | **Idoneidad y Compatibilidad de Cultivos** | **NASA POWER** (Climatología) + **SMAP L4** | `T2M` (Temp a 2m), `PRECTOTCORR` (Lluvia corregida), `GWETROOT` (Humedad radicular) | Estacional / 1 a 3 años | Ranking de cultivos sugeridos (p. ej. *Maíz $\to$ Frijol/Leguminosa $\to$ Abono Verde*) para regenerar nitrógeno y resistir el clima proyectado. |
| **Salud del Suelo** *(Estratégico)* | **Recuperación / Pérdida de Materia Orgánica y Nitrógeno** | **SMAP** + **SoilGrids (ISRIC)** | `GWETROOT`, `GWETTOP`, Textura edáfica, Carbono Orgánico del Suelo (SOC) | Ciclo de rotación (6-24 meses) | Puntuación de salud del suelo (0-100) y alerta: *"Sembrar monocultivo este ciclo agotará un 18% más el nitrógeno disponible"*. |
| **Gestor de Riego** *(Operativo)* | **Déficit Hídrico y Estrés del Cultivo** | **ECOSTRESS** (ISS) + **OpenET** | `ETa` (Evapotranspiración real), `ESI` (Evaporative Stress Index), `LST` (Temp Superficie) | Diario a 7 días | Alerta temprana de estrés hídrico previo a marchitamiento visible. Recomendación: *"Regar 15 mm en las próximas 48 h"*. |
| **Balance Hídrico** *(Táctico)* | **Balance Precipitación vs. Demanda Hídrica** | **GPM IMERG** + **NASA POWER** | `PRECTOTCORR`, `ALLSKY_SFC_SW_DWN` (Radiación solar), `RH2M` (Humedad relativa) | Semanal / 14 días | Semáforo hídrico (Superávit / Óptimo / Déficit crítico) con estimación de necesidad de riego suplementario. |
| **Calendario Agrícola** *(Táctico)* | **Ventana Óptima de Siembra** | **NASA POWER** + **SMAP L4** | `T2M_MIN` (Riesgo de helada), `GWETTOP` (Humedad primeros 5 cm), `T2M` | Ventana de 15 días | *"Condiciones óptimas de siembra del 18 al 25 de mayo (humedad adecuada de germinación y bajo riesgo de frío)"*. |
| **Fenología y Cosecha** *(Táctico)* | **Predicción de Etapas (Floración, Madurez, Cosecha)** | **NASA POWER** | `GDD` (Growing Degree Days acumulados a partir de `T2M_MAX` y `T2M_MIN`) | Seguimiento continuo del ciclo | *"La floración ocurrirá en 12 días; riesgo moderado de ola de calor durante polinización"*. |
| **Vigor y Rendimiento** *(Monitoreo)* | **Monitoreo de Biomasa y Rendimiento Relativo** | **Landsat 8/9 / Sentinel-2 / MODIS** (vía AppEEARS) | `NDVI` (Índice de Vegetación), `EVI` (Vigor mejorado), `NDWI` (Contenido de agua foliar) | Cada 8 a 16 días | Comparativa visual de vigor respecto al promedio histórico: *"Rendimiento proyectado: 88-94% del potencial de zona"*. |
| **Alertas Tempranas** *(Resiliencia)* | **Riesgo de Sequía Relámpago (Flash Drought) y Heladas** | **SMAP** + **ECOSTRESS** + **NASA POWER** | Caída abrupta de `GWETROOT` + Aumento de `ESI` + Umbrales de `T2M_MIN < 2°C` | 3 a 10 días | Alertas push prioritarias para activar medidas de mitigación (acolchado/mulch, riego defensivo, cobertura vegetal). |

---

## 2. Parámetros de la API NASA POWER para Eva-Bits

Para consultas directas al endpoint `/api/temporal/daily/point`:

* `T2M`: Temperatura media a 2 metros (°C).
* `T2M_MAX` / `T2M_MIN`: Temperaturas extremas diarias (°C).
* `PRECTOTCORR`: Precipitación diaria corregida ($mm/\text{día}$).
* `ALLSKY_SFC_SW_DWN`: Radiación solar global incidente en superficie ($MJ/m^2/\text{día}$).
* `RH2M`: Humedad relativa a 2 metros (%).
* `GWETROOT`: Disponibilidad de humedad en la zona radicular (0.0 = seco absoluto, 1.0 = saturación total).
* `GWETTOP`: Humedad en la capa superficial del suelo (0-5 cm).

---

## 3. Criterios de Adaptación Climática para Eva-Bits
1. **Prioridad Agroecológica:** Fomentar policultivos y rotaciones leguminosa-cereal para reducir fertilización química nitrogenada.
2. **Eficiencia Hídrica:** Seleccionar variedades tolerantes a sequía en lotes con tendencias decrecientes en `GWETROOT` o alta anomalía térmica en `ECOSTRESS`.
3. **Resiliencia de Suelos:** Alternar cultivos de raíces profundas y superficiales para romper capas compactadas y maximizar infiltración pluvial.
