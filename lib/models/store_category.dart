import 'package:flutter/material.dart';

/// Типы магазинов. [key] хранится в БД — не менять у существующих значений.
enum StoreCategory {
  grocery('grocery', 'Продукты', Icons.local_grocery_store_outlined, Color(0xFF43A047)),
  hardware('hardware', 'Ремонт', Icons.construction_outlined, Color(0xFFEF6C00)),
  household('household', 'Хозтовары', Icons.cleaning_services_outlined, Color(0xFF1E88E5)),
  pharmacy('pharmacy', 'Аптека', Icons.medical_services_outlined, Color(0xFFE53935)),
  pets('pets', 'Зоотовары', Icons.pets_outlined, Color(0xFF8D6E63)),
  kids('kids', 'Детские товары', Icons.child_friendly_outlined, Color(0xFFEC407A)),
  electronics('electronics', 'Электроника', Icons.devices_other_outlined, Color(0xFF5E35B1)),
  garden('garden', 'Сад и дача', Icons.yard_outlined, Color(0xFF7CB342)),
  other('other', 'Другое', Icons.shopping_bag_outlined, Color(0xFF546E7A));

  const StoreCategory(this.key, this.title, this.icon, this.color);

  final String key;
  final String title;
  final IconData icon;
  final Color color;

  static StoreCategory fromKey(String? key) =>
      StoreCategory.values.firstWhere((c) => c.key == key, orElse: () => StoreCategory.other);
}
