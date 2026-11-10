# Монетизация и публикация

## Модель

* Приложение **бесплатное**, с ненавязчивой рекламой.
* **VIP** — разовая покупка (non-consumable, ID `vip_forever`): отключает рекламу навсегда. Цену стоит держать на уровне «дешевле чашки кофе» (99–149 ₽ / $0.99–1.99): так делает Shopping List от Kiwi3 (1 млн+ установок, рейтинг 4,8).
  Покупка восстанавливается после переустановки («Восстановить покупку»).
* Две сборки из одного кода:

| Сборка | Магазины | Реклама | Оплата VIP |
|---|---|---|---|
| `STORE=gplay` | Google Play, App Store | AdMob | Google Play Billing / StoreKit (`in_app_purchase`) |
| `STORE=rustore` | RuStore, прямая установка, а также AppGallery, Xiaomi GetApps, Galaxy Store (реклама Яндекса работает без сервисов Google) | Яндекс Реклама | RuStore Pay SDK |

В других магазинах (AppGallery и подобных) без собственного SDK оплаты VIP будет недоступен, но реклама работать будет.

## 0. Страница для ссылок «Отправить список» (один раз)

GitHub → репозиторий → **Settings → Pages** → Source: **Deploy from a branch**, Branch: **gh-pages**, папка **/(root)** → Save.
Через минуту заработает `https://perunov84-gif.github.io/shopping-list/s/` — без неё присланные ссылки не откроются.
Ветку `gh-pages` автоматически обновляет workflow `pages.yml`.

## 1. Ключ подписи (один раз, хранить вечно)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks > keystore.b64
```

GitHub → Settings → Secrets and variables → Actions → **New repository secret**:

| Секрет | Значение |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | содержимое `keystore.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | пароль хранилища |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | пароль ключа |

Без этих секретов CI подписывает APK отладочным ключом: так можно тестировать, но публиковать нельзя.
**Потеря ключа = невозможность обновлять приложение в RuStore**, поэтому сделайте резервную копию.

## 2. Реклама

**Яндекс Реклама (RuStore-сборка):** https://partner.yandex.ru → «Мобильные приложения» → добавить приложение →
создать блоки «Адаптивный баннер (sticky)» и «Межстраничный». ID блоков (вида `R-M-1234567-1`) передать в сборку:
`--dart-define=YANDEX_BANNER_ID=... --dart-define=YANDEX_INTERSTITIAL_ID=...`.

**AdMob (Google Play / App Store):** https://admob.google.com → приложение Android (и iOS) → блоки «Адаптивный баннер»
и «Межстраничный».
* App ID Android → `android/gradle.properties`: `admobAppId=ca-app-pub-XXXX~YYYY`
* App ID iOS → `ios/Runner/Info.plist`, ключ `GADApplicationIdentifier`
* ID блоков → `--dart-define=ADMOB_BANNER_ID=... --dart-define=ADMOB_INTERSTITIAL_ID=...`
* Разместите файл `app-ads.txt` на сайте разработчика (требование AdMob).
* В AdMob включите сообщение о согласии GDPR (Privacy & messaging) — приложение уже вызывает форму UMP.

Пока ID не заданы, используются официальные тестовые ID: доход не начисляется, зато аккаунт не заблокируют за клики при разработке.

## 3. Покупка VIP

**Google Play Console:** Монетизация → Продукты → Встроенные товары → создать `vip_forever` (разовый), задать цену и активировать.
Покупки работают только для версии, загруженной в Play Console (хотя бы во внутреннее тестирование), и для аккаунтов-тестировщиков.

**App Store Connect:** In-App Purchases → Non-Consumable → `vip_forever`.

**RuStore Console** (https://console.rustore.ru): подключить монетизацию (нужен статус ИП/самозанятого/юрлица),
Продукты → разовая покупка `vip_forever`. Код приложения из адреса консоли (`/apps/123456`) записать в секрет
`RUSTORE_APP_ID`.

## 4. Публикация

### Google Play
1. Аккаунт разработчика — $25 разово. Для новых личных аккаунтов действует правило закрытого тестирования
   (12+ тестировщиков в течение 14 дней) перед выходом в продакшн.
2. Сборка: `flutter build appbundle --release --dart-define=STORE=gplay` (+ ID рекламы) → `.aab`.
3. Заполнить: описание, скриншоты, иконку 512×512, графику 1024×500, анкету о контенте, раздел «Безопасность данных»
   (рекламный ID, данные о покупках, микрофон — данные не сохраняются на сервере), ссылку на политику конфиденциальности.
4. Указать, что приложение содержит рекламу.

### RuStore
1. Регистрация в https://console.rustore.ru (бесплатно).
2. Загрузить `shopping-list-rustore.apk`, подписанный release-ключом.
3. Описание, скриншоты, возрастной рейтинг, политика конфиденциальности.

### App Store (iOS)
1. Apple Developer Program — $99 в год, нужен Mac с Xcode.
2. `flutter build ipa --release --dart-define=STORE=gplay` → загрузка через Transporter или Xcode.
3. Включить запрос App Tracking Transparency для персонализированной рекламы (текст уже есть в Info.plist).

### Другие площадки (AppGallery, Xiaomi GetApps, Galaxy Store, RuMarket и т. д.)
Используйте `shopping-list-rustore.apk`: Яндекс Реклама работает и без сервисов Google.

## Чек-лист перед релизом

- [ ] Секреты подписи заданы, сборка подписана release-ключом
- [ ] Боевые ID рекламы вместо тестовых
- [ ] Продукт `vip_forever` создан во всех магазинах
- [ ] Сборка без `TEST_BUILD=true` (иначе работает скрытый переключатель VIP)
- [ ] Увеличен `version` в `pubspec.yaml` (`1.0.1+2` и т. д.)
- [ ] Ссылка на политику конфиденциальности указана в магазине
