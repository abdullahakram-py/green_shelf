import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/widgets/category_selector.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../data/models/food_item.dart';
import '../../data/providers/food_provider.dart';

class AddEditFoodScreen extends ConsumerStatefulWidget {
  final FoodItem? itemToEdit;
  final String? initialName;
  final double? initialQuantity;
  final String? initialUnit;
  final String? initialCategory;

  const AddEditFoodScreen({
    super.key,
    this.itemToEdit,
    this.initialName,
    this.initialQuantity,
    this.initialUnit,
    this.initialCategory,
  });

  @override
  ConsumerState<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends ConsumerState<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _thresholdController;

  late String _category;
  late double _quantity;
  late String _unit;
  late String _location;
  late DateTime _purchaseDate;
  late DateTime _expiryDate;
  late int _remindLeadDays;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    final now = DateTime.now();

    _nameController = TextEditingController(text: item?.name ?? widget.initialName ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _thresholdController = TextEditingController(
      text: item?.lowStockThreshold != null ? item!.lowStockThreshold!.toString() : '',
    );

    _category = item?.category ?? widget.initialCategory ?? 'vegetable';
    _quantity = item?.quantity ?? widget.initialQuantity ?? 1.0;
    _unit = item?.unit ?? widget.initialUnit ?? 'pcs';
    _location = item?.location ?? 'Fridge';
    _purchaseDate = item?.purchaseDateTime ?? now;
    _expiryDate = item?.expiryDateTime ?? now.add(const Duration(days: 7));
    _remindLeadDays = 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final initial = isExpiry ? _expiryDate : _purchaseDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  void _applyQuickExpiry(int days) {
    setState(() {
      _expiryDate = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final threshold = double.tryParse(_thresholdController.text.trim());

      final food = FoodItem(
        id: widget.itemToEdit?.id,
        name: _nameController.text.trim(),
        category: _category.toLowerCase(),
        quantity: _quantity,
        unit: _unit,
        lowStockThreshold: threshold,
        purchaseDate: DateHelpers.toIsoDate(_purchaseDate),
        expiryDate: DateHelpers.toIsoDate(_expiryDate),
        location: _location,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        notificationId: widget.itemToEdit?.notificationId,
        createdAt: widget.itemToEdit?.createdAt ?? now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      if (widget.itemToEdit == null) {
        await ref.read(foodListProvider.notifier).addItem(food);
      } else {
        await ref.read(foodListProvider.notifier).updateItem(food);
      }

      if (mounted) {
        final reminderText = _remindLeadDays == 0
            ? 'on expiry day'
            : '$_remindLeadDays ${_remindLeadDays == 1 ? 'day' : 'days'} before';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food.name} saved · reminder set $reminderText'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save food: $e'),
            backgroundColor: AppColors.statusExpired,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemToEdit != null;
    final pastNamesAsync = ref.watch(pastItemNamesProvider);
    final pastNames = pastNamesAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? 'Edit food' : 'Add food',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with Autocomplete
                      _buildFieldLabel('Name'),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: _nameController.text),
                        optionsBuilder: (TextEditingValue textVal) {
                          if (textVal.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return pastNames.where((option) =>
                              option.toLowerCase().contains(textVal.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          _nameController.text = selection;
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onEditingComplete) {
                          if (_nameController.text.isNotEmpty && controller.text.isEmpty) {
                            controller.text = _nameController.text;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (val) => _nameController.text = val,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Milk, Spinach, Eggs',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter a food name';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Category Selector
                      _buildFieldLabel('Category'),
                      CategorySelector(
                        selectedCategory: _category,
                        onSelected: (cat) => setState(() => _category = cat),
                      ),
                      const SizedBox(height: 20),

                      // Quantity and Unit Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Quantity'),
                                QuantityStepper(
                                  value: _quantity,
                                  step: _unit == 'kg' || _unit == 'Litres' ? 0.5 : 1.0,
                                  min: _unit == 'kg' || _unit == 'Litres' ? 0.1 : 1.0,
                                  onChanged: (newVal) => setState(() => _quantity = newVal),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Unit'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F2ED),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: AppConstants.units.contains(_unit) ? _unit : AppConstants.units.first,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.textPrimary),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items: AppConstants.units.map((u) {
                                        return DropdownMenuItem(
                                          value: u,
                                          child: Text(u),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _unit = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Expiry Date Picker & Quick Chips
                      _buildFieldLabel('Expiry date'),
                      InkWell(
                        onTap: () => _pickDate(isExpiry: true),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F2ED),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateHelpers.formatReadable(_expiryDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: AppColors.primaryDark),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Expiry Chips (+3 days, +1 week, +1 month)
                      Row(
                        children: [
                          _buildQuickDateChip('+3 days', 3),
                          const SizedBox(width: 8),
                          _buildQuickDateChip('+1 week', 7),
                          const SizedBox(width: 8),
                          _buildQuickDateChip('+1 month', 30),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Storage Location (Fridge, Freezer, Cupboard)
                      _buildFieldLabel('Storage'),
                      Row(
                        children: AppConstants.storageLocations.map((loc) {
                          final isSelected = _location.toLowerCase() == loc.toLowerCase();
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _location = loc),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryDark : const Color(0xFFF3F2ED),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primaryDark : const Color(0xFFE5E5DC),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    loc,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Remind Me Dropdown
                      _buildFieldLabel('Remind me'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F2ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _remindLeadDays,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textPrimary),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('On day of expiry')),
                              DropdownMenuItem(value: 1, child: Text('1 day before')),
                              DropdownMenuItem(value: 2, child: Text('2 days before')),
                              DropdownMenuItem(value: 3, child: Text('3 days before')),
                              DropdownMenuItem(value: 7, child: Text('1 week before')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _remindLeadDays = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Low Stock Threshold (optional)
                      _buildFieldLabel('Low stock alert threshold (optional)'),
                      TextFormField(
                        controller: _thresholdController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 2 (reminds when quantity drops to 2 or less)',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes (optional)
                      _buildFieldLabel('Notes (optional)'),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Brand, opened on Tuesday, recipe idea',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Pinned Bottom Save Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      offset: const Offset(0, -4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEdit ? 'Save changes' : 'Save item',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int days) {
    return Expanded(
      child: InkWell(
        onTap: () => _applyQuickExpiry(days),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F2ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5DC)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
