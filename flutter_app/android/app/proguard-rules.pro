# Flutter Android ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }

# Riverpod
-keep class com.google.common.** { *; }

# General
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
