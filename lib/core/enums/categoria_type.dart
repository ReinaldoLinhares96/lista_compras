enum CategoriaType {
  alimentos, // 0
  higienePessoal, // 1
  limpezaDomestica, // 2
  // Adicione outras categorias conforme necessário
}

extension CategoriaTypeExtension on CategoriaType {
  int get value => index;

  static CategoriaType fromValue(int value) {
    return CategoriaType.values[value];
  }
}