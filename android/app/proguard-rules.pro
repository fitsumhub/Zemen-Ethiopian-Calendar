# Flutter / Play release shrinker keep rules for EthioCal Pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Flutter references Play Core deferred components optionally; not used by EthioCal.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# WorkManager (flutter_local_notifications) — R8 must keep Room DB impl
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep interface androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.InputMerger
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Keep Kotlin metadata
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }

# Home-screen widget — R8 must not strip / rename the provider (Samsung bind)
-keep class com.ethiocal.EthioCalHomeWidgetProvider { *; }
-keep class com.ethiocal.EthioCalHomeWidgetProvider$* { *; }
-keep class com.ethiocal.EthiopianDateMath { *; }
-keep class com.ethiocal.EthiopianDateMath$* { *; }
-keep class com.ethiocal.MainActivity { *; }
-keepclassmembers class * extends android.appwidget.AppWidgetProvider {
    public <init>();
}
