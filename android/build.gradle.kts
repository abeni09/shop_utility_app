buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core") {
                useVersion("1.13.1")
            }
        }
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

    project.evaluationDependsOn(":app")

    val configureNamespace: Project.() -> Unit = {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.LibraryExtension> {
                if (namespace == null) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        try {
                            val manifestXml = manifestFile.readText()
                            val packageMatch =
                                Regex("""package=["']([^"']+)["']""").find(
                                    manifestXml
                                )
                            if (packageMatch != null) {
                                namespace = packageMatch.groupValues[1]
                            }
                        } catch (e: Exception) {
                            // Ignore read errors
                        }
                    }
                }
                if (namespace == null) {
                    namespace = "fix.${name.replace("-", ".")}"
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace()
    } else {
        afterEvaluate { configureNamespace() }
    }

    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.AppPlugin ||
            this is com.android.build.gradle.LibraryPlugin
        ) {
            val android =
                project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.compileSdkVersion(36)
        }
    }

    tasks.withType<com.android.build.gradle.tasks.VerifyLibraryResourcesTask> {
        enabled = false
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
