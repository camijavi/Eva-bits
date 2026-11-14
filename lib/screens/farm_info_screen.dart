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
  final _formKey = GlobalKey<FormState>();

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

  void _onLotsCountChanged(String value, AppStrings s) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) return;
    _syncLotsCount(parsed, s);
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

  void _onSubplotsCountChanged(LotItem lot, String value, AppStrings s) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) return;
    _syncSubplotsCount(lot, parsed, s);
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

  void _submitForm(AppStrings s) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final farmSurface = double.tryParse(_totalSurfaceController.text) ?? 0.0;
    double totalLotsSurface = 0.0;
    bool subplotsExceed = false;

    for (final lot in _lots) {
      final lotSurface = double.tryParse(lot.surfaceController.text) ?? 0.0;
      totalLotsSurface += lotSurface;

      double lotSubplotsSurface = 0.0;
      for (final subplot in lot.subplots) {
        lotSubplotsSurface +=
            double.tryParse(subplot.surfaceController.text) ?? 0.0;
      }
      if (lotSubplotsSurface > lotSurface && lotSurface > 0) {
        subplotsExceed = true;
      }
    }

    final lotsExceed = totalLotsSurface > farmSurface && farmSurface > 0;

    _showSummaryDialog(
      s,
      lotsExceedWarning: lotsExceed,
      subplotsExceedWarning: subplotsExceed,
    );
  }

  void _showSummaryDialog(
    AppStrings s, {
    required bool lotsExceedWarning,
    required bool subplotsExceedWarning,
  }) {
    final unitShort = _getUnitShortName(_selectedUnit, s);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.agriculture, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.kSummaryTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lotsExceedWarning)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      s.kLotsSurfaceExceededWarning,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (subplotsExceedWarning)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      s.kSubplotsSurfaceExceededWarning,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildSummaryRow(
                  s.kFarmer,
                  s.kFarmer,
                  isBold: true,
                ),
                _buildSummaryRow(
                  s.kFarm,
                  _farmNameController.text,
                  isBold: true,
                ),
                _buildSummaryRow(
                  s.kTotalSurfaceLabel,
                  '${_totalSurfaceController.text} $unitShort',
                ),
                _buildSummaryRow(
                  s.kGeographicZoneLabel,
                  _geographicZoneController.text,
                ),
                _buildSummaryRow(
                  s.kSurfaceUnitLabel,
                  _getUnitFullName(_selectedUnit, s),
                ),
                _buildSummaryRow(
                  s.kLotsCountLabel,
                  '${_lots.length}',
                ),
                const Divider(height: 24),
                Text(
                  s.kLotsSectionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _lots.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${_lots[i].nameController.text} (${_lots[i].surfaceController.text} $unitShort)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (_lots[i].subplots.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.kSubplotsSectionTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                for (final sub in _lots[i].subplots)
                                  Text(
                                    '  - ${sub.nameController.text}: ${sub.surfaceController.text} $unitShort',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 2),
                            child: Text(
                              s.kNoSubplots,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.kClose),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text(s.kFormSavedSuccessfully),
                  ),
                );
              },
              child: Text(s.kConfirmSave),
            ),
          ],
        );
      },
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
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHierarchyHeader(s),
                const SizedBox(height: 16),
                _buildGeneralInfoCard(s, unitShort),
                const SizedBox(height: 20),
                _buildLotsHeaderCard(s),
                const SizedBox(height: 12),
                _buildLotsList(s, unitShort),
                const SizedBox(height: 24),
                _buildSaveButton(s),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHierarchyHeader(AppStrings s) {
    return Card(
      elevation: 0,
      color: AppColors.lotCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.treeLine, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.person, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              s.kFarmer,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            const SizedBox(width: 8),
            const Icon(Icons.landscape, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              s.kFarm,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              s.kLotsSectionTitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard(AppStrings s, String unitShort) {
    return Card(
      elevation: 2,
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildLotsHeaderCard(AppStrings s) {
    return Card(
      elevation: 2,
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.kLotsSectionTitle,
                    style: const TextStyle(
                      fontSize: 18,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lotsCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.kLotsCountLabel,
                      hintText: s.kLotsCountHint,
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) => _onLotsCountChanged(val, s),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return s.kFieldRequired;
                      }
                      final parsed = int.tryParse(val);
                      if (parsed == null || parsed < 0) {
                        return s.kLotsCountPositive;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _lots.isNotEmpty
                      ? () => _removeLotAt(_lots.length - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _addLot(s),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLotsList(AppStrings s, String unitShort) {
    if (_lots.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
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
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return s.kFieldRequired;
                }
                return null;
              },
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: lot.subplotsCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.kSubplotsCountLabel,
                  hintText: s.kSubplotsCountHint,
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) => _onSubplotsCountChanged(lot, val, s),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return s.kFieldRequired;
                  }
                  final parsed = int.tryParse(val);
                  if (parsed == null || parsed < 0) {
                    return s.kSubplotsCountPositive;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: lot.subplots.isNotEmpty
                  ? () => _removeSubplotAt(lot, lot.subplots.length - 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _addSubplot(lot, s),
              icon: const Icon(Icons.add),
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
              hintText: s.kSubplotNameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
          TextFormField(
            controller: subplot.surfaceController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              isDense: true,
              labelText: '${s.kSubplotSurfaceLabel} ($unitShort)',
              hintText: s.kSubplotSurfaceHint,
              suffixText: unitShort,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppStrings s) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _submitForm(s),
        icon: const Icon(Icons.save),
        label: Text(
          s.kSave,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

