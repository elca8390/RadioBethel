import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().also { properties ->
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { input ->
            properties.load(input)
        }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

android {
    namespace = "co.ecoingenieria.radiobethelcr"
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
        applicationId = "co.ecoingenieria.radiobethelcr"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                    ?: throw GradleException("Missing storeFile in key.properties")
                storeFile = file(storeFilePath)
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: throw GradleException("Missing keyAlias in key.properties")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: throw GradleException("Missing keyPassword in key.properties")
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: throw GradleException("Missing storePassword in key.properties")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
