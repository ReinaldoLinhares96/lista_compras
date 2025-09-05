package com.fortisacl.lista_compras_inteligente

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import com.android.billingclient.api.*

class MainActivity : FlutterActivity(), PurchasesUpdatedListener {

    // 1. DEFINIÇÃO DO CANAL E VARIÁVEIS
    // O nome do canal DEVE ser exatamente o mesmo do seu service em Dart.
    private val CHANNEL = "com.fortisacl.lista_compras_inteligente/billing"
    private lateinit var channel: MethodChannel
    private lateinit var billingClient: BillingClient

    // Variável para guardar os detalhes dos produtos buscados para usar na hora da compra.
    private var fetchedProductDetails: List<ProductDetails> = listOf()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Inicializa o BillingClient como antes
        billingClient = BillingClient.newBuilder(this)
            .setListener(this)
            .enablePendingPurchases()
            .build()

        startBillingConnection()

        // 2. CONFIGURAÇÃO DO METHODCHANNEL PARA "OUVIR" O DART
        channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            // `call` tem o nome do método e os argumentos (ex: productId)
            // `result` é usado para enviar a resposta de volta ao Dart
            when (call.method) {
                "getProducts" -> {
                    val productIds = call.argument<List<String>>("productIds")
                    if (productIds.isNullOrEmpty()) {
                        result.error("ARG_ERROR", "A lista de productIds está vazia.", null)
                    } else {
                        queryProductDetails(productIds, result)
                    }
                }
                "buyProduct" -> {
                    val productId = call.argument<String>("productId")
                    if (productId.isNullOrEmpty()) {
                        result.error("ARG_ERROR", "ProductId é nulo ou vazio.", null)
                    } else {
                        launchPurchaseFlow(productId, result)
                    }
                }
                "restorePurchases" -> {
                    // Lógica para restaurar compras
                    queryPurchases(result)
                }
                else -> {
                    // Informa ao Dart que o método chamado não foi implementado aqui
                    result.notImplemented()
                }
            }
        }
    }

    // 3. FUNÇÕES ADAPTADAS PARA RESPONDER AO DART

    private fun startBillingConnection() {
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    // Conexão bem-sucedida, pronto para receber chamadas.
                }
            }
            override fun onBillingServiceDisconnected() {
                startBillingConnection() // Tenta reconectar
            }
        })
    }

    private fun queryProductDetails(productIds: List<String>, result: MethodChannel.Result) {
        val productList = productIds.map { productId ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.SUBS) // ou INAPP
                .build()
        }

        val params = QueryProductDetailsParams.newBuilder().setProductList(productList)

        billingClient.queryProductDetailsAsync(params.build()) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && !productDetailsList.isNullOrEmpty()) {
                fetchedProductDetails = productDetailsList // Salva a lista para uso futuro
                
                // Transforma a lista de produtos em um formato que o Dart entenda (Map)
                val productsMap = productDetailsList.map {
                    mapOf(
                        "productId" to it.productId,
                        "title" to it.title,
                        "description" to it.description,
                        "price" to (it.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice ?: "N/A")
                    )
                }
                result.success(productsMap) // Envia a lista de produtos de volta ao Dart
            } else {
                result.error("BILLING_ERROR", "Falha ao buscar produtos: ${billingResult.debugMessage}", null)
            }
        }
    }

    private fun launchPurchaseFlow(productId: String, result: MethodChannel.Result) {
        val productDetails = fetchedProductDetails.find { it.productId == productId }

        if (productDetails == null) {
            result.error("PRODUCT_NOT_FOUND", "Produto '$productId' não encontrado. Busque os produtos primeiro.", null)
            return
        }

        val offerToken = productDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken
        if (offerToken == null) {
            result.error("OFFER_NOT_FOUND", "Nenhuma oferta encontrada para a assinatura '$productId'.", null)
            return
        }
        
        val productDetailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(productDetails)
            .setOfferToken(offerToken)
            .build()

        val billingFlowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productDetailsParams))
            .build()

        val billingResult = billingClient.launchBillingFlow(this, billingFlowParams)
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
            result.success("Fluxo de compra iniciado com sucesso.")
        } else {
            result.error("BILLING_UNAVAILABLE", "Não foi possível iniciar o fluxo de compra. Código: ${billingResult.responseCode}", null)
        }
    }

    private fun queryPurchases(result: MethodChannel.Result) {
        val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS)
        billingClient.queryPurchasesAsync(params.build()) { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val purchaseData = purchases.map { mapOf("productId" to it.products.firstOrNull()) }
                result.success(purchaseData)
            } else {
                result.error("QUERY_PURCHASES_ERROR", "Falha ao restaurar compras.", null)
            }
        }
    }

    // 4. LÓGICA DE ATUALIZAÇÃO E CONFIRMAÇÃO DE COMPRAS
    // Esta parte continua a mesma
    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: MutableList<Purchase>?) {
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (purchase in purchases) {
                if (purchase.purchaseState == Purchase.PurchaseState.PURCHASED && !purchase.isAcknowledged) {
                    acknowledgePurchase(purchase)
                }
            }
            // Opcional: Enviar evento de sucesso de volta para o Dart
            channel.invokeMethod("purchaseSuccess", null)
        } else {
            // Opcional: Enviar evento de erro/cancelamento de volta para o Dart
            channel.invokeMethod("purchaseError", mapOf("responseCode" to billingResult.responseCode))
        }
    }

    private fun acknowledgePurchase(purchase: Purchase) {
        val acknowledgePurchaseParams = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        billingClient.acknowledgePurchase(acknowledgePurchaseParams) { billingResult ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                // Compra confirmada com sucesso!
            }
        }
    }
}