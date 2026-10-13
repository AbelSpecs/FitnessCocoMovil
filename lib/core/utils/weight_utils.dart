/// Utilidades para conversión y formateo de peso (Kilogramos y Libras).
/// 1 kg = 2.20462 lbs

const double kgToLbsFactor = 2.20462;

/// Convierte kilogramos a libras redondeado a 1 decimal.
double kgToLbs(dynamic kg) {
  if (kg == null) return 0.0;
  final num? n = num.tryParse(kg.toString().trim());
  if (n == null || n <= 0) return 0.0;
  return double.parse((n * kgToLbsFactor).toStringAsFixed(1));
}

/// Convierte libras a kilogramos redondeado a 1 decimal.
double lbsToKg(dynamic lbs) {
  if (lbs == null) return 0.0;
  final num? n = num.tryParse(lbs.toString().trim());
  if (n == null || n <= 0) return 0.0;
  return double.parse((n / kgToLbsFactor).toStringAsFixed(1));
}

/// Obtiene el valor numérico en kg independientemente de la unidad en que se haya escrito.
double parseWeightToKg(dynamic rawVal, [String unit = 'kg']) {
  if (rawVal == null) return 0.0;
  final num? n = num.tryParse(rawVal.toString().trim());
  if (n == null || n <= 0) return 0.0;

  if (unit.toLowerCase() == 'lbs') {
    return lbsToKg(n);
  }
  return double.parse(n.toStringAsFixed(1));
}

/// Formatea un número eliminando decimales superfluos (.0) o manteniendo hasta 1 decimal.
String formatWeightNumber(double val) {
  if (val == val.roundToDouble()) {
    return val.toInt().toString();
  }
  return val.toStringAsFixed(1);
}

/// Formatea el peso en kg para mostrarlo en la interfaz con su equivalente en libras.
/// Ejemplo: "20 kg (44.1 lbs)"
String formatWeightWithEquivalent(dynamic rawKg) {
  if (rawKg == null) return '0 kg';
  final str = rawKg.toString().trim();
  if (str.isEmpty || str == '0' || str == '0.0') return '0 kg';

  final num? kg = num.tryParse(str);
  if (kg == null || kg <= 0) return '0 kg';

  final double lbs = kgToLbs(kg);
  final String kgDisplay = formatWeightNumber(kg.toDouble());
  final String lbsDisplay = formatWeightNumber(lbs);

  return '$kgDisplay kg ($lbsDisplay lbs)';
}

/// Parsea un valor de peso a numérico (int si es entero, double si tiene decimales).
/// Si recibe "20.0" o "20", devuelve 20. Si recibe "20.5", devuelve 20.5.
num parseWeightNum(dynamic rawVal) {
  if (rawVal == null) return 0;
  final str = rawVal.toString().trim();
  if (str.isEmpty) return 0;
  final n = num.tryParse(str);
  if (n == null || n <= 0) return 0;
  return n == n.toInt() ? n.toInt() : double.parse(n.toDouble().toStringAsFixed(1));
}
