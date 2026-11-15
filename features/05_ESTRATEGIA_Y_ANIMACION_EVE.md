# Estrategia de Impacto Agroclimático, Funcionalidad Científica y Sistema de Animación de Eve

## 1. Visión General de Eve en el Reto NASA Space Apps 2026
En el marco del desafío **"Field Shift: Adapting Farms with NASA Data"**, **Eve** trasciende el concepto de un asistente de texto tradicional para convertirse en una **compañera visual, pedagógica y científica** representada por la vaquita mascota de **Eva-Bits**.

Su función principal se divide en dos dimensiones complementarias:
1. **Cerebro Agronómico y Fitosanitario:** Sintetiza datos orbitales de la NASA, características edafológicas locales y estudios biotecnológicos de plagas para generar diagnósticos accionables, proyecciones cada tres semanas y alertas de cambios semanales.
2. **Guía Visual e Interactiva (Avatar Animado):** Acompaña a los agricultores (especialmente a nuevos usuarios o productores con baja alfabetización digital) mediante expresiones corporales (*emotes*) que comunican de un vistazo si el lote está sano, si existe una alerta climática o qué elemento de la pantalla deben inspeccionar.

---

## 2. Capacidades Científicas y Estratégicas para Maximizar el Puntaje del Jurado

### 2.1. Integración Explícita de Misiones y Recursos de la NASA
Cada recomendación emitida por la plataforma vincula una misión satelital específica con una decisión práctica en el campo:
* **NASA POWER (`T2M`, `ALLSKY_SFC_SW_DWN`, `RH2M`):** Cuantifica la radiación solar incidente (basada en el balance global de ~240 W/m² documentado por *NASA, 2009*), calcula la evapotranspiración de referencia ($ET_0$) y acumula los Grados-Día de Crecimiento (**GDD**) para predecir fechas exactas de floración y cosecha.
* **NASA SMAP L4 y Crop-CASMA (`GWETROOT`):** Evalúa la humedad en la zona radicular para determinar los días de reserva hídrica antes del punto de marchitez permanente según la textura del suelo.
* **NASA GPM (*Global Precipitation Measurement*):** Monitorea mediante radares y sensores de microondas el régimen de lluvias a través de las nubes, identificando eventos de precipitación extrema de 3 días (cuya frecuencia aumenta entre un 10% y un 50% según *NASA Ciencia, 2022*).
* **NASA GRACE y SMAP:** Vigilan conjuntamente la humedad superficial y el almacenamiento de aguas subterráneas para anticipar sequías severas con semanas o meses de antelación.
* **MODIS y NASA Harvest (`NDVI Proxy`):** Estiman el vigor fotosintético del dosel vegetal y proyectan el rendimiento esperado frente a anomalías térmicas.
* **Misión NASA-ISRO (NISAR):** Sustituye los calendarios de riego tradicionales fijos por láminas de riego calculadas en tiempo real según la pérdida real por evapotranspiración.

### 2.2. Matriz Tri-Capa: Clima Satelital + Textura de Suelo + Fitopatología
El valor diferencial de **Eve** radica en cruzar tres fuentes de datos independientes para anticipar crisis en la finca:
1. **Condición Meteorológica Satelital (NASA):** Humedad radicular, temperatura media y lluvia acumulada.
2. **Propiedades Físicas del Suelo (*Alianza Bioversity and CIAT, 2026*):**
   * *Suelo Arenoso:* Drenaje rápido que previene encharcamientos pero sufre alta lixiviación de nutrientes.
   * *Suelo Limoso:* Textura suave, alta fertilidad y buena retención, pero vulnerable a compactación superficial si queda descubierto en terrenos inclinados.
   * *Suelo Arcilloso:* Alta retención de agua y nutrientes, pero drenaje lento con riesgo de volverse pesado y pegajoso, dificultando el desarrollo radicular.
   * *Suelo Franco:* Equilibrio óptimo de arena, limo y arcilla con excelente aireación y retención.
3. **Vigilancia Fitosanitaria por Cultivo (Corpus Biotecnológico Eva-Bits):**
   * **Maíz (*Vilela, 2026; Jorge 4K, s.f.*):** Alerta sobre el gusano cogollero (*Spodoptera frugiperda*), el barrenador del tallo (*Diatraea*), el gusano de la mazorca y hongos disparados por alta humedad como el tizón foliar (*Exserohilum turcicum*) y la roya común (*Puccinia sorghi*).
   * **Café (*Porres y Cuxil, 2024*):** Advierte sobre la broca del café, la roya amarilla, el minador de la hoja y el ácaro araña roja en períodos secos (capaz de provocar hasta un 30% de pérdida de rendimiento).
   * **Frijol:** Vigila la mosca blanca (transmisora del virus del mosaico dorado del frijol), los pulgones (productores de melaza asociada al hongo fumagina) y el picudo del frijol en vainas.
   * **Melón (*Cañizo, s.f.; Dubón, 2006*):** Detecta condiciones favorables para la melera o mangla (*Aphis frangulae Koch / Aphis gossypii* de rápida reproducción sin fecundación), lagarta o vacanita, arañuela o socarrina en veranos secos, mosca blanca (*Bemisia*) y el complejo de gusanos soldados (*Spodoptera exigua, S. albula, S. frugiperda*).
   * **Piña (*Monge, 2018*):** Monitorea la larva de tecla (causante de galerías internas y exudado ámbar de "gomosis"), el gusano soldado, el picudo del tallo, los insectos blancos radiculares (causantes del efecto "escoba de bruja" en parches) y el hongo de pudrición acuosa.
   * **Sandía:** Alerta sobre la pulga saltona, gusano cogollero, gusano trozador, nematodos radiculares y ninfas de mosquita blanca.
   * **Manzana (*Murray y Aiston, 2012*):** Vigila el hongo oídio en variedades susceptibles (Jonathan, Idared, Gala, Jonagold, Roma) durante primaveras cálidas, la polilla de la manzana, el ácaro araña roja, los áfidos del floema y el piojo de San José.
   * **Naranja y Cítricos (*Delgado, 2024*):** Alerta sobre el piojo rojo de California (escama roja) y la mosca de la fruta.
   * **Caña de Azúcar (*Campos Hernández & Lugo Alonso, 2012*):** Evalúa el riesgo del picudo del tronco (hasta 10% de pérdida total y 40% de daño en retoños), la enfermedad fúngica *Pokka boeng* o cogollo retorcido (hasta 50% de marchitamiento) y el pulgón amarillo.
   * **Trigo:** Controla pulgones en el llenado de grano, el coro de las pasturas bajo rastrojos y los chinches del trigo (vaciamiento celular y espigas blancas).
   * **Arroz (*JICA, s.f.*):** Detecta condiciones cálidas y húmedas que disparan el tizón de la hoja y la mancha circular color chocolate.
   * **Banano y Plátano (*Deiss, 2025*):** Monitorea el pulgón del banano (vector del virus de la copa abultada), el gorgojo del plátano y la sigatoka negra propagada por lluvia y viento.
   * **Mango (*Sihdu, 2022*):** Vigila los barrenadores del tronco y ramas, el gorgojo de la semilla y la chicharrita del mango.
   * **Soya (*Agrotec, 2025*):** Alerta sobre el chinche marrón en vainas, las orugas defoliadoras y el ataque de termitas subterráneas en suelos arenosos y secos (frecuentemente confundido con deficiencia de nutrientes).

### 2.3. Fenómenos Naturales y Eventos Climáticos Compuestos
El sistema evalúa riesgos regionales en América Latina (donde el 19% de los 19.93 millones de km² corresponden a tierras agrícolas expuestas según *Efectos de los fenómenos climatológicos adversos en la producción y el comercio de los alimentos, 2000; NASA, 2021*):
* **El Niño 2026 y Alteración Pluviométrica (*NASA, 2026*):** Identificación temprana de sequías severas o lluvias torrenciales mediante radares GPM.
* **Eventos Climáticos Compuestos (*NASA Ciencia, 2022; NASA, 2024*):** Detección simultánea de olas de calor y sequías que refuerzan sus efectos destructivos y aumentan la probabilidad de pérdidas simultáneas de maíz del 29% al 57%.
* **Deslizamientos de Tierra y Erupciones Volcánicas (*NASA, 2013; NASA, s.f.*):** Alertas de saturación gravitacional en laderas inclinadas y protocolos de protección ante caída de ceniza volcánica y reducción de radiación solar.
* **Proyección de Rendimiento 2030 (*Gray, 2021*):** Comparativa de resiliencia climática que advierte la reducción proyectada del -24% en maíz frente al incremento del +17% en cultivos adaptados como el trigo.

### 2.4. Proyecciones Tri-Semanales (21 Días) y Notificación de Evolución Semanal (+7 Días)
* **Horizonte de 3 Semanas (`Fecha Inicio` a `Fecha Fin +21 días`):** Divide la planificación operativa en tres bloques semanales:
  * *Semana 1 (Días 1 a 7):* Corrección inmediata del déficit hídrico y control preventivo de plagas activas.
  * *Semana 2 (Días 8 a 14):* Seguimiento de suma térmica (GDD), vigilancia de lluvias GPM y punto de control semanal.
  * *Semana 3 (Días 15 a 21):* Regeneración edáfica, incorporación de abonos verdes o transición hacia cultivos fijadores de nitrógeno.
* **Alerta de Evolución tras 1 Semana (+7 Días):** Al cumplirse 7 días desde la lectura base, el sistema compara las métricas satelitales previas con las actuales y notifica al agricultor los cambios registrados en humedad radicular SMAP, acumulación térmica GDD y nivel de alerta fitosanitaria.

### 2.5. Guía Técnica de Sistemas de Riego de Precisión
Explica al agricultor qué tecnología de riego maximiza cada gota de agua según la textura de su parcela:
1. **Riego por Goteo de Alta Frecuencia (Por Pulsos):** Eficiencia del 92%-95%. Recomendado para **Suelo Arenoso y Franco**, aplicando láminas fraccionadas que impiden la lixiviación de nutrientes.
2. **Microaspersión de Baja Presión con Cobertura Vegetal (*Mulch*):** Eficiencia del 85%-88%. Recomendado para **Suelo Limoso y Laderas**, evitando el impacto directo de la gota y la compactación superficial.
3. **Goteo de Bajo Caudal Intermitente con Zanjas de Evacuación:** Eficiencia del 90%. Recomendado para **Suelo Arcilloso**, previniendo la saturación pegajosa y la asfixia radicular.
4. **Riego por Surcos Alternos Guiado por Satélite:** Eficiencia del 75%-80%. Alternativa accesible para **Suelo Franco** que reduce el consumo hídrico en un 35% al regar surcos intercalados según la evapotranspiración real.

---

## 3. Diseño e Interactividad de Eve (La Vaquita Animada)

### 3.1. Anatomía Visual del Personaje
A partir del diseño gráfico oficial del equipo, **Eve** está compuesta por formas vectoriales limpias y articulables:
* **Cabeza y Orejas:** Óvalo blanco superior con dos orejas elípticas superiores que pueden rotar independientemente para expresar atención, alegría o tristeza.
* **Rostro Expresivo:** Dos ojos circulares negros (capaces de parpadear, arquearse o dilatarse) y un hocico ovalado rosado (`#E89BB5`) con dos fosas nasales rectangulares negras.
* **Torso Característico:** Cuerpo circular blanco con la mancha orgánica negra distintiva en el costado izquierdo.
* **Extremidades Articuladas:** Dos brazos curvos blancos terminados en pezuñas esféricas negras (articulables desde el hombro para saludar, señalar o levantar/bajar el pulgar) y dos patas verticales rectas con pezuñas rectangulares negras.

### 3.2. Catálogo de los 8 Emotes de Eve
| Emote (`EveEmote`) | Estado / Disparador en la App | Animación Corporal y Expresión |
| :--- | :--- | :--- |
| **1. Saludo (`greeting`)** | Bienvenida en el Dashboard, apertura del chat de Eve y guía para nuevos usuarios. | El brazo derecho se eleva y oscila suavemente de lado a lado; las orejas se mueven con ritmo amigable y los ojos parpadean. |
| **2. Alerta `!` (`alert`)** | Riesgo alto de plaga, sequía relámpago (*Flash Drought*), inundación GPM o corredor biológico activo. | Aparece un indicador vectorial `!` pulsante sobre su cabeza; orejas totalmente erguidas, ojos abiertos en alerta y ligero temblor preventivo. |
| **3. Triste (`sad`)** | Humedad radicular crítica (< 35%), suelo degradado por monocultivo o balance negativo de nitrógeno. | Orejas caídas hacia los lados, párpados inclinados con expresión decaída, brazos hacia abajo y postura ligeramente encogida. |
| **4. Sorprendida (`surprised`)** | Notificación de cambio semanal (+7 días) o resultado impactante en el Simulador "Qué pasa si...". | Salto corto vertical, ojos redondos ampliados, orejas levantadas y ambos brazos abiertos hacia los costados. |
| **5. Feliz (`happy`)** | Humedad óptima, ventana de siembra abierta o índice de salud del suelo superior a 85/100. | Ojos arqueados en forma de sonrisa, rebote vertical alegre (*idle bounce*) y movimiento rítmico de ambos brazos. |
| **6. Pulgar Arriba (`thumbsUp`)** | Rotación de cultivos de Alta Compatibilidad (>= 80%) o ahorro positivo de urea comercial. | Brazo levantado mostrando un medallón vectorial de aprobación (*thumb up*), guiño/mirada positiva e inclinación afirmativa de la cabeza. |
| **7. Pulgar Abajo (`thumbsDown`)** | Rotación desaconsejada, siembra de la misma familia botánica en sublotes vecinos o riesgo de asfixia radicular. | Brazo extendido mostrando el indicador vectorial de desaprobación (*thumb down*) acompañado de un giro suave de cabeza de lado a lado. |
| **8. Señalando (`pointing`)** | Tutorial para nuevos agricultores (*onboarding*), señalando el selector de lotes, el botón de simulador o una alerta específica. | Brazo extendido apuntando en dirección al componente de la interfaz con un pulso direccional suave para guiar la atención del usuario. |

### 3.3. Opción Mostrar / Ocultar a Eve en Configuración (`Show Eve / Hide Eve`)
* En la pantalla de **Configuración (`SettingsScreen`)**, dentro de una sección dedicada a la **Asistente Virtual Eve**, el agricultor dispone de un interruptor (*Switch* / selector visual) con las opciones **Mostrar a Eve (`Show Eve`)** y **Ocultar a Eve (`Hide Eve`)**.
* Cuando está activo (**Mostrar a Eve**), la vaquita animada aparece en las tarjetas de diagnóstico, en el encabezado de predicciones, en la guía para nuevos usuarios y en el panel de conversación reaccionando en tiempo real con sus 8 emotes.
* Cuando está desactivado (**Ocultar a Eve**), los contenedores del personaje animado se ocultan limpiamente para ofrecer una vista compacta únicamente de datos, manteniendo intacta la precisión de los cálculos.

---

## 4. Plan de Implementación Paso a Paso

### Fase 1: Estado Global de Preferencia (`Show Eve / Hide Eve`) y Localización
1. **Archivo `lib/services/app_settings.dart`:**
   * Agregar `static final ValueNotifier<bool> showEve = ValueNotifier<bool>(true);` y el método `setShowEve(bool value)` para actualizar el estado en tiempo real en toda la aplicación.
2. **Archivos `lib/languages/spa.dart`, `lib/languages/eng.dart` y `lib/languages/app_strings.dart`:**
   * Incorporar las claves bilingües para la sección de configuración de Eve (`kEveVisibilitySectionTitle`, `kEveVisibilitySectionSubtitle`, `kShowEveOption`, `kHideEveOption`) y las etiquetas de los estados/mensajes de guía para nuevos usuarios, manteniendo la regla de cero textos hardcodeados y cero emojis.

### Fase 2: Motor de Animación Vectorial de Eve (`lib/widgets/eve_animated_avatar.dart`)
1. **Definición del Enum `EveEmote`:**
   * Declarar los 8 estados requeridos: `greeting`, `alert`, `sad`, `surprised`, `happy`, `thumbsUp`, `thumbsDown` y `pointing`.
2. **Construcción del `StatefulWidget` `EveAnimatedAvatar` con `SingleTickerProviderStateMixin`:**
   * Configurar un `AnimationController` continuo y fluido (60 FPS) que controle las transformaciones geométricas de las partes del cuerpo de la vaquita.
3. **Implementación de `_EveCowPainter extends CustomPainter`:**
   * Dibujar fielmente el diseño original de la vaquita (cuerpo redondo blanco con borde negro, mancha orgánica negra en el pecho izquierdo, patas rectas con pezuñas rectangulares, brazos curvos articulados con pezuñas circulares, cabeza ovalada, hocico rosado con fosas nasales cuadradas, ojos y orejas).
   * Aplicar matrices de rotación y traslación según el `EveEmote` activo (ej. oscilación del brazo en `greeting`, signo `!` vectorial en `alert`, orejas caídas en `sad`, ojos arqueados en `happy`, medallones vectoriales de pulgar arriba/abajo en `thumbsUp`/`thumbsDown` y brazo extendido en `pointing`).

### Fase 3: Interruptor `Mostrar a Eve / Ocultar a Eve` en `SettingsScreen`
1. **Archivo `lib/screens/settings_screen.dart`:**
   * Agregar la sección **"Asistente Virtual Eve"** con vista previa en vivo de la vaquita animada y el selector para alternar entre **Mostrar a Eve** y **Ocultar a Eve** (`AppSettings.showEve`).

### Fase 4: Integración Reactiva de Eve y sus Emotes en Predicciones y Dashboard
1. **Mapeo Automático de Predicción -> Emote (`lib/screens/predictions_screen.dart`):**
   * En la pestaña **Riego**: mostrar a Eve con emote `alert` o `sad` si el estado hídrico es crítico, `pointing` si es moderado, y `happy` si es óptimo.
   * En la pestaña **Rotación**: mostrar a Eve con emote `thumbsUp` cuando la compatibilidad sea alta (>= 80%) y `thumbsDown` o `alert` cuando exista riesgo de corredor biológico de plagas.
   * En la pestaña **Siembra (Proyección de 3 Semanas)**: mostrar a Eve con emote `pointing` o `happy` indicando la ventana de siembra.
   * En la pestaña **Alertas (Fenómenos Naturales y Plagas)**: mostrar a Eve con emote `alert` (`!`) junto a las advertencias de plagas y clima extremo.
   * En el modal de **Notificación Semanal (+7 Días)**: mostrar a Eve con emote `surprised` explicando los cambios ocurridos en la última semana.
   * En el **Chat de Eve**: mostrar a Eve con emote `greeting` al iniciar y selector interactivo de emotes/guía rápida.
2. **Respeto Estricto a `AppSettings.showEve`:**
   * Envolver las apariciones visuales de la vaquita en un `ValueListenableBuilder<bool>(valueListenable: AppSettings.showEve, ...)` para que desaparezcan instantáneamente si el usuario elige `Hide Eve` en Settings.

### Fase 5: Modo Guía para Nuevos Usuarios (Onboarding Contextual con Eve)
1. **Tarjeta / Banner de Ayuda Interactiva:**
   * Permitir que los nuevos agricultores toquen a Eve para recibir una explicación guiada (usando los emotes `greeting` y `pointing`) sobre cómo seleccionar un lote/sublote en el menú desplegable, cómo usar el simulador *"Qué pasa si..."* y cómo interpretar las alertas de la NASA.
