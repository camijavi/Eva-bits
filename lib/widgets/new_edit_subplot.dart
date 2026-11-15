import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../database/database_manager.dart';
import '../languages/app_strings.dart';
import '../services/app_settings.dart';

/// Shows a bottom sheet modal to either create a new subplot or edit an existing subplot.
Future<bool?> showNewOrEditSubplotModal(
  BuildContext context, {
  required int lotId,
  double? lotSurface,
  double? currentOtherSubplotsSurface,
  Map<String, dynamic>? subplot,
  required VoidCallback onSaved,
  String? surfaceUnit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => NewEditSubplotSheet(
      lotId: lotId,
      lotSurface: lotSurface,
      currentOtherSubplotsSurface: currentOtherSubplotsSurface,
      subplot: subplot,
      onSaved: onSaved,
      surfaceUnit: surfaceUnit,
    ),
  );
}

class NewEditSubplotSheet extends StatefulWidget {
  final int lotId;
  final double? lotSurface;
  final double? currentOtherSubplotsSurface;
  final Map<String, dynamic>? subplot;
  final VoidCallback onSaved;
  final String? surfaceUnit;

  const NewEditSubplotSheet({
    super.key,
    required this.lotId,
    this.lotSurface,
    this.currentOtherSubplotsSurface,
    this.subplot,
    required this.onSaved,
    this.surfaceUnit,
  });

  bool get isEditing => subplot != null;

  String get effectiveSurfaceUnit =>
      surfaceUnit ?? AppSettings.getSurfaceUnitShort();

  @override
  State<NewEditSubplotSheet> createState() => _NewEditSubplotSheetState();
}

class _NewEditSubplotSheetState extends State<NewEditSubplotSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _surfaceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.subplot?['name']?.toString() ?? '',
    );
    _surfaceController = TextEditingController(
      text: widget.subplot?['surface']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surfaceController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(AppStrings s) async {
    if (!_formKey.currentState!.validate()) return;

    final surfaceVal = double.tryParse(_surfaceController.text.trim()) ?? 0.0;
    final nameVal = _nameController.text.trim();

    // Check if adding/updating this subplot would exceed the lot's surface
    if (widget.lotSurface != null && widget.lotSurface! > 0) {
      final otherSurface = widget.currentOtherSubplotsSurface ?? 0.0;
      final totalNewSubplotSurface = otherSurface + surfaceVal;
      // Allow minor floating point tolerance
      if (totalNewSubplotSurface > (widget.lotSurface! + 0.001)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              '${s.kExceededLotSurfaceWarning} (${widget.lotSurface!.toStringAsFixed(2)} ${widget.effectiveSurfaceUnit})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing) {
        final subplotMap = Map<String, dynamic>.from(widget.subplot!);
        subplotMap['lot_id'] = widget.lotId;
        subplotMap['name'] = nameVal;
        subplotMap['surface'] = surfaceVal;

        await DatabaseManager().updateSubplot(subplotMap);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text(
                s.kSubplotUpdatedSuccessfully,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      } else {
        await DatabaseManager().insertSubplot({
          'lot_id': widget.lotId,
          'name': nameVal,
          'surface': surfaceVal,
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
                s.kSubplotCreatedSuccessfully,
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
          s.kDeleteSubplotConfirm,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B2E1C),
          ),
        ),
        content: Text(
          s.kDeleteSubplotWarning,
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
              s.kDeleteSubplot,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final subplotId = widget.subplot!['id'] as int;
      await DatabaseManager().deleteSubplot(subplotId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              s.kSubplotDeletedSuccessfully,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                            : Icons.grid_view_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing ? s.kEditSubplot : s.kAddNewSubplot,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E1C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.kSubplotSurfaceHint,
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
                      tooltip: s.kDeleteSubplot,
                      onPressed: () => _handleDelete(s),
                    ),
                ],
              ),
              const SizedBox(height: 22),

              // Subplot Name Field
              Text(
                s.kSubplotNameLabel,
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
                  hintText: s.kSubplotNameHint,
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
                '${s.kSubplotSurfaceLabel} (${widget.effectiveSurfaceUnit})',
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
                  hintText: s.kSubplotSurfaceHint,
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
                                  widget.isEditing
                                      ? s.kSave
                                      : s.kSaveSubplot,
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
}
