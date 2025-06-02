########################################
# Flutter
########################################
-keep class io.flutter.** { *; }

########################################
# Firebase / Google Play Services
########################################
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

########################################
# MainActivity (entry point)
########################################
-keep class com.nextu.app.MainActivity { *; }

########################################
# Native methods (JNI)
########################################
-keepclasseswithmembernames class * {
    native <methods>;
}

########################################
# Reflection-safe constructors
########################################
-keepclassmembers class * {
    <init>();
}
