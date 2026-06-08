import 'api_service.dart';

class LiquidationService {
  final _api = ApiService();

  /// Calendrier des 4 sessions de l'année (statut + montants si complétées).
  Future<List<dynamic>> getCalendar({int? year}) async {
    final query = year != null ? '?year=$year' : '';
    return (await _api.get('/liquidation/calendar$query')) as List<dynamic>;
  }

  /// Prochaine liquidation : date + jours restants.
  Future<Map<String, dynamic>> getNext() async {
    return (await _api.get('/liquidation/next')) as Map<String, dynamic>;
  }

  /// Aperçu personnel : points de la période + estimation DT.
  Future<Map<String, dynamic>> getMyPreview() async {
    return (await _api.get('/liquidation/my-preview')) as Map<String, dynamic>;
  }

  /// Rapport post-liquidation d'une session (filtré selon le rôle côté backend).
  Future<Map<String, dynamic>> getReport(String sessionId, {int? year}) async {
    final query = year != null ? '?year=$year' : '';
    return (await _api.get('/liquidation/$sessionId/report$query'))
        as Map<String, dynamic>;
  }
}
