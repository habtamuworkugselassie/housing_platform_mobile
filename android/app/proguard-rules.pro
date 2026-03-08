# Flutter / Dart
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep application class (MainActivity, etc.)
-keep class com.ethio_properties.housing_platform_mobile.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
