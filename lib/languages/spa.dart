// Spanish text constants
const String kOk = 'OK';
const String kCancel = 'Cancelar';
const String kSave = 'Guardar';
const String kClose = 'Cerrar';

// Titles & Hierarchy
const String kFarmInfoTitle = 'Información de la Finca';
const String kFarmer = 'Agricultor';
const String kFarm = 'Finca';
const String kGeneralInfoSection = 'Información General de la Finca';
const String kLotsSectionTitle = 'Lotes';
const String kSubplotsSectionTitle = 'Subparcelas (opcional)';
const String kSummaryTitle = 'Resumen de la Finca';

// Farm Fields
const String kFarmNameLabel = 'Nombre de la finca';
const String kFarmNameHint = 'Ingrese el nombre de la finca';
const String kCountryLabel = 'País';
const String kCountryHint = 'Ingrese el país';
const String kTotalSurfaceLabel = 'Superficie total';
const String kTotalSurfaceHint = 'Ingrese la superficie total';
const String kGeographicZoneLabel = 'Zona geográfica';
const String kGeographicZoneHint = 'Ingrese la zona geográfica';

// GPS & Location
const String kFarmLocationLabel = 'Ubicación de la finca';
const String kWhereIsYourFarm = '¿Dónde está tu finca?';
const String kGetGpsLocationButton = 'Detectar Ubicación GPS Actual';
const String kGettingGpsLocation = 'Obteniendo señal GPS...';
const String kLatitudeLabel = 'Latitud';
const String kLatitudeHint = 'ej. 13.0910';
const String kLongitudeLabel = 'Longitud';
const String kLongitudeHint = 'ej. -86.3538';
const String kGpsSuccess = 'Coordenadas GPS capturadas con éxito';
const String kGpsServiceDisabled =
    'Los servicios de ubicación están desactivados. Por favor active el GPS.';
const String kGpsPermissionDenied = 'El permiso de ubicación fue denegado.';
const String kGpsPermissionDeniedPermanently =
    'Los permisos de ubicación están permanentemente denegados. Por favor actívelos en ajustes.';
const String kGpsError = 'No se pudieron obtener las coordenadas GPS.';
const String kLocationNotCapturedYet =
    'Ubicación GPS no registrada aún. Presione para detectar.';
const String kRefreshLocation = 'Actualizar GPS';
const String kLocationRequired =
    'Por favor detecte la ubicación GPS de la finca antes de continuar.';
const String kGpsCoordinates = 'Coordenadas';

// Surface Units
const String kSurfaceUnitLabel = 'Unidad de medida de superficie';
const String kSurfaceUnitHint = 'Seleccione la unidad de medida';
const String kUnitHectares = 'Hectáreas (ha)';
const String kUnitAcres = 'Acres (ac)';
const String kUnitSquareMeters = 'Metros cuadrados (m²)';
const String kUnitTareas = 'Tareas';

const String kUnitHectaresShort = 'ha';
const String kUnitAcresShort = 'ac';
const String kUnitSquareMetersShort = 'm²';
const String kUnitTareasShort = 'tareas';

// Lots
const String kLotsCountLabel = '¿Cuántos lotes hay?';
const String kLotsCountHint = 'Número de lotes';
const String kLot = 'Lote';
const String kLotNameLabel = 'Nombre del lote';
const String kLotNameHint = 'Ingrese el nombre del lote';
const String kLotSurfaceLabel = 'Superficie del lote';
const String kLotSurfaceHint = 'Ingrese la superficie del lote';
const String kAddLot = 'Agregar lote';
const String kRemoveLot = 'Eliminar lote';

// Subplots
const String kSubplotsCountLabel =
    '¿Cuántas subparcelas hay en este lote? (0 o más)';
const String kSubplotsCountHint = 'Ingrese número de subparcelas';
const String kSubplot = 'Subparcela';
const String kSubplotNameLabel = 'Nombre de la subparcela';
const String kSubplotNameHint = 'Ingrese el nombre de la subparcela';
const String kSubplotSurfaceLabel = 'Superficie de la subparcela';
const String kSubplotSurfaceHint = 'Ingrese la superficie de la subparcela';
const String kAddSubplot = 'Agregar subparcela';
const String kRemoveSubplot = 'Eliminar subparcela';
const String kNoSubplots = 'Sin subparcelas en este lote';

// Validation & Alerts
const String kFieldRequired = 'Este campo es obligatorio';
const String kInvalidNumber = 'Por favor ingrese un número positivo válido';
const String kLotsCountPositive = 'Por favor ingrese 0 o más lotes';
const String kSubplotsCountPositive = 'Por favor ingrese 0 o más subparcelas';
const String kLotsSurfaceExceededWarning =
    '¡Advertencia: La superficie de los lotes supera la de la finca!';
const String kSubplotsSurfaceExceededWarning =
    '¡Advertencia: La superficie de las subparcelas supera la del lote!';
const String kFormSavedSuccessfully =
    '¡Información de la finca guardada con éxito!';
const String kConfirmSave = 'Confirmar y Guardar';
const String kErrorSavingData =
    'Error al guardar los datos de la finca. Por favor intente nuevamente.';

// Wizard & Quick Start
const String kStep1Title = 'Finca';
const String kStep2Title = 'Lotes';
const String kStep3Title = 'Resumen';
const String kQuickStartWholeFarm = 'Omitir división (Usar toda la finca como 1 lote)';
const String kNextStep = 'Siguiente';
const String kPreviousStep = 'Atrás';
const String kSingleLotMode = 'Lote Único (Toda la finca)';
const String kMainLot = 'Lote Principal';
const String kCustomLotsMode = 'Múltiples Lotes / Subparcelas';
const String kAllocatedSurface = 'Superficie Asignada';
const String kAskIvyTitle = 'Consultar a Ivy (Predicción)';
const String kNasaDataReady = 'Datos NASA & Clima';
const String kNoLotsAddedYet = 'Aún no has agregado lotes.';
const String kLotsDistribution = 'Distribución de Lotes';
const String kNasaDataDescription =
    'Datos satelitales NASA POWER y SMAP (radiación, lluvia y humedad) sincronizados con tus coordenadas.';

// Dashboard Mockup
const String kDashboardGreeting = '¡Hola, María!';
const String kDashboardSubtitle =
    'Aquí tienes un resumen de tu finca y las recomendaciones para hoy.';
const String kDashboardWeatherSummary = 'Mayormente soleado';
const String kDashboardYourFarm = 'Tu finca';
const String kDashboardFarmSize = 'Tamaño';
const String kDashboardCurrentCrops = 'Cultivos actuales: Maíz, Frijol';
const String kDashboardViewDetails = 'Ver detalles';
const String kDashboardWhatToDo = '¿Qué quieres hacer hoy?';
const String kDashboardAction1 = 'Comparar rotaciones de cultivos';
const String kDashboardAction2 =
    'Explorar datos del entorno (clima y suelo)';
const String kDashboardAction3 = 'Ver recomendaciones personalizadas';
const String kNavHome = 'Inicio';
const String kNavLots = 'Lotes';
const String kNavRotations = 'Rotaciones';
const String kNavCommunity = 'Comunidad';
const String kNavMore = 'Más';

// Lots Screen
const String kLotsScreenTitle = 'Lotes de la Finca';
const String kLotsScreenSubtitle = 'Consulta y gestiona todos los lotes registrados en tu finca.';
const String kSearchLotsHint = 'Buscar lote por nombre...';
const String kFilterAll = 'Todos';
const String kFilterLargest = 'Mayor superficie';
const String kFilterSmallest = 'Menor superficie';
const String kFilterWithSubplots = 'Con subparcelas';
const String kFilterPriorityTitle = 'Mi prioridad es:';
const String kRegisteredLotsTitle = 'Lotes registrados';
const String kAddNewLot = 'Agregar nuevo lote';
const String kEditLot = 'Editar Lote';
const String kDeleteLot = 'Eliminar Lote';
const String kDeleteLotConfirm = '¿Estás seguro de que deseas eliminar este lote?';
const String kDeleteLotWarning = 'Esta acción no se puede deshacer. También se eliminarán las subparcelas asociadas.';
const String kLotNamePrompt = 'Nombre del lote';
const String kLotSurfacePrompt = 'Superficie';
const String kLotUpdatedSuccessfully = '¡Lote actualizado con éxito!';
const String kLotCreatedSuccessfully = '¡Lote registrado con éxito!';
const String kLotDeletedSuccessfully = '¡Lote eliminado con éxito!';
const String kNoLotsFound = 'No se encontraron lotes que coincidan con la búsqueda.';
const String kNoLotsYetSubtitle = 'Agrega tu primer lote para organizar los cultivos y suelo de tu finca.';
const String kSubplotsCount = 'subparcelas';
const String kSubplotSingular = 'subparcela';
const String kSaveLot = 'Guardar Lote';

// Farm Details & Edit
const String kFarmDetailsTitle = 'Detalles de la Finca';
const String kEditFarm = 'Editar Finca';
const String kEditFarmInfo = 'Editar Información de la Finca';
const String kFarmOverview = 'Resumen de la Finca';
const String kLotsAndSubplots = 'Lotes y Subparcelas';
const String kEnvironmentalContext = 'Datos Ambientales y Clima';
const String kSaveChanges = 'Guardar Cambios';
const String kFarmUpdatedSuccessfully = '¡Finca actualizada con éxito!';
const String kTotalLots = 'Total de Lotes';
const String kTotalSubplots = 'Total de Subparcelas';
const String kNoLotsRegistered = 'Aún no hay lotes registrados.';
const String kLandAllocation = 'Distribución del Terreno';
const String kSoilMoisture = 'Humedad del Suelo';
const String kSolarRadiation = 'Radiación Solar';
const String kPrecipitation = 'Precipitación';
const String kTemperature = 'Temperatura';
const String kUnallocatedSurface = 'Sin asignar';
const String kGpsSynchronized = 'GPS Sincronizado';
const String kNoFarmsFound = 'No se encontró información de la finca. Por favor completa el registro inicial.';

// Language
const String kLanguage = 'Idioma';
const String kEnglish = 'Inglés';
const String kSpanish = 'Español';

// Settings Screen
const String kSettingsTitle = 'Configuración';
const String kSettingsSubtitle = 'Personaliza idioma, tema y unidades de medida';
const String kLanguageSectionTitle = 'Idioma';
const String kLanguageSectionSubtitle = 'Selecciona el idioma de la aplicación';
const String kThemeSectionTitle = 'Tema';
const String kThemeSectionSubtitle = 'Elige apariencia clara, oscura o del sistema';
const String kThemeLight = 'Claro';
const String kThemeDark = 'Oscuro';
const String kThemeSystem = 'Sistema';
const String kUnitsSectionTitle = 'Unidades de Medida';
const String kUnitsSectionSubtitle = 'Configura las unidades de superficie y temperatura';
const String kSurfaceUnitsTitle = 'Unidad de Superficie';
const String kTemperatureUnitsTitle = 'Unidad de Temperatura';
const String kUnitManzanas = 'Manzanas (mz)';
const String kUnitManzanasShort = 'mz';
const String kUnitCelsius = 'Celsius (°C)';
const String kUnitFahrenheit = 'Fahrenheit (°F)';
const String kUnitCelsiusShort = '°C';
const String kUnitFahrenheitShort = '°F';
const String kSettingsSaved = 'Configuración actualizada';

// Subplot Details & Management
const String kLotDetailsTitle = 'Detalles del Lote';
const String kSubplotsTitle = 'Subparcelas';
const String kAddNewSubplot = 'Agregar Subparcela';
const String kEditSubplot = 'Editar Subparcela';
const String kDeleteSubplot = 'Eliminar Subparcela';
const String kDeleteSubplotConfirm = '¿Estás seguro de que deseas eliminar esta subparcela?';
const String kDeleteSubplotWarning = 'Esta acción no se puede deshacer. Se eliminarán los registros asociados a esta subparcela.';
const String kSubplotCreatedSuccessfully = '¡Subparcela registrada con éxito!';
const String kSubplotUpdatedSuccessfully = '¡Subparcela actualizada con éxito!';
const String kSubplotDeletedSuccessfully = '¡Subparcela eliminada con éxito!';
const String kSaveSubplot = 'Guardar Subparcela';
const String kLotAllocation = 'Distribución del Terreno del Lote';
const String kTotalLotSurface = 'Superficie Total del Lote';
const String kAllocatedToSubplots = 'Asignado a subparcelas';
const String kUnallocatedFromLot = 'Sin asignar';
const String kNoSubplotsYet = 'Aún no hay subparcelas en este lote.';
const String kNoSubplotsSubtitle = 'Divide este lote en subparcelas para gestionar cultivos específicos, rotaciones y prácticas de suelo.';
const String kExceededLotSurfaceWarning = '¡La superficie total de las subparcelas supera la superficie del lote!';

// Soil Classification
const String kSoilTypeLabel = 'Tipo de Suelo';
const String kSoilTypeHint = 'Selecciona el tipo de suelo';
const String kSoilComposition = 'Composición del Suelo';
const String kSoilSandy = 'Arenosos';
const String kSoilClay = 'Arcillosos';
const String kSoilSilt = 'Limosos';
const String kSoilLoam = 'Francos';
const String kSoilClayLoam = 'Franco-arcilloso';
const String kSoilSandyLoam = 'Franco-arenoso';
const String kSoilOrganic = 'Humífero / Orgánico';
const String kSoilRocky = 'Pedregoso';
const String kSoilUnknown = 'Sin especificar';

// Crop Selection & Management
const String kCropLabel = 'Cultivo Actual';
const String kCropHint = 'Selecciona un cultivo (Opcional)';
const String kAssignCrop = 'Asignar Cultivo';
const String kChangeCrop = 'Cambiar';
const String kNoCropAssigned = 'Sin cultivo asignado';
const String kClearCrop = 'Ninguno (Quitar cultivo)';
const String kPopularCrops = 'Cultivos Frecuentes';
const String kAllCrops = 'Todos los Cultivos';
const String kSearchCropHint = 'Buscar cultivo por nombre...';
const String kCategoryGrains = 'Granos y Legumbres';
const String kCategoryFruits = 'Frutales';
const String kCategoryCommercial = 'Comerciales y Agroforestales';
const String kCropUpdatedSuccessfully = '¡Cultivo actualizado con éxito!';

// Agroclimatic Predictions Screen
const String kPredictionsTitle = 'Predicciones Agroclimáticas';
const String kPredictionsSubtitle = 'NASA POWER • SMAP L4 • Grafo Espacial';
const String kAskIvyTooltip = 'Consultar a Ivy AI';
const String kTabIrrigation = 'Riego';
const String kTabRotation = 'Rotación';
const String kTabPlantingGdd = 'Siembra';
const String kTabVigorNdvi = 'Vigor';
const String kTabRisks = 'Alertas';
const String kTabNutrition = 'Nutrición';
const String kPredictionContext = 'Contexto de la Parcela:';
const String kWhatIfSimulator = 'Simular qué pasa si...';
const String kWholeFarmGeneral = 'Toda la Finca';
const String kCropPrefix = 'Cultivo:';
const String kSoilPrefix = 'Suelo:';
const String kMetricRootMoisture = 'Humedad en Raíz';
const String kMetricRootMoistureSub = 'NASA SMAP L4';
const String kMetric7dDeficit = 'Déficit a 7 Días';
const String kMetric7dDeficitSub = 'Consumo vs. Lluvia';
const String kMetricReserveDays = 'Días de Reserva';
const String kMetricReserveDaysSub = 'Antes de marchitez';
const String kMetricRequiredDepth = 'Lámina Requerida';
const String kMetricRequiredDepthSub = 'Agua a aplicar';
const String kSoilImpactTitle = '¿Cómo influye la textura de tu suelo?';
const String kSoilImpactDescription = 'En suelos arenosos el agua se filtra rápidamente al fondo, necesitando riegos cortos y frecuentes. En suelos arcillosos el agua se almacena por más días, pero si llueve en exceso se debe vigilar el drenaje para evitar que las raíces se asfixien.';
const String kCorridorRiskTitle = '¡Cuidado! Corredor de Plagas en el Lindero';
const String kCorridorRiskDescription = 'Tus parcelas vecinas tienen cultivos de la misma familia botánica. Rotar con leguminosas (frijol o abono verde) corta el avance de gusanos y hongos.';
const String kAgroJustificationTitle = 'Beneficio para tu Parcela:';
const String kAlternativeCropsTitle = 'Otras Opciones Compatibles:';
const String kOptimalCropPrefix = 'Recomendado:';
const String kMetricThermalSumGdd = 'Suma Térmica (GDD)';
const String kMetricThermalSumGddSub = 'Calor acumulado (Tbase 10°C)';
const String kMetricDaysToFlowering = 'Días para Floración';
const String kRecommendedRangePrefix = 'Fecha ideal:';
const String kMetricNdviProxy = 'Vigor Satelital (NDVI)';
const String kMetricNdviProxySub = 'Verdor y fotosíntesis';
const String kMetricRelativeYield = 'Rendimiento Proyectado';
const String kMetricRelativeYieldSub = 'Del potencial de tu lote';
const String kMetricBiologicalNFixation = 'Aporte Biológico de Nitrógeno';
const String kMetricNBalancePerHa = 'Nitrógeno al Suelo';
const String kMetricUreaSavings = 'Ahorro en Fertilizante';
const String kMetricSoilHealthScore = 'Salud y Fuerza del Suelo';
const String kMetricSoilHealthScoreSub = 'Fertilidad y materia orgánica';
const String kSimulatorTitle = 'Simulador de Cultivo y Suelo';
const String kSimulatorCropQuestion = '¿Qué cultivo quieres probar?';
const String kSimulatorSoilQuestion = '¿Qué tipo de tierra tiene tu parcela?';
const String kSimulatorApplyButton = 'Calcular con este Escenario';
const String kAskIvyButton = 'Preguntar a Ivy';
const String kIvyCopilotTitle = 'Ivy • Copiloto Agroclimático';
const String kIvyAnalyzingScenario = 'Ivy está analizando tus satélites y cultivo...';
const String kIvyInputHint = 'Hazle una pregunta a Ivy sobre tu finca...';
const String kIvyErrorMessage = 'Ocurrió un error al contactar a Ivy. Intenta de nuevo.';
const String kStatusAttentionRequired = '¡Atención Requerida!';
const String kStatusPlanIrrigation = 'Planificar Riego';
const String kStatusOptimalMoisture = 'Humedad Óptima';
const String kSynergyLabel = 'Sinergia';
const String kBiologicalNFixationPerHa = 'FBN por Ha';
const String kUreaSavingsShort = 'Ahorro Urea';
const String kDaysUnit = 'días';
const String kIvyInitialPrompt = 'Explícame las predicciones para mi cultivo y tipo de suelo actual.';
const String kVisualParcelView = 'Mapa 2.5D';
const String kCompactListView = 'Lista';
const String kSoilBalancedDesc = 'Franco (Equilibrado)';
const String kSoilClayDesc = 'Arcilloso (Alta retención / Infiltración lenta)';
const String kSoilSandyDesc = 'Arenoso (Drenaje rápido / Baja retención)';
const String kSoilSiltDesc = 'Limoso (Compactación superficial)';
const String kActiveSubplotBadge = 'Seleccionado';
const String kTapToInspectSubplot = 'Toca un lote o sublote para inspeccionar';

// Prediction Engine Localized Messages
const String kIrrigationUrgentTitle = 'Riego Urgente Requerido';
const String kIrrigationModerateTitle = 'Humedad Moderada - Monitorear';
const String kIrrigationOptimalTitle = 'Nivel Hídrico Óptimo';
String kIrrigationUrgentRec(Object moisture, Object soil, Object crop, Object kc, Object waterMm) =>
    'Humedad radicular crítica ($moisture%) en suelo $soil para $crop (Kc: $kc). Aplica lámina de $waterMm mm en las próximas 48 h para evitar marchitez.';
String kIrrigationModerateRec(Object soil, Object days, Object waterMm) =>
    'Suelo $soil retiene agua para los próximos $days días. Programa riego preventivo ($waterMm mm) al promediar la semana.';
String kIrrigationOptimalRec(Object moisture, Object crop, Object soil) =>
    'Reserva hídrica suficiente ($moisture%) para $crop en suelo $soil. No se requiere riego en los siguientes 7 días.';

const String kCompatibilityHigh = 'Alta Compatibilidad';
const String kCompatibilityMedium = 'Media Compatibilidad';
const String kCompatibilityDiscouraged = 'Desaconsejada';
const String kCropBeansLegume = 'Frijol (Fabaceae)';
const String kCropCornSorghumGrass = 'Maíz o Sorgo (Gramíneas)';
const String kCropRedBeansLegume = 'Frijol Rojo (Leguminosa)';
const String kCropDroughtBeansSorghum = 'Frijol Alacita / Sorgo Sequero';
const String kCropCrotalariaManure = 'Crotalaria / Abono Verde';
const String kCropSoybean = 'Soya';
const String kCropTolerantSorghum = 'Sorgo Tolerante';
const String kCropCrotalariaGreenManure = 'Crotalaria (Abono Verde)';
const String kCropVegetables = 'Hortalizas';
const String kCropSesame = 'Ajonjolí';
const String kCropSunflower = 'Girasol';
const String kFamilyUnknown = 'Desconocida';
String kRotationCorridorRiskExp(Object family, Object crop) =>
    'Se detectó que parcelas vecinas comparten la misma familia ($family). Rotar con $crop romperá el corredor biológico de plagas y fijará nitrógeno.';
String kRotationStandardExp(Object currentCrop, Object suggestedCrop) =>
    'La secuencia sugerida ($currentCrop -> $suggestedCrop) optimiza el uso de nutrientes y aprovecha el nivel hídrico actual.';

const String kWindowStatusOptimal = 'Ventana Óptima de Siembra';
const String kWindowStatusWaitMoisture = 'Esperar Mayor Humedad';
const String kDateRangeNext10To14Days = 'Próximos 10 a 14 días';
const String kDateRangePostponeUntilRain = 'Postergar hasta próximas lluvias';
String kThermalAdviceFavorable(Object gdd) =>
    'Suma térmica favorable ($gdd GDD/sem). La germinación ocurrirá en 4 a 6 días sin riesgo de estrés térmico.';
String kThermalAdviceMoistureLow(Object moisturePct) =>
    'La humedad radicular ($moisturePct%) está por debajo del umbral de germinación uniforme (mínimo 42%).';

const String kVigorStatusExcellent = 'Vigor Excelente';
const String kVigorStatusNormal = 'Vigor Normal';
const String kVigorStatusWaterStress = 'Bajo Estrés Hídrico';
const String kBiomassConditionDense =
    'Dosel vegetal denso con alta actividad fotosintética. Proyección de cosecha en percentil superior.';
const String kBiomassConditionNormal =
    'Desarrollo vegetativo acorde a la fecha fenológica sin anomalías marcadas.';
String kBiomassConditionStress(Object lossPct) =>
    'Vigor deprimido por déficit hídrico sostenido. Se proyecta merma del $lossPct% si no se irriga.';

const String kRiskAlertFlashDroughtTitle = 'Alerta de Sequía Relámpago (Flash Drought)';
const String kRiskAlertWaterloggingTitle = 'Riesgo de Saturación y Asfixia Radicular';
const String kRiskAlertHeatStressTitle = 'Estrés Térmico por Golpe de Calor';
const String kRiskAlertNoneTitle = 'Sin Riesgos Climáticos Extremos Activos';
const String kRiskAdviceFlashDroughtSandy =
    'Suelo arenoso con drenaje acelerado: la humedad se evapora rápidamente bajo radiación solar intensa. Aplica cobertura vegetal (mulch) y riegos cortos frecuentes.';
const String kRiskAdviceFlashDroughtStandard =
    'Caída acelerada de humedad por radiación solar extrema. Aplica acolchado (mulch) orgánico en las bases y adelanta ciclos de riego defensivo.';
const String kRiskAdviceWaterloggingClay =
    'Suelo arcilloso con infiltración lenta: el exceso de agua estancada asfixia las raíces. Abre zanjas de evacuación superficial y evita el pisoteo del terreno.';
const String kRiskAdviceWaterloggingStandard =
    'Precipitación acumulada excesiva en suelo saturado. Abre zanjas de drenaje superficiales para evacuar escorrentía estancada.';
const String kRiskAdviceHeatStress =
    'Temperaturas diurnas elevadas que pueden provocar aborto floral en leguminosas y hortalizas. Mantén hidratado el follaje.';
const String kRiskAdviceNone =
    'Las variables hidroclimáticas se mantienen dentro de los umbrales seguros para los cultivos de la finca.';

String kSoilNutritionDiagnosisLegumeSandy(Object nGain, Object ureaSavings) =>
    'La rotación propuesta con leguminosas aportará ~$nGain kg N/ha. En suelo arenoso, se aconseja incorporar biomasa verde para evitar lixiviación, ahorrando ~$ureaSavings kg de urea.';
String kSoilNutritionDiagnosisLegumeStandard(Object nGain, Object ureaSavings) =>
    'La rotación propuesta con leguminosas aportará un estimado de $nGain kg de Nitrógeno biológico por hectárea, ahorrando cerca de $ureaSavings kg de urea comercial.';
const String kSoilNutritionDiagnosisCerealSandy =
    'Los cereales extraen nitrógeno (-35 kg N/ha) y en suelo arenoso el lavado por lluvia es severo. Incorpora abonos verdes profundos o compost inmediatamente.';
const String kSoilNutritionDiagnosisCerealStandard =
    'Los cereales extraen nitrógeno del perfil (-35 kg N/ha). Se recomienda incorporar cobertura vegetal o compost para mantener la fertilidad del suelo.';

const String kDefaultCropName = 'Maíz';
const String kDefaultSoilName = 'Franco';






