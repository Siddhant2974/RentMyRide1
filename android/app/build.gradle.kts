plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Ensure this line is present (or applied later):
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.rentmyride_app" // <-- ensure this matches google-services.json
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.rentmyride_app" // <-- ensure this matches google-services.json
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Add Firebase Android BoM and any desired Firebase SDKs (e.g. Analytics).
dependencies {
    // Import the Firebase BoM (keeps Firebase libs in sync)
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))

    // Add Firebase SDKs you want to use (with BoM you don't specify versions)
    implementation("com.google.firebase:firebase-analytics")
    // implementation("com.google.firebase:firebase-auth") // if needed on native side
}

flutter {
    source = "../.."
}
