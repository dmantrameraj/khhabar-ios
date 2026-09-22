import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — reads from android/key.properties, which is gitignored
// (see .gitignore) since it holds the keystore path and passwords. Falls
// back to null values if the file is missing, so a fresh checkout without
// the release key can still build a debug APK (just not a signed release
// one) instead of failing the whole Gradle configuration step.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.khhabar.khhabar_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Changed 2026-09-22 from the Flutter template default
        // (com.khhabar.khhabar_app) to match com.khhabar.app, the package
        // name already locked into the Play Console listing at the moment
        // the app was first registered there — that lock is permanent, so
        // this had to move to match it, not the reverse. Keep this in sync
        // with lib/features/auth/account_screen.dart's _playStorePackageId
        // and the backend's public/.well-known/assetlinks.json
        // (package_name) — both reference this same id, and App Links
        // verification silently breaks if assetlinks.json falls out of
        // sync with whatever this is set to.
        applicationId = "com.khhabar.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key when key.properties is missing
            // (e.g. a fresh checkout without the release keystore) so
            // `flutter build apk --release` still produces something
            // runnable rather than failing outright — never use that
            // fallback for an actual Play Store upload.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
