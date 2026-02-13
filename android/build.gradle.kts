// 🚀 在最上方定義插件版本
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 確保 Android Gradle 插件版本足夠新
        classpath("com.android.tools.build:gradle:8.5.0")
        // 確保 Kotlin 插件與 Java 17 相容
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 保持原本的 Build Directory 設定 (Flutter 預設)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // 🚀 關鍵修正：針對 image_cropper 或舊套件強制執行 API 等級對齊
    project.afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension) {
            // 強制所有子專案至少使用 API 35 編譯，避免 Registrar 錯誤
            android.compileSdkVersion(35)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// 自動修正 Namespace 邏輯 (保留並優化)
subprojects {
    val fixNamespace = Action<Project> {
        val android = extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension) {
            if (android.namespace == null) {
                // 如果套件沒有設定 namespace，則使用其 group 名稱
                android.namespace = group.toString()
            }
        }
    }

    if (project.state.executed) {
        fixNamespace.execute(project)
    } else {
        project.afterEvaluate {
            fixNamespace.execute(this)
        }
    }
}