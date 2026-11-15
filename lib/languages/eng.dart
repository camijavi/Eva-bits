// English text constants
const String kOk = 'OK';
const String kCancel = 'Cancel';
const String kSave = 'Save';
const String kClose = 'Close';

// Titles & Hierarchy
const String kFarmInfoTitle = 'Farm Information';
const String kFarmer = 'Farmer';
const String kFarm = 'Farm';
const String kGeneralInfoSection = 'General Farm Information';
const String kLotsSectionTitle = 'Lots';
const String kSubplotsSectionTitle = 'Subplots (Optional)';
const String kSummaryTitle = 'Farm Summary';

// Farm Fields
const String kFarmNameLabel = 'Farm Name';
const String kFarmNameHint = 'Enter farm name';
const String kCountryLabel = 'Country';
const String kCountryHint = 'Enter country';
const String kTotalSurfaceLabel = 'Total Surface';
const String kTotalSurfaceHint = 'Enter total surface';
const String kGeographicZoneLabel = 'Geographic Zone';
const String kGeographicZoneHint = 'Enter geographic zone';

// GPS & Location
const String kFarmLocationLabel = 'Farm Location';
const String kWhereIsYourFarm = 'Where is your farm?';
const String kGetGpsLocationButton = 'Detect Current GPS Location';
const String kGettingGpsLocation = 'Acquiring GPS signal...';
const String kLatitudeLabel = 'Latitude';
const String kLatitudeHint = 'e.g. 13.0910';
const String kLongitudeLabel = 'Longitude';
const String kLongitudeHint = 'e.g. -86.3538';
const String kGpsSuccess = 'GPS coordinates captured successfully';
const String kGpsServiceDisabled =
    'Location services are disabled on your device. Please enable GPS.';
const String kGpsPermissionDenied = 'Location permission was denied.';
const String kGpsPermissionDeniedPermanently =
    'Location permissions are permanently denied. Please enable them in settings.';
const String kGpsError = 'Failed to acquire GPS coordinates.';
const String kLocationNotCapturedYet =
    'GPS location not recorded yet. Tap to detect.';
const String kRefreshLocation = 'Update GPS';
const String kLocationRequired =
    'Please detect the farm GPS location before continuing.';
const String kGpsCoordinates = 'Coordinates';

// Surface Units
const String kSurfaceUnitLabel = 'Surface Unit of Measurement';
const String kSurfaceUnitHint = 'Select measurement unit';
const String kUnitHectares = 'Hectares (ha)';
const String kUnitAcres = 'Acres (ac)';
const String kUnitSquareMeters = 'Square Meters (m²)';
const String kUnitTareas = 'Tareas';

const String kUnitHectaresShort = 'ha';
const String kUnitAcresShort = 'ac';
const String kUnitSquareMetersShort = 'm²';
const String kUnitTareasShort = 'tareas';

// Lots
const String kLotsCountLabel = 'How many lots are there?';
const String kLotsCountHint = 'Number of lots';
const String kLot = 'Lot';
const String kLotNameLabel = 'Lot Name';
const String kLotNameHint = 'Enter lot name';
const String kLotSurfaceLabel = 'Lot Surface';
const String kLotSurfaceHint = 'Enter lot surface';
const String kAddLot = 'Add Lot';
const String kRemoveLot = 'Remove Lot';

// Subplots
const String kSubplotsCountLabel = 'Number of Subplots (0 or more)';
const String kSubplotsCountHint = 'Enter number of subplots';
const String kSubplot = 'Subplot';
const String kSubplotNameLabel = 'Subplot Name';
const String kSubplotNameHint = 'Enter subplot name';
const String kSubplotSurfaceLabel = 'Subplot Surface';
const String kSubplotSurfaceHint = 'Enter subplot surface';
const String kAddSubplot = 'Add Subplot';
const String kRemoveSubplot = 'Remove Subplot';
const String kNoSubplots = 'No subplots in this lot';

// Validation & Alerts
const String kFieldRequired = 'This field is required';
const String kInvalidNumber = 'Please enter a valid positive number';
const String kLotsCountPositive = 'Please enter 0 or more lots';
const String kSubplotsCountPositive = 'Please enter 0 or more subplots';
const String kLotsSurfaceExceededWarning =
    'Warning: Total lot surface exceeds farm surface!';
const String kSubplotsSurfaceExceededWarning =
    'Warning: Total subplot surface exceeds lot surface!';
const String kFormSavedSuccessfully = 'Farm information saved successfully!';
const String kConfirmSave = 'Confirm and Save';
const String kErrorSavingData = 'Error saving farm data. Please try again.';

// Wizard & Quick Start
const String kStep1Title = 'Farm';
const String kStep2Title = 'Lots';
const String kStep3Title = 'Summary';
const String kQuickStartWholeFarm = 'Bypass lot division (Use whole farm as 1 lot)';
const String kNextStep = 'Next';
const String kPreviousStep = 'Back';
const String kSingleLotMode = 'Single Lot (Whole Farm)';
const String kMainLot = 'Main Lot';
const String kCustomLotsMode = 'Multiple Lots / Subplots';
const String kAllocatedSurface = 'Allocated Surface';
const String kAskIvyTitle = 'Ask Ivy (Prediction)';
const String kNasaDataReady = 'NASA & Climate Data';
const String kNoLotsAddedYet = 'You have not added any lots yet.';
const String kLotsDistribution = 'Lots Distribution';
const String kNasaDataDescription =
    'NASA POWER and SMAP satellite data (solar radiation, rainfall, and soil moisture) synchronized for your coordinates.';

// Dashboard Mockup
const String kDashboardGreeting = 'Hello, María!';
const String kDashboardSubtitle =
    'Here is a summary of your farm and recommendations for today.';
const String kDashboardWeatherSummary = 'Mostly sunny';
const String kDashboardYourFarm = 'Your Farm';
const String kDashboardFarmSize = 'Size';
const String kDashboardCurrentCrops = 'Current crops: Corn, Beans';
const String kDashboardViewDetails = 'View details';
const String kDashboardWhatToDo = 'What would you like to do today?';
const String kDashboardAction1 = 'Compare crop rotations';
const String kDashboardAction2 =
    'Explore environmental data (climate and soil)';
const String kDashboardAction3 = 'View personalized recommendations';
const String kNavHome = 'Home';
const String kNavLots = 'Lots';
const String kNavRotations = 'Rotations';
const String kNavCommunity = 'Community';
const String kNavMore = 'More';

// Lots Screen
const String kLotsScreenTitle = 'Farm Lots';
const String kLotsScreenSubtitle = 'Manage and view all registered lots on your farm.';
const String kSearchLotsHint = 'Search lot by name...';
const String kFilterAll = 'All';
const String kFilterLargest = 'Largest area';
const String kFilterSmallest = 'Smallest area';
const String kFilterWithSubplots = 'With subplots';
const String kFilterPriorityTitle = 'My priority is:';
const String kRegisteredLotsTitle = 'Registered lots';
const String kAddNewLot = 'Add new lot';
const String kEditLot = 'Edit Lot';
const String kDeleteLot = 'Delete Lot';
const String kDeleteLotConfirm = 'Are you sure you want to delete this lot?';
const String kDeleteLotWarning = 'This action cannot be undone. Any associated subplots will also be removed.';
const String kLotNamePrompt = 'Lot Name';
const String kLotSurfacePrompt = 'Surface Area';
const String kLotUpdatedSuccessfully = 'Lot updated successfully!';
const String kLotCreatedSuccessfully = 'Lot registered successfully!';
const String kLotDeletedSuccessfully = 'Lot deleted successfully!';
const String kNoLotsFound = 'No lots found matching your search.';
const String kNoLotsYetSubtitle = 'Add your first lot to organize your farm crops and soil.';
const String kSubplotsCount = 'subplots';
const String kSubplotSingular = 'subplot';
const String kSaveLot = 'Save Lot';

// Farm Details & Edit
const String kFarmDetailsTitle = 'Farm Details';
const String kEditFarm = 'Edit Farm';
const String kEditFarmInfo = 'Edit Farm Information';
const String kFarmOverview = 'Farm Overview';
const String kLotsAndSubplots = 'Lots & Subplots';
const String kEnvironmentalContext = 'Environmental & Climate Data';
const String kSaveChanges = 'Save Changes';
const String kFarmUpdatedSuccessfully = 'Farm updated successfully!';
const String kTotalLots = 'Total Lots';
const String kTotalSubplots = 'Total Subplots';
const String kNoLotsRegistered = 'No lots registered yet.';
const String kLandAllocation = 'Land Allocation';
const String kSoilMoisture = 'Soil Moisture';
const String kSolarRadiation = 'Solar Radiation';
const String kPrecipitation = 'Precipitation';
const String kTemperature = 'Temperature';
const String kUnallocatedSurface = 'Unallocated';
const String kGpsSynchronized = 'GPS Synchronized';
const String kNoFarmsFound = 'No farm data found. Please complete the initial registration.';

// Language
const String kLanguage = 'Language';
const String kEnglish = 'English';
const String kSpanish = 'Spanish';

// Settings Screen
const String kSettingsTitle = 'Settings';
const String kSettingsSubtitle = 'Customize language, theme, and measurement units';
const String kLanguageSectionTitle = 'Language';
const String kLanguageSectionSubtitle = 'Select the application language';
const String kThemeSectionTitle = 'Theme';
const String kThemeSectionSubtitle = 'Choose light, dark, or system appearance';
const String kThemeLight = 'Light';
const String kThemeDark = 'Dark';
const String kThemeSystem = 'System';
const String kUnitsSectionTitle = 'Measurement Units';
const String kUnitsSectionSubtitle = 'Configure surface area and temperature units';
const String kSurfaceUnitsTitle = 'Surface Area Unit';
const String kTemperatureUnitsTitle = 'Temperature Unit';
const String kUnitManzanas = 'Manzanas (mz)';
const String kUnitManzanasShort = 'mz';
const String kUnitCelsius = 'Celsius (°C)';
const String kUnitFahrenheit = 'Fahrenheit (°F)';
const String kUnitCelsiusShort = '°C';
const String kUnitFahrenheitShort = '°F';
const String kSettingsSaved = 'Settings updated';

// Subplot Details & Management
const String kLotDetailsTitle = 'Lot Details';
const String kSubplotsTitle = 'Subplots';
const String kAddNewSubplot = 'Add Subplot';
const String kEditSubplot = 'Edit Subplot';
const String kDeleteSubplot = 'Delete Subplot';
const String kDeleteSubplotConfirm = 'Are you sure you want to delete this subplot?';
const String kDeleteSubplotWarning = 'This action cannot be undone. All records for this subplot will be removed.';
const String kSubplotCreatedSuccessfully = 'Subplot registered successfully!';
const String kSubplotUpdatedSuccessfully = 'Subplot updated successfully!';
const String kSubplotDeletedSuccessfully = 'Subplot deleted successfully!';
const String kSaveSubplot = 'Save Subplot';
const String kLotAllocation = 'Lot Land Allocation';
const String kTotalLotSurface = 'Total Lot Area';
const String kAllocatedToSubplots = 'Allocated to subplots';
const String kUnallocatedFromLot = 'Unallocated';
const String kNoSubplotsYet = 'No subplots in this lot yet.';
const String kNoSubplotsSubtitle = 'Divide this lot into subplots to manage specific crops, rotations, and soil practices.';
const String kExceededLotSurfaceWarning = 'Total subplot area exceeds the lot surface area!';

// Soil Classification
const String kSoilTypeLabel = 'Soil Type';
const String kSoilTypeHint = 'Select soil type';
const String kSoilComposition = 'Soil Composition';
const String kSoilSandy = 'Sandy (Arenosos)';
const String kSoilClay = 'Clay (Arcillosos)';
const String kSoilSilt = 'Silt (Limosos)';
const String kSoilLoam = 'Loam (Francos)';
const String kSoilClayLoam = 'Clay Loam (Franco-arcilloso)';
const String kSoilSandyLoam = 'Sandy Loam (Franco-arenoso)';
const String kSoilOrganic = 'Organic-rich (Humífero)';
const String kSoilRocky = 'Rocky (Pedregoso)';
const String kSoilUnknown = 'Unspecified';

// Crop Selection & Management
const String kCropLabel = 'Current Crop';
const String kCropHint = 'Select a crop (Optional)';
const String kAssignCrop = 'Assign Crop';
const String kChangeCrop = 'Change';
const String kNoCropAssigned = 'No crop assigned';
const String kClearCrop = 'None (Clear crop)';
const String kPopularCrops = 'Frequent Crops';
const String kAllCrops = 'All Crops';
const String kSearchCropHint = 'Search crop by name...';
const String kCategoryGrains = 'Grains & Legumes';
const String kCategoryFruits = 'Fruits';
const String kCategoryCommercial = 'Commercial & Cash Crops';
const String kCropUpdatedSuccessfully = 'Crop updated successfully!';

// Agroclimatic Predictions Screen
const String kPredictionsTitle = 'Agroclimatic Predictions';
const String kPredictionsSubtitle = 'NASA POWER • SMAP L4 • Spatial Graph';
const String kAskIvyTooltip = 'Ask Eve AI';
const String kTabIrrigation = 'Irrigation';
const String kTabRotation = 'Rotation';
const String kTabPlantingGdd = 'Planting';
const String kTabVigorNdvi = 'Vigor';
const String kTabRisks = 'Alerts';
const String kTabNutrition = 'Nutrition';
const String kPredictionContext = 'Parcel Context:';
const String kWhatIfSimulator = 'Simulate what if...';
const String kWholeFarmGeneral = 'Whole Farm';
const String kCropPrefix = 'Crop:';
const String kSoilPrefix = 'Soil:';
const String kMetricRootMoisture = 'Root Zone Moisture';
const String kMetricRootMoistureSub = 'NASA SMAP L4';
const String kMetric7dDeficit = '7-Day Deficit';
const String kMetric7dDeficitSub = 'Crop demand vs. rain';
const String kMetricReserveDays = 'Reserve Days';
const String kMetricReserveDaysSub = 'Before wilting stress';
const String kMetricRequiredDepth = 'Required Water Depth';
const String kMetricRequiredDepthSub = 'Water to apply';
const String kSoilImpactTitle = 'How does your soil texture affect irrigation?';
const String kSoilImpactDescription = 'In sandy soils, water drains rapidly to lower layers, requiring shorter and more frequent watering. In clay soils, water is stored for more days, but drainage must be monitored during heavy rains to prevent root asphyxia.';
const String kCorridorRiskTitle = 'Watch out! Pest Corridor in Adjacent Parcel';
const String kCorridorRiskDescription = 'Adjacent parcels share crops of the same botanical family. Rotating with legumes (beans or green manure) cuts the spread of pests and fungi.';
const String kAgroJustificationTitle = 'Benefit for Your Parcel:';
const String kAlternativeCropsTitle = 'Other Compatible Options:';
const String kOptimalCropPrefix = 'Recommended:';
const String kMetricThermalSumGdd = 'Thermal Sum (GDD)';
const String kMetricThermalSumGddSub = 'Accumulated heat (Tbase 10°C)';
const String kMetricDaysToFlowering = 'Days to Flowering';
const String kRecommendedRangePrefix = 'Ideal window:';
const String kMetricNdviProxy = 'Satellite Vigor (NDVI)';
const String kMetricNdviProxySub = 'Greenness and photosynthesis';
const String kMetricRelativeYield = 'Projected Yield';
const String kMetricRelativeYieldSub = 'Of your parcel potential';
const String kMetricBiologicalNFixation = 'Biological Nitrogen Fixation';
const String kMetricNBalancePerHa = 'Nitrogen to Soil';
const String kMetricUreaSavings = 'Fertilizer Savings';
const String kMetricSoilHealthScore = 'Soil Health & Vitality';
const String kMetricSoilHealthScoreSub = 'Fertility and organic matter';
const String kSimulatorTitle = 'Crop & Soil Simulator';
const String kSimulatorCropQuestion = 'Which crop do you want to test?';
const String kSimulatorSoilQuestion = 'What type of soil does your parcel have?';
const String kSimulatorApplyButton = 'Calculate this Scenario';
const String kAskIvyButton = 'Ask Eve';
const String kIvyCopilotTitle = 'Eve • Agroecological Assistant';
const String kIvyAnalyzingScenario = 'Eve is analyzing your satellite, soil, and crop data...';
const String kIvyInputHint = 'Ask Eve anything about your farm...';
const String kIvyErrorMessage = 'An error occurred while contacting Eve. Please try again.';
const String kStatusAttentionRequired = 'Attention Required!';
const String kStatusPlanIrrigation = 'Plan Irrigation';
const String kStatusOptimalMoisture = 'Optimal Moisture';
const String kSynergyLabel = 'Synergy';
const String kBiologicalNFixationPerHa = 'BNF per Ha';
const String kUreaSavingsShort = 'Urea Savings';
const String kDaysUnit = 'days';
const String kIvyInitialPrompt = 'Explain the predictions for my current crop and soil type.';
const String kVisualParcelView = '2.5D Map';
const String kCompactListView = 'List';
const String kSoilBalancedDesc = 'Loam (Balanced)';
const String kSoilClayDesc = 'Clay (High retention / Slow infiltration)';
const String kSoilSandyDesc = 'Sandy (Fast drainage / Low retention)';
const String kSoilSiltDesc = 'Silt (Surface crusting)';
const String kActiveSubplotBadge = 'Selected';
const String kTapToInspectSubplot = 'Tap a parcel or subplot to inspect';

// Prediction Engine Localized Messages
const String kIrrigationUrgentTitle = 'Urgent Irrigation Required';
const String kIrrigationModerateTitle = 'Moderate Moisture - Monitor';
const String kIrrigationOptimalTitle = 'Optimal Water Level';
String kIrrigationUrgentRec(Object moisture, Object soil, Object crop, Object kc, Object waterMm) =>
    'Critical root moisture ($moisture%) in $soil soil for $crop (Kc: $kc). Apply a depth of $waterMm mm within 48 h to prevent wilting.';
String kIrrigationModerateRec(Object soil, Object days, Object waterMm) =>
    '$soil soil retains water for the next $days days. Schedule preventive irrigation ($waterMm mm) mid-week.';
String kIrrigationOptimalRec(Object moisture, Object crop, Object soil) =>
    'Sufficient water reserve ($moisture%) for $crop in $soil soil. No irrigation required over the next 7 days.';

const String kCompatibilityHigh = 'High Compatibility';
const String kCompatibilityMedium = 'Medium Compatibility';
const String kCompatibilityDiscouraged = 'Not Recommended';
const String kCropBeansLegume = 'Beans (Fabaceae)';
const String kCropCornSorghumGrass = 'Corn or Sorghum (Grasses)';
const String kCropRedBeansLegume = 'Red Beans (Legume)';
const String kCropDroughtBeansSorghum = 'Drought-tolerant Beans / Sorghum';
const String kCropCrotalariaManure = 'Crotalaria / Green Manure';
const String kCropSoybean = 'Soybeans';
const String kCropTolerantSorghum = 'Tolerant Sorghum';
const String kCropCrotalariaGreenManure = 'Crotalaria (Green Manure)';
const String kCropVegetables = 'Vegetables';
const String kCropSesame = 'Sesame';
const String kCropSunflower = 'Sunflower';
const String kFamilyUnknown = 'Unknown';
String kRotationCorridorRiskExp(Object family, Object crop) =>
    'Neighboring plots share the same botanical family ($family). Rotating with $crop will disrupt pest corridors and fix biological nitrogen.';
String kRotationStandardExp(Object currentCrop, Object suggestedCrop) =>
    'The suggested sequence ($currentCrop -> $suggestedCrop) optimizes nutrient usage and leverages current moisture levels.';

const String kWindowStatusOptimal = 'Optimal Planting Window';
const String kWindowStatusWaitMoisture = 'Wait for Higher Moisture';
const String kDateRangeNext10To14Days = 'Next 10 to 14 days';
const String kDateRangePostponeUntilRain = 'Postpone until upcoming rains';
String kThermalAdviceFavorable(Object gdd) =>
    'Favorable thermal accumulation ($gdd GDD/week). Germination will occur in 4 to 6 days with low thermal stress risk.';
String kThermalAdviceMoistureLow(Object moisturePct) =>
    'Root zone moisture ($moisturePct%) is below the uniform germination threshold (minimum 42%).';

const String kVigorStatusExcellent = 'Excellent Vigor';
const String kVigorStatusNormal = 'Normal Vigor';
const String kVigorStatusWaterStress = 'Under Water Stress';
const String kBiomassConditionDense =
    'Dense plant canopy with high photosynthetic activity. Harvest projection in the upper percentile.';
const String kBiomassConditionNormal =
    'Vegetative development consistent with phenological timing without marked anomalies.';
String kBiomassConditionStress(Object lossPct) =>
    'Depressed vigor due to sustained water deficit. Projected yield loss of $lossPct% without irrigation.';

const String kRiskAlertFlashDroughtTitle = 'Flash Drought Alert';
const String kRiskAlertWaterloggingTitle = 'Waterlogging & Root Asphyxia Risk';
const String kRiskAlertHeatStressTitle = 'Heat Stress Alert';
const String kRiskAlertNoneTitle = 'No Active Extreme Weather Risks';
const String kRiskAdviceFlashDroughtSandy =
    'Sandy soil with accelerated drainage: moisture evaporates rapidly under intense solar radiation. Apply organic mulch and frequent short irrigation cycles.';
const String kRiskAdviceFlashDroughtStandard =
    'Rapid moisture loss from extreme solar radiation. Apply organic mulch to root bases and advance defensive irrigation cycles.';
const String kRiskAdviceWaterloggingClay =
    'Clay soil with slow infiltration: standing water asphyxiates roots. Open surface drainage ditches and avoid soil compaction.';
const String kRiskAdviceWaterloggingStandard =
    'Excessive accumulated precipitation in saturated soil. Open surface drainage ditches to evacuate stagnant runoff.';
const String kRiskAdviceHeatStress =
    'High daytime temperatures that may cause flower abortion in legumes and vegetables. Keep foliage hydrated.';
const String kRiskAdviceNone =
    'Hydroclimatic variables remain within safe thresholds for the farm crops.';

String kSoilNutritionDiagnosisLegumeSandy(Object nGain, Object ureaSavings) =>
    'The proposed legume rotation will contribute ~$nGain kg N/ha. In sandy soil, incorporating green biomass is recommended to prevent leaching, saving ~$ureaSavings kg of urea.';
String kSoilNutritionDiagnosisLegumeStandard(Object nGain, Object ureaSavings) =>
    'The proposed legume rotation will contribute an estimated $nGain kg of biological nitrogen per hectare, saving about $ureaSavings kg of commercial urea.';
const String kSoilNutritionDiagnosisCerealSandy =
    'Cereals deplete nitrogen (-35 kg N/ha) and rainfall leaching in sandy soil is severe. Incorporate deep green manure or compost immediately.';
const String kSoilNutritionDiagnosisCerealStandard =
    'Cereals deplete nitrogen from the profile (-35 kg N/ha). Incorporating cover crops or compost is recommended to maintain soil fertility.';

const String kDefaultCropName = 'Corn';
const String kDefaultSoilName = 'Loam';

// Eve Advanced Capabilities (Biotech Corpus, 3-Week Projections, Irrigation Systems)
const String kWeeklyNotificationBannerTitle = 'Weekly Checkpoint (+7 Days): View changes detected by Eve';
const String kWeeklyDeltaDialogTitle = 'Weekly Parcel Evolution (+7 Days)';
const String kIrrigationSystemsSectionTitle = 'Recommended Precision Irrigation Systems';
const String kIrrigationSystemsSectionSub = 'NASA-ISRO Mission (NISAR) • Bioversity Alliance & CIAT (2026)';
const String kRecommendedSystemBadge = 'Best for your soil';
const String kEfficiencyLabel = 'Efficiency:';
const String kBestForSoilLabel = 'Ideal soil:';
const String kThreeWeekProjectionTitle = '3-Week Rolling Projection (Every 3 Weeks)';
const String kThreeWeekProjectionSub = '21-day operational horizon with weekly checkpoints';
const String kNaturalPhenomenaSectionTitle = 'Natural Phenomena Surveillance (NASA GPM / SMAP / GRACE)';
const String kCropPestsSectionTitle = 'Crop Pest & Disease Warnings';
const String kHighRiskBadge = 'High Risk';
const String kModerateRiskBadge = 'Monitor';
const String kPreventionLabel = 'Prevention:';
const String kSourceLabel = 'Source:';
const String kQuickPromptPests = 'What pests threaten my crop?';
const String kQuickPromptPhenomena = 'What natural phenomena is NASA tracking?';
const String kQuickPrompt3Weeks = 'View 3-week projection';
const String kQuickPromptIrrigation = 'Which irrigation system fits my soil?';

// Eve Animated Mascot & Settings Visibility
const String kEveVisibilitySectionTitle = 'Eve Virtual Assistant';
const String kEveVisibilitySectionSubtitle = 'Show or hide the animated cow mascot Eve across app screens';
const String kShowEveOption = 'Show Eve';
const String kShowEveSubtitle = 'Eve accompanies you with animations, alerts, and interactive guidance';
const String kHideEveOption = 'Hide Eve';
const String kHideEveSubtitle = 'Compact mode displaying data cards only';
const String kEvePreviewEmoteLabel = 'Tap an emote to see Eve react:';
const String kEmoteGreeting = 'Wave';
const String kEmoteAlert = 'Alert !';
const String kEmoteSad = 'Sad';
const String kEmoteSurprised = 'Surprised';
const String kEmoteHappy = 'Happy';
const String kEmoteThumbsUp = 'Thumbs up';
const String kEmoteThumbsDown = 'Thumbs down';
const String kEmotePointing = 'Pointing';
const String kEmoteJumping = 'Jumping';
const String kEmoteCalm = 'Calm';
const String kEveGuideBannerTitle = 'Hi! I am Eve, your farming guide';
const String kEveGuideStep1 = 'Step 1: Use the dropdown menu to select Whole Farm, a Lot, or a specific Subplot.';
const String kEveGuideStep2 = 'Step 2: Tap "Simulate what if..." to test how another crop or soil changes your results.';
const String kEveGuideStep3 = 'Step 3: Review 3-week projections, irrigation systems, and NASA-backed pest warnings.';
const String kEveGuideNextTip = 'Next tip';
const String kEveReactionIrrigationCritical = 'Watch out! Your soil is critically dry. Apply irrigation soon.';
const String kEveReactionIrrigationModerate = 'I am pointing below to the ideal irrigation system to save water.';
const String kEveReactionIrrigationOptimal = 'Awesome! Root-zone moisture is optimal according to NASA SMAP.';
const String kEveReactionRotationGood = 'Thumbs up! This rotation regenerates your soil and fixes nitrogen.';
const String kEveReactionRotationRisk = 'Be careful planting the same crop family next to adjacent plots.';
const String kEveReactionRisksAlert = 'Alert! Check the active crop pests and natural phenomena warnings.';







