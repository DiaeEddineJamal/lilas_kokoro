# Keep our custom icons and notification resources
-keep class com.example.lilas_kokoro.** { *; }

# Keep Flutter Local Notifications resources
-keep class com.dexterous.** { *; }

# Keep drawable and mipmap resources
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep notification icons
-keep class **.R$drawable { *; }
-keep class **.R$mipmap { *; }

# Keep our custom launcher and notification icons
-keep class **.R$drawable$ic_notification { *; }
-keep class **.R$mipmap$launcher_icon { *; }

# Don't obfuscate resource names
-keepnames class **.R$*

# Flutter and system rules
-flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep custom icon resources from being stripped
-keepclassmembers class **.R$* {
    public static <fields>;
}
-keep public class * extends java.lang.Exception
-keep-community-class-members class **.R$* {
    public static <fields>;
}
-dontwarn io.flutter.embedding.** 