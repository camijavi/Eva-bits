import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/crop_types.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';
import 'crop_picker_sheet.dart';

/// Shows a bottom sheet modal to either create a new lot or edit an existing lot.
Future<bool?> showNewOrEditLotModal(
  BuildContext context, {
  Map<String, dynamic>? lot,
  required VoidCallback onSaved,
  String? surfaceUnit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => NewEditPlotSheet(
      lot: lot,
      onSaved: onSaved,
      surfaceUnit: surfaceUnit,
    ),
  );
}

class NewEditPlotSheet extends StatefulWidget {
  final Map<String, dynamic>? lot;
  final VoidCallback onSaved;
  final String? surfaceUnit;

  const NewEditPlotSheet({
    super.key,
    this.lot,
    required this.onSaved,
    this.surfaceUnit,
  });

  bool get isEditing => lot != null;

  String get effectiveSurfaceUnit =>
      surfaceUnit ?? AppSettings.getSurfaceUnitShort();

  @override
  State<NewEditPlotSheet> createState() => _NewEditPlotSheetState();
}

class _NewEditPlotSheetState extends State<NewEditPlotSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _surfaceController;
  String? _selectedCrop;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.lot?['name']?.toString() ?? '',
    );
    _surfaceController = TextEditingController(
      text: widget.lot?['surface']?.toString() ?? '',
    );
    _selectedCrop = widget.lot?['crop']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surfaceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final surfaceVal = double.tryParse(_surfaceController.text.trim()) ?? 0.0;
      final nameVal = _nameController.text.trim();

      if (widget.isEditing) {
        final lotMap = Map<String, dynamic>.from(widget.lot!);
        lotMap['name'] = nameVal;
        lotMap['surface'] = surfaceVal;
        lotMap['crop'] = _selectedCrop;

        await DatabaseManager().updateLot(lotMap);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                s.kLotUpdatedSuccessfully,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      } else {
        final farmId = await DatabaseManager().getOrCreateDefaultFarmId();
        await DatabaseManager().insertLot({
          'farm_id': farmId,
          'name': nameVal,
          'surface': surfaceVal,
          'crop': _selectedCrop,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                s.kLotCreatedSuccessfully,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
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

  Future<void> _handleDelete(AppStrings s) async {
    if (!widget.isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.kDeleteLotConfirm,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2E1C),
          ),
        ),
        content: Text(
          s.kDeleteLotWarning,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              s.kCancel,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              s.kDeleteLot,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final lotId = widget.lot!['id'] as int;
      await DatabaseManager().deleteLot(lotId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              s.kLotDeletedSuccessfully,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(s.kErrorSavingData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final s = AppLanguage.strings;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
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

              // Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        widget.isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_location_alt_outlined,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing ? s.kEditLot : s.kAddNewLot,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E1C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isEditing
                              ? s.kEditFarmInfo
                              : s.kLotsScreenSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.isEditing)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade600,
                        size: 26,
                      ),
                      tooltip: s.kDeleteLot,
                      onPressed: () => _handleDelete(s),
                    ),
                ],
              ),
              const SizedBox(height: 22),

              // Lot Name Field
              Text(
                s.kLotNameLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E1C),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: s.kLotNameHint,
                  filled: true,
                  fillColor: const Color(0xFFF9FBF8),
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2E1C),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return s.kFieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Surface Area Field
              Text(
                '${s.kLotSurfaceLabel} (${widget.effectiveSurfaceUnit})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E1C),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _surfaceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: s.kLotSurfaceHint,
                  filled: true,
                  fillColor: const Color(0xFFF9FBF8),
                  prefixIcon: const Icon(
                    Icons.square_foot_rounded,
                    color: AppColors.primary,
                  ),
                  suffixText: widget.effectiveSurfaceUnit,
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2E1C),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return s.kFieldRequired;
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return s.kInvalidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Crop Selector
              Text(
                s.kCropLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E1C),
                ),
              ),
              const SizedBox(height: 8),
              _buildCropSelector(s),
              const SizedBox(height: 26),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        s.kCancel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5A37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : () => _handleSave(s),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isEditing ? s.kSave : s.kSaveLot,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropSelector(AppStrings s) {
    final isSpanish = AppLanguage.isSpanish;
    final crop = CropTypes.getByKey(_selectedCrop);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final result = await showCropPickerModal(
          context,
          selectedCropKey: _selectedCrop,
        );
        if (result != null) {
          setState(() {
            _selectedCrop = result.isEmpty ? null : result;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (crop != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: crop.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    crop.icon,
                    size: 18,
                    color: crop.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  crop.localizedName(isSpanish),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E1C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.kChangeCrop,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5A37),
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.eco_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.kCropHint,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
