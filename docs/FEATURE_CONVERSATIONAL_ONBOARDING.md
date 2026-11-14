# Functional Specification: Conversational Onboarding & Quick Start Bypass

## 1. Overview and Purpose

The **Conversational Onboarding & Quick Start Bypass** subsystem captures and structures agricultural land data (farm identification, geographic location, total surface area, and hierarchical lots/subplots) with minimal user friction.

The system provides two entry channels:
1. **Conversational Extraction Channel:** Ingests unformatted voice audio or natural language text descriptions and uses an LLM entity extraction pipeline to parse and normalize the input into structured data.
2. **Quick Start Bypass Channel:** Bypasses sequential manual entry using either a one-click validated preset profile or an automatic single-lot consolidation.

---

## 2. System Architecture

```mermaid
flowchart TD
    subgraph InputChannels ["Input Channels"]
        A1["Voice Audio / Natural Text"] --> B1["Entity Extraction Engine<br>(Azure AI Foundry)"]
        A2["Manual Step Wizard"] --> B2["Step 1: General Info"]
        A3["Quick Start Bypass Buttons"] --> B3["Direct State Assignment"]
    end

    subgraph Processing ["Processing & Normalization"]
        B1 --> C1["JSON Schema Validation<br>& Unit Normalization"]
        B2 --> C2["Step 2: Lots & Subplots"]
    end

    subgraph State ["Application State"]
        C1 --> D["Farm State Repository<br>(FarmInfoScreen State)"]
        C2 --> D
        B3 --> D
    end

    subgraph Output ["Target Screen"]
        D --> E["Step 3: Summary Review & NASA Linking"]
    end
```

---

## 3. Natural Language Entity Extraction Pipeline

### 3.1 Input Ingestion
* **Input Types:** Transcribed voice audio streams or raw text strings.
* **Domain:** Smallholder agricultural descriptions, which frequently combine vernacular measurement units, regional colloquialisms, and implicit lot divisions.

### 3.2 Unit Normalization Rules
Regional and vernacular measurement units are normalized to standard application enumerations:

| Vernacular / Regional Input | Target `SurfaceUnit` Enum | Standardization Factor (to Hectares) |
| :--- | :--- | :--- |
| *Hectárea*, *ha*, *hectares* | `SurfaceUnit.hectares` | $1.0\text{ ha}$ |
| *Acre*, *ac*, *acres* | `SurfaceUnit.acres` | $0.4047\text{ ha}$ |
| *Manzana*, *mz* | `SurfaceUnit.hectares` | $0.704\text{ ha}$ (regional standard) |
| *Tarea*, *tareas* | `SurfaceUnit.tareas` | $0.0628\text{ ha}$ (regional standard) |
| *Metro cuadrado*, *m²* | `SurfaceUnit.squareMeters` | $0.0001\text{ ha}$ |

### 3.3 Geographic Zone Mapping
Mentions of municipal or departmental jurisdictions in Nicaragua (e.g., *Estelí*, *Matagalpa*, *Jinotega*, *León*, *Chinandega*, *Rivas*) are extracted and matched to geographic coordinate centroids used by NASA Earth Observation services (NASA POWER and SMAP).

### 3.4 Extraction Prompt Specification
```text
Task: Parse agricultural descriptions into a structured JSON representation of a farm.

Instructions:
1. Extract 'farm_name'. If not stated, infer a default based on the zone or crop.
2. Extract 'geographic_zone' and map to the nearest recognized administrative zone.
3. Extract 'total_surface' (numerical float) and 'surface_unit'.
4. Identify individual parcels or crops and populate the 'lots' array with 'name', 'surface', and 'current_crop'.
5. Ensure the sum of lot surfaces does not exceed total_surface.
6. Output valid JSON matching the specified schema.
```

---

## 4. JSON Schema Specification

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "FarmProfile",
  "type": "object",
  "required": ["farm_name", "geographic_zone", "total_surface", "surface_unit", "lots"],
  "properties": {
    "farm_name": {
      "type": "string",
      "description": "Identifier or registered name of the farm."
    },
    "geographic_zone": {
      "type": "string",
      "description": "Geographical region or municipality."
    },
    "total_surface": {
      "type": "number",
      "minimum": 0.01,
      "description": "Total surface area of the property."
    },
    "surface_unit": {
      "type": "string",
      "enum": ["hectares", "acres", "squareMeters", "tareas"]
    },
    "lots": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "surface"],
        "properties": {
          "name": { "type": "string" },
          "surface": { "type": "number", "minimum": 0.01 },
          "current_crop": { "type": "string" },
          "subplots": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["name", "surface"],
              "properties": {
                "name": { "type": "string" },
                "surface": { "type": "number", "minimum": 0.01 }
              }
            }
          }
        }
      }
    }
  }
}
```

### Sample Instance
```json
{
  "farm_name": "Finca Las Delicias",
  "geographic_zone": "Estelí",
  "total_surface": 2.5,
  "surface_unit": "hectares",
  "lots": [
    {
      "name": "Lote 1 - Maíz",
      "surface": 1.5,
      "current_crop": "Maíz",
      "subplots": []
    },
    {
      "name": "Lote 2 - Frijol Criollo",
      "surface": 1.0,
      "current_crop": "Frijol Criollo",
      "subplots": []
    }
  ]
}
```

---

## 5. Quick Start Bypass Implementation

To expedite testing and eliminate entry overhead, the system implements two direct bypass routines within the onboarding wizard:

### 5.1 Preset Demo Bypass (`_loadDemoFarm`)
* **Trigger:** Action button on Step 1: *"Cargar Demo y Probar"* (`kQuickStartBypass`).
* **Execution:**
  1. Clears existing controller allocations and memory buffers.
  2. Injects pre-validated test vectors into state:
     * `_farmNameController.text` = `"Finca Las Delicias (María)"`
     * `_geographicZoneController.text` = `"Estelí"`
     * `_totalSurfaceController.text` = `"2.5"`
     * `_selectedUnit` = `SurfaceUnit.hectares`
     * `_lots` = 2 pre-allocated `LotItem` objects (1.5 ha and 1.0 ha).
  3. Updates step index directly: `_currentStep = 2` (Step 3: Summary).
* **Latency:** Instantaneous ($< 5\text{ ms}$).

### 5.2 Single-Lot Bypass (`_bypassAsSingleLot`)
* **Trigger:** Button on Step 1: *"Omitir división (1 Lote)"* (`kQuickStartWholeFarm`).
* **Execution:**
  1. Validates general farm fields on Step 1 (`_step1FormKey.currentState.validate()`).
  2. Consolidates 100% of the declared farm surface into a single primary `LotItem` (`"<Farm Name> - Lote Principal"`).
  3. Sets `_lotsCountController.text` = `"1"`.
  4. Advances wizard state immediately: `_currentStep = 2` (Step 3: Summary).

---

## 6. Application State Mapping

| Target State Variable | Source Entity Key / Bypass Mapping | Type |
| :--- | :--- | :--- |
| `_farmNameController.text` | `farm_name` | `String` |
| `_geographicZoneController.text` | `geographic_zone` | `String` |
| `_totalSurfaceController.text` | `total_surface.toString()` | `String` |
| `_selectedUnit` | `surface_unit` (parsed enum) | `SurfaceUnit` |
| `_lots` | `lots[]` | `List<LotItem>` |
| `_currentStep` | `2` (when bypass is triggered) | `int` |
