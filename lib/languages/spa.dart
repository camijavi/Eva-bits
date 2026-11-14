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
const String kAskIvyTitle = '🌾 Consultar a Ivy (Predicción)';
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
const String kNavRotations = 'Rotaciones';
const String kNavCommunity = 'Comunidad';
const String kNavMore = 'Más';

// Language
const String kLanguage = 'Idioma';
const String kEnglish = 'Inglés';
const String kSpanish = 'Español';

