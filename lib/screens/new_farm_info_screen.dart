import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/agricultural_locations.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import '../widgets/eve_animated_avatar.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

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
  bool _isGettingLocation = false;
  bool _isSaving = false;
  bool _isCheckingExistingFarm = true;
  String? _selectedLocationId;
  bool _isCustomLocation = false;

  SurfaceUnit _selectedUnit = SurfaceUnit.hectares;
  final List<LotItem> _lots = [];

  @override
  void initState() {
    super.initState();
    // Ensure this setup screen always sets and uses light theme
    AppSettings.setThemeMode(ThemeMode.light);
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation(AppLanguage.strings);
      });
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
      _getCurrentLocation(AppLanguage.strings);
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

  Future<void> _getCurrentLocation(AppStrings s) async {
    setState(() => _isGettingLocation = true);

    try {
      final position = await _determinePosition(s);
      if (position != null && mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              '${s.kGpsSuccess}: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text(s.kGpsError),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
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

  bool _isShowingGpsDialog = false;

  void _showEveGpsPermissionDialog(
    AppStrings s, {
    bool isPermanentlyDenied = false,
    bool isServiceDisabled = false,
  }) {
    if (!mounted || _isShowingGpsDialog) return;
    _isShowingGpsDialog = true;

    final isSpanish = AppLanguage.isSpanish;

    final dialogTitle = isServiceDisabled
        ? (isSpanish
            ? 'Activa tu GPS para continuar'
            : 'Enable your GPS to continue')
        : (isSpanish
            ? 'Eve necesita tu ubicación'
            : 'Eve needs your location');

    final dialogExplanation = isSpanish
        ? 'Para calcular datos agroecológicos precisos y consultar la radiación solar, lluvia y humedad del suelo de la NASA, necesito conocer las coordenadas de tu finca.'
        : 'To calculate accurate agroecological metrics and query NASA solar radiation, rainfall, and soil moisture, I need access to your farm coordinates.';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F5E9),
                      border: Border.all(
                        color: const Color(0xFFC8E6C9),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC8E6C9).withValues(alpha: 0.5),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: EveAnimatedAvatar(
                        emote: EveEmote.alert,
                        size: 88,
                        isSpeaking: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dialogTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dialogExplanation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF374151),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSpanish
                                    ? 'Tus datos son privados'
                                    : 'Your data is private',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSpanish
                                    ? 'Las coordenadas se guardan únicamente en tu dispositivo para los cálculos locales y nunca se comparten con terceros.'
                                    : 'Coordinates are saved only on your device for local calculations and are never shared with third parties.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.green.shade900,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isServiceDisabled
                        ? (isSpanish
                            ? 'Por favor, activa el servicio de ubicación en los ajustes de tu teléfono.'
                            : 'Please turn on the location service in your phone settings.')
                        : (isSpanish
                            ? 'Ve a la Configuración de la aplicación para permitir el permiso de ubicación.'
                            : 'Go to App Settings to enable location permission.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        if (isServiceDisabled) {
                          await Geolocator.openLocationSettings();
                        } else {
                          await Geolocator.openAppSettings();
                        }
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: Text(
                        isSpanish ? 'Ir a Configuración' : 'Open Settings',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      isSpanish
                          ? 'Ahora no / Usar zona predefinida'
                          : 'Not now / Use preset zone',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isShowingGpsDialog = false;
    });
  }

  Future<Position?> _determinePosition(AppStrings s) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showEveGpsPermissionDialog(
          s,
          isServiceDisabled: true,
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showEveGpsPermissionDialog(
            s,
            isPermanentlyDenied: false,
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showEveGpsPermissionDialog(
          s,
          isPermanentlyDenied: true,
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
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
      _getCurrentLocation(s);
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
          body: Column(
            children: [
              _buildStepIndicator(s),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  children: [
                    if (_currentStep == 0)
                      _buildStep1FarmInfo(s, unitShort)
                    else if (_currentStep == 1)
                      _buildStep2LotsInfo(s, unitShort)
                    else
                      _buildStep3Summary(s, unitShort),
                  ],
                ),
              ),
            ],
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
    final steps = [s.kStep1Title, s.kStep2Title, s.kStep3Title];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = _currentStep == index;
          final isDone = _currentStep > index;

          return Expanded(
            child: InkWell(
              onTap: () {
                // Allow tapping completed steps to jump back
                if (index < _currentStep) {
                  setState(() => _currentStep = index);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isDone
                        ? AppColors.primary
                        : (isActive ? AppColors.primaryLight : Colors.grey.shade300),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      steps[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? AppColors.primaryDark
                            : (isDone ? Colors.black87 : Colors.grey),
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right,
                          size: 16, color: Colors.grey.shade400),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Step 1: Farm Info ---
  Widget _buildStep1FarmInfo(AppStrings s, String unitShort) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            color: AppColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.kGeneralInfoSection,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _farmNameController,
                    decoration: InputDecoration(
                      labelText: s.kFarmNameLabel,
                      hintText: s.kFarmNameHint,
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return s.kFieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLocationId,
                    isExpanded: true,
                    menuMaxHeight: 280,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 4,
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    decoration: InputDecoration(
                      labelText: s.kCountryLabel,
                      hintText: s.kCountryHint,
                      prefixIcon: const Icon(Icons.public, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: [
                      ...AgriculturalLocation.presets.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc.id,
                          child: Text(
                            loc.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: AgriculturalLocation.customId,
                        child: Text(
                          'Otra región / Coordenadas mundiales',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedLocationId = val;
                        if (val == AgriculturalLocation.customId) {
                          _isCustomLocation = true;
                          _countryController.clear();
                        } else {
                          _isCustomLocation = false;
                          final loc = AgriculturalLocation.presets
                              .firstWhere((p) => p.id == val);
                          _countryController.text = loc.displayName;
                          _latitude = loc.latitude;
                          _longitude = loc.longitude;
                        }
                      });
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return s.kFieldRequired;
                      }
                      return null;
                    },
                  ),
                  if (_isCustomLocation) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countryController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: s.kCountryLabel,
                        hintText: 'Ej. Nicaragua, Estelí / Costa Rica, Alajuela',
                        prefixIcon: const Icon(Icons.edit_location_alt_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return s.kFieldRequired;
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  // GPS Farm Location Card (Automatic & Current GPS)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _latitude != null
                          ? const Color(0xFFF1F8E9)
                          : AppColors.lotCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _latitude != null
                            ? AppColors.primaryLight
                            : AppColors.treeLine,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _latitude != null
                                  ? Icons.location_on
                                  : Icons.location_searching,
                              color: _latitude != null
                                  ? AppColors.primary
                                  : Colors.grey.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.kWhereIsYourFarm,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            if (_latitude != null)
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                tooltip: s.kRefreshLocation,
                                onPressed: _isGettingLocation
                                    ? null
                                    : () => _getCurrentLocation(s),
                                icon: const Icon(Icons.refresh, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isGettingLocation) ...[
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.kGettingGpsLocation,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ] else if (_latitude != null &&
                            _longitude != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.treeLine),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.satellite_alt,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${s.kLatitudeLabel}: ${_latitude!.toStringAsFixed(6)}   |   ${s.kLongitudeLabel}: ${_longitude!.toStringAsFixed(6)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            s.kLocationNotCapturedYet,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _getCurrentLocation(s),
                              icon: const Icon(Icons.my_location, size: 18),
                              label: Text(s.kGetGpsLocationButton),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SurfaceUnit>(
                    initialValue: _selectedUnit,
                    menuMaxHeight: 220,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 4,
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    decoration: InputDecoration(
                      labelText: s.kSurfaceUnitLabel,
                      hintText: s.kSurfaceUnitHint,
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: SurfaceUnit.values.map((unit) {
                      return DropdownMenuItem<SurfaceUnit>(
                        value: unit,
                        child: Text(_getUnitFullName(unit, s)),
                      );
                    }).toList(),
                    onChanged: (SurfaceUnit? newUnit) {
                      if (newUnit != null) {
                        setState(() {
                          _selectedUnit = newUnit;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _totalSurfaceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${s.kTotalSurfaceLabel} ($unitShort)',
                      hintText: s.kTotalSurfaceHint,
                      suffixText: unitShort,
                      prefixIcon: const Icon(Icons.square_foot),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => _bypassAsSingleLot(s),
                    icon: const Icon(Icons.fast_forward),
                    label: Text(
                      s.kQuickStartWholeFarm,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
    final farmSurface = _totalFarmSurface;
    final allocated = _totalLotsSurface;
    final isExceeded = allocated > farmSurface && farmSurface > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Allocation progress bar
        Card(
          elevation: 1,
          color: isExceeded ? Colors.orange.shade50 : AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isExceeded ? Colors.orange : AppColors.treeLine,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.kAllocatedSurface,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${allocated.toStringAsFixed(1)} / ${farmSurface.toStringAsFixed(1)} $unitShort',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExceeded ? Colors.orange.shade900 : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: farmSurface > 0
                      ? (allocated / farmSurface).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: Colors.grey.shade200,
                  color: isExceeded ? Colors.orange : AppColors.primary,
                ),
                if (isExceeded)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      s.kLotsSurfaceExceededWarning,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLotsHeaderCard(s),
        const SizedBox(height: 12),
        _buildLotsList(s, unitShort),
      ],
    );
  }

  Widget _buildLotsHeaderCard(AppStrings s) {
    return Card(
      elevation: 2,
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.grid_view_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.kLotsSectionTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsList(AppStrings s, String unitShort) {
    if (_lots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.layers_clear, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(s.kNoLotsAddedYet),
              const SizedBox(height: 8),
              ElevatedButton.icon(
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
      separatorBuilder: (_, index) => const SizedBox(height: 16),
      itemBuilder: (ctx, index) {
        return _buildLotCard(_lots[index], index, s, unitShort);
      },
    );
  }

  Widget _buildLotCard(
      LotItem lot, int index, AppStrings s, String unitShort) {
    final lotNumberStr = '${s.kLot} ${index + 1}';

    return Card(
      elevation: 2,
      color: AppColors.lotCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.treeLine, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lotNumberStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: s.kRemoveLot,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeLotAt(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lot.nameController,
              decoration: InputDecoration(
                labelText: s.kLotNameLabel,
                hintText: s.kLotNameHint,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lot.surfaceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${s.kLotSurfaceLabel} ($unitShort)',
                hintText: s.kLotSurfaceHint,
                suffixText: unitShort,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.crop_square),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildSubplotsSection(lot, s, unitShort),
          ],
        ),
      ),
    );
  }

  Widget _buildSubplotsSection(
      LotItem lot, AppStrings s, String unitShort) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.subdirectory_arrow_right,
                color: AppColors.accent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.kSubplotsSectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addSubplot(lot, s),
              icon: const Icon(Icons.add, size: 15),
              label: Text(
                s.kAddSubplot,
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 12),
          for (var i = 0; i < lot.subplots.length; i++)
            _buildSubplotCard(lot, lot.subplots[i], i, s, unitShort),
        ],
      ],
    );
  }

  Widget _buildSubplotCard(LotItem lot, SubplotItem subplot, int index,
      AppStrings s, String unitShort) {
    final subplotNumberStr = '${s.kSubplot} ${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.subplotCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subplotNumberStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: s.kRemoveSubplot,
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: () => _removeSubplotAt(lot, index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: subplot.nameController,
            decoration: InputDecoration(
              isDense: true,
              labelText: s.kSubplotNameLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: subplot.surfaceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              labelText: '${s.kSubplotSurfaceLabel} ($unitShort)',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Farm Summary Card
        Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.treeLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.kSummaryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildSummaryRow(
                  s.kFarm,
                  _farmNameController.text.isNotEmpty
                      ? _farmNameController.text
                      : '-',
                  isBold: true,
                ),
                _buildSummaryRow(
                  s.kCountryLabel,
                  _countryController.text.isNotEmpty
                      ? _countryController.text
                      : '-',
                ),
                if (_latitude != null && _longitude != null)
                  _buildSummaryRow(
                    s.kFarmLocationLabel,
                    '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    isBold: true,
                  ),
                _buildSummaryRow(
                  s.kTotalSurfaceLabel,
                  '${_totalSurfaceController.text} $unitShort',
                ),
                _buildSummaryRow(
                  s.kLotsCountLabel,
                  '${_lots.length}',
                ),
                if (_lots.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${s.kLotsDistribution}:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  for (final lot in _lots)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: Text(
                        '• ${lot.nameController.text}: ${lot.surfaceController.text} $unitShort',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // NASA Environmental Card
        Card(
          elevation: 2,
          color: const Color(0xFFF1F8E9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primaryLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.kNasaDataReady,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.kNasaDataDescription,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar(AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _currentStep--);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        s.kPreviousStep,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                        _getCurrentLocation(s);
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _currentStep == 2
                            ? Icons.save
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
