# R8 удалял сгенерированные классы Room (WorkManager из рекламных SDK) → падение при запуске.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn androidx.work.**

# Рекламные и платёжные SDK (на случай агрессивного режима R8 в AGP 9)
-keep class com.yandex.mobile.ads.** { *; }
-dontwarn com.yandex.mobile.ads.**
-keep class ru.rustore.** { *; }
-dontwarn ru.rustore.**
-keep class com.google.android.gms.ads.** { *; }
