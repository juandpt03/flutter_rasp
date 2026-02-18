-keep class com.juandpt.flutter_rasp.FlutterRaspPlugin { *; }

-obfuscate

-repackageclasses 'com.juandpt.flutter_rasp.internal'

-adaptclassstrings com.juandpt.flutter_rasp.detectors.**

-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
