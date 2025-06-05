plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Imports for Properties and FileInputStream are not strictly needed if using System.getenv() directly for all signing values.
// However, they don't hurt if left. Let's remove them to be clean if not used.

android {
    namespace = "au.id.dylan.celly_viewer"
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
        applicationId = "au.id.dylan.celly_viewer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode // Use Flutter injected version code
        versionName = flutter.versionName // Use Flutter injected version name
    }

    signingConfigs {
        create("release") {
            // Directly use environment variables, which will be populated by GitHub Actions secrets
            // The GitHub Actions workflow step 'Decode Keystore and Setup Signing' creates 'android/release.jks'
            // So, the path relative to this app/build.gradle.kts is '../release.jks'
            storeFile = rootProject.file("../release.jks") // Path to the keystore file created by CI
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // TODO: Add your own R8/ProGuard settings here if needed
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
