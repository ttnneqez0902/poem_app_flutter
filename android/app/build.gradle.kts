plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // 建議使用目前的穩定 NDK 版本
    ndkVersion = "27.0.12077973"
    namespace = "com.example.eczema_self_assessment"

    // 🚀 修正 1：手動指定為 34 或 35 (image_cropper 11.x 需要較新的 SDK)
    compileSdk = 35

    compileOptions {
        // 🚀 修正 2：為了更好的相容性，建議升級到 Java 17
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // 🚀 修正 3：對應 Java 版本
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.eczema_self_assessment"

        // 🚀 修正 4：維持 24 (滿足 LINE SDK) 是對的，
        // 但請確保 image_cropper 能跑，通常 minSdk 21 即可
        minSdk = 24

        // 🚀 修正 5：手動指定 targetSdk
        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            // 建議加入混淆優化，但若開發中可先跳過
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🚀 修正 6：desugar 庫版本
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}