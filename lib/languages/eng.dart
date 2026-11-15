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
const String kAskIvyTitle = '🌾 Ask Ivy (Prediction)';
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
const String kSoilLoam = 'Loam (Franco)';
const String kSoilClay = 'Clay (Arcilloso)';
const String kSoilSandy = 'Sandy (Arenoso)';
const String kSoilClayLoam = 'Clay Loam (Franco-arcilloso)';
const String kSoilSandyLoam = 'Sandy Loam (Franco-arenoso)';
const String kSoilSilt = 'Silt (Limoso)';
const String kSoilOrganic = 'Organic-rich (Humífero)';
const String kSoilRocky = 'Rocky (Pedregoso)';
const String kSoilUnknown = 'Unspecified';



