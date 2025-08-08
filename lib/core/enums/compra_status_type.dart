enum CompraStatusType { ativa, finalizada, cancelada }

extension CompraStatusTypeExtension on CompraStatusType {
  int get value => index;

  static CompraStatusType fromValue(int value) {
    return CompraStatusType.values[value];
  }
}
