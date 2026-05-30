import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.attributes.Attribute
plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
keyProperties.load(FileInputStream(keyPropertiesFile))
android {
    namespace = "com.huuua.cubia.wxx_cubia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildFeatures {
        resValues = true
    }
    flavorDimensions += "app"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wxx.cubia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        val config = signingConfigs.create("config") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
        release {
            signingConfig = config
        }
        debug {
            signingConfig = config
        }
    }

    productFlavors {
        create("google") {
            dimension = "app"
            resValue("string", "app_name", "POPStar")
            applicationId = "com.wxx.cubia"
            manifestPlaceholders.putAll(
                mapOf(
                    "CHANNEL_VALUE" to "main",
                    "app_icon" to "@mipmap/ic_launcher",
                    "admobapplicationid" to "ca-app-pub-5914587552835750~2901079555"
                )
            )
        }


        create("taptap") {
            dimension = "app"
            resValue("string", "app_name", "POPStar-消灭星星")
            applicationId = "com.wxx.popstar"
            manifestPlaceholders.putAll(
                mapOf(
                    "CHANNEL_VALUE" to "main",
                    "app_icon" to "@mipmap/ic_launcher",
                    "admobapplicationid" to "ca-app-pub-5914587552835750~2901079555"
                )
            )
        }

        create("samsung") {
            dimension = "app"
            resValue("string", "app_name", "PopStar Blast")
            applicationId = "com.wxx.popstar"
            manifestPlaceholders.putAll(
                mapOf(
                    "CHANNEL_VALUE" to "main",
                    "app_icon" to "@mipmap/ic_launcher",
                    "admobapplicationid" to "ca-app-pub-5914587552835750~2901079555"
                )
            )
        }

        create("popstar2") {
            dimension = "app"
            resValue("string", "app_name", "POPStar")
            applicationId = "com.wxx.popstar2"
            manifestPlaceholders.putAll(
                mapOf(
                    "CHANNEL_VALUE" to "main",
                    "app_icon" to "@mipmap/ic_launcher",
                    "admobapplicationid" to "ca-app-pub-5914587552835750~2901079555"
                )
            )
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

dependencies {
    // ⭐ flutter_local_notifications 必须
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

}
configurations.all {
    attributes.attribute(
        Attribute.of("com.android.build.api.attributes.ProductFlavor:platform", String::class.java),
        "play"
    )
}

