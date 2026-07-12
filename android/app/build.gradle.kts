import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "2"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "2.0.0"

// 读取 Flutter 引擎版本
val flutterSdkPath = localProperties.getProperty("flutter.sdk") ?: ""
val engineVersionFile = file("$flutterSdkPath/bin/cache/engine.stamp")
val engineVersion = if (engineVersionFile.exists()) {
    engineVersionFile.readText().trim()
} else {
    ""
}

android {
    namespace = "com.cheymin.cilicili"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin", "src/main/java")
        }
    }

    defaultConfig {
        applicationId = "com.cheymin.cilicili"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// 显式添加 Flutter embedding 依赖到 api 配置（确保 FlutterActivity 可被编译）
// Flutter Gradle plugin 默认只在无插件项目添加此依赖；有插件时由插件传递，
// 但某些情况下传递失败会导致 FlutterActivity 无法解析。
dependencies {
    if (engineVersion.isNotEmpty()) {
        "releaseApi"("io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
        "debugApi"("io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
    }
}

flutter {
    source = "../.."
}
