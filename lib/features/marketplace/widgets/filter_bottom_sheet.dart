import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(double? minPrice, double? maxPrice, int? bedrooms, int? bathrooms) onApply;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialBedrooms;
  final int? initialBathrooms;

  const FilterBottomSheet({
    Key? key,
    required this.onApply,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialBedrooms,
    this.initialBathrooms,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  int? _selectedBedrooms;
  int? _selectedBathrooms;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
        text: widget.initialMinPrice != null ? widget.initialMinPrice!.toStringAsFixed(0) : '');
    _maxPriceController = TextEditingController(
        text: widget.initialMaxPrice != null ? widget.initialMaxPrice!.toStringAsFixed(0) : '');
    _selectedBedrooms = widget.initialBedrooms;
    _selectedBathrooms = widget.initialBathrooms;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);
    widget.onApply(minPrice, maxPrice, _selectedBedrooms, _selectedBathrooms);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedBedrooms = null;
      _selectedBathrooms = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Price Range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '\$ ',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '\$ ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Bedrooms',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (index) {
                final val = index == 0 ? null : index; // 0 means "Any"
                final isSelected = _selectedBedrooms == val;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(val == null ? 'Any' : '$val+'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBedrooms = val;
                      });
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.surfaceColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bathrooms',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (index) {
                final val = index == 0 ? null : index; // 0 means "Any"
                final isSelected = _selectedBathrooms == val;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(val == null ? 'Any' : '$val+'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBathrooms = val;
                      });
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.surfaceColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}
