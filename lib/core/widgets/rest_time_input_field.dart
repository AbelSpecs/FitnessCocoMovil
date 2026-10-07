import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/time_utils.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class RestTimeInputField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String label;

  const RestTimeInputField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.label = 'Descanso',
  });

  @override
  State<RestTimeInputField> createState() => _RestTimeInputFieldState();
}

class _RestTimeInputFieldState extends State<RestTimeInputField> {
  late TextEditingController _controller;

  static const _presets = [
    {'label': '30s', 'value': '30'},
    {'label': '45s', 'value': '45'},
    {'label': '1 min', 'value': '60'},
    {'label': '1:30m', 'value': '90'},
    {'label': '2 min', 'value': '120'},
    {'label': '2:30m', 'value': '150'},
    {'label': '3 min', 'value': '180'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant RestTimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                      'Tiempos de descanso sugeridos',
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
                    final isSelected = _controller.text.trim() == preset['value'];
                    return ChoiceChip(
                      label: Text(preset['label']!),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: const Color(0xFF242427),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      onSelected: (_) {
                        _controller.text = preset['value']!;
                        widget.onChanged(preset['value']!);
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
    final totalSec = parseRestTimeToSeconds(rawText);
    final equivalentText = totalSec > 0 ? formatRestTimeDisplay(rawText) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: widget.label,
                  isDense: true,
                  hintText: 'Ej. 90s, 1:30',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.timer_outlined, color: AppTheme.primary, size: 18),
                    onPressed: () => _showPresetsModal(context),
                    tooltip: 'Sugerencias de descanso',
                  ),
                ),
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged(v);
                },
              ),
            ),
          ],
        ),
        if (equivalentText != null && equivalentText != rawText) ...[
          const SizedBox(height: 3),
          Text(
            'Equivale a: $equivalentText',
            style: const TextStyle(color: AppTheme.primaryGlow, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}
