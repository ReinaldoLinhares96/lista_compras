import java.util.Properties // ADICIONE ESTA LINHA
import java.io.FileInputStream // ADICIONE ESTA LINHA SE VOCÊ AINDA NÃO TEM

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// START: Load keystore properties
// Define um objeto Properties para carregar as propriedades do keystore
val keystoreProperties = Properties() // Removido 'java.util.' pois agora importamos
val keystorePropertiesFile = rootProject.file("key.properties") // Busca key.properties na raiz do projeto 'android'

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}
// END: Load keystore properties

android {
    namespace = "com.fortisacl.lista_compras_inteligente"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fortisacl.lista_compras_inteligente"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // START: Signing configuration
    signingConfigs {
        create("release") { // Cria uma configuração de assinatura chamada 'release'
            storeFile = file("app_release.keystore") // Caminho relativo ao módulo app/
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }
    // END: Signing configuration

    buildTypes {
        release {
            // Aplica a configuração de assinatura 'release' criada acima
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true // Opcional: Ativar minificação para reduzir o tamanho do APK
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}