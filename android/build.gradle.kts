buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Enable this configuration but modify it to match Flutter's expectations
val flutterBuildDir = rootProject.layout.projectDirectory.dir("../build/app")
val newBuildDir = rootProject.layout.buildDirectory.dir("../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    afterEvaluate {
        if (project.name == "app") {
            // Special configuration for the app project to match Flutter's expectations
            project.layout.buildDirectory.set(flutterBuildDir)
        } else {
            // For other projects
            val newSubprojectBuildDir = newBuildDir.dir(project.name)
            project.layout.buildDirectory.value(newSubprojectBuildDir)
        }

        // Set Java compatibility for all Android projects
        if (plugins.hasPlugin("com.android.library") ||
            plugins.hasPlugin("com.android.application")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
        if (plugins.hasPlugin("org.jetbrains.kotlin.android") || plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "11"
                }
            }

            extensions.configure<com.android.build.gradle.BaseExtension> {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}