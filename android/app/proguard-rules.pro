# Google ML Kit Text Recognition - Ignore unused language models to fix R8 build errors
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Preserve attributes required for reflection and native callbacks
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google ML Kit - Comprehensive Keep Rules
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Services (GMS)
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Specific rules for GMS Tasks (crucial for result callbacks)
-keep class com.google.android.gms.tasks.** { *; }

# Keep all Vision and Document Scanner Native classes
# Keep DocumentScanner native class and its fields to preserve MethodChannel.Result
-keep class com.google.mlkit.document_scanner.** { *; }
-keepclassmembers class com.google.mlkit.document_scanner.DocumentScanner { *; }
-keep class com.google.mlkit.vision.** { *; }

# Keep all ML Kit Flutter Plugin classes and their members
-keep class com.google_mlkit_document_scanner.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_entity_extraction.** { *; }
-keep class com.google_mlkit_language_id.** { *; }
-keep class com.google_mlkit_translation.** { *; }

# General ML Kit internal rules
-keep class com.google.android.gms.internal.ml.** { *; }
-keep class com.google.firebase.ml.** { *; }

# Preserve MethodChannel bridge
-keep class io.flutter.plugin.common.** { *; }
-keepclassmembers class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler {
   <fields>;
   <methods>;
}
