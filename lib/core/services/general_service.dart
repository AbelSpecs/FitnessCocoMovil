import 'package:pyrosfitmovil/core/network/api_client.dart';
import 'package:pyrosfitmovil/core/models/country_model.dart';
import 'package:pyrosfitmovil/core/models/city_model.dart';
import 'package:pyrosfitmovil/core/models/phone_code_model.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class GeneralService {
  static final _api = ApiClient.instance;

  static Future<List<Country>> getCountries() async {
    try {
      final response = await _api.get('/Countries');
      final data = response.data['data'] as List;
      logger.i('Paises obtenidos: $data');
      return data.map((e) => Country.fromJson(e)).toList();
    } catch (e) {
      logger.e('Error en getCountries: $e');
      return [];
    }
  }

  // este metodo hay que refactorizarlo cuando @Keiver haga que devuelva un arreglo
  static Future<List<City>> getCities(int countryId) async {
    try {
      final response = await _api.get('/Cities/$countryId');
      final data = response.data['data'] as Map<String, dynamic>;
      final cities = City.fromJson(data);
      return [cities];
    } catch (e) {
      logger.e('Error al obtener ciudades: $e');
      return [];
    }
  }

  static Future<List<PhoneCode>> getPhoneCodes() async {
    try {
      // Usaremos los países directamente para los códigos telefónicos ya que la api
      // podría no tener /general/phone-codes.
      final response = await _api.get('/Countries');
      final data = response.data['data'] as List;
      final countries = data.map((e) => Country.fromJson(e)).toList();
      return countries
          .map((c) => PhoneCode(id: c.id, code: c.phoneCode, countryId: c.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getQr(int coachId) async {
    try {
      final response = await _api.get('/Qrs/GenerateQr/$coachId');
      logger.i('QR obtenido exitosamente');
      logger.i('Data del QR: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error al obtener QR: $e');
      return null;
    }
  }
}
