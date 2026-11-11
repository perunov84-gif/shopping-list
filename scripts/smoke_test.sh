#!/usr/bin/env bash
# Запускает APK в эмуляторе, снимает журнал сбоев и скриншоты. Вызывается из CI.
set -u
OUT=/tmp/ci/smoke
mkdir -p "$OUT"
PKG=ru.perunov.shopping_list
adb wait-for-device
SIZE=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1); W=${SIZE%x*}; H=${SIZE#*x}
tap() { adb shell input tap $(( W * $1 / 100 )) $(( H * $2 / 100 )); sleep 3; }
for apk in dist/shopping-list-gplay.apk dist/shopping-list-rustore.apk; do
  name=$(basename "$apk" .apk)
  adb uninstall "$PKG" >/dev/null 2>&1 || true
  adb install -r -g "$apk" > "$OUT/$name-install.txt" 2>&1
  adb logcat -c
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
  sleep 0.6; adb exec-out screencap -p > "$OUT/$name-0-splash.png"
  sleep 25
  adb exec-out screencap -p > "$OUT/$name-1-start.png"
  tap 50 70                      # «Создать список»
  adb exec-out screencap -p > "$OUT/$name-2-sheet.png"
  tap 20 52                      # плитка «Продукты»
  adb shell input text "moloko,hleb"; adb shell input keyevent 66; sleep 3
  adb exec-out screencap -p > "$OUT/$name-3-list.png"
  # Присланная ссылка: должна открыть приложение сразу на списке
  D=$(python3 -c 'import zlib,base64,json;c=zlib.compressobj(9,zlib.DEFLATED,-15);b=c.compress(json.dumps({"v":1,"id":"smoke123","n":"От жены","c":"grocery","t":[["Молоко","2 л"],["Хлеб"],["Гвозди"]]},ensure_ascii=False).encode())+c.flush();print(base64.urlsafe_b64encode(b).decode().rstrip("="))')
  adb shell am start -W -a android.intent.action.VIEW -d "shoppinglist://list?d=$D" "$PKG" > "$OUT/$name-deeplink.txt" 2>&1
  sleep 6
  adb exec-out screencap -p > "$OUT/$name-4-deeplink.png"
  adb shell input keyevent 4; sleep 2              # назад: список открыт в режиме редактирования? выходим на главный
  adb exec-out screencap -p > "$OUT/$name-5-home.png"
  adb shell pidof "$PKG" > "$OUT/$name-pid.txt" 2>&1 || echo "NOT RUNNING" > "$OUT/$name-pid.txt"
  adb logcat -d -v brief > "$OUT/$name-logcat-full.txt" 2>&1
  grep -n "FATAL EXCEPTION" -A40 "$OUT/$name-logcat-full.txt" > "$OUT/$name-crash.txt" || true
  grep -E "E/flutter|I/flutter" "$OUT/$name-logcat-full.txt" > "$OUT/$name-flutter.txt" || true
done
exit 0
