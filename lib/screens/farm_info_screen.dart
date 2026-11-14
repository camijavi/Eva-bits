import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../languages/app_strings.dart';

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
  const FarmInfoScreen({super.key});

  @override
  State<FarmInfoScreen> createState() => _FarmInfoScreenState();
}

class _FarmInfoScreenState extends State<FarmInfoScreen> {
  final _step1FormKey = GlobalKey<FormState>();

  // Wizard state: 0 = Farm Info, 1 = Lots & Subplots, 2 = Summary & Ivy
  int _currentStep = 0;

  // Farm General Controllers
  late final TextEditingController _farmNameController;
  late final TextEditingController _totalSurfaceController;
  late final TextEditingController _geographicZoneController;
  late final TextEditingController _lotsCountController;

  SurfaceUnit _selectedUnit = SurfaceUnit.hectares;
  final List<LotItem> _lots = [];

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController();
    _totalSurfaceController = TextEditingController();
    _geographicZoneController = TextEditingController();
    _lotsCountController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _totalSurfaceController.dispose();
    _geographicZoneController.dispose();
    _lotsCountController.dispose();
    for (final lot in _lots) {
      lot.dispose();
    }
    super.dispose();
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

    final total = _totalSurfaceController.text.trim();
    for (final lot in _lots) {
      lot.dispose();
    }
    _lots.clear();

    setState(() {
      _lots.add(
        LotItem(
          nameController: TextEditingController(
            text: '${_farmNameController.text.trim()} - Lote Principal',
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
    return ValueListenableBuilder<AppLanguageType>(
      valueListenable: AppLanguage.current,
      builder: (context, currentLang, _) {
        final s = AppLanguage.strings;
        final unitShort = _getUnitShortName(_selectedUnit, s);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 1,
            title: Text(
              s.kFarmInfoTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              TextButton.icon(
                onPressed: AppLanguage.toggleLanguage,
                icon: const Icon(Icons.language, color: Colors.white, size: 20),
                label: Text(
                  AppLanguage.isSpanish ? s.kEnglish : s.kSpanish,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              _buildStepIndicator(s),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
              _buildBottomNavigationBar(s),
            ],
          ),
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
                      Text(
                        s.kGeneralInfoSection,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                  TextFormField(
                    controller: _geographicZoneController,
                    decoration: InputDecoration(
                      labelText: s.kGeographicZoneLabel,
                      hintText: s.kGeographicZoneHint,
                      prefixIcon: const Icon(Icons.map),
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Estelí',
                      'Matagalpa',
                      'Jinotega',
                      'León',
                    ].map((zone) {
                      return ActionChip(
                        avatar: const Icon(Icons.location_on, size: 14),
                        label: Text(zone, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            _geographicZoneController.text = zone;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SurfaceUnit>(
                    initialValue: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: s.kSurfaceUnitLabel,
                      hintText: s.kSurfaceUnitHint,
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => _bypassAsSingleLot(s),
                    icon: const Icon(Icons.fast_forward),
                    label: Text(s.kQuickStartWholeFarm),
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
                    Text(
                      s.kAllocatedSurface,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _addLot(s),
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.kAddLot),
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
              const Text('Aún no has agregado lotes.'),
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
                Text(
                  lotNumberStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
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
                color: AppColors.accent, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.kSubplotsSectionTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addSubplot(lot, s),
              icon: const Icon(Icons.add, size: 16),
              label: Text(s.kAddSubplot),
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
              Text(
                subplotNumberStr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
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
                    Text(
                      s.kSummaryTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
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
                  s.kGeographicZoneLabel,
                  _geographicZoneController.text.isNotEmpty
                      ? _geographicZoneController.text
                      : '-',
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
                  const Text(
                    'Distribución de Lotes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    Text(
                      s.kNasaDataReady,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Datos satelitales NASA POWER (radiación y lluvia) y SMAP (humedad del suelo) sincronizados con tu zona.',
                  style: TextStyle(fontSize: 12),
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  setState(() => _currentStep--);
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(s.kPreviousStep),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (_currentStep == 0) {
                  if (_step1FormKey.currentState!.validate()) {
                    setState(() => _currentStep = 1);
                  }
                } else if (_currentStep == 1) {
                  setState(() => _currentStep = 2);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text(s.kFormSavedSuccessfully),
                    ),
                  );
                }
              },
              icon: Icon(
                _currentStep == 2 ? Icons.save : Icons.arrow_forward,
              ),
              label: Text(
                _currentStep == 2 ? s.kSave : s.kNextStep,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
