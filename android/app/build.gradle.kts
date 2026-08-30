plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dxstunnel.dxs_tunnel"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.dxstunnel.dxs_tunnel"

        minSdk = 26
        targetSdk = 35

        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility =
            JavaVersion.VERSION_17

        targetCompatibility =
            JavaVersion.VERSION_17

        isCoreLibraryDesugaringEnabled =
            true
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {

    implementation(
        "com.wireguard.android:tunnel:1.0.20260102"
    )

    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.5"
    )
}

flutter {
    source = "../.."
}
