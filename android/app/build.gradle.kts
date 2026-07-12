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

// Flutter plugin 在有插件的项目中不会直接给 app 添加 embedding 依赖，
// 而是指望插件子项目传递。这里显式添加以确保 FlutterActivity 可编译。
project.afterEvaluate {
    val engineVersion = localProperties.getProperty("flutter.engineVersion") ?: ""
    if (engineVersion.isNotEmpty()) {
        dependencies.add("releaseApi", "io.flutter:flutter_embedding_release:1.0.0-$engineVersion")
        dependencies.add("debugApi", "io.flutter:flutter_embedding_debug:1.0.0-$engineVersion")
        println("CiliCili: Added Flutter embedding dependency with engine version: $engineVersion")
    } else {
        println("CiliCili: WARNING - Could not determine Flutter engine version!")
    }
}

flutter {
    source = "../.."
}
