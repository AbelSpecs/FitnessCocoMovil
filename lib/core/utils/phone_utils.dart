import 'package:flutter/services.dart';

class CountryPhoneConfig {
  final String countryName;
  final String phoneCode;
  final int digits;
  final String placeholder;

  const CountryPhoneConfig({
    required this.countryName,
    required this.phoneCode,
    required this.digits,
    required this.placeholder,
  });
}

const List<CountryPhoneConfig> phoneConfigs = [
  CountryPhoneConfig(countryName: 'Venezuela', phoneCode: '+58', digits: 10, placeholder: '412-123-4567'),
  CountryPhoneConfig(countryName: 'Colombia', phoneCode: '+57', digits: 10, placeholder: '300-123-4567'),
  CountryPhoneConfig(countryName: 'Estados Unidos', phoneCode: '+1', digits: 10, placeholder: '555-123-4567'),
  CountryPhoneConfig(countryName: 'Canadá', phoneCode: '+1', digits: 10, placeholder: '416-123-4567'),
  CountryPhoneConfig(countryName: 'Puerto Rico', phoneCode: '+1', digits: 10, placeholder: '787-123-4567'),
  CountryPhoneConfig(countryName: 'España', phoneCode: '+34', digits: 9, placeholder: '612-345-678'),
  CountryPhoneConfig(countryName: 'México', phoneCode: '+52', digits: 10, placeholder: '55-1234-5678'),
  CountryPhoneConfig(countryName: 'Argentina', phoneCode: '+54', digits: 10, placeholder: '11-1234-5678'),
  CountryPhoneConfig(countryName: 'Chile', phoneCode: '+56', digits: 9, placeholder: '9-1234-5678'),
  CountryPhoneConfig(countryName: 'Perú', phoneCode: '+51', digits: 9, placeholder: '912-345-678'),
  CountryPhoneConfig(countryName: 'Ecuador', phoneCode: '+593', digits: 9, placeholder: '99-123-4567'),
  CountryPhoneConfig(countryName: 'Bolivia', phoneCode: '+591', digits: 8, placeholder: '7123-4567'),
  CountryPhoneConfig(countryName: 'Brasil', phoneCode: '+55', digits: 11, placeholder: '11-91234-5678'),
  CountryPhoneConfig(countryName: 'Costa Rica', phoneCode: '+506', digits: 8, placeholder: '8123-4567'),
  CountryPhoneConfig(countryName: 'Cuba', phoneCode: '+53', digits: 8, placeholder: '5123-4567'),
  CountryPhoneConfig(countryName: 'República Dominicana', phoneCode: '+1', digits: 10, placeholder: '809-123-4567'),
  CountryPhoneConfig(countryName: 'Panamá', phoneCode: '+507', digits: 8, placeholder: '6123-4567'),
  CountryPhoneConfig(countryName: 'Uruguay', phoneCode: '+598', digits: 8, placeholder: '91-234-567'),
  CountryPhoneConfig(countryName: 'Paraguay', phoneCode: '+595', digits: 9, placeholder: '981-123-456'),
  CountryPhoneConfig(countryName: 'Guatemala', phoneCode: '+502', digits: 8, placeholder: '5123-4567'),
  CountryPhoneConfig(countryName: 'Honduras', phoneCode: '+504', digits: 8, placeholder: '9123-4567'),
  CountryPhoneConfig(countryName: 'El Salvador', phoneCode: '+503', digits: 8, placeholder: '7123-4567'),
  CountryPhoneConfig(countryName: 'Nicaragua', phoneCode: '+505', digits: 8, placeholder: '8123-4567'),
];

const CountryPhoneConfig defaultPhoneConfig = CountryPhoneConfig(
  countryName: 'Default',
  phoneCode: '',
  digits: 10,
  placeholder: '412-123-4567',
);

String _normalizeText(String? text) {
  if (text == null) return '';
  const withAccents = 'áéíóúüñÁÉÍÓÚÜÑ';
  const withoutAccents = 'aeiouunAEIOUUN';
  var result = text.trim().toLowerCase();
  for (var i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return result;
}

String _normalizeCode(String? code) {
  if (code == null || code.trim().isEmpty) return '';
  final trimmed = code.trim();
  return trimmed.startsWith('+') ? trimmed : '+$trimmed';
}

CountryPhoneConfig getPhoneConfig({String? countryName, String? phoneCode}) {
  final normName = _normalizeText(countryName);
  final normCode = _normalizeCode(phoneCode);

  if (normName.isNotEmpty && normCode.isNotEmpty) {
    for (final c in phoneConfigs) {
      if (_normalizeText(c.countryName) == normName && c.phoneCode == normCode) {
        return c;
      }
    }
  }

  if (normName.isNotEmpty) {
    for (final c in phoneConfigs) {
      if (_normalizeText(c.countryName) == normName) {
        return c;
      }
    }
  }

  if (normCode.isNotEmpty) {
    for (final c in phoneConfigs) {
      if (c.phoneCode == normCode) {
        return c;
      }
    }
  }

  return defaultPhoneConfig;
}

/// Limpia el teléfono dejando únicamente los dígitos.
String cleanPhoneNumber(String? phone) {
  if (phone == null) return '';
  return phone.replaceAll(RegExp(r'\D'), '');
}

/// Formatea el número de teléfono agregando guiones según el patrón del placeholder.
String formatPhoneNumber(String value, CountryPhoneConfig config) {
  final cleanDigits = cleanPhoneNumber(value);
  final limitedDigits = cleanDigits.length > config.digits
      ? cleanDigits.substring(0, config.digits)
      : cleanDigits;

  if (limitedDigits.isEmpty) return '';

  final parts = config.placeholder.split('-');
  if (parts.length <= 1) {
    return limitedDigits;
  }

  final groupLengths = parts.map((p) {
    final len = cleanPhoneNumber(p).length;
    return len > 0 ? len : p.length;
  }).toList();

  final formattedParts = <String>[];
  var currentIndex = 0;

  for (final len in groupLengths) {
    if (currentIndex >= limitedDigits.length) break;
    final end = (currentIndex + len).clamp(0, limitedDigits.length);
    formattedParts.add(limitedDigits.substring(currentIndex, end));
    currentIndex = end;
  }

  if (currentIndex < limitedDigits.length) {
    formattedParts.add(limitedDigits.substring(currentIndex));
  }

  return formattedParts.join('-');
}

({bool isValid, String? message}) validatePhoneNumber(
  String? phone,
  CountryPhoneConfig config,
) {
  final clean = cleanPhoneNumber(phone);
  if (clean.isEmpty) {
    return (isValid: false, message: 'El teléfono es obligatorio');
  }

  if (clean.length != config.digits) {
    final countryLabel = config.countryName != 'Default'
        ? config.countryName
        : (config.phoneCode.isNotEmpty ? config.phoneCode : 'el país seleccionado');
    return (
      isValid: false,
      message: 'El número de teléfono debe tener ${config.digits} dígitos para $countryLabel',
    );
  }

  return (isValid: true, message: null);
}

class CountryPhoneInputFormatter extends TextInputFormatter {
  final CountryPhoneConfig config;

  CountryPhoneInputFormatter(this.config);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatPhoneNumber(newValue.text, config);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

