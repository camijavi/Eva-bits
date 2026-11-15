# Especificación Funcional: Orquestación de la Asistente Agroecológica (Eve con `gpt-5-mini`)

## 1. Propósito y Filosofía de la Asistente
La asistente virtual **Eve** es el núcleo conversacional y de soporte a la decisión de **Eva-Bits** para el reto **NASA Space Apps Challenge 2026: "Field Shift: Adapting Farms with NASA Data"**. Su propósito es actuar como una **agrónoma y fitopatóloga de bolsillo, accesible y empática** para pequeños y medianos agricultores.

En lugar de abrumar al productor con gráficas abstractas o métricas crudas como *"Anomalía SMAP L4 de -0.18 m³/m³"*, **Eve** traduce las observaciones satelitales de la NASA, la topología espacial de la finca y el respaldo científico del equipo de biotecnología en **sugerencias accionables, alertas tempranas de fenómenos naturales, control preventivo de plagas, proyecciones cada 3 semanas y recomendaciones de sistemas de riego**.

---

## 2. Rol, Reglas de Citación de Fuentes y Límites del Modelo (`gpt-5-mini`)

Para evitar alucinaciones y garantizar rigor científico ante el jurado de la NASA:
1. **El LLM NO inventa números ni fuentes:** Todos los balances hídricos, suma térmica (GDD), índices de vigor (NDVI proxy), proyecciones de 21 días y matrices de riesgo fitosanitario son calculados determinísticamente por el motor de Eva-Bits antes de invocar a Eve.
2. **Protocolo Estricto de Citación de Fuentes (*Strict Source Grounding*):**
   Eve tiene la instrucción obligatoria de respaldar cada sugerencia o advertencia citando explícitamente la fuente técnica correspondiente del contexto brindado:
   * **Fuentes Satelitales y Climáticas (NASA):**
     * **NASA POWER (2009 / Live API):** Radiación solar (~240 W/m² absorbidos globalmente), temperatura a 2 metros (`T2M`) y humedad relativa (`RH2M`).
     * **NASA GPM (*Global Precipitation Measurement*, s.f.):** Monitoreo por radar y microondas de patrones de lluvia, tormentas en tiempo real y precipitaciones extremas de 3 días (+10% a +50% en frecuencia según *NASA Ciencia, 2022*).
     * **NASA SMAP & GRACE (s.f.):** Humedad superficial/radicular (`GWETROOT`) y reservas de acuíferos subterráneos para anticipar sequías severas con semanas o meses de antelación.
     * **NASA Ciencia (2022, 2024, 2026) & Gray (2021):** Alertas de **El Niño 2026**, **Eventos Climáticos Compuestos** (combinación simultánea de olas de calor y sequías que elevan el riesgo de pérdida de maíz del 29% al 57%) y proyección climática 2030 (reducción del -24% en rendimiento de maíz vs. +17% en trigo bajo altas emisiones).
     * **Misión NASA-ISRO (NISAR) & NASA Harvest:** Agricultura de precisión guiada por satélite que reemplaza calendarios fijos por mediciones en tiempo real de evapotranspiración y humedad del suelo.
   * **Fuentes de Suelos y Fitopatología (Documento Biotecnológico Eva-Bits):**
     * **Clasificación Edafológica:** *Alianza Bioversity and CIAT (2026)* para suelos **Arenosos**, **Limosos**, **Arcillosos** y **Francos**.
     * **Plagas y Enfermedades por Cultivo:**
       * **Maíz:** *Jorge 4K (s.f.)* y *Vilela (2026)* (Gusano cogollero *Spodoptera frugiperda*, Barrenador del tallo *Diatraea*, Gusano de la mazorca, Tizón foliar *Exserohilum turcicum*, Roya común *Puccinia sorghi*).
       * **Melón:** *Cañizo (s.f.)* y *Dubón (2006)* (Melera/Mangla *Aphis frangulae Koch / Aphis gossypii*, Lagarta/Vacanita, Arañuela/Socarrina en veranos secos, Mosca blanca *Bemisia*, Gusanos soldados *Spodoptera exigua, S. albula, S. frugiperda*).
       * **Piña:** *Monge (2018)* (Tecla y exudado de gomosis, Gusano soldado, Picudo en tallo/corona, Insectos blancos radiculares que causan "escoba de bruja", Pudrición acuosa fúngica).
       * **Sandía:** Pulga saltona, Gusano cogollero, Gusano trozador, Nematodos y Mosquita blanca.
       * **Manzana:** *Murray y Aiston (2012)* (Hongo Oídio en variedades Jonathan/Idared/Gala/Jonagold/Roma, Polilla de la manzana, Ácaro araña roja, Áfidos, Piojo de San José).
       * **Naranja / Cítricos:** *Delgado (2024)* (Piojo rojo de California / escama roja y Mosca de la fruta).
       * **Café:** *Porres y Cuxil (2024)* (Broca del café, Roya amarilla, Araña roja con hasta 30% de pérdida en períodos secos, Minador de la hoja).
       * **Frijol:** Mosca blanca (transmisora del virus del mosaico dorado), Pulgones (melaza y hongo fumagina) y Picudo del frijol.
       * **Caña de Azúcar:** *Campos Hernández & Lugo Alonso (2012)* (Picudo del tronco con 10% de pérdida y 40% de daño en retoños, hongo *Pokka boeng* o cogollo retorcido con hasta 50% de marchitamiento, Pulgón amarillo).
       * **Trigo:** Pulgones del trigo en llenado de grano, Coro de las pasturas en rastrojos y Chinches del trigo.
       * **Arroz:** *JICA (s.f.)* (Tizón de la hoja y Mancha circular color chocolate en alta humedad y sol).
       * **Banano y Plátano:** *Deiss (2025)* (Pulgón del banano transmisor del virus de la copa abultada, Gorgojo del plátano, Sigatoka negra).
       * **Mango:** *Sihdu (2022)* (Barrenadores del tallo, Gorgojo de la semilla, Chicharrita del mango).
       * **Soya:** *Agrotec (2025)* (Chinche marrón en vainas, Orugas defoliadoras y Termitas en suelos arenosos y secos).

---

## 3. Flujo de Datos y Contexto Estructurado (Payload de Eve)

Cuando el agricultor consulta a **Eve**, la aplicación inyecta un paquete estructurado con:
1. **Perfil y Topología Espacial de la Finca:** Lotes, sublotes, colindancias (corredores biológicos) y textura de suelo (*Alianza Bioversity and CIAT, 2026*).
2. **Telemetría Satelital NASA en Vivo / Caché:** Temperatura (`T2M`), precipitación (`PRECTOTCORR`), radiación (`ALLSKY_SFC_SW_DWN`) e índice de humedad radicular (`GWETROOT`).
3. **Advertencias de Fenómenos Naturales:** Evaluación automática de sequías, inundaciones/huracanes (El Niño 2026), deslizamientos en terrenos inclinados, eventos climáticos compuestos y anomalías térmicas.
4. **Diagnóstico Fitosanitario Activo:** Plagas y hongos de mayor riesgo para el cultivo seleccionado según el clima actual (ej. climas húmedos disparan *Exserohilum turcicum*, *Puccinia sorghi* o *Sigatoka negra*; veranos secos disparan *Araña roja* o *Termitas* en suelo arenoso).
5. **Proyección Tri-Semanal (21 Días) y Control de Cambios Semanal (+7 Días):**
   * Ventana proyectada desde `Fecha Inicio` hasta `Fecha Fin (+21 días)` dividida en 3 semanas operativas.
   * Comparativa de evolución tras 7 días (notificación de variación hídrica, térmica y de riesgo de plagas).
6. **Sistemas de Riego de Precisión:** Recomendación técnica del sistema de riego ideal según la textura del suelo y el déficit de evapotranspiración.

---

## 4. Reglas de Comportamiento y Estilo de Respuesta de Eve

1. **Prioridad a la Acción Inmediata y Advertencias Tempranas:**
   * La primera sección de Eve destaca siempre la alerta más urgente (fenómeno natural activo, urgencia de riego o riesgo inminente de plaga/hongo).
2. **Citación Transparente y Educativa:**
   * Cada bloque menciona de dónde proviene el dato (ej. *"Según las observaciones de NASA SMAP y GPM..."*, *"De acuerdo con el estudio de Vilela (2026) para el cultivo de maíz..."*, *"Considerando tu suelo arenoso (Alianza Bioversity and CIAT, 2026)..."*).
3. **Cero Emojis en Interfaz y Respuestas:**
   * Toda la interfaz utiliza iconografía vectorial de Flutter (`Icons`), manteniendo las respuestas limpias, legibles y compatibles con síntesis de voz (Text-to-Speech).
4. **Respaldo Determinista sin Conexión (Offline Grounded Mode):**
   * Si el agricultor se encuentra en el campo sin conexión a internet o sin credenciales activas de Azure AI Foundry, Eve genera instantáneamente un informe estructurado completo basado en el motor determinista local y la base de conocimientos biotecnológicos.
