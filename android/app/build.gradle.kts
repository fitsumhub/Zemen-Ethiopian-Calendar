import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.Properties
import java.io.FileInputStream
import java.io.IOException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Optional AdMob App ID override via android/admob.properties (recommended for production).
val admobProperties = Properties()
val admobPropertiesFile = rootProject.file("admob.properties")
val admobAppId: String = if (admobPropertiesFile.exists()) {
    admobProperties.load(FileInputStream(admobPropertiesFile))
    admobProperties.getProperty(
        "admobAppId",
        "ca-app-pub-3940256099942544~3347511713",
    )
} else {
    // Google sample App ID — safe for debug/QA. Replace via admob.properties before monetized release.
    "ca-app-pub-3940256099942544~3347511713"
}

android {
    namespace = "com.ethiocal"
    compileSdk = 37

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.zemen.calendar"
        minSdk = 24
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Local fallback only — Play uploads require key.properties + upload-keystore.jks
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

// Gradle's Copy task chmods every file to mode 644. On Windows that chmod is a
// no-op that still fails when the destination disappears (kernel_blob.bin is
// large and often locked or quarantined mid-copy). Copy the Flutter assets
// with NIO instead, which does not set Unix modes.
tasks.withType<Copy>().configureEach {
    val copyTask = this
    val osName = System.getProperty("os.name").orEmpty()
    if (!name.startsWith("copyFlutterAssets") || !osName.contains("Windows", ignoreCase = true)) {
        return@configureEach
    }
    eachFile {
        exclude()
    }
    doLast {
        val destDir = copyTask.destinationDir
            ?: throw GradleException("${copyTask.name} has no destination directory")
        (copyTask.source as FileTree).visit(
            object : FileVisitor {
                override fun visitDir(dirDetails: FileVisitDetails) = Unit

                override fun visitFile(fileDetails: FileVisitDetails) {
                    val target = fileDetails.relativePath.getFile(destDir)
                    target.parentFile?.mkdirs()
                    val sourcePath = fileDetails.file.toPath()
                    val targetPath = target.toPath()
                    var lastError: IOException? = null
                    for (attempt in 1..6) {
                        try {
                            Files.copy(
                                sourcePath,
                                targetPath,
                                StandardCopyOption.REPLACE_EXISTING,
                            )
                            // Defender often locks kernel_blob.bin right after it is written.
                            Files.newInputStream(targetPath).use { }
                            lastError = null
                            break
                        } catch (error: IOException) {
                            lastError = error
                            Thread.sleep(250L * attempt)
                        }
                    }
                    lastError?.let { throw it }
                }
            },
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
