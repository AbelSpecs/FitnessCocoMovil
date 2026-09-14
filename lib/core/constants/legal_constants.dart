/// Documentación Legal Oficial de PYROSFIT
/// Fecha de vigencia: Agosto de 2026
/// Plataforma: Aplicación Móvil y Sitio Web (pyrosfit.com)

class LegalSubSection {
  final String? subtitle;
  final String text;

  const LegalSubSection({
    this.subtitle,
    required this.text,
  });
}

class LegalSection {
  final String id;
  final String number;
  final String title;
  final bool isWarning;
  final String? intro;
  final List<String>? bullets;
  final List<LegalSubSection>? subsections;

  const LegalSection({
    required this.id,
    required this.number,
    required this.title,
    this.isWarning = false,
    this.intro,
    this.bullets,
    this.subsections,
  });
}

class LegalMetadata {
  static const String appName = "PYROSFIT";
  static const String effectiveDate = "Agosto de 2026";
  static const String platform = "Aplicación Móvil y Sitio Web (pyrosfit.com)";
  static const String supportEmail = "soporte@pyrosfit.com";
  static const String version = "1.0";
  static const String geekSolutionsUrl = "https://geek-solutions-landing-page-front.vercel.app/#inicio";
}

const List<LegalSection> termsOfUseSections = [
  LegalSection(
    id: "aceptacion",
    number: "1.1",
    title: "Aceptación de los Términos",
    intro:
        "El uso de PYROSFIT implica la aceptación expresa y sin reservas de estos Términos y Condiciones, así como de nuestra Política de Privacidad. El servicio está dirigido exclusivamente a personas con capacidad legal para contratar.",
  ),
  LegalSection(
    id: "descripcion",
    number: "1.2",
    title: "Descripción del Servicio",
    intro:
        "PYROSFIT es una plataforma digital de acondicionamiento físico, seguimiento de rutinas (Pyros Streak) y gestión de comunidad orientada a fomentar hábitos de vida saludables. Los servicios incluyen planes de entrenamiento, herramientas de registro de actividad y funciones interactivas para usuarios.",
  ),
  LegalSection(
    id: "exencion-medica",
    number: "1.3",
    title: "Exención de Responsabilidad Médica",
    isWarning: true,
    subsections: [
      LegalSubSection(
        subtitle: "No somos profesionales médicos",
        text:
            "El contenido, rutinas y herramientas proporcionadas por PYROSFIT tienen fines exclusivamente informativos y motivacionales. No constituyen asesoramiento médico, diagnóstico o tratamiento profesional.",
      ),
      LegalSubSection(
        subtitle: "Consulta previa",
        text:
            "Debes consultar a un médico o profesional de la salud antes de iniciar cualquier programa de ejercicios, rutinas de alta intensidad o cambios en tu dieta, especialmente si padeces condiciones de salud preexistentes.",
      ),
      LegalSubSection(
        subtitle: "Riesgo del usuario",
        text:
            "El uso de las rutinas de entrenamiento de PYROSFIT se realiza bajo tu propia cuenta y riesgo. PYROSFIT, sus creadores y desarrolladores no asumen responsabilidad alguna por lesiones, daños físicos o perjuicios derivados de la práctica de los ejercicios mostrados en la app.",
      ),
    ],
  ),
  LegalSection(
    id: "cuentas-seguridad",
    number: "1.4",
    title: "Cuentas de Usuario y Seguridad",
    bullets: [
      "Para acceder a las funciones principales de la app, deberás crear una cuenta de usuario proporcionando información veraz y actualizada.",
      "Eres el único responsable de mantener la confidencialidad de tus datos de acceso y de todas las actividades que ocurran bajo tu cuenta.",
      "PYROSFIT se reserva el derecho de suspender o cancelar cuentas que incumplan las normas de la comunidad o realicen un uso fraudulento.",
    ],
  ),
  LegalSection(
    id: "propiedad-intelectual",
    number: "1.5",
    title: "Propiedad Intelectual",
    intro:
        "Todo el contenido disponible en PYROSFIT (incluyendo, entre otros, el logotipo P+F, tipografías, diseños de interfaz, textos, gráficos, iconos y código fuente) es propiedad exclusiva de PYROSFIT y está protegido por las leyes de propiedad intelectual. Se prohíbe la reproducción, distribución, modificación o uso comercial no autorizado de cualquier elemento de la marca sin el consentimiento previo por escrito.",
  ),
  LegalSection(
    id: "conducta-comunidad",
    number: "1.6",
    title: 'Conducta de la Comunidad ("Gente Fit")',
    intro:
        'Fomentamos un ambiente de respeto, motivación y apoyo mutuo. Queda estrictamente prohibido publicar o transmitir contenido ofensivo, discriminatorio, acosador o inapropiado dentro de las funciones comunitarias de la app, así como intentar vulnerar la seguridad de la plataforma.',
  ),
];

const List<LegalSection> privacyPolicySections = [
  LegalSection(
    id: "informacion-recopilada",
    number: "2.1",
    title: "Información que Recopilamos",
    bullets: [
      "Datos de Registro: Nombre de usuario, correo electrónico y contraseña necesarios para crear y asegurar tu cuenta en la plataforma.",
      "Datos de Actividad Física y Progreso: Historial de rutinas completadas, registros de rachas (Pyros Streak), estadísticas de entrenamiento y preferencias personales introducidas en la app.",
      "Información Técnica: Datos sobre el dispositivo móvil, dirección IP, sistema operativo y registros de errores recopilados automáticamente para garantizar el funcionamiento técnico del servicio.",
    ],
  ),
  LegalSection(
    id: "uso-informacion",
    number: "2.2",
    title: "Uso de la Información",
    intro: "Utilizamos la información recopilada estrictamente para:",
    bullets: [
      "Proporcionar, mantener y mejorar las funcionalidades de la aplicación y las rutinas de entrenamiento.",
      "Personalizar tu experiencia en la plataforma y realizar un seguimiento preciso de tu progreso físico y rachas.",
      "Enviar notificaciones importantes sobre el servicio, actualizaciones de la app o recordatorios motivacionales.",
    ],
  ),
  LegalSection(
    id: "seguridad-datos",
    number: "2.3",
    title: "Protección y Seguridad de los Datos",
    intro:
        "Implementamos medidas de seguridad técnicas y organizativas adecuadas para proteger tu información personal contra accesos no autorizados, alteraciones, divulgación o destrucción. Tus datos no son vendidos, alquilados ni compartidos con terceros con fines comerciales o publicitarios.",
  ),
  LegalSection(
    id: "derechos-usuario",
    number: "2.4",
    title: "Derechos del Usuario",
    intro:
        "Puedes acceder, actualizar o solicitar la eliminación de tu cuenta y datos personales en cualquier momento desde la configuración de la app o enviando una solicitud directa a nuestro equipo de soporte.",
  ),
  LegalSection(
    id: "contacto-legal",
    number: "2.5",
    title: "Contacto",
    intro:
        "Si tienes preguntas, dudas o inquietudes sobre nuestros Términos y Condiciones o sobre esta Política de Privacidad, puedes ponerte en contacto con nosotros en cualquier momento a través de nuestro correo oficial de soporte: soporte@pyrosfit.com",
  ),
];
