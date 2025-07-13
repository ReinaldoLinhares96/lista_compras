import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "com.example.lista_compras"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Mantido como corrigido anteriormente
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.lista_compras"
        minSdk = 23 // Mantido em 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("app_release.keystore")
            storePassword = keystoreProperties.getProperty("storePassword")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
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

dependencies {
    // ... (suas dependências existentes) ...
    // implementation(platform("com.google.firebase:firebase-bom:32.4.0")) // Removido ou comentado se não for estritamente necessário para outras dependências
    // implementation("com.google.firebase:firebase-auth") // Manter se usar FirebaseAuth
    // implementation("com.google.android.gms:play-services-auth:23.2.1") // Removido esta linha, pois vamos forçar via resolutionStrategy

    // CORREÇÃO CRÍTICA AQUI: Forçar a versão de play-services-auth para uma conhecida e estável
    // Adicione esta seção ao seu build.gradle.kts
    configurations.all {
        resolutionStrategy {
            force("com.google.android.gms:play-services-auth:21.2.0") // VERSÃO CONHECIDA E ESTÁVEL
        }
    }
}