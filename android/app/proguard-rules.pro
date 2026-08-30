# Flutter / Dart
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep application class (MainActivity, etc.)
-keep class com.ethio_properties.housing_platform_mobile.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# --- Live video: LiveKit + WebRTC ---
# WebRTC uses JNI/native callbacks; R8 must not rename or strip these.
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn com.cloudwebrtc.webrtc.**
-keep class io.livekit.** { *; }
-dontwarn io.livekit.**
# LiveKit's generated protobuf models
-keep class livekit.** { *; }
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# --- Networking (Dio uses OkHttp on Android) ---
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# --- permission_handler ---
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# --- flutter_secure_storage ---
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# Kotlin metadata / coroutines used by several plugins
-dontwarn kotlin.**
-dontwarn kotlinx.**

# Keep annotations and enum values (used reflectively by some plugins)
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
