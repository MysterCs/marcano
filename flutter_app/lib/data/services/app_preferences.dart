import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferencias locales del aplicativo, guardadas en el dispositivo.
///
/// Se usa el mismo almacenamiento seguro del token para no agregar
/// dependencias nuevas.
class AppPreferences extends ChangeNotifier {
  AppPreferences({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _pageSizeKey = 'marcano_page_size';
  static const int defaultPageSize = 25;

  /// Opciones validas para el listado de productos.
  static const List<int> pageSizeOptions = [10, 25, 50, 100];

  final FlutterSecureStorage _storage;

  int pageSize = defaultPageSize;

  /// Carga la preferencia guardada; si no existe usa el valor por defecto.
  Future<void> load() async {
    final raw = await _storage.read(key: _pageSizeKey);
    final parsed = raw == null ? null : int.tryParse(raw);
    if (parsed != null && pageSizeOptions.contains(parsed)) {
      pageSize = parsed;
    }
    notifyListeners();
  }

  /// Guarda cuantos productos se muestran por pagina en el inventario.
  Future<void> setPageSize(int value) async {
    pageSize = value;
    notifyListeners();
    await _storage.write(key: _pageSizeKey, value: value.toString());
  }
}
