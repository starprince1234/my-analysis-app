buildscript { // <--- 请寻找这个 buildscript 块
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 这一行就是我们需要修改的 Android Gradle Plugin 版本
        classpath("com.android.tools.build:gradle:8.5.1") // <--- 找到这行，把 8.9.1 修改为 8.5.1
        // 如果有 Kotlin Gradle Plugin，也可能在这里
        // classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:X.Y.Z")
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven("https://maven.aliyun.com/repository/google") // Google 仓库镜像
        maven("https://maven.aliyun.com/repository/public")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
