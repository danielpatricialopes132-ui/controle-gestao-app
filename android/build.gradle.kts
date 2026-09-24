allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    val configureAndroid = {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val compileSdkMethod = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                compileSdkMethod.invoke(androidExt, 36)
            } catch (e: Exception) {
                try {
                    val compileSdkProp = androidExt.javaClass.getMethod("compileSdk", Int::class.javaPrimitiveType)
                    compileSdkProp.invoke(androidExt, 36)
                } catch (e2: Exception) {
                    // ignore
                }
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
