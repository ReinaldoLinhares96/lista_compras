import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'item_compra_model.g.dart';

@HiveType(typeId: 4)
class ItemCompraModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String compraId;
  @HiveField(2)
  final String? produtoId;
  @HiveField(3)
  String nomeProduto;
  @HiveField(4)
  int quantidadeComprada;
  @HiveField(5)
  double precoUnitario;
  @HiveField(6)
  double subtotal;
  @HiveField(7)
  bool ehAvulso;
  @HiveField(8)
  bool adicionadoNaLista;
  @HiveField(9)
  DateTime createdAt;
  @HiveField(10)
  DateTime updatedAt;
  @HiveField(11)
  bool isActive;
  @HiveField(12)
  bool isRemoved;

  ItemCompraModel({
    String? id,
    required this.compraId,
    this.produtoId,
    required this.nomeProduto,
    required this.quantidadeComprada,
    required this.precoUnitario,
    double? subtotal,
    bool? ehAvulso,
    bool? adicionadoNaLista,
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       subtotal = subtotal ?? (quantidadeComprada * precoUnitario),
       ehAvulso = ehAvulso ?? false,
       adicionadoNaLista = adicionadoNaLista ?? false,
       isActive = isActive ?? true,
       isRemoved = isRemoved ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  ItemCompraModel copyWith({
    String? id,
    String? compraId,
    String? produtoId,
    String? nomeProduto,
    int? quantidadeComprada,
    double? precoUnitario,
    double? subtotal,
    bool? ehAvulso,
    bool? adicionadoNaLista,
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newQuantidadeComprada = quantidadeComprada ?? this.quantidadeComprada;
    final newPrecoUnitario = precoUnitario ?? this.precoUnitario;
    final calculatedSubtotal = newQuantidadeComprada * newPrecoUnitario;

    return ItemCompraModel(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      produtoId: produtoId ?? this.produtoId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      quantidadeComprada: newQuantidadeComprada,
      precoUnitario: newPrecoUnitario,
      subtotal: subtotal ?? calculatedSubtotal,
      ehAvulso: ehAvulso ?? this.ehAvulso,
      adicionadoNaLista: adicionadoNaLista ?? this.adicionadoNaLista,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
