allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
subprojects {
    val fixNamespace = Action<Project> {
        val android = extensions.findByName("android")
        if (android is com.android.build.gradle.BaseExtension) {
            if (android.namespace == null) {
                // 自動將套件的 group 名稱設定為其 namespace
                android.namespace = group.toString()
            }
        }
    }

    // 關鍵修正：如果專案已經 evaluated，就直接跑；否則才加入 afterEvaluate 監聽
    if (project.state.executed) {
        fixNamespace.execute(project)
    } else {
        project.afterEvaluate {
            fixNamespace.execute(this)
        }
    }
}