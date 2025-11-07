import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// 🎛️ Provider para la configuración visual de la wishlist
/// 📐 Guarda cuántas columnas uso (1-5) y si muestro lista o cuadrícula
class WishlistViewSettings {
  final int gridColumns;
  final bool isListView;

  WishlistViewSettings({
    this.gridColumns = 3,
    this.isListView = false,
  });

  WishlistViewSettings copyWith({
    int? gridColumns,
    bool? isListView,
  }) {
    return WishlistViewSettings(
      gridColumns: gridColumns ?? this.gridColumns,
      isListView: isListView ?? this.isListView,
    );
  }
}

final wishlistViewSettingsProvider = StateNotifierProvider<WishlistViewSettingsNotifier, WishlistViewSettings>((ref) {
  return WishlistViewSettingsNotifier();
});

class WishlistViewSettingsNotifier extends StateNotifier<WishlistViewSettings> {
  WishlistViewSettingsNotifier() : super(WishlistViewSettings());

  void setGridColumns(int columns) {
    state = state.copyWith(gridColumns: columns, isListView: false);
  }

  void setListView(bool isList) {
    state = state.copyWith(isListView: isList);
  }
}


