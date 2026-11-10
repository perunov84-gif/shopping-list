#!/usr/bin/env bash
# Запускает APK в эмуляторе, снимает журнал сбоев и скриншоты. Вызывается из CI.
set -u
OUT=/tmp/ci/smoke
mkdir -p "$OUT"
PKG=ru.perunov.shopping_list
adb wait-for-device
for apk in dist/shopping-list-gplay.apk dist/shopping-list-rustore.apk; do
  name=$(basename "$apk" .apk)
  adb uninstall "$PKG" >/dev/null 2>&1 || true
  adb install -r -g "$apk" > "$OUT/$name-install.txt" 2>&1
  adb logcat -c
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
  sleep 25
  adb exec-out screencap -p > "$OUT/$name-start.png"
  # простой сценарий: создать список «Продукты»
  adb shell input tap 540 1300 >/dev/null 2>&1
  sleep 3
  adb exec-out screencap -p > "$OUT/$name-step2.png"
  adb shell pidof "$PKG" > "$OUT/$name-pid.txt" 2>&1 || echo "NOT RUNNING" > "$OUT/$name-pid.txt"
  adb logcat -d -v brief > "$OUT/$name-logcat-full.txt" 2>&1
  grep -E "AndroidRuntime|FATAL|flutter|E/|Exception" "$OUT/$name-logcat-full.txt" | grep -v -E "^W/" | head -400 > "$OUT/$name-errors.txt"
done
exit 0
