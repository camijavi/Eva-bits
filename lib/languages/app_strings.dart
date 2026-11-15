import 'package:flutter/foundation.dart';
import 'eng.dart' as eng;
import 'spa.dart' as spa;

enum AppLanguageType {
  spanish,
  english,
}

abstract class AppStrings {
  String get kOk;
  String get kCancel;
  String get kSave;
  String get kClose;

  // Titles & Hierarchy
  String get kFarmInfoTitle;
  String get kFarmer;
  String get kFarm;
  String get kGeneralInfoSection;
  String get kLotsSectionTitle;
  String get kSubplotsSectionTitle;
  String get kSummaryTitle;

  // Farm Fields
  String get kFarmNameLabel;
  String get kFarmNameHint;
  String get kCountryLabel;
  String get kCountryHint;
  String get kTotalSurfaceLabel;
  String get kTotalSurfaceHint;
  String get kGeographicZoneLabel;
  String get kGeographicZoneHint;

  // GPS & Location
  String get kFarmLocationLabel;
  String get kWhereIsYourFarm;
  String get kGetGpsLocationButton;
  String get kGettingGpsLocation;
  String get kLatitudeLabel;
  String get kLatitudeHint;
  String get kLongitudeLabel;
  String get kLongitudeHint;
  String get kGpsSuccess;
  String get kGpsServiceDisabled;
  String get kGpsPermissionDenied;
  String get kGpsPermissionDeniedPermanently;
  String get kGpsError;
  String get kLocationNotCapturedYet;
  String get kRefreshLocation;
  String get kLocationRequired;
  String get kGpsCoordinates;

  // Surface Units
  String get kSurfaceUnitLabel;
  String get kSurfaceUnitHint;
  String get kUnitHectares;
  String get kUnitAcres;
  String get kUnitSquareMeters;
  String get kUnitTareas;
  String get kUnitHectaresShort;
  String get kUnitAcresShort;
  String get kUnitSquareMetersShort;
  String get kUnitTareasShort;

  // Lots
  String get kLotsCountLabel;
  String get kLotsCountHint;
  String get kLot;
  String get kLotNameLabel;
  String get kLotNameHint;
  String get kLotSurfaceLabel;
  String get kLotSurfaceHint;
  String get kAddLot;
  String get kRemoveLot;

  // Subplots
  String get kSubplotsCountLabel;
  String get kSubplotsCountHint;
  String get kSubplot;
  String get kSubplotNameLabel;
  String get kSubplotNameHint;
  String get kSubplotSurfaceLabel;
  String get kSubplotSurfaceHint;
  String get kAddSubplot;
  String get kRemoveSubplot;
  String get kNoSubplots;

  // Validation & Feedback
  String get kFieldRequired;
  String get kInvalidNumber;
  String get kLotsCountPositive;
  String get kSubplotsCountPositive;
  String get kLotsSurfaceExceededWarning;
  String get kSubplotsSurfaceExceededWarning;
  String get kFormSavedSuccessfully;
  String get kConfirmSave;
  String get kErrorSavingData;

  // Wizard & Quick Start
  String get kStep1Title;
  String get kStep2Title;
  String get kStep3Title;
  String get kQuickStartWholeFarm;
  String get kNextStep;
  String get kPreviousStep;
  String get kSingleLotMode;
  String get kMainLot;
  String get kCustomLotsMode;
  String get kAllocatedSurface;
  String get kAskIvyTitle;
  String get kNasaDataReady;
  String get kNoLotsAddedYet;
  String get kLotsDistribution;
  String get kNasaDataDescription;

  // Dashboard Mockup
  String get kDashboardGreeting;
  String get kDashboardSubtitle;
  String get kDashboardWeatherSummary;
  String get kDashboardYourFarm;
  String get kDashboardFarmSize;
  String get kDashboardCurrentCrops;
  String get kDashboardViewDetails;
  String get kDashboardWhatToDo;
  String get kDashboardAction1;
  String get kDashboardAction2;
  String get kDashboardAction3;
  String get kNavHome;
  String get kNavLots;
  String get kNavRotations;
  String get kNavCommunity;
  String get kNavMore;

  // Lots Screen
  String get kLotsScreenTitle;
  String get kLotsScreenSubtitle;
  String get kSearchLotsHint;
  String get kFilterAll;
  String get kFilterLargest;
  String get kFilterSmallest;
  String get kFilterWithSubplots;
  String get kFilterPriorityTitle;
  String get kRegisteredLotsTitle;
  String get kAddNewLot;
  String get kEditLot;
  String get kDeleteLot;
  String get kDeleteLotConfirm;
  String get kDeleteLotWarning;
  String get kLotNamePrompt;
  String get kLotSurfacePrompt;
  String get kLotUpdatedSuccessfully;
  String get kLotCreatedSuccessfully;
  String get kLotDeletedSuccessfully;
  String get kNoLotsFound;
  String get kNoLotsYetSubtitle;
  String get kSubplotsCount;
  String get kSubplotSingular;
  String get kSaveLot;

  // Farm Details & Edit
  String get kFarmDetailsTitle;
  String get kEditFarm;
  String get kEditFarmInfo;
  String get kFarmOverview;
  String get kLotsAndSubplots;
  String get kEnvironmentalContext;
  String get kSaveChanges;
  String get kFarmUpdatedSuccessfully;
  String get kTotalLots;
  String get kTotalSubplots;
  String get kNoLotsRegistered;
  String get kLandAllocation;
  String get kSoilMoisture;
  String get kSolarRadiation;
  String get kPrecipitation;
  String get kTemperature;
  String get kUnallocatedSurface;
  String get kGpsSynchronized;
  String get kNoFarmsFound;

  // Language
  String get kLanguage;
  String get kEnglish;
  String get kSpanish;

  // Settings Screen
  String get kSettingsTitle;
  String get kSettingsSubtitle;
  String get kLanguageSectionTitle;
  String get kLanguageSectionSubtitle;
  String get kThemeSectionTitle;
  String get kThemeSectionSubtitle;
  String get kThemeLight;
  String get kThemeDark;
  String get kThemeSystem;
  String get kUnitsSectionTitle;
  String get kUnitsSectionSubtitle;
  String get kSurfaceUnitsTitle;
  String get kTemperatureUnitsTitle;
  String get kUnitManzanas;
  String get kUnitManzanasShort;
  String get kUnitCelsius;
  String get kUnitFahrenheit;
  String get kUnitCelsiusShort;
  String get kUnitFahrenheitShort;
  String get kSettingsSaved;

  // Subplot Details & Management
  String get kLotDetailsTitle;
  String get kSubplotsTitle;
  String get kAddNewSubplot;
  String get kEditSubplot;
  String get kDeleteSubplot;
  String get kDeleteSubplotConfirm;
  String get kDeleteSubplotWarning;
  String get kSubplotCreatedSuccessfully;
  String get kSubplotUpdatedSuccessfully;
  String get kSubplotDeletedSuccessfully;
  String get kSaveSubplot;
  String get kLotAllocation;
  String get kTotalLotSurface;
  String get kAllocatedToSubplots;
  String get kUnallocatedFromLot;
  String get kNoSubplotsYet;
  String get kNoSubplotsSubtitle;
  String get kExceededLotSurfaceWarning;

  // Soil Classification
  String get kSoilTypeLabel;
  String get kSoilTypeHint;
  String get kSoilComposition;
  String get kSoilLoam;
  String get kSoilClay;
  String get kSoilSandy;
  String get kSoilClayLoam;
  String get kSoilSandyLoam;
  String get kSoilSilt;
  String get kSoilOrganic;
  String get kSoilRocky;
  String get kSoilUnknown;

  // Crop Selection & Management
  String get kCropLabel;
  String get kCropHint;
  String get kAssignCrop;
  String get kChangeCrop;
  String get kNoCropAssigned;
  String get kClearCrop;
  String get kPopularCrops;
  String get kAllCrops;
  String get kSearchCropHint;
  String get kCategoryGrains;
  String get kCategoryFruits;
  String get kCategoryCommercial;
  String get kCropUpdatedSuccessfully;

  // Agroclimatic Predictions Screen
  String get kPredictionsTitle;
  String get kPredictionsSubtitle;
  String get kAskIvyTooltip;
  String get kTabIrrigation;
  String get kTabRotation;
  String get kTabPlantingGdd;
  String get kTabVigorNdvi;
  String get kTabRisks;
  String get kTabNutrition;
  String get kPredictionContext;
  String get kWhatIfSimulator;
  String get kWholeFarmGeneral;
  String get kCropPrefix;
  String get kSoilPrefix;
  String get kMetricRootMoisture;
  String get kMetricRootMoistureSub;
  String get kMetric7dDeficit;
  String get kMetric7dDeficitSub;
  String get kMetricReserveDays;
  String get kMetricReserveDaysSub;
  String get kMetricRequiredDepth;
  String get kMetricRequiredDepthSub;
  String get kSoilImpactTitle;
  String get kSoilImpactDescription;
  String get kCorridorRiskTitle;
  String get kCorridorRiskDescription;
  String get kAgroJustificationTitle;
  String get kAlternativeCropsTitle;
  String get kOptimalCropPrefix;
  String get kMetricThermalSumGdd;
  String get kMetricThermalSumGddSub;
  String get kMetricDaysToFlowering;
  String get kRecommendedRangePrefix;
  String get kMetricNdviProxy;
  String get kMetricNdviProxySub;
  String get kMetricRelativeYield;
  String get kMetricRelativeYieldSub;
  String get kMetricBiologicalNFixation;
  String get kMetricNBalancePerHa;
  String get kMetricUreaSavings;
  String get kMetricSoilHealthScore;
  String get kMetricSoilHealthScoreSub;
  String get kSimulatorTitle;
  String get kSimulatorCropQuestion;
  String get kSimulatorSoilQuestion;
  String get kSimulatorApplyButton;
  String get kAskIvyButton;
  String get kIvyCopilotTitle;
  String get kIvyAnalyzingScenario;
  String get kIvyInputHint;
  String get kIvyErrorMessage;
  String get kStatusAttentionRequired;
  String get kStatusPlanIrrigation;
  String get kStatusOptimalMoisture;
  String get kSynergyLabel;
  String get kBiologicalNFixationPerHa;
  String get kUreaSavingsShort;
  String get kDaysUnit;
  String get kIvyInitialPrompt;
  String get kVisualParcelView;
  String get kCompactListView;
  String get kSoilBalancedDesc;
  String get kSoilClayDesc;
  String get kSoilSandyDesc;
  String get kSoilSiltDesc;
  String get kActiveSubplotBadge;
  String get kTapToInspectSubplot;

  // Prediction Engine Localized Messages
  String get kIrrigationUrgentTitle;
  String get kIrrigationModerateTitle;
  String get kIrrigationOptimalTitle;
  String kIrrigationUrgentRec(Object moisture, Object soil, Object crop, Object kc, Object waterMm);
  String kIrrigationModerateRec(Object soil, Object days, Object waterMm);
  String kIrrigationOptimalRec(Object moisture, Object crop, Object soil);

  String get kCompatibilityHigh;
  String get kCompatibilityMedium;
  String get kCompatibilityDiscouraged;
  String get kCropBeansLegume;
  String get kCropCornSorghumGrass;
  String get kCropRedBeansLegume;
  String get kCropDroughtBeansSorghum;
  String get kCropCrotalariaManure;
  String get kCropSoybean;
  String get kCropTolerantSorghum;
  String get kCropCrotalariaGreenManure;
  String get kCropVegetables;
  String get kCropSesame;
  String get kCropSunflower;
  String get kFamilyUnknown;
  String kRotationCorridorRiskExp(Object family, Object crop);
  String kRotationStandardExp(Object currentCrop, Object suggestedCrop);

  String get kWindowStatusOptimal;
  String get kWindowStatusWaitMoisture;
  String get kDateRangeNext10To14Days;
  String get kDateRangePostponeUntilRain;
  String kThermalAdviceFavorable(Object gdd);
  String kThermalAdviceMoistureLow(Object moisturePct);

  String get kVigorStatusExcellent;
  String get kVigorStatusNormal;
  String get kVigorStatusWaterStress;
  String get kBiomassConditionDense;
  String get kBiomassConditionNormal;
  String kBiomassConditionStress(Object lossPct);

  String get kRiskAlertFlashDroughtTitle;
  String get kRiskAlertWaterloggingTitle;
  String get kRiskAlertHeatStressTitle;
  String get kRiskAlertNoneTitle;
  String get kRiskAdviceFlashDroughtSandy;
  String get kRiskAdviceFlashDroughtStandard;
  String get kRiskAdviceWaterloggingClay;
  String get kRiskAdviceWaterloggingStandard;
  String get kRiskAdviceHeatStress;
  String get kRiskAdviceNone;

  String kSoilNutritionDiagnosisLegumeSandy(Object nGain, Object ureaSavings);
  String kSoilNutritionDiagnosisLegumeStandard(Object nGain, Object ureaSavings);
  String get kSoilNutritionDiagnosisCerealSandy;
  String get kSoilNutritionDiagnosisCerealStandard;

  String get kDefaultCropName;
  String get kDefaultSoilName;
}

class EngStrings implements AppStrings {
  const EngStrings();

  @override
  String get kOk => eng.kOk;
  @override
  String get kCancel => eng.kCancel;
  @override
  String get kSave => eng.kSave;
  @override
  String get kClose => eng.kClose;

  @override
  String get kFarmInfoTitle => eng.kFarmInfoTitle;
  @override
  String get kFarmer => eng.kFarmer;
  @override
  String get kFarm => eng.kFarm;
  @override
  String get kGeneralInfoSection => eng.kGeneralInfoSection;
  @override
  String get kLotsSectionTitle => eng.kLotsSectionTitle;
  @override
  String get kSubplotsSectionTitle => eng.kSubplotsSectionTitle;
  @override
  String get kSummaryTitle => eng.kSummaryTitle;

  @override
  String get kFarmNameLabel => eng.kFarmNameLabel;
  @override
  String get kFarmNameHint => eng.kFarmNameHint;
  @override
  String get kCountryLabel => eng.kCountryLabel;
  @override
  String get kCountryHint => eng.kCountryHint;
  @override
  String get kTotalSurfaceLabel => eng.kTotalSurfaceLabel;
  @override
  String get kTotalSurfaceHint => eng.kTotalSurfaceHint;
  @override
  String get kGeographicZoneLabel => eng.kGeographicZoneLabel;
  @override
  String get kGeographicZoneHint => eng.kGeographicZoneHint;

  @override
  String get kFarmLocationLabel => eng.kFarmLocationLabel;
  @override
  String get kWhereIsYourFarm => eng.kWhereIsYourFarm;
  @override
  String get kGetGpsLocationButton => eng.kGetGpsLocationButton;
  @override
  String get kGettingGpsLocation => eng.kGettingGpsLocation;
  @override
  String get kLatitudeLabel => eng.kLatitudeLabel;
  @override
  String get kLatitudeHint => eng.kLatitudeHint;
  @override
  String get kLongitudeLabel => eng.kLongitudeLabel;
  @override
  String get kLongitudeHint => eng.kLongitudeHint;
  @override
  String get kGpsSuccess => eng.kGpsSuccess;
  @override
  String get kGpsServiceDisabled => eng.kGpsServiceDisabled;
  @override
  String get kGpsPermissionDenied => eng.kGpsPermissionDenied;
  @override
  String get kGpsPermissionDeniedPermanently =>
      eng.kGpsPermissionDeniedPermanently;
  @override
  String get kGpsError => eng.kGpsError;
  @override
  String get kLocationNotCapturedYet => eng.kLocationNotCapturedYet;
  @override
  String get kRefreshLocation => eng.kRefreshLocation;
  @override
  String get kLocationRequired => eng.kLocationRequired;
  @override
  String get kGpsCoordinates => eng.kGpsCoordinates;

  @override
  String get kSurfaceUnitLabel => eng.kSurfaceUnitLabel;
  @override
  String get kSurfaceUnitHint => eng.kSurfaceUnitHint;
  @override
  String get kUnitHectares => eng.kUnitHectares;
  @override
  String get kUnitAcres => eng.kUnitAcres;
  @override
  String get kUnitSquareMeters => eng.kUnitSquareMeters;
  @override
  String get kUnitTareas => eng.kUnitTareas;
  @override
  String get kUnitHectaresShort => eng.kUnitHectaresShort;
  @override
  String get kUnitAcresShort => eng.kUnitAcresShort;
  @override
  String get kUnitSquareMetersShort => eng.kUnitSquareMetersShort;
  @override
  String get kUnitTareasShort => eng.kUnitTareasShort;

  @override
  String get kLotsCountLabel => eng.kLotsCountLabel;
  @override
  String get kLotsCountHint => eng.kLotsCountHint;
  @override
  String get kLot => eng.kLot;
  @override
  String get kLotNameLabel => eng.kLotNameLabel;
  @override
  String get kLotNameHint => eng.kLotNameHint;
  @override
  String get kLotSurfaceLabel => eng.kLotSurfaceLabel;
  @override
  String get kLotSurfaceHint => eng.kLotSurfaceHint;
  @override
  String get kAddLot => eng.kAddLot;
  @override
  String get kRemoveLot => eng.kRemoveLot;

  @override
  String get kSubplotsCountLabel => eng.kSubplotsCountLabel;
  @override
  String get kSubplotsCountHint => eng.kSubplotsCountHint;
  @override
  String get kSubplot => eng.kSubplot;
  @override
  String get kSubplotNameLabel => eng.kSubplotNameLabel;
  @override
  String get kSubplotNameHint => eng.kSubplotNameHint;
  @override
  String get kSubplotSurfaceLabel => eng.kSubplotSurfaceLabel;
  @override
  String get kSubplotSurfaceHint => eng.kSubplotSurfaceHint;
  @override
  String get kAddSubplot => eng.kAddSubplot;
  @override
  String get kRemoveSubplot => eng.kRemoveSubplot;
  @override
  String get kNoSubplots => eng.kNoSubplots;

  @override
  String get kFieldRequired => eng.kFieldRequired;
  @override
  String get kInvalidNumber => eng.kInvalidNumber;
  @override
  String get kLotsCountPositive => eng.kLotsCountPositive;
  @override
  String get kSubplotsCountPositive => eng.kSubplotsCountPositive;
  @override
  String get kLotsSurfaceExceededWarning => eng.kLotsSurfaceExceededWarning;
  @override
  String get kSubplotsSurfaceExceededWarning => eng.kSubplotsSurfaceExceededWarning;
  @override
  String get kFormSavedSuccessfully => eng.kFormSavedSuccessfully;
  @override
  String get kConfirmSave => eng.kConfirmSave;
  @override
  String get kErrorSavingData => eng.kErrorSavingData;

  @override
  String get kStep1Title => eng.kStep1Title;
  @override
  String get kStep2Title => eng.kStep2Title;
  @override
  String get kStep3Title => eng.kStep3Title;
  @override
  String get kQuickStartWholeFarm => eng.kQuickStartWholeFarm;
  @override
  String get kNextStep => eng.kNextStep;
  @override
  String get kPreviousStep => eng.kPreviousStep;
  @override
  String get kSingleLotMode => eng.kSingleLotMode;
  @override
  String get kMainLot => eng.kMainLot;
  @override
  String get kCustomLotsMode => eng.kCustomLotsMode;
  @override
  String get kAllocatedSurface => eng.kAllocatedSurface;
  @override
  String get kAskIvyTitle => eng.kAskIvyTitle;
  @override
  String get kNasaDataReady => eng.kNasaDataReady;
  @override
  String get kNoLotsAddedYet => eng.kNoLotsAddedYet;
  @override
  String get kLotsDistribution => eng.kLotsDistribution;
  @override
  String get kNasaDataDescription => eng.kNasaDataDescription;

  @override
  String get kDashboardGreeting => eng.kDashboardGreeting;
  @override
  String get kDashboardSubtitle => eng.kDashboardSubtitle;
  @override
  String get kDashboardWeatherSummary => eng.kDashboardWeatherSummary;
  @override
  String get kDashboardYourFarm => eng.kDashboardYourFarm;
  @override
  String get kDashboardFarmSize => eng.kDashboardFarmSize;
  @override
  String get kDashboardCurrentCrops => eng.kDashboardCurrentCrops;
  @override
  String get kDashboardViewDetails => eng.kDashboardViewDetails;
  @override
  String get kDashboardWhatToDo => eng.kDashboardWhatToDo;
  @override
  String get kDashboardAction1 => eng.kDashboardAction1;
  @override
  String get kDashboardAction2 => eng.kDashboardAction2;
  @override
  String get kDashboardAction3 => eng.kDashboardAction3;
  @override
  String get kNavHome => eng.kNavHome;
  @override
  String get kNavLots => eng.kNavLots;
  @override
  String get kNavRotations => eng.kNavRotations;
  @override
  String get kNavCommunity => eng.kNavCommunity;
  @override
  String get kNavMore => eng.kNavMore;

  // Lots Screen
  @override
  String get kLotsScreenTitle => eng.kLotsScreenTitle;
  @override
  String get kLotsScreenSubtitle => eng.kLotsScreenSubtitle;
  @override
  String get kSearchLotsHint => eng.kSearchLotsHint;
  @override
  String get kFilterAll => eng.kFilterAll;
  @override
  String get kFilterLargest => eng.kFilterLargest;
  @override
  String get kFilterSmallest => eng.kFilterSmallest;
  @override
  String get kFilterWithSubplots => eng.kFilterWithSubplots;
  @override
  String get kFilterPriorityTitle => eng.kFilterPriorityTitle;
  @override
  String get kRegisteredLotsTitle => eng.kRegisteredLotsTitle;
  @override
  String get kAddNewLot => eng.kAddNewLot;
  @override
  String get kEditLot => eng.kEditLot;
  @override
  String get kDeleteLot => eng.kDeleteLot;
  @override
  String get kDeleteLotConfirm => eng.kDeleteLotConfirm;
  @override
  String get kDeleteLotWarning => eng.kDeleteLotWarning;
  @override
  String get kLotNamePrompt => eng.kLotNamePrompt;
  @override
  String get kLotSurfacePrompt => eng.kLotSurfacePrompt;
  @override
  String get kLotUpdatedSuccessfully => eng.kLotUpdatedSuccessfully;
  @override
  String get kLotCreatedSuccessfully => eng.kLotCreatedSuccessfully;
  @override
  String get kLotDeletedSuccessfully => eng.kLotDeletedSuccessfully;
  @override
  String get kNoLotsFound => eng.kNoLotsFound;
  @override
  String get kNoLotsYetSubtitle => eng.kNoLotsYetSubtitle;
  @override
  String get kSubplotsCount => eng.kSubplotsCount;
  @override
  String get kSubplotSingular => eng.kSubplotSingular;
  @override
  String get kSaveLot => eng.kSaveLot;

  // Farm Details & Edit
  @override
  String get kFarmDetailsTitle => eng.kFarmDetailsTitle;
  @override
  String get kEditFarm => eng.kEditFarm;
  @override
  String get kEditFarmInfo => eng.kEditFarmInfo;
  @override
  String get kFarmOverview => eng.kFarmOverview;
  @override
  String get kLotsAndSubplots => eng.kLotsAndSubplots;
  @override
  String get kEnvironmentalContext => eng.kEnvironmentalContext;
  @override
  String get kSaveChanges => eng.kSaveChanges;
  @override
  String get kFarmUpdatedSuccessfully => eng.kFarmUpdatedSuccessfully;
  @override
  String get kTotalLots => eng.kTotalLots;
  @override
  String get kTotalSubplots => eng.kTotalSubplots;
  @override
  String get kNoLotsRegistered => eng.kNoLotsRegistered;
  @override
  String get kLandAllocation => eng.kLandAllocation;
  @override
  String get kSoilMoisture => eng.kSoilMoisture;
  @override
  String get kSolarRadiation => eng.kSolarRadiation;
  @override
  String get kPrecipitation => eng.kPrecipitation;
  @override
  String get kTemperature => eng.kTemperature;
  @override
  String get kUnallocatedSurface => eng.kUnallocatedSurface;
  @override
  String get kGpsSynchronized => eng.kGpsSynchronized;
  @override
  String get kNoFarmsFound => eng.kNoFarmsFound;

  @override
  String get kLanguage => eng.kLanguage;
  @override
  String get kEnglish => eng.kEnglish;
  @override
  String get kSpanish => eng.kSpanish;

  // Settings Screen
  @override
  String get kSettingsTitle => eng.kSettingsTitle;
  @override
  String get kSettingsSubtitle => eng.kSettingsSubtitle;
  @override
  String get kLanguageSectionTitle => eng.kLanguageSectionTitle;
  @override
  String get kLanguageSectionSubtitle => eng.kLanguageSectionSubtitle;
  @override
  String get kThemeSectionTitle => eng.kThemeSectionTitle;
  @override
  String get kThemeSectionSubtitle => eng.kThemeSectionSubtitle;
  @override
  String get kThemeLight => eng.kThemeLight;
  @override
  String get kThemeDark => eng.kThemeDark;
  @override
  String get kThemeSystem => eng.kThemeSystem;
  @override
  String get kUnitsSectionTitle => eng.kUnitsSectionTitle;
  @override
  String get kUnitsSectionSubtitle => eng.kUnitsSectionSubtitle;
  @override
  String get kSurfaceUnitsTitle => eng.kSurfaceUnitsTitle;
  @override
  String get kTemperatureUnitsTitle => eng.kTemperatureUnitsTitle;
  @override
  String get kUnitManzanas => eng.kUnitManzanas;
  @override
  String get kUnitManzanasShort => eng.kUnitManzanasShort;
  @override
  String get kUnitCelsius => eng.kUnitCelsius;
  @override
  String get kUnitFahrenheit => eng.kUnitFahrenheit;
  @override
  String get kUnitCelsiusShort => eng.kUnitCelsiusShort;
  @override
  String get kUnitFahrenheitShort => eng.kUnitFahrenheitShort;
  @override
  String get kSettingsSaved => eng.kSettingsSaved;

  // Subplot Details & Management
  @override
  String get kLotDetailsTitle => eng.kLotDetailsTitle;
  @override
  String get kSubplotsTitle => eng.kSubplotsTitle;
  @override
  String get kAddNewSubplot => eng.kAddNewSubplot;
  @override
  String get kEditSubplot => eng.kEditSubplot;
  @override
  String get kDeleteSubplot => eng.kDeleteSubplot;
  @override
  String get kDeleteSubplotConfirm => eng.kDeleteSubplotConfirm;
  @override
  String get kDeleteSubplotWarning => eng.kDeleteSubplotWarning;
  @override
  String get kSubplotCreatedSuccessfully => eng.kSubplotCreatedSuccessfully;
  @override
  String get kSubplotUpdatedSuccessfully => eng.kSubplotUpdatedSuccessfully;
  @override
  String get kSubplotDeletedSuccessfully => eng.kSubplotDeletedSuccessfully;
  @override
  String get kSaveSubplot => eng.kSaveSubplot;
  @override
  String get kLotAllocation => eng.kLotAllocation;
  @override
  String get kTotalLotSurface => eng.kTotalLotSurface;
  @override
  String get kAllocatedToSubplots => eng.kAllocatedToSubplots;
  @override
  String get kUnallocatedFromLot => eng.kUnallocatedFromLot;
  @override
  String get kNoSubplotsYet => eng.kNoSubplotsYet;
  @override
  String get kNoSubplotsSubtitle => eng.kNoSubplotsSubtitle;
  @override
  String get kExceededLotSurfaceWarning => eng.kExceededLotSurfaceWarning;

  // Soil Classification
  @override
  String get kSoilTypeLabel => eng.kSoilTypeLabel;
  @override
  String get kSoilTypeHint => eng.kSoilTypeHint;
  @override
  String get kSoilComposition => eng.kSoilComposition;
  @override
  String get kSoilLoam => eng.kSoilLoam;
  @override
  String get kSoilClay => eng.kSoilClay;
  @override
  String get kSoilSandy => eng.kSoilSandy;
  @override
  String get kSoilClayLoam => eng.kSoilClayLoam;
  @override
  String get kSoilSandyLoam => eng.kSoilSandyLoam;
  @override
  String get kSoilSilt => eng.kSoilSilt;
  @override
  String get kSoilOrganic => eng.kSoilOrganic;
  @override
  String get kSoilRocky => eng.kSoilRocky;
  @override
  String get kSoilUnknown => eng.kSoilUnknown;

  // Crop Selection & Management
  @override
  String get kCropLabel => eng.kCropLabel;
  @override
  String get kCropHint => eng.kCropHint;
  @override
  String get kAssignCrop => eng.kAssignCrop;
  @override
  String get kChangeCrop => eng.kChangeCrop;
  @override
  String get kNoCropAssigned => eng.kNoCropAssigned;
  @override
  String get kClearCrop => eng.kClearCrop;
  @override
  String get kPopularCrops => eng.kPopularCrops;
  @override
  String get kAllCrops => eng.kAllCrops;
  @override
  String get kSearchCropHint => eng.kSearchCropHint;
  @override
  String get kCategoryGrains => eng.kCategoryGrains;
  @override
  String get kCategoryFruits => eng.kCategoryFruits;
  @override
  String get kCategoryCommercial => eng.kCategoryCommercial;
  @override
  String get kCropUpdatedSuccessfully => eng.kCropUpdatedSuccessfully;

  // Agroclimatic Predictions Screen
  @override
  String get kPredictionsTitle => eng.kPredictionsTitle;
  @override
  String get kPredictionsSubtitle => eng.kPredictionsSubtitle;
  @override
  String get kAskIvyTooltip => eng.kAskIvyTooltip;
  @override
  String get kTabIrrigation => eng.kTabIrrigation;
  @override
  String get kTabRotation => eng.kTabRotation;
  @override
  String get kTabPlantingGdd => eng.kTabPlantingGdd;
  @override
  String get kTabVigorNdvi => eng.kTabVigorNdvi;
  @override
  String get kTabRisks => eng.kTabRisks;
  @override
  String get kTabNutrition => eng.kTabNutrition;
  @override
  String get kPredictionContext => eng.kPredictionContext;
  @override
  String get kWhatIfSimulator => eng.kWhatIfSimulator;
  @override
  String get kWholeFarmGeneral => eng.kWholeFarmGeneral;
  @override
  String get kCropPrefix => eng.kCropPrefix;
  @override
  String get kSoilPrefix => eng.kSoilPrefix;
  @override
  String get kMetricRootMoisture => eng.kMetricRootMoisture;
  @override
  String get kMetricRootMoistureSub => eng.kMetricRootMoistureSub;
  @override
  String get kMetric7dDeficit => eng.kMetric7dDeficit;
  @override
  String get kMetric7dDeficitSub => eng.kMetric7dDeficitSub;
  @override
  String get kMetricReserveDays => eng.kMetricReserveDays;
  @override
  String get kMetricReserveDaysSub => eng.kMetricReserveDaysSub;
  @override
  String get kMetricRequiredDepth => eng.kMetricRequiredDepth;
  @override
  String get kMetricRequiredDepthSub => eng.kMetricRequiredDepthSub;
  @override
  String get kSoilImpactTitle => eng.kSoilImpactTitle;
  @override
  String get kSoilImpactDescription => eng.kSoilImpactDescription;
  @override
  String get kCorridorRiskTitle => eng.kCorridorRiskTitle;
  @override
  String get kCorridorRiskDescription => eng.kCorridorRiskDescription;
  @override
  String get kAgroJustificationTitle => eng.kAgroJustificationTitle;
  @override
  String get kAlternativeCropsTitle => eng.kAlternativeCropsTitle;
  @override
  String get kOptimalCropPrefix => eng.kOptimalCropPrefix;
  @override
  String get kMetricThermalSumGdd => eng.kMetricThermalSumGdd;
  @override
  String get kMetricThermalSumGddSub => eng.kMetricThermalSumGddSub;
  @override
  String get kMetricDaysToFlowering => eng.kMetricDaysToFlowering;
  @override
  String get kRecommendedRangePrefix => eng.kRecommendedRangePrefix;
  @override
  String get kMetricNdviProxy => eng.kMetricNdviProxy;
  @override
  String get kMetricNdviProxySub => eng.kMetricNdviProxySub;
  @override
  String get kMetricRelativeYield => eng.kMetricRelativeYield;
  @override
  String get kMetricRelativeYieldSub => eng.kMetricRelativeYieldSub;
  @override
  String get kMetricBiologicalNFixation => eng.kMetricBiologicalNFixation;
  @override
  String get kMetricNBalancePerHa => eng.kMetricNBalancePerHa;
  @override
  String get kMetricUreaSavings => eng.kMetricUreaSavings;
  @override
  String get kMetricSoilHealthScore => eng.kMetricSoilHealthScore;
  @override
  String get kMetricSoilHealthScoreSub => eng.kMetricSoilHealthScoreSub;
  @override
  String get kSimulatorTitle => eng.kSimulatorTitle;
  @override
  String get kSimulatorCropQuestion => eng.kSimulatorCropQuestion;
  @override
  String get kSimulatorSoilQuestion => eng.kSimulatorSoilQuestion;
  @override
  String get kSimulatorApplyButton => eng.kSimulatorApplyButton;
  @override
  String get kAskIvyButton => eng.kAskIvyButton;
  @override
  String get kIvyCopilotTitle => eng.kIvyCopilotTitle;
  @override
  String get kIvyAnalyzingScenario => eng.kIvyAnalyzingScenario;
  @override
  String get kIvyInputHint => eng.kIvyInputHint;
  @override
  String get kIvyErrorMessage => eng.kIvyErrorMessage;
  @override
  String get kStatusAttentionRequired => eng.kStatusAttentionRequired;
  @override
  String get kStatusPlanIrrigation => eng.kStatusPlanIrrigation;
  @override
  String get kStatusOptimalMoisture => eng.kStatusOptimalMoisture;
  @override
  String get kSynergyLabel => eng.kSynergyLabel;
  @override
  String get kBiologicalNFixationPerHa => eng.kBiologicalNFixationPerHa;
  @override
  String get kUreaSavingsShort => eng.kUreaSavingsShort;
  @override
  String get kDaysUnit => eng.kDaysUnit;
  @override
  String get kIvyInitialPrompt => eng.kIvyInitialPrompt;
  @override
  String get kVisualParcelView => eng.kVisualParcelView;
  @override
  String get kCompactListView => eng.kCompactListView;
  @override
  String get kSoilBalancedDesc => eng.kSoilBalancedDesc;
  @override
  String get kSoilClayDesc => eng.kSoilClayDesc;
  @override
  String get kSoilSandyDesc => eng.kSoilSandyDesc;
  @override
  String get kSoilSiltDesc => eng.kSoilSiltDesc;
  @override
  String get kActiveSubplotBadge => eng.kActiveSubplotBadge;
  @override
  String get kTapToInspectSubplot => eng.kTapToInspectSubplot;

  // Prediction Engine Localized Messages
  @override
  String get kIrrigationUrgentTitle => eng.kIrrigationUrgentTitle;
  @override
  String get kIrrigationModerateTitle => eng.kIrrigationModerateTitle;
  @override
  String get kIrrigationOptimalTitle => eng.kIrrigationOptimalTitle;
  @override
  String kIrrigationUrgentRec(Object moisture, Object soil, Object crop, Object kc, Object waterMm) =>
      eng.kIrrigationUrgentRec(moisture, soil, crop, kc, waterMm);
  @override
  String kIrrigationModerateRec(Object soil, Object days, Object waterMm) =>
      eng.kIrrigationModerateRec(soil, days, waterMm);
  @override
  String kIrrigationOptimalRec(Object moisture, Object crop, Object soil) =>
      eng.kIrrigationOptimalRec(moisture, crop, soil);

  @override
  String get kCompatibilityHigh => eng.kCompatibilityHigh;
  @override
  String get kCompatibilityMedium => eng.kCompatibilityMedium;
  @override
  String get kCompatibilityDiscouraged => eng.kCompatibilityDiscouraged;
  @override
  String get kCropBeansLegume => eng.kCropBeansLegume;
  @override
  String get kCropCornSorghumGrass => eng.kCropCornSorghumGrass;
  @override
  String get kCropRedBeansLegume => eng.kCropRedBeansLegume;
  @override
  String get kCropDroughtBeansSorghum => eng.kCropDroughtBeansSorghum;
  @override
  String get kCropCrotalariaManure => eng.kCropCrotalariaManure;
  @override
  String get kCropSoybean => eng.kCropSoybean;
  @override
  String get kCropTolerantSorghum => eng.kCropTolerantSorghum;
  @override
  String get kCropCrotalariaGreenManure => eng.kCropCrotalariaGreenManure;
  @override
  String get kCropVegetables => eng.kCropVegetables;
  @override
  String get kCropSesame => eng.kCropSesame;
  @override
  String get kCropSunflower => eng.kCropSunflower;
  @override
  String get kFamilyUnknown => eng.kFamilyUnknown;
  @override
  String kRotationCorridorRiskExp(Object family, Object crop) =>
      eng.kRotationCorridorRiskExp(family, crop);
  @override
  String kRotationStandardExp(Object currentCrop, Object suggestedCrop) =>
      eng.kRotationStandardExp(currentCrop, suggestedCrop);

  @override
  String get kWindowStatusOptimal => eng.kWindowStatusOptimal;
  @override
  String get kWindowStatusWaitMoisture => eng.kWindowStatusWaitMoisture;
  @override
  String get kDateRangeNext10To14Days => eng.kDateRangeNext10To14Days;
  @override
  String get kDateRangePostponeUntilRain => eng.kDateRangePostponeUntilRain;
  @override
  String kThermalAdviceFavorable(Object gdd) => eng.kThermalAdviceFavorable(gdd);
  @override
  String kThermalAdviceMoistureLow(Object moisturePct) => eng.kThermalAdviceMoistureLow(moisturePct);

  @override
  String get kVigorStatusExcellent => eng.kVigorStatusExcellent;
  @override
  String get kVigorStatusNormal => eng.kVigorStatusNormal;
  @override
  String get kVigorStatusWaterStress => eng.kVigorStatusWaterStress;
  @override
  String get kBiomassConditionDense => eng.kBiomassConditionDense;
  @override
  String get kBiomassConditionNormal => eng.kBiomassConditionNormal;
  @override
  String kBiomassConditionStress(Object lossPct) => eng.kBiomassConditionStress(lossPct);

  @override
  String get kRiskAlertFlashDroughtTitle => eng.kRiskAlertFlashDroughtTitle;
  @override
  String get kRiskAlertWaterloggingTitle => eng.kRiskAlertWaterloggingTitle;
  @override
  String get kRiskAlertHeatStressTitle => eng.kRiskAlertHeatStressTitle;
  @override
  String get kRiskAlertNoneTitle => eng.kRiskAlertNoneTitle;
  @override
  String get kRiskAdviceFlashDroughtSandy => eng.kRiskAdviceFlashDroughtSandy;
  @override
  String get kRiskAdviceFlashDroughtStandard => eng.kRiskAdviceFlashDroughtStandard;
  @override
  String get kRiskAdviceWaterloggingClay => eng.kRiskAdviceWaterloggingClay;
  @override
  String get kRiskAdviceWaterloggingStandard => eng.kRiskAdviceWaterloggingStandard;
  @override
  String get kRiskAdviceHeatStress => eng.kRiskAdviceHeatStress;
  @override
  String get kRiskAdviceNone => eng.kRiskAdviceNone;

  @override
  String kSoilNutritionDiagnosisLegumeSandy(Object nGain, Object ureaSavings) =>
      eng.kSoilNutritionDiagnosisLegumeSandy(nGain, ureaSavings);
  @override
  String kSoilNutritionDiagnosisLegumeStandard(Object nGain, Object ureaSavings) =>
      eng.kSoilNutritionDiagnosisLegumeStandard(nGain, ureaSavings);
  @override
  String get kSoilNutritionDiagnosisCerealSandy => eng.kSoilNutritionDiagnosisCerealSandy;
  @override
  String get kSoilNutritionDiagnosisCerealStandard => eng.kSoilNutritionDiagnosisCerealStandard;

  @override
  String get kDefaultCropName => eng.kDefaultCropName;
  @override
  String get kDefaultSoilName => eng.kDefaultSoilName;
}

class SpaStrings implements AppStrings {
  const SpaStrings();

  @override
  String get kOk => spa.kOk;
  @override
  String get kCancel => spa.kCancel;
  @override
  String get kSave => spa.kSave;
  @override
  String get kClose => spa.kClose;

  @override
  String get kFarmInfoTitle => spa.kFarmInfoTitle;
  @override
  String get kFarmer => spa.kFarmer;
  @override
  String get kFarm => spa.kFarm;
  @override
  String get kGeneralInfoSection => spa.kGeneralInfoSection;
  @override
  String get kLotsSectionTitle => spa.kLotsSectionTitle;
  @override
  String get kSubplotsSectionTitle => spa.kSubplotsSectionTitle;
  @override
  String get kSummaryTitle => spa.kSummaryTitle;

  @override
  String get kFarmNameLabel => spa.kFarmNameLabel;
  @override
  String get kFarmNameHint => spa.kFarmNameHint;
  @override
  String get kCountryLabel => spa.kCountryLabel;
  @override
  String get kCountryHint => spa.kCountryHint;
  @override
  String get kTotalSurfaceLabel => spa.kTotalSurfaceLabel;
  @override
  String get kTotalSurfaceHint => spa.kTotalSurfaceHint;
  @override
  String get kGeographicZoneLabel => spa.kGeographicZoneLabel;
  @override
  String get kGeographicZoneHint => spa.kGeographicZoneHint;

  @override
  String get kFarmLocationLabel => spa.kFarmLocationLabel;
  @override
  String get kWhereIsYourFarm => spa.kWhereIsYourFarm;
  @override
  String get kGetGpsLocationButton => spa.kGetGpsLocationButton;
  @override
  String get kGettingGpsLocation => spa.kGettingGpsLocation;
  @override
  String get kLatitudeLabel => spa.kLatitudeLabel;
  @override
  String get kLatitudeHint => spa.kLatitudeHint;
  @override
  String get kLongitudeLabel => spa.kLongitudeLabel;
  @override
  String get kLongitudeHint => spa.kLongitudeHint;
  @override
  String get kGpsSuccess => spa.kGpsSuccess;
  @override
  String get kGpsServiceDisabled => spa.kGpsServiceDisabled;
  @override
  String get kGpsPermissionDenied => spa.kGpsPermissionDenied;
  @override
  String get kGpsPermissionDeniedPermanently =>
      spa.kGpsPermissionDeniedPermanently;
  @override
  String get kGpsError => spa.kGpsError;
  @override
  String get kLocationNotCapturedYet => spa.kLocationNotCapturedYet;
  @override
  String get kRefreshLocation => spa.kRefreshLocation;
  @override
  String get kLocationRequired => spa.kLocationRequired;
  @override
  String get kGpsCoordinates => spa.kGpsCoordinates;

  @override
  String get kSurfaceUnitLabel => spa.kSurfaceUnitLabel;
  @override
  String get kSurfaceUnitHint => spa.kSurfaceUnitHint;
  @override
  String get kUnitHectares => spa.kUnitHectares;
  @override
  String get kUnitAcres => spa.kUnitAcres;
  @override
  String get kUnitSquareMeters => spa.kUnitSquareMeters;
  @override
  String get kUnitTareas => spa.kUnitTareas;
  @override
  String get kUnitHectaresShort => spa.kUnitHectaresShort;
  @override
  String get kUnitAcresShort => spa.kUnitAcresShort;
  @override
  String get kUnitSquareMetersShort => spa.kUnitSquareMetersShort;
  @override
  String get kUnitTareasShort => spa.kUnitTareasShort;

  @override
  String get kLotsCountLabel => spa.kLotsCountLabel;
  @override
  String get kLotsCountHint => spa.kLotsCountHint;
  @override
  String get kLot => spa.kLot;
  @override
  String get kLotNameLabel => spa.kLotNameLabel;
  @override
  String get kLotNameHint => spa.kLotNameHint;
  @override
  String get kLotSurfaceLabel => spa.kLotSurfaceLabel;
  @override
  String get kLotSurfaceHint => spa.kLotSurfaceHint;
  @override
  String get kAddLot => spa.kAddLot;
  @override
  String get kRemoveLot => spa.kRemoveLot;

  @override
  String get kSubplotsCountLabel => spa.kSubplotsCountLabel;
  @override
  String get kSubplotsCountHint => spa.kSubplotsCountHint;
  @override
  String get kSubplot => spa.kSubplot;
  @override
  String get kSubplotNameLabel => spa.kSubplotNameLabel;
  @override
  String get kSubplotNameHint => spa.kSubplotNameHint;
  @override
  String get kSubplotSurfaceLabel => spa.kSubplotSurfaceLabel;
  @override
  String get kSubplotSurfaceHint => spa.kSubplotSurfaceHint;
  @override
  String get kAddSubplot => spa.kAddSubplot;
  @override
  String get kRemoveSubplot => spa.kRemoveSubplot;
  @override
  String get kNoSubplots => spa.kNoSubplots;

  @override
  String get kFieldRequired => spa.kFieldRequired;
  @override
  String get kInvalidNumber => spa.kInvalidNumber;
  @override
  String get kLotsCountPositive => spa.kLotsCountPositive;
  @override
  String get kSubplotsCountPositive => spa.kSubplotsCountPositive;
  @override
  String get kLotsSurfaceExceededWarning => spa.kLotsSurfaceExceededWarning;
  @override
  String get kSubplotsSurfaceExceededWarning => spa.kSubplotsSurfaceExceededWarning;
  @override
  String get kFormSavedSuccessfully => spa.kFormSavedSuccessfully;
  @override
  String get kConfirmSave => spa.kConfirmSave;
  @override
  String get kErrorSavingData => spa.kErrorSavingData;

  @override
  String get kStep1Title => spa.kStep1Title;
  @override
  String get kStep2Title => spa.kStep2Title;
  @override
  String get kStep3Title => spa.kStep3Title;
  @override
  String get kQuickStartWholeFarm => spa.kQuickStartWholeFarm;
  @override
  String get kNextStep => spa.kNextStep;
  @override
  String get kPreviousStep => spa.kPreviousStep;
  @override
  String get kSingleLotMode => spa.kSingleLotMode;
  @override
  String get kMainLot => spa.kMainLot;
  @override
  String get kCustomLotsMode => spa.kCustomLotsMode;
  @override
  String get kAllocatedSurface => spa.kAllocatedSurface;
  @override
  String get kAskIvyTitle => spa.kAskIvyTitle;
  @override
  String get kNasaDataReady => spa.kNasaDataReady;
  @override
  String get kNoLotsAddedYet => spa.kNoLotsAddedYet;
  @override
  String get kLotsDistribution => spa.kLotsDistribution;
  @override
  String get kNasaDataDescription => spa.kNasaDataDescription;

  @override
  String get kDashboardGreeting => spa.kDashboardGreeting;
  @override
  String get kDashboardSubtitle => spa.kDashboardSubtitle;
  @override
  String get kDashboardWeatherSummary => spa.kDashboardWeatherSummary;
  @override
  String get kDashboardYourFarm => spa.kDashboardYourFarm;
  @override
  String get kDashboardFarmSize => spa.kDashboardFarmSize;
  @override
  String get kDashboardCurrentCrops => spa.kDashboardCurrentCrops;
  @override
  String get kDashboardViewDetails => spa.kDashboardViewDetails;
  @override
  String get kDashboardWhatToDo => spa.kDashboardWhatToDo;
  @override
  String get kDashboardAction1 => spa.kDashboardAction1;
  @override
  String get kDashboardAction2 => spa.kDashboardAction2;
  @override
  String get kDashboardAction3 => spa.kDashboardAction3;
  @override
  String get kNavHome => spa.kNavHome;
  @override
  String get kNavLots => spa.kNavLots;
  @override
  String get kNavRotations => spa.kNavRotations;
  @override
  String get kNavCommunity => spa.kNavCommunity;
  @override
  String get kNavMore => spa.kNavMore;

  // Lots Screen
  @override
  String get kLotsScreenTitle => spa.kLotsScreenTitle;
  @override
  String get kLotsScreenSubtitle => spa.kLotsScreenSubtitle;
  @override
  String get kSearchLotsHint => spa.kSearchLotsHint;
  @override
  String get kFilterAll => spa.kFilterAll;
  @override
  String get kFilterLargest => spa.kFilterLargest;
  @override
  String get kFilterSmallest => spa.kFilterSmallest;
  @override
  String get kFilterWithSubplots => spa.kFilterWithSubplots;
  @override
  String get kFilterPriorityTitle => spa.kFilterPriorityTitle;
  @override
  String get kRegisteredLotsTitle => spa.kRegisteredLotsTitle;
  @override
  String get kAddNewLot => spa.kAddNewLot;
  @override
  String get kEditLot => spa.kEditLot;
  @override
  String get kDeleteLot => spa.kDeleteLot;
  @override
  String get kDeleteLotConfirm => spa.kDeleteLotConfirm;
  @override
  String get kDeleteLotWarning => spa.kDeleteLotWarning;
  @override
  String get kLotNamePrompt => spa.kLotNamePrompt;
  @override
  String get kLotSurfacePrompt => spa.kLotSurfacePrompt;
  @override
  String get kLotUpdatedSuccessfully => spa.kLotUpdatedSuccessfully;
  @override
  String get kLotCreatedSuccessfully => spa.kLotCreatedSuccessfully;
  @override
  String get kLotDeletedSuccessfully => spa.kLotDeletedSuccessfully;
  @override
  String get kNoLotsFound => spa.kNoLotsFound;
  @override
  String get kNoLotsYetSubtitle => spa.kNoLotsYetSubtitle;
  @override
  String get kSubplotsCount => spa.kSubplotsCount;
  @override
  String get kSubplotSingular => spa.kSubplotSingular;
  @override
  String get kSaveLot => spa.kSaveLot;

  // Farm Details & Edit
  @override
  String get kFarmDetailsTitle => spa.kFarmDetailsTitle;
  @override
  String get kEditFarm => spa.kEditFarm;
  @override
  String get kEditFarmInfo => spa.kEditFarmInfo;
  @override
  String get kFarmOverview => spa.kFarmOverview;
  @override
  String get kLotsAndSubplots => spa.kLotsAndSubplots;
  @override
  String get kEnvironmentalContext => spa.kEnvironmentalContext;
  @override
  String get kSaveChanges => spa.kSaveChanges;
  @override
  String get kFarmUpdatedSuccessfully => spa.kFarmUpdatedSuccessfully;
  @override
  String get kTotalLots => spa.kTotalLots;
  @override
  String get kTotalSubplots => spa.kTotalSubplots;
  @override
  String get kNoLotsRegistered => spa.kNoLotsRegistered;
  @override
  String get kLandAllocation => spa.kLandAllocation;
  @override
  String get kSoilMoisture => spa.kSoilMoisture;
  @override
  String get kSolarRadiation => spa.kSolarRadiation;
  @override
  String get kPrecipitation => spa.kPrecipitation;
  @override
  String get kTemperature => spa.kTemperature;
  @override
  String get kUnallocatedSurface => spa.kUnallocatedSurface;
  @override
  String get kGpsSynchronized => spa.kGpsSynchronized;
  @override
  String get kNoFarmsFound => spa.kNoFarmsFound;

  @override
  String get kLanguage => spa.kLanguage;
  @override
  String get kEnglish => spa.kEnglish;
  @override
  String get kSpanish => spa.kSpanish;

  // Settings Screen
  @override
  String get kSettingsTitle => spa.kSettingsTitle;
  @override
  String get kSettingsSubtitle => spa.kSettingsSubtitle;
  @override
  String get kLanguageSectionTitle => spa.kLanguageSectionTitle;
  @override
  String get kLanguageSectionSubtitle => spa.kLanguageSectionSubtitle;
  @override
  String get kThemeSectionTitle => spa.kThemeSectionTitle;
  @override
  String get kThemeSectionSubtitle => spa.kThemeSectionSubtitle;
  @override
  String get kThemeLight => spa.kThemeLight;
  @override
  String get kThemeDark => spa.kThemeDark;
  @override
  String get kThemeSystem => spa.kThemeSystem;
  @override
  String get kUnitsSectionTitle => spa.kUnitsSectionTitle;
  @override
  String get kUnitsSectionSubtitle => spa.kUnitsSectionSubtitle;
  @override
  String get kSurfaceUnitsTitle => spa.kSurfaceUnitsTitle;
  @override
  String get kTemperatureUnitsTitle => spa.kTemperatureUnitsTitle;
  @override
  String get kUnitManzanas => spa.kUnitManzanas;
  @override
  String get kUnitManzanasShort => spa.kUnitManzanasShort;
  @override
  String get kUnitCelsius => spa.kUnitCelsius;
  @override
  String get kUnitFahrenheit => spa.kUnitFahrenheit;
  @override
  String get kUnitCelsiusShort => spa.kUnitCelsiusShort;
  @override
  String get kUnitFahrenheitShort => spa.kUnitFahrenheitShort;
  @override
  String get kSettingsSaved => spa.kSettingsSaved;

  // Subplot Details & Management
  @override
  String get kLotDetailsTitle => spa.kLotDetailsTitle;
  @override
  String get kSubplotsTitle => spa.kSubplotsTitle;
  @override
  String get kAddNewSubplot => spa.kAddNewSubplot;
  @override
  String get kEditSubplot => spa.kEditSubplot;
  @override
  String get kDeleteSubplot => spa.kDeleteSubplot;
  @override
  String get kDeleteSubplotConfirm => spa.kDeleteSubplotConfirm;
  @override
  String get kDeleteSubplotWarning => spa.kDeleteSubplotWarning;
  @override
  String get kSubplotCreatedSuccessfully => spa.kSubplotCreatedSuccessfully;
  @override
  String get kSubplotUpdatedSuccessfully => spa.kSubplotUpdatedSuccessfully;
  @override
  String get kSubplotDeletedSuccessfully => spa.kSubplotDeletedSuccessfully;
  @override
  String get kSaveSubplot => spa.kSaveSubplot;
  @override
  String get kLotAllocation => spa.kLotAllocation;
  @override
  String get kTotalLotSurface => spa.kTotalLotSurface;
  @override
  String get kAllocatedToSubplots => spa.kAllocatedToSubplots;
  @override
  String get kUnallocatedFromLot => spa.kUnallocatedFromLot;
  @override
  String get kNoSubplotsYet => spa.kNoSubplotsYet;
  @override
  String get kNoSubplotsSubtitle => spa.kNoSubplotsSubtitle;
  @override
  String get kExceededLotSurfaceWarning => spa.kExceededLotSurfaceWarning;

  // Soil Classification
  @override
  String get kSoilTypeLabel => spa.kSoilTypeLabel;
  @override
  String get kSoilTypeHint => spa.kSoilTypeHint;
  @override
  String get kSoilComposition => spa.kSoilComposition;
  @override
  String get kSoilLoam => spa.kSoilLoam;
  @override
  String get kSoilClay => spa.kSoilClay;
  @override
  String get kSoilSandy => spa.kSoilSandy;
  @override
  String get kSoilClayLoam => spa.kSoilClayLoam;
  @override
  String get kSoilSandyLoam => spa.kSoilSandyLoam;
  @override
  String get kSoilSilt => spa.kSoilSilt;
  @override
  String get kSoilOrganic => spa.kSoilOrganic;
  @override
  String get kSoilRocky => spa.kSoilRocky;
  @override
  String get kSoilUnknown => spa.kSoilUnknown;

  // Crop Selection & Management
  @override
  String get kCropLabel => spa.kCropLabel;
  @override
  String get kCropHint => spa.kCropHint;
  @override
  String get kAssignCrop => spa.kAssignCrop;
  @override
  String get kChangeCrop => spa.kChangeCrop;
  @override
  String get kNoCropAssigned => spa.kNoCropAssigned;
  @override
  String get kClearCrop => spa.kClearCrop;
  @override
  String get kPopularCrops => spa.kPopularCrops;
  @override
  String get kAllCrops => spa.kAllCrops;
  @override
  String get kSearchCropHint => spa.kSearchCropHint;
  @override
  String get kCategoryGrains => spa.kCategoryGrains;
  @override
  String get kCategoryFruits => spa.kCategoryFruits;
  @override
  String get kCategoryCommercial => spa.kCategoryCommercial;
  @override
  String get kCropUpdatedSuccessfully => spa.kCropUpdatedSuccessfully;

  // Agroclimatic Predictions Screen
  @override
  String get kPredictionsTitle => spa.kPredictionsTitle;
  @override
  String get kPredictionsSubtitle => spa.kPredictionsSubtitle;
  @override
  String get kAskIvyTooltip => spa.kAskIvyTooltip;
  @override
  String get kTabIrrigation => spa.kTabIrrigation;
  @override
  String get kTabRotation => spa.kTabRotation;
  @override
  String get kTabPlantingGdd => spa.kTabPlantingGdd;
  @override
  String get kTabVigorNdvi => spa.kTabVigorNdvi;
  @override
  String get kTabRisks => spa.kTabRisks;
  @override
  String get kTabNutrition => spa.kTabNutrition;
  @override
  String get kPredictionContext => spa.kPredictionContext;
  @override
  String get kWhatIfSimulator => spa.kWhatIfSimulator;
  @override
  String get kWholeFarmGeneral => spa.kWholeFarmGeneral;
  @override
  String get kCropPrefix => spa.kCropPrefix;
  @override
  String get kSoilPrefix => spa.kSoilPrefix;
  @override
  String get kMetricRootMoisture => spa.kMetricRootMoisture;
  @override
  String get kMetricRootMoistureSub => spa.kMetricRootMoistureSub;
  @override
  String get kMetric7dDeficit => spa.kMetric7dDeficit;
  @override
  String get kMetric7dDeficitSub => spa.kMetric7dDeficitSub;
  @override
  String get kMetricReserveDays => spa.kMetricReserveDays;
  @override
  String get kMetricReserveDaysSub => spa.kMetricReserveDaysSub;
  @override
  String get kMetricRequiredDepth => spa.kMetricRequiredDepth;
  @override
  String get kMetricRequiredDepthSub => spa.kMetricRequiredDepthSub;
  @override
  String get kSoilImpactTitle => spa.kSoilImpactTitle;
  @override
  String get kSoilImpactDescription => spa.kSoilImpactDescription;
  @override
  String get kCorridorRiskTitle => spa.kCorridorRiskTitle;
  @override
  String get kCorridorRiskDescription => spa.kCorridorRiskDescription;
  @override
  String get kAgroJustificationTitle => spa.kAgroJustificationTitle;
  @override
  String get kAlternativeCropsTitle => spa.kAlternativeCropsTitle;
  @override
  String get kOptimalCropPrefix => spa.kOptimalCropPrefix;
  @override
  String get kMetricThermalSumGdd => spa.kMetricThermalSumGdd;
  @override
  String get kMetricThermalSumGddSub => spa.kMetricThermalSumGddSub;
  @override
  String get kMetricDaysToFlowering => spa.kMetricDaysToFlowering;
  @override
  String get kRecommendedRangePrefix => spa.kRecommendedRangePrefix;
  @override
  String get kMetricNdviProxy => spa.kMetricNdviProxy;
  @override
  String get kMetricNdviProxySub => spa.kMetricNdviProxySub;
  @override
  String get kMetricRelativeYield => spa.kMetricRelativeYield;
  @override
  String get kMetricRelativeYieldSub => spa.kMetricRelativeYieldSub;
  @override
  String get kMetricBiologicalNFixation => spa.kMetricBiologicalNFixation;
  @override
  String get kMetricNBalancePerHa => spa.kMetricNBalancePerHa;
  @override
  String get kMetricUreaSavings => spa.kMetricUreaSavings;
  @override
  String get kMetricSoilHealthScore => spa.kMetricSoilHealthScore;
  @override
  String get kMetricSoilHealthScoreSub => spa.kMetricSoilHealthScoreSub;
  @override
  String get kSimulatorTitle => spa.kSimulatorTitle;
  @override
  String get kSimulatorCropQuestion => spa.kSimulatorCropQuestion;
  @override
  String get kSimulatorSoilQuestion => spa.kSimulatorSoilQuestion;
  @override
  String get kSimulatorApplyButton => spa.kSimulatorApplyButton;
  @override
  String get kAskIvyButton => spa.kAskIvyButton;
  @override
  String get kIvyCopilotTitle => spa.kIvyCopilotTitle;
  @override
  String get kIvyAnalyzingScenario => spa.kIvyAnalyzingScenario;
  @override
  String get kIvyInputHint => spa.kIvyInputHint;
  @override
  String get kIvyErrorMessage => spa.kIvyErrorMessage;
  @override
  String get kStatusAttentionRequired => spa.kStatusAttentionRequired;
  @override
  String get kStatusPlanIrrigation => spa.kStatusPlanIrrigation;
  @override
  String get kStatusOptimalMoisture => spa.kStatusOptimalMoisture;
  @override
  String get kSynergyLabel => spa.kSynergyLabel;
  @override
  String get kBiologicalNFixationPerHa => spa.kBiologicalNFixationPerHa;
  @override
  String get kUreaSavingsShort => spa.kUreaSavingsShort;
  @override
  String get kDaysUnit => spa.kDaysUnit;
  @override
  String get kIvyInitialPrompt => spa.kIvyInitialPrompt;
  @override
  String get kVisualParcelView => spa.kVisualParcelView;
  @override
  String get kCompactListView => spa.kCompactListView;
  @override
  String get kSoilBalancedDesc => spa.kSoilBalancedDesc;
  @override
  String get kSoilClayDesc => spa.kSoilClayDesc;
  @override
  String get kSoilSandyDesc => spa.kSoilSandyDesc;
  @override
  String get kSoilSiltDesc => spa.kSoilSiltDesc;
  @override
  String get kActiveSubplotBadge => spa.kActiveSubplotBadge;
  @override
  String get kTapToInspectSubplot => spa.kTapToInspectSubplot;

  // Prediction Engine Localized Messages
  @override
  String get kIrrigationUrgentTitle => spa.kIrrigationUrgentTitle;
  @override
  String get kIrrigationModerateTitle => spa.kIrrigationModerateTitle;
  @override
  String get kIrrigationOptimalTitle => spa.kIrrigationOptimalTitle;
  @override
  String kIrrigationUrgentRec(Object moisture, Object soil, Object crop, Object kc, Object waterMm) =>
      spa.kIrrigationUrgentRec(moisture, soil, crop, kc, waterMm);
  @override
  String kIrrigationModerateRec(Object soil, Object days, Object waterMm) =>
      spa.kIrrigationModerateRec(soil, days, waterMm);
  @override
  String kIrrigationOptimalRec(Object moisture, Object crop, Object soil) =>
      spa.kIrrigationOptimalRec(moisture, crop, soil);

  @override
  String get kCompatibilityHigh => spa.kCompatibilityHigh;
  @override
  String get kCompatibilityMedium => spa.kCompatibilityMedium;
  @override
  String get kCompatibilityDiscouraged => spa.kCompatibilityDiscouraged;
  @override
  String get kCropBeansLegume => spa.kCropBeansLegume;
  @override
  String get kCropCornSorghumGrass => spa.kCropCornSorghumGrass;
  @override
  String get kCropRedBeansLegume => spa.kCropRedBeansLegume;
  @override
  String get kCropDroughtBeansSorghum => spa.kCropDroughtBeansSorghum;
  @override
  String get kCropCrotalariaManure => spa.kCropCrotalariaManure;
  @override
  String get kCropSoybean => spa.kCropSoybean;
  @override
  String get kCropTolerantSorghum => spa.kCropTolerantSorghum;
  @override
  String get kCropCrotalariaGreenManure => spa.kCropCrotalariaGreenManure;
  @override
  String get kCropVegetables => spa.kCropVegetables;
  @override
  String get kCropSesame => spa.kCropSesame;
  @override
  String get kCropSunflower => spa.kCropSunflower;
  @override
  String get kFamilyUnknown => spa.kFamilyUnknown;
  @override
  String kRotationCorridorRiskExp(Object family, Object crop) =>
      spa.kRotationCorridorRiskExp(family, crop);
  @override
  String kRotationStandardExp(Object currentCrop, Object suggestedCrop) =>
      spa.kRotationStandardExp(currentCrop, suggestedCrop);

  @override
  String get kWindowStatusOptimal => spa.kWindowStatusOptimal;
  @override
  String get kWindowStatusWaitMoisture => spa.kWindowStatusWaitMoisture;
  @override
  String get kDateRangeNext10To14Days => spa.kDateRangeNext10To14Days;
  @override
  String get kDateRangePostponeUntilRain => spa.kDateRangePostponeUntilRain;
  @override
  String kThermalAdviceFavorable(Object gdd) => spa.kThermalAdviceFavorable(gdd);
  @override
  String kThermalAdviceMoistureLow(Object moisturePct) => spa.kThermalAdviceMoistureLow(moisturePct);

  @override
  String get kVigorStatusExcellent => spa.kVigorStatusExcellent;
  @override
  String get kVigorStatusNormal => spa.kVigorStatusNormal;
  @override
  String get kVigorStatusWaterStress => spa.kVigorStatusWaterStress;
  @override
  String get kBiomassConditionDense => spa.kBiomassConditionDense;
  @override
  String get kBiomassConditionNormal => spa.kBiomassConditionNormal;
  @override
  String kBiomassConditionStress(Object lossPct) => spa.kBiomassConditionStress(lossPct);

  @override
  String get kRiskAlertFlashDroughtTitle => spa.kRiskAlertFlashDroughtTitle;
  @override
  String get kRiskAlertWaterloggingTitle => spa.kRiskAlertWaterloggingTitle;
  @override
  String get kRiskAlertHeatStressTitle => spa.kRiskAlertHeatStressTitle;
  @override
  String get kRiskAlertNoneTitle => spa.kRiskAlertNoneTitle;
  @override
  String get kRiskAdviceFlashDroughtSandy => spa.kRiskAdviceFlashDroughtSandy;
  @override
  String get kRiskAdviceFlashDroughtStandard => spa.kRiskAdviceFlashDroughtStandard;
  @override
  String get kRiskAdviceWaterloggingClay => spa.kRiskAdviceWaterloggingClay;
  @override
  String get kRiskAdviceWaterloggingStandard => spa.kRiskAdviceWaterloggingStandard;
  @override
  String get kRiskAdviceHeatStress => spa.kRiskAdviceHeatStress;
  @override
  String get kRiskAdviceNone => spa.kRiskAdviceNone;

  @override
  String kSoilNutritionDiagnosisLegumeSandy(Object nGain, Object ureaSavings) =>
      spa.kSoilNutritionDiagnosisLegumeSandy(nGain, ureaSavings);
  @override
  String kSoilNutritionDiagnosisLegumeStandard(Object nGain, Object ureaSavings) =>
      spa.kSoilNutritionDiagnosisLegumeStandard(nGain, ureaSavings);
  @override
  String get kSoilNutritionDiagnosisCerealSandy => spa.kSoilNutritionDiagnosisCerealSandy;
  @override
  String get kSoilNutritionDiagnosisCerealStandard => spa.kSoilNutritionDiagnosisCerealStandard;

  @override
  String get kDefaultCropName => spa.kDefaultCropName;
  @override
  String get kDefaultSoilName => spa.kDefaultSoilName;
}

class AppLanguage {
  static const EngStrings engInstance = EngStrings();
  static const SpaStrings spaInstance = SpaStrings();

  static final ValueNotifier<AppLanguageType> current =
      ValueNotifier<AppLanguageType>(AppLanguageType.spanish);

  static AppStrings get strings =>
      current.value == AppLanguageType.spanish ? spaInstance : engInstance;

  static bool get isSpanish => current.value == AppLanguageType.spanish;

  static void setLanguage(AppLanguageType lang) {
    current.value = lang;
  }

  static void toggleLanguage() {
    current.value = current.value == AppLanguageType.spanish
        ? AppLanguageType.english
        : AppLanguageType.spanish;
  }
}

