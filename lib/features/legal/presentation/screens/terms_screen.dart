import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/constants/legal_constants.dart';
import 'package:pyrosfitmovil/core/widgets/legal/medical_disclaimer_card.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  int _selectedTabIndex = 0; // 0: Términos de Uso, 1: Política de Privacidad

  Widget _buildSection(LegalSection sec) {
    if (sec.isWarning) {
      return const MedicalDisclaimerCard(
        margin: EdgeInsets.symmetric(vertical: 8),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  sec.number,
                  style: const TextStyle(
                    color: AppTheme.primaryGlow,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sec.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (sec.intro != null) ...[
            const SizedBox(height: 10),
            Text(
              sec.intro!,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
          if (sec.bullets != null && sec.bullets!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...sec.bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.primaryGlow, fontSize: 13)),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (sec.subsections != null && sec.subsections!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...sec.subsections!.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sub.subtitle != null)
                      Text(
                        '• ${sub.subtitle}:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      sub.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
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
    final activeSections = _selectedTabIndex == 0 ? termsOfUseSections : privacyPolicySections;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text(
          'Documentación Legal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: context.pyrosStyles.buildMeshBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF221F1B), Color(0xFF18181B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'DOCUMENTACIÓN OFICIAL',
                            style: TextStyle(
                              color: AppTheme.primaryGlow,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Text(
                          'Vigencia: Agosto 2026',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Términos, Privacidad & Exención Médica',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Regulaciones de acceso, deberes de usuario, exención de responsabilidad de salud y protección de datos para nuestra comunidad Gente Fit.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Tabs
              Container(
                height: 42,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? AppTheme.primary.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: _selectedTabIndex == 0
                                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 16,
                                color: _selectedTabIndex == 0 ? AppTheme.primaryGlow : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '1. Términos de Uso',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedTabIndex == 0 ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? AppTheme.primary.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            border: _selectedTabIndex == 1
                                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.5))
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.privacy_tip_outlined,
                                size: 16,
                                color: _selectedTabIndex == 1 ? AppTheme.primaryGlow : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '2. Política de Privacidad',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedTabIndex == 1 ? Colors.white : Colors.grey,
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
              const SizedBox(height: 16),

              // Cláusulas de la pestaña activa
              ...activeSections.map(_buildSection),

              // Card de Soporte Oficial
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail_outline_rounded, color: AppTheme.primaryGlow, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Dudas o consultas legales?',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Escríbenos a soporte@pyrosfit.com',
                            style: TextStyle(color: AppTheme.primaryGlow, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Center(
                child: Text(
                  '© ${DateTime.now().year} PyrosFit by GeekSolutions. Todos los derechos reservados.',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
