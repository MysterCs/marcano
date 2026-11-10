import 'package:flutter/material.dart';

class ProductCategoryStyle {
  const ProductCategoryStyle({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

class ProductCategoryHelper {
  const ProductCategoryHelper._();

  static const String defaultCategory = 'Otros / General';

  static const List<String> allCategories = [
    'Patch Cords y Pig Tails',
    'Fibra Óptica y Empalmes',
    'Racks, Bandejas y Gabinetes',
    'Equipos Activos y Red',
    'Cableado y Conectividad',
    'Canalización y Herrajes',
    'Energía y Respaldo',
    'Herramientas y Consumibles',
    defaultCategory,
  ];

  static String inferCategory(String? productName) {
    if (productName == null || productName.trim().isEmpty) {
      return defaultCategory;
    }
    final upper = ' ${productName.toUpperCase()} '
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U');

    const rules = <String, List<String>>{
      'Patch Cords y Pig Tails': ['PATCH', 'PIG TAIL', 'PIGTAIL', 'PIG ', 'JUMP'],
      'Racks, Bandejas y Gabinetes': [
        'BANDEJA',
        'RACK',
        'GABINETE',
        'ORGANIZADOR',
        'ORG.',
        'CAJA',
        'TAPA',
        'PANEL',
        'ODF',
      ],
      'Equipos Activos y Red': [
        'SWITCH',
        'ROUTER',
        'CONVERTIDOR',
        'TRANSCEIVER',
        'SFP',
        'MODULO',
        'MEDIA CONVERTER',
        'ONU',
        'OLT',
        'ANTENA',
        'MIKROTIK',
        'TRANSCEPTOR',
      ],
      'Fibra Óptica y Empalmes': [
        'SPLITTER',
        'ATENUADOR',
        'EMPALME',
        'MANGA',
        'ACOPLADOR',
        'COUPLER',
        'ADAPTADOR',
        'F.O',
        'FIBRA',
        'OPTICA',
        'OPTICO',
        'FTTH',
      ],
      'Cableado y Conectividad': [
        'CABLE',
        'CONECTOR',
        'JACK',
        'FACEPLATE',
        'FACE PLATE',
        'FACE ',
        'PLUG',
        'RJ-45',
        'RJ45',
        'UTP',
        'HEMBRA/HEMBRA',
        'COAXIAL',
      ],
      'Canalización y Herrajes': [
        'CANALETA',
        'ESQUINA',
        'ANGULO',
        'HERRAJE',
        'ESCALERILLA',
        'PLACA',
        'ARGOLLA',
        'HEBILLA',
        'FLEJE',
        'TIEWRAP',
        'TIE WRAP',
        'TIE ',
        'AMARRA',
        'ABRAZADERA',
        'TORNILLO',
        'TUERCA',
        'RAMPLUG',
        'SOPORTE',
        'RIEL',
      ],
      'Energía y Respaldo': [
        'BATERIA',
        'FUENTE',
        'UPS',
        'INVERSOR',
        'REGULADOR',
        'CARGADOR',
        'REGLETA',
        'BREAKER',
        'TRANSFORMADOR',
      ],
      'Herramientas y Consumibles': [
        'ETIQUETA',
        'KIT',
        'PELA',
        'CORTADORA',
        'MEDIDOR',
        'LIJA',
        'PEGAMENTO',
        'ACELERADOR',
        'TOALLITA',
        'ALCOHOL',
        'CINTA',
        'PINZA',
        'DESTORNILLADOR',
        'DISCO',
        'BROCA',
        'ROLLO',
        'LIMPIADOR',
      ],
    };

    for (final entry in rules.entries) {
      for (final keyword in entry.value) {
        if (upper.contains(keyword)) {
          return entry.key;
        }
      }
    }
    if (upper.contains(' FO ')) {
      return 'Fibra Óptica y Empalmes';
    }
    return defaultCategory;
  }

  static ProductCategoryStyle styleFor(String category) {
    switch (category) {
      case 'Patch Cords y Pig Tails':
        return const ProductCategoryStyle(
          name: 'Patch Cords y Pig Tails',
          icon: Icons.settings_input_component_outlined,
          color: Color(0xFFE11D48),
        );
      case 'Fibra Óptica y Empalmes':
        return const ProductCategoryStyle(
          name: 'Fibra Óptica y Empalmes',
          icon: Icons.hub_outlined,
          color: Color(0xFF3B82F6),
        );
      case 'Racks, Bandejas y Gabinetes':
        return const ProductCategoryStyle(
          name: 'Racks, Bandejas y Gabinetes',
          icon: Icons.dns_outlined,
          color: Color(0xFFF97316),
        );
      case 'Equipos Activos y Red':
        return const ProductCategoryStyle(
          name: 'Equipos Activos y Red',
          icon: Icons.router_outlined,
          color: Color(0xFF10B981),
        );
      case 'Cableado y Conectividad':
        return const ProductCategoryStyle(
          name: 'Cableado y Conectividad',
          icon: Icons.cable_outlined,
          color: Color(0xFF8B5CF6),
        );
      case 'Canalización y Herrajes':
        return const ProductCategoryStyle(
          name: 'Canalización y Herrajes',
          icon: Icons.architecture_outlined,
          color: Color(0xFF06B6D4),
        );
      case 'Energía y Respaldo':
        return const ProductCategoryStyle(
          name: 'Energía y Respaldo',
          icon: Icons.battery_charging_full_outlined,
          color: Color(0xFFEAB308),
        );
      case 'Herramientas y Consumibles':
        return const ProductCategoryStyle(
          name: 'Herramientas y Consumibles',
          icon: Icons.handyman_outlined,
          color: Color(0xFFEC4899),
        );
      default:
        return const ProductCategoryStyle(
          name: defaultCategory,
          icon: Icons.category_outlined,
          color: Color(0xFF9CA3AF),
        );
    }
  }
}
