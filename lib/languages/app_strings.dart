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
  String get kTotalSurfaceLabel;
  String get kTotalSurfaceHint;
  String get kGeographicZoneLabel;
  String get kGeographicZoneHint;

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

  // Wizard & Quick Start
  String get kStep1Title;
  String get kStep2Title;
  String get kStep3Title;
  String get kQuickStartBypass;
  String get kQuickStartWholeFarm;
  String get kNextStep;
  String get kPreviousStep;
  String get kSingleLotMode;
  String get kCustomLotsMode;
  String get kAllocatedSurface;
  String get kAskIvyTitle;
  String get kNasaDataReady;
  String get kFastDemoBanner;
  String get kPresetLoadedMsg;

  // Language
  String get kLanguage;
  String get kEnglish;
  String get kSpanish;
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
  String get kTotalSurfaceLabel => eng.kTotalSurfaceLabel;
  @override
  String get kTotalSurfaceHint => eng.kTotalSurfaceHint;
  @override
  String get kGeographicZoneLabel => eng.kGeographicZoneLabel;
  @override
  String get kGeographicZoneHint => eng.kGeographicZoneHint;

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
  String get kStep1Title => eng.kStep1Title;
  @override
  String get kStep2Title => eng.kStep2Title;
  @override
  String get kStep3Title => eng.kStep3Title;
  @override
  String get kQuickStartBypass => eng.kQuickStartBypass;
  @override
  String get kQuickStartWholeFarm => eng.kQuickStartWholeFarm;
  @override
  String get kNextStep => eng.kNextStep;
  @override
  String get kPreviousStep => eng.kPreviousStep;
  @override
  String get kSingleLotMode => eng.kSingleLotMode;
  @override
  String get kCustomLotsMode => eng.kCustomLotsMode;
  @override
  String get kAllocatedSurface => eng.kAllocatedSurface;
  @override
  String get kAskIvyTitle => eng.kAskIvyTitle;
  @override
  String get kNasaDataReady => eng.kNasaDataReady;
  @override
  String get kFastDemoBanner => eng.kFastDemoBanner;
  @override
  String get kPresetLoadedMsg => eng.kPresetLoadedMsg;

  @override
  String get kLanguage => eng.kLanguage;
  @override
  String get kEnglish => eng.kEnglish;
  @override
  String get kSpanish => eng.kSpanish;
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
  String get kTotalSurfaceLabel => spa.kTotalSurfaceLabel;
  @override
  String get kTotalSurfaceHint => spa.kTotalSurfaceHint;
  @override
  String get kGeographicZoneLabel => spa.kGeographicZoneLabel;
  @override
  String get kGeographicZoneHint => spa.kGeographicZoneHint;

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
  String get kStep1Title => spa.kStep1Title;
  @override
  String get kStep2Title => spa.kStep2Title;
  @override
  String get kStep3Title => spa.kStep3Title;
  @override
  String get kQuickStartBypass => spa.kQuickStartBypass;
  @override
  String get kQuickStartWholeFarm => spa.kQuickStartWholeFarm;
  @override
  String get kNextStep => spa.kNextStep;
  @override
  String get kPreviousStep => spa.kPreviousStep;
  @override
  String get kSingleLotMode => spa.kSingleLotMode;
  @override
  String get kCustomLotsMode => spa.kCustomLotsMode;
  @override
  String get kAllocatedSurface => spa.kAllocatedSurface;
  @override
  String get kAskIvyTitle => spa.kAskIvyTitle;
  @override
  String get kNasaDataReady => spa.kNasaDataReady;
  @override
  String get kFastDemoBanner => spa.kFastDemoBanner;
  @override
  String get kPresetLoadedMsg => spa.kPresetLoadedMsg;

  @override
  String get kLanguage => spa.kLanguage;
  @override
  String get kEnglish => spa.kEnglish;
  @override
  String get kSpanish => spa.kSpanish;
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

