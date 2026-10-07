import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/weight_utils.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class WeightInputField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String label;
  final bool compact;
  final bool enabled;

  const WeightInputField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.label = 'Peso',
    this.compact = false,
    this.enabled = true,
  });

  @override
  State<WeightInputField> createState() => _WeightInputFieldState();
}

class _WeightInputFieldState extends State<WeightInputField> {
  late TextEditingController _controller;
  String _unit = 'kg'; // 'kg' or 'lbs'

  static const _presets = [
    {'kg': 5, 'lbs': 11.0, 'label': '5 kg'},
    {'kg': 10, 'lbs': 22.0, 'label': '10 kg'},
    {'kg': 15, 'lbs': 33.0, 'label': '15 kg'},
    {'kg': 20, 'lbs': 44.1, 'label': '20 kg'},
    {'kg': 25, 'lbs': 55.1, 'label': '25 kg'},
    {'kg': 30, 'lbs': 66.1, 'label': '30 kg'},
    {'kg': 40, 'lbs': 88.2, 'label': '40 kg'},
    {'kg': 50, 'lbs': 110.2, 'label': '50 kg'},
    {'kg': 60, 'lbs': 132.3, 'label': '60 kg'},
    {'kg': 80, 'lbs': 176.4, 'label': '80 kg'},
    {'kg': 100, 'lbs': 220.5, 'label': '100 kg'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant WeightInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final currentKg = _unit == 'kg'
          ? (double.tryParse(_controller.text) ?? 0.0)
          : lbsToKg(_controller.text);
      final newKg = double.tryParse(widget.initialValue) ?? 0.0;
      if ((currentKg - newKg).abs() > 0.1) {
        if (_unit == 'lbs') {
          final inLbs = kgToLbs(newKg);
          _controller.text = inLbs > 0 ? formatWeightNumber(inLbs) : '';
        } else {
          _controller.text = newKg > 0 ? formatWeightNumber(newKg) : '';
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleUnitToggle(String newUnit) {
    if (newUnit == _unit) return;
    final currentVal = double.tryParse(_controller.text) ?? 0.0;
    setState(() {
      _unit = newUnit;
      if (currentVal > 0) {
        if (newUnit == 'lbs') {
          final inLbs = kgToLbs(currentVal);
          _controller.text = formatWeightNumber(inLbs);
        } else {
          final inKg = lbsToKg(currentVal);
          _controller.text = formatWeightNumber(inKg);
        }
      }
    });
  }

  void _onTextChange(String text) {
    setState(() {});
    if (text.trim().isEmpty) {
      widget.onChanged('');
      return;
    }
    final numVal = double.tryParse(text.trim());
    if (numVal == null || numVal < 0) return;

    if (_unit == 'lbs') {
      final inKg = lbsToKg(numVal);
      widget.onChanged(formatWeightNumber(inKg));
    } else {
      widget.onChanged(formatWeightNumber(numVal));
    }
  }

  void _showPresetsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pesos comunes sugeridos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _presets.map((preset) {
                    final kgVal = (preset['kg'] as num).toDouble();
                    final lbsVal = (preset['lbs'] as num).toDouble();
                    return ActionChip(
                      backgroundColor: const Color(0xFF242427),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      label: Text(
                        '${formatWeightNumber(kgVal)} kg  •  ${formatWeightNumber(lbsVal)} lbs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        if (_unit == 'lbs') {
                          _controller.text = formatWeightNumber(lbsVal);
                        } else {
                          _controller.text = formatWeightNumber(kgVal);
                        }
                        widget.onChanged(formatWeightNumber(kgVal));
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawText = _controller.text.trim();
    final numVal = double.tryParse(rawText) ?? 0.0;
    String? equivalentText;
    if (numVal > 0) {
      if (_unit == 'kg') {
        final lbs = kgToLbs(numVal);
        equivalentText = '${formatWeightNumber(lbs)} lbs';
      } else {
        final kg = lbsToKg(numVal);
        equivalentText = '${formatWeightNumber(kg)} kg';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: '${widget.label} (${_unit.toUpperCase()})',
                  isDense: true,
                  hintText: _unit == 'lbs' ? 'Ej. 45' : 'Ej. 20',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: widget.enabled
                            ? () => _handleUnitToggle(_unit == 'kg' ? 'lbs' : 'kg')
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _unit.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryGlow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 16),
                        onPressed: widget.enabled ? () => _showPresetsModal(context) : null,
                        tooltip: 'Pesos sugeridos',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      ),
                    ],
                  ),
                ),
                onChanged: _onTextChange,
              ),
            ),
          ],
        ),
        if (equivalentText != null) ...[
          const SizedBox(height: 3),
          Text(
            'Equivale a: $equivalentText',
            style: const TextStyle(
              color: AppTheme.primaryGlow,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
