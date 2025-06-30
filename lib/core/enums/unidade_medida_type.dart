enum UnidadeMedidaType {
  unidade, // 0
  quilograma, // 1
  litro, // 2
  // Adicione outros tipos conforme necessário
}

// Extensão para facilitar a conversão entre enum e int
extension UnidadeMedidaTypeExtension on UnidadeMedidaType {
  int get value => index;

  static UnidadeMedidaType fromValue(int value) {
    return UnidadeMedidaType.values[value];
  }
}