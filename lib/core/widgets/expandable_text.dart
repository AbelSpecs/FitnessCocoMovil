import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/utils/exercise_filter.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

/// Widget de texto expandible para mvil:
/// - Emplea elipsis si el texto supera el nmero de lneas permitidas.
/// - Botn interactivo 'Ver ms' / 'Ver menos' que despliega el texto restante hacia abajo.
/// - Evita desbordamientos y solapamientos de elementos.
/// - Garantiza separacin adecuada entre palabras (wordSpacing).
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final Color? buttonColor;
  final String moreLabel;
  final String lessLabel;
  final bool cleanFormatting;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
    this.buttonColor,
    this.moreLabel = 'Ver más',
    this.lessLabel = 'Ver menos',
    this.cleanFormatting = true,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayText = widget.cleanFormatting
        ? cleanExerciseDescription(widget.text)
        : widget.text.trim();

    if (displayText.isEmpty) return const SizedBox.shrink();

    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final effectiveStyle = baseStyle.copyWith(
      wordSpacing: baseStyle.wordSpacing ?? 1.2,
      letterSpacing: baseStyle.letterSpacing ?? 0.2,
      height: baseStyle.height ?? 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: displayText, style: effectiveStyle);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity);

        final exceeds = tp.didExceedMaxLines;
        final primaryColor = widget.buttonColor ?? AppTheme.primary;

        if (!exceeds && !_isExpanded) {
          return Text(
            displayText,
            style: effectiveStyle,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                displayText,
                style: effectiveStyle,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? widget.lessLabel : widget.moreLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
