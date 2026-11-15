import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/agricultural_locations.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';

/// Opens the farm editing modal bottom sheet on top of the current screen.
Future<bool?> showEditFarmInfoModal(
  BuildContext context, {
  required Map<String, dynamic> farm,
  required VoidCallback onFarmUpdated,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditFarmInfoSheet(
      farm: farm,
      onFarmUpdated: onFarmUpdated,
    ),
  );
}

class EditFarmInfoSheet extends StatefulWidget {
  final Map<String, dynamic> farm;
  final VoidCallback onFarmUpdated;

  const EditFarmInfoSheet({
    super.key,
    required this.farm,
    required this.onFarmUpdated,
  });

  @override
  State<EditFarmInfoSheet> createState() => _EditFarmInfoSheetState();
}

class _EditFarmInfoSheetState extends State<EditFarmInfoSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _countryController;
  late TextEditingController _surfaceController;

  late String _selectedUnit;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  String? _selectedLocationId;
  bool _isCustomLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.farm['name']?.toString() ?? '',
    );
    final initialCountry = widget.farm['country']?.toString() ?? '';
    _countryController = TextEditingController(text: initialCountry);
    final match = AgriculturalLocation.findByText(initialCountry);
    if (match != null) {
      _selectedLocationId = match.id;
      _isCustomLocation = false;
    } else if (initialCountry.isNotEmpty) {
      _selectedLocationId = AgriculturalLocation.customId;
      _isCustomLocation = true;
    } else {
      _selectedLocationId = 'nic_esteli';
      _isCustomLocation = false;
      _countryController.text = AgriculturalLocation.presets.first.displayName;
    }

    _surfaceController = TextEditingController(
      text: widget.farm['total_surface']?.toString() ?? '',
    );

    _selectedUnit = widget.farm['surface_unit']?.toString() ?? 'ha';
    _latitude = (widget.farm['latitude'] is num)
        ? (widget.farm['latitude'] as num).toDouble()
        : null;
    _longitude = (widget.farm['longitude'] is num)
        ? (widget.farm['longitude'] as num).toDouble()
        : null;
    if (_latitude == null && match != null) {
      _latitude = match.latitude;
      _longitude = match.longitude;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _surfaceController.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition(AppStrings s) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade900,
            content: Text(s.kGpsServiceDisabled),
          ),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange.shade900,
              content: Text(s.kGpsPermissionDenied),
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text(s.kGpsPermissionDeniedPermanently),
          ),
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

  Future<void> _refreshGpsLocation(AppStrings s) async {
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

  Future<void> _saveChanges(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;

    final parsedSurface = double.tryParse(_surfaceController.text.trim());
    if (parsedSurface == null || parsedSurface <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text(s.kInvalidNumber),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final farmId = widget.farm['id'];
      final updatedFarmData = {
        'id': farmId,
        'name': _nameController.text.trim(),
        'country': _countryController.text.trim(),
        'surface_unit': _selectedUnit,
        'total_surface': parsedSurface,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      await DatabaseManager().updateFarm(updatedFarmData);

      if (mounted) {
        widget.onFarmUpdated();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.kFarmUpdatedSuccessfully,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
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

  String _getUnitDisplay(String unit, AppStrings s) {
    switch (unit.toLowerCase()) {
      case 'acres':
      case 'acre':
        return s.kUnitAcres;
      case 'm2':
      case 'm²':
      case 'square meters':
      case 'metros cuadrados':
        return s.kUnitSquareMeters;
      case 'tareas':
      case 'tarea':
        return s.kUnitTareas;
      case 'ha':
      case 'hectares':
      case 'hectáreas':
      default:
        return s.kUnitHectares;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, _, child) {
        final s = AppLanguage.strings;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.getCardBg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Title and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            s.kEditFarmInfo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2E1C),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Farm Name
                  Text(
                    s.kFarmNameLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E4034),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: s.kFarmNameHint,
                      prefixIcon: const Icon(Icons.agriculture_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF9FAF8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
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

                  // Country
                  Text(
                    s.kCountryLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E4034),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLocationId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: s.kCountryHint,
                      prefixIcon: const Icon(Icons.public_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF9FAF8),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
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
                  ),
                  if (_isCustomLocation) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _countryController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Ej. USA, Iowa / España, Sevilla / Brasil',
                        prefixIcon: const Icon(Icons.edit_location_alt_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF9FAF8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
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

                  // Surface and Surface Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.kTotalSurfaceLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E4034),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _surfaceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                hintText: s.kTotalSurfaceHint,
                                prefixIcon:
                                    const Icon(Icons.square_foot_rounded),
                                filled: true,
                                fillColor: const Color(0xFFF9FAF8),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return s.kFieldRequired;
                                }
                                final n = double.tryParse(val.trim());
                                if (n == null || n <= 0) {
                                  return s.kInvalidNumber;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.kSurfaceUnitLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E4034),
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                                  ['ha', 'acres', 'm2', 'tareas'].contains(
                                _selectedUnit.toLowerCase(),
                              )
                                      ? _selectedUnit.toLowerCase()
                                      : 'ha',
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF9FAF8),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'ha',
                                  child: Text(
                                    _getUnitDisplay('ha', s),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'acres',
                                  child: Text(
                                    _getUnitDisplay('acres', s),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'm2',
                                  child: Text(
                                    _getUnitDisplay('m2', s),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'tareas',
                                  child: Text(
                                    _getUnitDisplay('tareas', s),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUnit = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // GPS Location Section
                  Text(
                    s.kFarmLocationLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E4034),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6E4D8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.gps_fixed_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.kGpsCoordinates,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (_latitude != null && _longitude != null)
                                    ? '${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°'
                                    : s.kLocationNotCapturedYet,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B2E1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _isGettingLocation
                              ? null
                              : () => _refreshGpsLocation(s),
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          tooltip: s.kRefreshLocation,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : () => _saveChanges(s),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        s.kSaveChanges,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}