import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pyrosfitmovil/core/constants/legal_constants.dart';
import 'package:pyrosfitmovil/core/widgets/legal/medical_disclaimer_card.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class TermsDialog extends StatefulWidget {
  final int initialTab; // 0: Términos, 1: Privacidad
  final VoidCallback? onAccept;

  const TermsDialog({
    super.key,
    this.initialTab = 0,
    this.onAccept,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTab = 0,
    VoidCallback? onAccept,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TermsDialog(
        initialTab: initialTab,
        onAccept: onAccept,
      ),
    );
  }

  @override
  State<TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<TermsDialog> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  Widget _buildSectionItem(LegalSection sec) {
    if (sec.isWarning) {
      return const MedicalDisclaimerCard(
        margin: EdgeInsets.only(bottom: 12),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sec.number,
                  style: const TextStyle(
                    color: AppTheme.primaryGlow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sec.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (sec.intro != null) ...[
            const SizedBox(height: 6),
            Text(
              sec.intro!,
              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
            ),
          ],
          if (sec.bullets != null && sec.bullets!.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...sec.bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.primaryGlow, fontSize: 12)),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (sec.subsections != null && sec.subsections!.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...sec.subsections!.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sub.subtitle != null)
                      Text(
                        '• ${sub.subtitle}:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      sub.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppTheme.primaryGlow, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documentación Legal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Vigencia: Agosto de 2026',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = 0),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? AppTheme.primary.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: _activeTab == 0
                                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: _activeTab == 0 ? AppTheme.primaryGlow : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '1. Términos de Uso',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _activeTab == 0 ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = 1),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? AppTheme.primary.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: _activeTab == 1
                                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.privacy_tip_outlined,
                                size: 14,
                                color: _activeTab == 1 ? AppTheme.primaryGlow : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '2. Privacidad',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _activeTab == 1 ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _activeTab == 0
                            ? 'Bienvenido a PYROSFIT. Estos Términos y Condiciones regulan el acceso y uso de nuestra aplicación móvil para nuestra comunidad de Gente Fit.'
                            : 'En PYROSFIT, valoramos profundamente la privacidad de nuestra comunidad. Esta política describe cómo recopilamos, usamos y protegemos tu información.',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                      ),
                    ),
                    if (_activeTab == 0)
                      ...termsOfUseSections.map(_buildSectionItem)
                    else
                      ...privacyPolicySections.map(_buildSectionItem),
                  ],
                ),
              ),
            ),

            // Footer
            const Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/terms');
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primaryGlow),
                    label: const Text(
                      'Página completa',
                      style: TextStyle(color: AppTheme.primaryGlow, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: BorderSide(color: AppTheme.border.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
                  ),
                  if (widget.onAccept != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        widget.onAccept!();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
                      label: const Text('Aceptar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
