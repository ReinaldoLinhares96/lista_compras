enum CompraStatusType {
  ativa, // 0
  finalizada, // 1
  cancelada, // 2
  // Adicione outros status conforme necessário
}

extension CompraStatusTypeExtension on CompraStatusType {
  int get value => index;

  static CompraStatusType fromValue(int value) {
    return CompraStatusType.values[value];
  }
}