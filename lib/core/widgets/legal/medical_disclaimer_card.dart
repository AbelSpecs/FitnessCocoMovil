import 'package:flutter/material.dart';

class MedicalDisclaimerCard extends StatelessWidget {
  final bool compact;
  final EdgeInsetsGeometry? margin;

  const MedicalDisclaimerCard({
    super.key,
    this.compact = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        '1.3 Exención de Responsabilidad Médica',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'IMPORTANTE',
                        style: TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                    children: [
                      TextSpan(
                        text: 'No somos profesionales médicos: ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'El contenido, rutinas y herramientas de PYROSFIT tienen fines informativos y motivacionales. No constituyen asesoramiento médico, diagnóstico o tratamiento.',
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Consulta previa: ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'Debes consultar a un médico antes de iniciar programas de entrenamiento o cambios en tu dieta, especialmente si tienes condiciones preexistentes.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Riesgo del usuario: ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'La práctica de las rutinas se realiza bajo tu propia cuenta y riesgo. PYROSFIT no asume responsabilidad por lesiones derivadas de los ejercicios.',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
