import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 发布签名：android/key.properties（已在 .gitignore，不入库）
//
// 设计取舍：文件不存在时**回退到 debug 签名**而不是报错。
// 这样别人 clone 仓库（或 CI 没注入密钥）仍能构建 release 包做验证，
// 只是产物不能上架——比"构建直接失败"更适合当前单人开发的节奏。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKey = keystorePropertiesFile.exists()

android {
    namespace = "com.yueji.note"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 要求 core library desugaring（P3-2）
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // 应用 ID：一旦上架不可更改。当前为占位命名空间，
        // 若你有自有域名，把 namespace / applicationId 两处同步改成反写域名即可。
        applicationId = "com.yueji.note"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 有正式密钥就用正式密钥；没有则退回 debug（产物仅供验证，不可上架）
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 正式包不做混淆映射外泄：保留 mapping 以便线上崩溃符号化
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// core library desugaring（flutter_local_notifications 依赖，P3-2）
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
