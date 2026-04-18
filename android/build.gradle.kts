buildscript {
repositories {
google()
mavenCentral()
}
dependencies {
classpath("com.google.gms:google-services:4.4.0")
}
}

allprojects {
repositories {
google()
mavenCentral()
}
}

// Fix build directory issues
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
layout.buildDirectory.set(newBuildDir.dir(name))
}

subprojects {
evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
delete(rootProject.layout.buildDirectory)
}
