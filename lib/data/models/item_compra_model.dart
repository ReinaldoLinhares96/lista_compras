import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool adicionadoNaLista; // Nome correto da propriedade
  @HiveField(9)
  DateTime createdAt;
  @HiveField(10)
  DateTime updatedAt;
  @HiveField(11)
  bool isActive;
  @HiveField(12)
  bool isRemoved;
  @HiveField(13)
  String? userId;

  ItemCompraModel({
    String? id,
    required this.compraId,
    this.produtoId,
    required this.nomeProduto,
    required this.quantidadeComprada,
    required this.precoUnitario,
    double? subtotal,
    bool? ehAvulso,
    bool? adicionadoNaLista, // Nome correto no parâmetro do construtor
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  }) : id = id ?? const Uuid().v4(),
       subtotal = subtotal ?? (quantidadeComprada * precoUnitario),
       ehAvulso = ehAvulso ?? false,
       adicionadoNaLista =
           adicionadoNaLista ?? false, // Usando o nome correto aqui
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
    bool? adicionadoNaLista, // Nome correto no parâmetro do copyWith
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
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
      adicionadoNaLista:
          adicionadoNaLista ?? this.adicionadoNaLista, // CORRIGIDO AQUI
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  // NOVO: Factory constructor para ler do Firestore
  factory ItemCompraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('missing data for ItemCompraModel(id: ${doc.id})');
    }
    return ItemCompraModel(
      id: doc.id,
      compraId: data['compraId'] as String,
      produtoId: data['produtoId'] as String?,
      nomeProduto: data['nomeProduto'] as String,
      quantidadeComprada: (data['quantidadeComprada'] as num).toInt(),
      precoUnitario: (data['precoUnitario'] as num).toDouble(),
      subtotal: (data['subtotal'] as num? ?? 0.0).toDouble(),
      ehAvulso: data['ehAvulso'] as bool? ?? false,
      adicionadoNaLista: data['adicionadoNaLista'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      isRemoved: data['isRemoved'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String?,
    );
  }

  // NOVO: Método para converter para um Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'compraId': compraId,
      'produtoId': produtoId,
      'nomeProduto': nomeProduto,
      'quantidadeComprada': quantidadeComprada,
      'precoUnitario': precoUnitario,
      'subtotal': subtotal,
      'ehAvulso': ehAvulso,
      'adicionadoNaLista': adicionadoNaLista,
      'isActive': isActive,
      'isRemoved': isRemoved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }
}
