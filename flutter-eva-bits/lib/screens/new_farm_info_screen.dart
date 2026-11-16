import 'package:flutter/material.dart';
import '../constants/agricultural_locations.dart';
import '../constants/app_colors.dart';
import '../constants/responsive.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../widgets/eve_animated_avatar.dart';
import 'dashboard_screen.dart';

enum SurfaceUnit {
  hectares,
  acres,
  squareMeters,
  tareas,
}

class SubplotItem {
  final TextEditingController nameController;
  final TextEditingController surfaceController;

  SubplotItem({
    required this.nameController,
    required this.surfaceController,
  });

  void dispose() {
    nameController.dispose();
    surfaceController.dispose();
  }
}

class LotItem {
  final TextEditingController nameController;
  final TextEditingController surfaceController;
  final TextEditingController subplotsCountController;
  final List<SubplotItem> subplots;

  LotItem({
    required this.nameController,
    required this.surfaceController,
    required this.subplotsCountController,
    List<SubplotItem>? subplots,
  }) : subplots = subplots ?? [];

  void dispose() {
    nameController.dispose();
    surfaceController.dispose();
    subplotsCountController.dispose();
    for (final subplot in subplots) {
      subplot.dispose();
    }
  }
}

class FarmInfoScreen extends StatefulWidget {
  final bool checkExisting;

  const FarmInfoScreen({
    super.key,
    this.checkExisting = true,
  });

  @override
  State<FarmInfoScreen> createState() => _FarmInfoScreenState();
}

class _FarmInfoScreenState extends State<FarmInfoScreen> {
  final _step1FormKey = GlobalKey<FormState>();

  // Wizard state: 0 = Farm Info, 1 = Lots & Subplots, 2 = Summary & Ivy
  int _currentStep = 0;

  // Farm General Controllers
  late final TextEditingController _farmNameController;
  late final TextEditingController _countryController;
  late final TextEditingController _totalSurfaceController;
  late final TextEditingController _lotsCountController;

  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _isCheckingExistingFarm = true;
  String? _selectedLocationId;

  SurfaceUnit _selectedUnit = SurfaceUnit.hectares;
  final List<LotItem> _lots = [];

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController();
    final defaultPreset = AgriculturalLocation.presets.firstWhere(
      (p) => p.id == 'nic_esteli',
      orElse: () => AgriculturalLocation.presets.first,
    );
    _selectedLocationId = defaultPreset.id;
    _countryController = TextEditingController(text: defaultPreset.displayName);
    _latitude = defaultPreset.latitude;
    _longitude = defaultPreset.longitude;
    _totalSurfaceController = TextEditingController();
    _lotsCountController = TextEditingController(text: '0');

    if (widget.checkExisting) {
      _checkExistingFarm();
    } else {
      _isCheckingExistingFarm = false;
    }
  }

  Future<void> _checkExistingFarm() async {
    try {
      final existingFarm = await DatabaseManager().getLatestFarm();
      if (existingFarm != null && mounted) {
        final farmName = existingFarm['name']?.toString();
        final country = existingFarm['country']?.toString();
        final surface = existingFarm['total_surface']?.toString();
        final unit = existingFarm['surface_unit']?.toString() ?? 'ha';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(
                  farmName: farmName,
                  location: country,
                  surface: surface != null ? '$surface $unit' : null,
                ),
              ),
            );
          }
        });
        return;
      }
    } catch (_) {
      // If error occurs or database is empty, proceed to setup wizard
    }

    if (mounted) {
      setState(() => _isCheckingExistingFarm = false);
    }
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _countryController.dispose();
    _totalSurfaceController.dispose();
    _lotsCountController.dispose();
    for (final lot in _lots) {
      lot.dispose();
    }
    super.dispose();
  }

  Future<void> _saveFarmDataToDatabase(AppStrings s) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final unitShort = _getUnitShortName(_selectedUnit, s);
    final farmData = <String, dynamic>{
      'name': _farmNameController.text.trim(),
      'country': _countryController.text.trim(),
      'surface_unit': unitShort,
      'total_surface':
          double.tryParse(_totalSurfaceController.text.trim()) ?? 0.0,
      'latitude': _latitude,
      'longitude': _longitude,
    };

    final lotsData = _lots.map((lot) {
      return <String, dynamic>{
        'name': lot.nameController.text.trim(),
        'surface': double.tryParse(lot.surfaceController.text.trim()) ?? 0.0,
        'subplots': lot.subplots.map((sub) {
          return <String, dynamic>{
            'name': sub.nameController.text.trim(),
            'surface':
                double.tryParse(sub.surfaceController.text.trim()) ?? 0.0,
          };
        }).toList(),
      };
    }).toList();

    try {
      await DatabaseManager().insertFarm(
        farm: farmData,
        lots: lotsData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(s.kFormSavedSuccessfully),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              farmName: _farmNameController.text.isNotEmpty
                  ? _farmNameController.text
                  : null,
              location: _countryController.text.isNotEmpty
                  ? _countryController.text
                  : null,
              surface: _totalSurfaceController.text.isNotEmpty
                  ? '${_totalSurfaceController.text} $unitShort'
                  : null,
            ),
          ),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text(s.kErrorSavingData),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getUnitFullName(SurfaceUnit unit, AppStrings s) {
    switch (unit) {
      case SurfaceUnit.hectares:
        return s.kUnitHectares;
      case SurfaceUnit.acres:
        return s.kUnitAcres;
      case SurfaceUnit.squareMeters:
        return s.kUnitSquareMeters;
      case SurfaceUnit.tareas:
        return s.kUnitTareas;
    }
  }

  String _getUnitShortName(SurfaceUnit unit, AppStrings s) {
    switch (unit) {
      case SurfaceUnit.hectares:
        return s.kUnitHectaresShort;
      case SurfaceUnit.acres:
        return s.kUnitAcresShort;
      case SurfaceUnit.squareMeters:
        return s.kUnitSquareMetersShort;
      case SurfaceUnit.tareas:
        return s.kUnitTareasShort;
    }
  }

  // Bypass: Use whole farm as 1 single lot and jump straight to Step 3
  void _bypassAsSingleLot(AppStrings s) {
    if (!_step1FormKey.currentState!.validate()) {
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade900,
          content: Text(s.kLocationRequired),
        ),
      );
      return;
    }

    final total = _totalSurfaceController.text.trim();
    for (final lot in _lots) {
      lot.dispose();
    }
    _lots.clear();

    setState(() {
      _lots.add(
        LotItem(
          nameController: TextEditingController(
            text: '${_farmNameController.text.trim()} - ${s.kMainLot}',
          ),
          surfaceController: TextEditingController(text: total),
          subplotsCountController: TextEditingController(text: '0'),
        ),
      );
      _lotsCountController.text = '1';
      _currentStep = 2; // Jump to Review & Ivy
    });
  }

  void _syncLotsCount(int targetCount, AppStrings s) {
    if (targetCount == _lots.length) return;

    setState(() {
      if (targetCount > _lots.length) {
        final toAdd = targetCount - _lots.length;
        for (var i = 0; i < toAdd; i++) {
          final lotIndex = _lots.length + 1;
          _lots.add(
            LotItem(
              nameController: TextEditingController(
                text: '${s.kLot} $lotIndex',
              ),
              surfaceController: TextEditingController(),
              subplotsCountController: TextEditingController(text: '0'),
            ),
          );
        }
      } else {
        while (_lots.length > targetCount) {
          final removed = _lots.removeLast();
          removed.dispose();
        }
      }
      _lotsCountController.text = targetCount.toString();
    });
  }

  void _addLot(AppStrings s) {
    _syncLotsCount(_lots.length + 1, s);
  }

  void _removeLotAt(int index) {
    if (index >= 0 && index < _lots.length) {
      setState(() {
        final removed = _lots.removeAt(index);
        removed.dispose();
        _lotsCountController.text = _lots.length.toString();
      });
    }
  }

  void _syncSubplotsCount(LotItem lot, int targetCount, AppStrings s) {
    if (targetCount == lot.subplots.length) return;

    setState(() {
      if (targetCount > lot.subplots.length) {
        final toAdd = targetCount - lot.subplots.length;
        for (var i = 0; i < toAdd; i++) {
          final subplotIndex = lot.subplots.length + 1;
          lot.subplots.add(
            SubplotItem(
              nameController: TextEditingController(
                text: '${s.kSubplot} $subplotIndex',
              ),
              surfaceController: TextEditingController(),
            ),
          );
        }
      } else {
        while (lot.subplots.length > targetCount) {
          final removed = lot.subplots.removeLast();
          removed.dispose();
        }
      }
      lot.subplotsCountController.text = targetCount.toString();
    });
  }

  void _addSubplot(LotItem lot, AppStrings s) {
    _syncSubplotsCount(lot, lot.subplots.length + 1, s);
  }

  void _removeSubplotAt(LotItem lot, int index) {
    if (index >= 0 && index < lot.subplots.length) {
      setState(() {
        final removed = lot.subplots.removeAt(index);
        removed.dispose();
        lot.subplotsCountController.text = lot.subplots.length.toString();
      });
    }
  }

  double get _totalFarmSurface =>
      double.tryParse(_totalSurfaceController.text) ?? 0.0;

  double get _totalLotsSurface {
    double sum = 0.0;
    for (final lot in _lots) {
      sum += double.tryParse(lot.surfaceController.text) ?? 0.0;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingExistingFarm) {
      return Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, currentLang, _) {
        final s = AppLanguage.strings;
        final unitShort = _getUnitShortName(_selectedUnit, s);

        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          appBar: AppBar(
            backgroundColor: AppColors.getHeaderBg(context),
            foregroundColor: Colors.white,
            elevation: 1,
            title: Text(
              s.kFarmInfoTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: AppLanguage.toggleLanguage,
                icon: const Icon(Icons.language,
                    color: Colors.white, size: 18),
                label: Text(
                  AppLanguage.isSpanish ? s.kEnglish : s.kSpanish,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Spacing between AppBar header and the progress line
                SizedBox(
                  height: Responsive(context).value<double>(
                    mobile: 14.0,
                    tablet: 18.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive(context).value<double>(
                      mobile: 16.0,
                      tablet: 18.0,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive(context).maxContentWidth,
                      ),
                      child: _buildStepIndicator(s),
                    ),
                  ),
                ),
                SizedBox(
                  height: Responsive(context).value<double>(
                    mobile: 10.0,
                    tablet: 14.0,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive(context).value<double>(
                        mobile: 16.0,
                        tablet: 18.0,
                      ),
                      vertical: 6,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: Responsive(context).maxContentWidth,
                          ),
                          child: _currentStep == 0
                              ? _buildStep1FarmInfo(s, unitShort)
                              : (_currentStep == 1
                                  ? _buildStep2LotsInfo(s, unitShort)
                                  : _buildStep3Summary(s, unitShort)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _currentStep == 1
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  tooltip: s.kAddLot,
                  onPressed: () => _addLot(s),
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
          bottomNavigationBar: _buildBottomNavigationBar(s),
        );
      },
    );
  }

  // --- Step Indicator ---
  Widget _buildStepIndicator(AppStrings s) {
    final isDark = AppColors.isDark(context);
    final isTablet = Responsive(context).isTabletOrDesktop;
    final steps = [s.kStep1Title, s.kStep2Title, s.kStep3Title];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: isTablet ? 10 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              final isActive = _currentStep == index;
              final isDone = _currentStep > index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    // Allow tapping completed steps to jump back
                    if (index < _currentStep) {
                      setState(() => _currentStep = index);
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 6 : 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: isTablet ? 15 : 12,
                          backgroundColor: isDone
                              ? AppColors.primary
                              : (isActive
                                  ? AppColors.primaryLight
                                  : (isDark
                                      ? const Color(0xFF2E4235)
                                      : Colors.grey.shade300)),
                          child: isDone
                              ? Icon(Icons.check,
                                  size: isTablet ? 18 : 14, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: isTablet ? 13.5 : 12,
                                    color: isActive
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textMutedDark
                                            : Colors.black54),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        SizedBox(width: isTablet ? 8 : 6),
                        Flexible(
                          child: Text(
                            steps[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? (isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primaryDark)
                                  : (isDone
                                      ? AppColors.getTextPrimary(context)
                                      : (isDark
                                          ? AppColors.textMutedDark
                                          : Colors.grey)),
                            ),
                          ),
                        ),
                        if (index < steps.length - 1)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 8 : 4),
                            child: Icon(
                              Icons.chevron_right,
                              size: isTablet ? 20 : 16,
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: isTablet ? 12 : 10),
          // Línea de progreso (Progress line)
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / steps.length,
              minHeight: isTablet ? 7 : 5,
              backgroundColor:
                  isDark ? const Color(0xFF26382C) : Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLanguage.isSpanish
                    ? 'Paso ${_currentStep + 1} de ${steps.length}'
                    : 'Step ${_currentStep + 1} of ${steps.length}',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              Text(
                '${((_currentStep + 1) / steps.length * 100).toInt()}%',
                style: TextStyle(
                  fontSize: isTablet ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NASA Location & Telemetry Card ---
  Widget _buildNasaLocationCard(AppStrings s, bool isDark, {bool isTablet = false}) {
    final currentPreset = AgriculturalLocation.presets.firstWhere(
      (loc) => loc.id == _selectedLocationId,
      orElse: () => AgriculturalLocation.presets.first,
    );

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162B1D) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        border: Border.all(
          color: isDark ? const Color(0xFF264C32) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF203F2A)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
                child: Icon(
                  Icons.satellite_alt_rounded,
                  color: AppColors.primary,
                  size: isTablet ? 28 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 14 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLanguage.isSpanish
                          ? 'Sincronización Satelital NASA'
                          : 'NASA Satellite Synchronization',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 18 : 14.5,
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentPreset.region}, ${currentPreset.country}',
                      style: TextStyle(
                        fontSize: isTablet ? 14.5 : 12,
                        color: AppColors.getTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8,
                  vertical: isTablet ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF13281C)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2E633B)
                        : const Color(0xFF86EFAC),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: isTablet ? 16 : 12, color: const Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      'NASA POWER',
                      style: TextStyle(
                        fontSize: isTablet ? 12.5 : 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 14 : 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1D14) : Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF203B29)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.explore_outlined,
                    size: isTablet ? 22 : 18, color: AppColors.primary),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Text(
                    '${s.kLatitudeLabel}: ${currentPreset.latitude.toStringAsFixed(4)}°   |   ${s.kLongitudeLabel}: ${currentPreset.longitude.toStringAsFixed(4)}°',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 14.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 14 : 10),
          Row(
            children: [
              _buildNasaTag(
                Icons.wb_sunny_outlined,
                AppLanguage.isSpanish ? 'Radiación Solar' : 'Solar Radiation',
                isDark,
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              _buildNasaTag(
                Icons.water_drop_outlined,
                AppLanguage.isSpanish ? 'Precipitación' : 'Precipitation',
                isDark,
                isTablet: isTablet,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              _buildNasaTag(
                Icons.grass_outlined,
                AppLanguage.isSpanish ? 'Humedad Suelo' : 'Soil Moisture',
                isDark,
                isTablet: isTablet,
              ),
            ],
          ),
          if (isTablet) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF102417) : const Color(0xFFE8F5E9).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.satellite_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLanguage.isSpanish
                          ? 'Malla satelital global de 0.5° × 0.5° (~50 km) con telemetría climática histórica y diaria.'
                          : '0.5° × 0.5° global satellite grid (~50 km) with historical and daily climate telemetry.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF1B5E20),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNasaTag(IconData icon, String label, bool isDark, {bool isTablet = false}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 10 : 6,
          horizontal: isTablet ? 8 : 4,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13281C) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
          border: Border.all(
            color: isDark ? const Color(0xFF1E3A27) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isTablet ? 17 : 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isTablet ? 12.5 : 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Sub-components ---
  Widget _buildEveBanner(bool isDark, {bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 14,
        vertical: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192A1E) : const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        border: Border.all(
          color: isDark ? const Color(0xFF264C32) : const Color(0xFFC8E6C9),
        ),
      ),
      child: Row(
        children: [
          EveAnimatedAvatar(
            size: isTablet ? 56 : 44,
            emote: EveEmote.happy,
            isSpeaking: false,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              AppLanguage.isSpanish
                  ? '¡Hola! Configura los datos de tu finca y selecciona tu región para sincronizar la telemetría climática de la NASA.'
                  : 'Hello! Set up your farm info and choose your region to sync NASA climate telemetry.',
              style: TextStyle(
                fontSize: isTablet ? 15 : 12.5,
                color: isDark ? AppColors.textMutedDark : const Color(0xFF2E4E39),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmNameField(AppStrings s, {bool isTablet = false}) {
    return TextFormField(
      controller: _farmNameController,
      style: TextStyle(fontSize: isTablet ? 16 : 14),
      decoration: InputDecoration(
        labelText: s.kFarmNameLabel,
        hintText: s.kFarmNameHint,
        labelStyle: TextStyle(fontSize: isTablet ? 15.5 : 14),
        hintStyle: TextStyle(fontSize: isTablet ? 15 : 14),
        prefixIcon: Icon(Icons.business, size: isTablet ? 24 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 20 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return s.kFieldRequired;
        }
        return null;
      },
    );
  }

  Widget _buildNasaRegionDropdown(AppStrings s, {bool isTablet = false}) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedLocationId,
      isExpanded: true,
      menuMaxHeight: 380,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      dropdownColor: AppColors.getCardBg(context),
      style: TextStyle(
        color: AppColors.getTextPrimary(context),
        fontSize: isTablet ? 15.5 : 13,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.primary,
        size: isTablet ? 28 : 24,
      ),
      decoration: InputDecoration(
        labelText: AppLanguage.isSpanish
            ? 'Región Agrícola (NASA)'
            : 'Agricultural Region (NASA)',
        hintText: s.kCountryHint,
        labelStyle: TextStyle(fontSize: isTablet ? 15.5 : 14),
        hintStyle: TextStyle(fontSize: isTablet ? 15 : 14),
        prefixIcon: Icon(Icons.public, color: AppColors.primary, size: isTablet ? 24 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 20 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: AgriculturalLocation.presets.map((loc) {
        return DropdownMenuItem<String>(
          value: loc.id,
          child: Text(
            loc.displayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTablet ? 15 : 13,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        final loc = AgriculturalLocation.presets
            .firstWhere((p) => p.id == val);
        setState(() {
          _selectedLocationId = val;
          _countryController.text = loc.displayName;
          _latitude = loc.latitude;
          _longitude = loc.longitude;
        });
      },
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return s.kFieldRequired;
        }
        return null;
      },
    );
  }

  Widget _buildSurfaceUnitDropdown(AppStrings s, {bool isTablet = false}) {
    return DropdownButtonFormField<SurfaceUnit>(
      initialValue: _selectedUnit,
      isExpanded: true,
      menuMaxHeight: 260,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      dropdownColor: AppColors.getCardBg(context),
      style: TextStyle(
        color: AppColors.getTextPrimary(context),
        fontSize: isTablet ? 15.5 : 13,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.primary,
        size: isTablet ? 28 : 24,
      ),
      decoration: InputDecoration(
        labelText: s.kSurfaceUnitLabel,
        hintText: s.kSurfaceUnitHint,
        labelStyle: TextStyle(fontSize: isTablet ? 15.5 : 14),
        hintStyle: TextStyle(fontSize: isTablet ? 15 : 14),
        prefixIcon: Icon(Icons.straighten, size: isTablet ? 24 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 20 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      items: SurfaceUnit.values.map((unit) {
        return DropdownMenuItem<SurfaceUnit>(
          value: unit,
          child: Text(
            _getUnitFullName(unit, s),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.getTextPrimary(context),
              fontSize: isTablet ? 15 : 13,
            ),
          ),
        );
      }).toList(),
      onChanged: (SurfaceUnit? newUnit) {
        if (newUnit != null) {
          setState(() {
            _selectedUnit = newUnit;
          });
        }
      },
    );
  }

  Widget _buildTotalSurfaceField(AppStrings s, String unitShort, {bool isTablet = false}) {
    return TextFormField(
      controller: _totalSurfaceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(fontSize: isTablet ? 16 : 14),
      decoration: InputDecoration(
        labelText: '${s.kTotalSurfaceLabel} ($unitShort)',
        hintText: s.kTotalSurfaceHint,
        suffixText: unitShort,
        labelStyle: TextStyle(fontSize: isTablet ? 15.5 : 14),
        hintStyle: TextStyle(fontSize: isTablet ? 15 : 14),
        suffixStyle: TextStyle(fontSize: isTablet ? 15 : 14, fontWeight: FontWeight.w600),
        prefixIcon: Icon(Icons.square_foot, size: isTablet ? 24 : 20),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 20 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: BorderSide(color: AppColors.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return s.kFieldRequired;
        }
        final numVal = double.tryParse(val);
        if (numVal == null || numVal <= 0) {
          return s.kInvalidNumber;
        }
        return null;
      },
    );
  }

  Widget _buildBypassButton(AppStrings s, bool isDark, {bool isTablet = false}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.accentDark : AppColors.accent,
        side: BorderSide(
          color: isDark ? AppColors.accentDark : AppColors.accent,
          width: isTablet ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 12,
          vertical: isTablet ? 16 : 10,
        ),
        minimumSize: Size.fromHeight(isTablet ? 56 : 46),
      ),
      onPressed: () => _bypassAsSingleLot(s),
      icon: Icon(Icons.fast_forward, size: isTablet ? 24 : 18),
      label: Text(
        s.kQuickStartWholeFarm,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isTablet ? 15.5 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAgroecologicalTip(bool isDark, {bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 12,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13281C) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E462B) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: isTablet ? 22 : 18,
            color: const Color(0xFF16A34A),
          ),
          SizedBox(width: isTablet ? 10 : 8),
          Expanded(
            child: Text(
              AppLanguage.isSpanish
                  ? 'Consejo agroecológico: La superficie total permite a Eva Bits calcular balances hídricos y estimaciones satelitales NASA precisas para cada lote.'
                  : 'Agroecological tip: Total farm surface allows Eva Bits to calculate water balances and precise NASA telemetry for each lot.',
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 11.5,
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1: Farm Info ---
  Widget _buildStep1FarmInfo(AppStrings s, String unitShort) {
    final isDark = AppColors.isDark(context);
    final isTablet = Responsive(context).isTabletOrDesktop;

    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEveBanner(isDark, isTablet: isTablet),
          SizedBox(height: isTablet ? 18 : 14),
          Card(
            elevation: 2,
            color: AppColors.getCardBg(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              side: BorderSide(color: AppColors.getBorder(context)),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 28 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.eco,
                        color: AppColors.primary,
                        size: isTablet ? 26 : 22,
                      ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Expanded(
                        child: Text(
                          s.kGeneralInfoSection,
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  _buildFarmNameField(s, isTablet: isTablet),
                  SizedBox(height: isTablet ? 22 : 16),
                  _buildNasaRegionDropdown(s, isTablet: isTablet),
                  SizedBox(height: isTablet ? 22 : 16),
                  _buildNasaLocationCard(s, isDark, isTablet: isTablet),
                  SizedBox(height: isTablet ? 22 : 16),
                  _buildSurfaceUnitDropdown(s, isTablet: isTablet),
                  SizedBox(height: isTablet ? 22 : 16),
                  _buildTotalSurfaceField(s, unitShort, isTablet: isTablet),
                  SizedBox(height: isTablet ? 24 : 16),
                  _buildBypassButton(s, isDark, isTablet: isTablet),
                  if (isTablet) ...[
                    const SizedBox(height: 20),
                    _buildAgroecologicalTip(isDark, isTablet: true),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Lots and Subplots ---
  Widget _buildStep2LotsInfo(AppStrings s, String unitShort) {
    final isDark = AppColors.isDark(context);
    final isTablet = Responsive(context).isTabletOrDesktop;
    final farmSurface = _totalFarmSurface;
    final allocated = _totalLotsSurface;
    final isExceeded = allocated > farmSurface && farmSurface > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAllocationCard(s, unitShort, farmSurface, allocated, isExceeded, isDark, isTablet: isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _buildLotsHeaderCard(s, isTablet: isTablet),
        SizedBox(height: isTablet ? 16 : 12),
        _buildLotsList(s, unitShort, isTablet: isTablet),
      ],
    );
  }

  Widget _buildAllocationCard(
    AppStrings s,
    String unitShort,
    double farmSurface,
    double allocated,
    bool isExceeded,
    bool isDark, {
    bool isTablet = false,
  }) {
    final pct = farmSurface > 0 ? (allocated / farmSurface * 100).toInt() : 0;

    return Card(
      elevation: 2,
      color: isExceeded
          ? (isDark ? const Color(0xFF3B1E12) : Colors.orange.shade50)
          : AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        side: BorderSide(
          color: isExceeded ? Colors.orange : AppColors.getBorder(context),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.kAllocatedSurface,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 5 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: isExceeded
                        ? (isDark ? const Color(0xFF5A2A1A) : Colors.orange.shade100)
                        : (isDark ? const Color(0xFF1F3D2A) : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 11.5,
                      fontWeight: FontWeight.bold,
                      color: isExceeded
                          ? Colors.orange.shade900
                          : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Text(
              '${allocated.toStringAsFixed(1)} / ${farmSurface.toStringAsFixed(1)} $unitShort',
              style: TextStyle(
                fontSize: isTablet ? 17 : 14,
                fontWeight: FontWeight.bold,
                color: isExceeded ? Colors.orange.shade400 : AppColors.primary,
              ),
            ),
            SizedBox(height: isTablet ? 14 : 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: farmSurface > 0
                    ? (allocated / farmSurface).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: isTablet ? 9 : 6,
                backgroundColor: isDark ? const Color(0xFF26382C) : Colors.grey.shade200,
                color: isExceeded ? Colors.orange : AppColors.primary,
              ),
            ),
            if (isExceeded)
              Padding(
                padding: EdgeInsets.only(top: isTablet ? 10 : 8),
                child: Text(
                  s.kLotsSurfaceExceededWarning,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 11,
                    color: isDark ? Colors.orange.shade300 : Colors.orange.shade900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsHeaderCard(AppStrings s, {bool isTablet = false}) {
    return Card(
      elevation: 2,
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Row(
          children: [
            Icon(Icons.grid_view_rounded, color: AppColors.primary, size: isTablet ? 24 : 20),
            SizedBox(width: isTablet ? 10 : 8),
            Expanded(
              child: Text(
                s.kLotsSectionTitle,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 5 : 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_lots.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: isTablet ? 13.5 : 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsList(AppStrings s, String unitShort, {bool isTablet = false}) {
    final isDark = AppColors.isDark(context);
    if (_lots.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 40 : 32),
          child: Column(
            children: [
              Icon(Icons.layers_clear, size: isTablet ? 56 : 48, color: isDark ? AppColors.textMutedDark : Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                s.kNoLotsAddedYet,
                style: TextStyle(fontSize: isTablet ? 15 : 13, color: AppColors.getTextSecondary(context)),
              ),
              SizedBox(height: isTablet ? 14 : 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(isTablet ? 160 : 130, isTablet ? 48 : 40),
                ),
                onPressed: () => _addLot(s),
                icon: const Icon(Icons.add),
                label: Text(s.kAddLot),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lots.length,
      separatorBuilder: (_, index) => SizedBox(height: isTablet ? 20 : 16),
      itemBuilder: (ctx, index) {
        return _buildLotCard(_lots[index], index, s, unitShort, isTablet: isTablet);
      },
    );
  }

  Widget _buildLotCard(
      LotItem lot, int index, AppStrings s, String unitShort, {bool isTablet = false}) {
    final isDark = AppColors.isDark(context);
    final lotNumberStr = '${s.kLot} ${index + 1}';

    return Card(
      elevation: 2,
      color: AppColors.getLotCardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
        side: BorderSide(color: AppColors.getBorder(context), width: 1.2),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 22 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, color: AppColors.primary, size: isTablet ? 24 : 20),
                SizedBox(width: isTablet ? 10 : 8),
                Expanded(
                  child: Text(
                    lotNumberStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: s.kRemoveLot,
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: isTablet ? 24 : 20),
                  onPressed: () => _removeLotAt(index),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 18 : 12),
            TextFormField(
              controller: lot.nameController,
              style: TextStyle(fontSize: isTablet ? 15.5 : 14),
              decoration: InputDecoration(
                labelText: s.kLotNameLabel,
                hintText: s.kLotNameHint,
                labelStyle: TextStyle(fontSize: isTablet ? 15 : 14),
                filled: true,
                fillColor: AppColors.getInputBg(context),
                prefixIcon: Icon(Icons.label_outline, size: isTablet ? 24 : 20),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 12,
                  vertical: isTablet ? 18 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 18 : 12),
            TextFormField(
              controller: lot.surfaceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: isTablet ? 15.5 : 14),
              decoration: InputDecoration(
                labelText: '${s.kLotSurfaceLabel} ($unitShort)',
                hintText: s.kLotSurfaceHint,
                suffixText: unitShort,
                labelStyle: TextStyle(fontSize: isTablet ? 15 : 14),
                suffixStyle: TextStyle(fontSize: isTablet ? 15 : 14, fontWeight: FontWeight.w600),
                filled: true,
                fillColor: AppColors.getInputBg(context),
                prefixIcon: Icon(Icons.crop_square, size: isTablet ? 24 : 20),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 18 : 12,
                  vertical: isTablet ? 18 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Divider(color: AppColors.getBorder(context)),
            const SizedBox(height: 8),
            _buildSubplotsSection(lot, s, unitShort, isTablet: isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSubplotsSection(
      LotItem lot, AppStrings s, String unitShort, {bool isTablet = false}) {
    final isDark = AppColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.subdirectory_arrow_right,
                color: AppColors.accent, size: isTablet ? 20 : 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.kSubplotsSectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addSubplot(lot, s),
              icon: Icon(Icons.add, size: isTablet ? 18 : 16),
              label: Text(
                s.kAddSubplot,
                style: TextStyle(fontSize: isTablet ? 13.5 : 12),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (lot.subplots.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              s.kNoSubplots,
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 12,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textMutedDark : Colors.grey.shade600,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 12),
          for (var i = 0; i < lot.subplots.length; i++)
            _buildSubplotCard(lot, lot.subplots[i], i, s, unitShort, isTablet: isTablet),
        ],
      ],
    );
  }

  Widget _buildSubplotCard(LotItem lot, SubplotItem subplot, int index,
      AppStrings s, String unitShort, {bool isTablet = false}) {
    final isDark = AppColors.isDark(context);
    final subplotNumberStr = '${s.kSubplot} ${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152219) : AppColors.subplotCardBg,
        borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, size: isTablet ? 18 : 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subplotNumberStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 14 : 13,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: s.kRemoveSubplot,
                icon: Icon(Icons.close, size: isTablet ? 18 : 16, color: Colors.red),
                onPressed: () => _removeSubplotAt(lot, index),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 10 : 8),
          TextFormField(
            controller: subplot.nameController,
            style: TextStyle(fontSize: isTablet ? 14.5 : 13.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: s.kSubplotNameLabel,
              labelStyle: TextStyle(fontSize: isTablet ? 14 : 13),
              filled: true,
              fillColor: AppColors.getInputBg(context),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 14 : 10,
                vertical: isTablet ? 14 : 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: isTablet ? 10 : 8),
          TextFormField(
            controller: subplot.surfaceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: isTablet ? 14.5 : 13.5),
            decoration: InputDecoration(
              isDense: true,
              labelText: '${s.kSubplotSurfaceLabel} ($unitShort)',
              labelStyle: TextStyle(fontSize: isTablet ? 14 : 13),
              filled: true,
              fillColor: AppColors.getInputBg(context),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 14 : 10,
                vertical: isTablet ? 14 : 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Summary ---
  Widget _buildStep3Summary(AppStrings s, String unitShort) {
    final isDark = AppColors.isDark(context);
    final isTablet = Responsive(context).isTabletOrDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFarmSummaryCard(s, unitShort, isDark, isTablet: isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _buildNasaSummaryCard(s, isDark, isTablet: isTablet),
      ],
    );
  }

  Widget _buildFarmSummaryCard(AppStrings s, String unitShort, bool isDark, {bool isTablet = false}) {
    return Card(
      elevation: 2,
      color: AppColors.getCardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: isTablet ? 26 : 20),
                SizedBox(width: isTablet ? 10 : 8),
                Expanded(
                  child: Text(
                    s.kSummaryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: isTablet ? 24 : 20, color: AppColors.getBorder(context)),
            _buildSummaryRow(
              s.kFarm,
              _farmNameController.text.isNotEmpty
                  ? _farmNameController.text
                  : '-',
              isBold: true,
              isTablet: isTablet,
            ),
            _buildSummaryRow(
              s.kCountryLabel,
              _countryController.text.isNotEmpty
                  ? _countryController.text
                  : '-',
              isTablet: isTablet,
            ),
            if (_latitude != null && _longitude != null)
              _buildSummaryRow(
                s.kFarmLocationLabel,
                '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                isBold: true,
                isTablet: isTablet,
              ),
            _buildSummaryRow(
              s.kTotalSurfaceLabel,
              '${_totalSurfaceController.text} $unitShort',
              isTablet: isTablet,
            ),
            _buildSummaryRow(
              s.kLotsCountLabel,
              '${_lots.length}',
              isTablet: isTablet,
            ),
            if (_lots.isNotEmpty) ...[
              SizedBox(height: isTablet ? 16 : 12),
              Text(
                '${s.kLotsDistribution}:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 15.5 : 13,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              for (final lot in _lots)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    '• ${lot.nameController.text}: ${lot.surfaceController.text} $unitShort',
                    style: TextStyle(
                      fontSize: isTablet ? 14.5 : 13,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNasaSummaryCard(AppStrings s, bool isDark, {bool isTablet = false}) {
    final currentPreset = AgriculturalLocation.presets.firstWhere(
      (loc) => loc.id == _selectedLocationId,
      orElse: () => AgriculturalLocation.presets.first,
    );

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1B2F22) : const Color(0xFFF1F8E9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2E4E39) : AppColors.primaryLight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: AppColors.primary, size: isTablet ? 26 : 20),
                SizedBox(width: isTablet ? 10 : 8),
                Expanded(
                  child: Text(
                    s.kNasaDataReady,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 15.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 5 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF142B1C) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF275C35) : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: isTablet ? 16 : 12, color: const Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        'NASA POWER',
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 14 : 8),
            Text(
              s.kNasaDataDescription,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.getTextSecondary(context),
                height: 1.4,
              ),
            ),
            SizedBox(height: isTablet ? 18 : 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF122218) : Colors.white,
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                border: Border.all(
                  color: isDark ? const Color(0xFF203B29) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    AppLanguage.isSpanish ? 'Región NASA' : 'NASA Region',
                    '${currentPreset.region}, ${currentPreset.country}',
                    isTablet: isTablet,
                  ),
                  _buildSummaryRow(
                    AppLanguage.isSpanish ? 'Coordenadas' : 'Coordinates',
                    '${currentPreset.latitude.toStringAsFixed(4)}°, ${currentPreset.longitude.toStringAsFixed(4)}°',
                    isTablet: isTablet,
                  ),
                  _buildSummaryRow(
                    AppLanguage.isSpanish ? 'Telemetría activa' : 'Active telemetry',
                    AppLanguage.isSpanish ? 'Radiación, Lluvia, Humedad' : 'Radiation, Rain, Moisture',
                    isBold: true,
                    isTablet: isTablet,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isTablet = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 5 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isTablet ? 15 : 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 15.5 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar(AppStrings s) {
    final isDark = AppColors.isDark(context);
    final isTablet = Responsive(context).isTabletOrDesktop;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.getNavBarBg(context),
        border: Border(
          top: BorderSide(color: AppColors.getBorder(context)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive(context).maxContentWidth,
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimary(context),
                        side: BorderSide(color: AppColors.getBorder(context)),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: isTablet ? 14 : 12,
                        ),
                        minimumSize: Size.fromHeight(isTablet ? 52 : 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _currentStep--);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: isTablet ? 20 : 18),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            s.kPreviousStep,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_currentStep > 0) SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isTablet ? 14 : 12,
                      ),
                      minimumSize: Size.fromHeight(isTablet ? 52 : 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      ),
                    ),
                    onPressed: () {
                      if (_currentStep == 0) {
                        if (_step1FormKey.currentState!.validate()) {
                          if (_latitude == null || _longitude == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.orange.shade900,
                                content: Text(s.kLocationRequired),
                              ),
                            );
                            return;
                          }
                          setState(() => _currentStep = 1);
                        }
                      } else if (_currentStep == 1) {
                        setState(() => _currentStep = 2);
                      } else {
                        _saveFarmDataToDatabase(s);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSaving)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          Text(
                            _currentStep == 2 ? s.kSave : s.kNextStep,
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Icon(
                            _currentStep == 2
                                ? Icons.save
                                : Icons.arrow_forward,
                            size: isTablet ? 20 : 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
