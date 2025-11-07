import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// 🎛️ Configuración visual compartida para las pantallas de listas
/// 📐 Guarda cuántas columnas uso (1-5) y si muestro lista o cuadrícula
class ListViewSettings {
  final int gridColumns;
  final bool isListView;

  ListViewSettings({
    this.gridColumns = 3,
    this.isListView = false,
  });

  ListViewSettings copyWith({
    int? gridColumns,
    bool? isListView,
  }) {
    return ListViewSettings(
      gridColumns: gridColumns ?? this.gridColumns,
      isListView: isListView ?? this.isListView,
    );
  }
}

final listViewSettingsProvider = StateNotifierProvider<ListViewSettingsNotifier, ListViewSettings>((ref) {
  return ListViewSettingsNotifier();
});

class ListViewSettingsNotifier extends StateNotifier<ListViewSettings> {
  ListViewSettingsNotifier() : super(ListViewSettings());

  void setGridColumns(int columns) {
    state = state.copyWith(gridColumns: columns, isListView: false);
  }

  void setListView(bool isList) {
    state = state.copyWith(isListView: isList);
  }
}


