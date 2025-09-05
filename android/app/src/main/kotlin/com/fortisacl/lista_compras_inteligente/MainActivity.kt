package com.fortisacl.lista_compras_inteligente

import android.os.Bundle
import androidx.annotation.NonNull
import com.android.billingclient.api.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), PurchasesUpdatedListener {

    private val CHANNEL = "com.fortisacl.lista_compras_inteligente/billing"
    private lateinit var billingClient: BillingClient
    private var resultCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getProducts" -> {
                        val ids = call.argument<List<String>>("productIds") ?: emptyList()
                        queryProducts(ids, result)
                    }
                    "buyProduct" -> {
                        val productId = call.argument<String>("productId")
                        if (productId != null) {
                            launchPurchase(productId, result)
                        } else {
                            result.error("INVALID", "Product ID missing", null)
                        }
                    }
                    "restorePurchases" -> {
                        restorePurchases(result)
                    }
                    else -> result.notImplemented()
                }
            }

        initBillingClient()
    }

    private fun initBillingClient() {
        billingClient = BillingClient.newBuilder(this)
            .setListener(this)
            .enablePendingPurchases()
            .build()
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    println("BillingClient conectado com sucesso!")
                }
            }

            override fun onBillingServiceDisconnected() {
                println("BillingClient desconectado!")
            }
        })
    }

    private fun queryProducts(productIds: List<String>, result: MethodChannel.Result) {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                productIds.map {
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(it)
                        .setProductType(BillingClient.ProductType.SUBS) // Assinatura
                        .build()
                }
            ).build()

        billingClient.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val products = productDetailsList.map {
                    mapOf(
                        "id" to it.productId,
                        "title" to it.title,
                        "description" to it.description,
                        "price" to it.oneTimePurchaseOfferDetails?.formattedPrice
                            ?: it.subscriptionOfferDetails?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice
                            ?: "N/A"
                    )
                }
                result.success(products)
            } else {
                result.error("QUERY_FAILED", "Erro ao buscar produtos", null)
            }
        }
    }

    private fun launchPurchase(productId: String, result: MethodChannel.Result) {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
                )
            ).build()

        billingClient.queryProductDetailsAsync(params) { billingResult, productDetailsList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK &&
                productDetailsList.isNotEmpty()
            ) {
                val productDetails = productDetailsList[0]
                val offerToken =
                    productDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken ?: ""

                val flowParams = BillingFlowParams.newBuilder()
                    .setProductDetailsParamsList(
                        listOf(
                            BillingFlowParams.ProductDetailsParams.newBuilder()
                                .setProductDetails(productDetails)
                                .setOfferToken(offerToken)
                                .build()
                        )
                    )
                    .build()

                val billingResultLaunch = billingClient.launchBillingFlow(this, flowParams)
                if (billingResultLaunch.responseCode == BillingClient.BillingResponseCode.OK) {
                    result.success("purchase_started")
                } else {
                    result.error("LAUNCH_FAILED", "Falha ao iniciar compra", null)
                }
            } else {
                result.error("NOT_FOUND", "Produto não encontrado", null)
            }
        }
    }

    private fun restorePurchases(result: MethodChannel.Result) {
        billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        ) { billingResult, purchases ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val restored = purchases.map {
                    mapOf(
                        "id" to it.products.joinToString(),
                        "purchaseToken" to it.purchaseToken,
                        "isAcknowledged" to it.isAcknowledged
                    )
                }
                result.success(restored)
            } else {
                result.error("RESTORE_FAILED", "Falha ao restaurar compras", null)
            }
        }
    }

    override fun onPurchasesUpdated(
        billingResult: BillingResult,
        purchases: MutableList<Purchase>?
    ) {
        if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (purchase in purchases) {
                println("Compra recebida: ${purchase.products}")
                // Aqui você poderia validar no backend antes de liberar
            }
        } else if (billingResult.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) {
            println("Compra cancelada pelo usuário")
        } else {
            println("Erro na compra: ${billingResult.debugMessage}")
        }
    }
}
