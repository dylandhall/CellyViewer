plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "au.id.dylan.celly_viewer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("../key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = java.util.Properties()
                keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
                try {
                    storeFile = rootProject.file("../${keystoreProperties.getProperty("storeFile")}")
                    storePassword = keystoreProperties.getProperty("storePassword")
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                } catch (e: Exception) {
                    throw GradleException("Error reading signing properties from ../key.properties", e)
                }
            } else {
                // For local builds or if key.properties is missing, this will cause an issue
                // if 'release' signingConfig is strictly required.
                // The CI workflow MUST create key.properties.
                // Consider how you want to handle local release builds without key.properties.
                // One option is to have a fallback or specific instructions for local release.
                println("Warning: ../key.properties not found. Release build may fail or use debug signing if not configured otherwise.")
                // To make it use debug if key.properties is not found for local builds,
                // you might need more complex logic or rely on Android Studio's build variants.
                // For CI, this 'else' branch should ideally not be hit if secrets are set.
            }
        }
    }

    buildTypes {
        release {
            // Use the 'release' signing config defined above
            signingConfig = signingConfigs.getByName("release")
            // TODO: You may want to add other release-specific settings here
            // e.g., R8/ProGuard settings for code shrinking and obfuscation
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
