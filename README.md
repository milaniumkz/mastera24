# Mastera24

Flutter-приложение для заказчиков и исполнителей. Backend: Firebase Authentication,
Cloud Firestore, Storage, Cloud Messaging и Cloud Functions (Node.js 20).

## Работа из облака

В GitHub выберите **Code → Codespaces → Create codespace on main**.
Конфигурация `.devcontainer` устанавливает Flutter 3.41.1, Node.js 20 и зависимости.
Она также подходит для VS Code Dev Containers. Среда рассчитана на веб-разработку;
для сборки iOS нужен macOS/Xcode, для Android — Android SDK.

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Откройте адрес порта 8080 из вкладки **Ports**. Для входа через OAuth домен облачного
предпросмотра необходимо добавить в разрешённые домены Firebase Authentication.

## Локальная установка

Требуются Flutter 3.41.1 и Node.js 20.

```bash
flutter pub get
npm ci --prefix functions
```

Проверки и сборка:

```bash
flutter analyze
flutter test
npm test --prefix functions
flutter build web --release
```

## Структура

- `lib/` — приложение и интеграции Firebase.
- `functions/` — серверные функции, платежи и уведомления.
- `test/` — тесты приложения; тесты функций находятся в `functions/`.
- `assets/`, `web/`, `android/`, `ios/`, `macos/`, `linux/`, `windows/` — ресурсы и платформы.
- `firestore.rules`, `firestore.indexes.json`, `storage.rules`, `firebase.json` — правила, индексы и развёртывание.

## Firebase и секреты

Сохранена клиентская конфигурация проекта `mastera24-bfbcf`. Это идентификаторы
приложения; доступ к backend определяется Authentication и правилами Firebase.
Облачная копия с этой конфигурацией обращается к существующему backend. Для
изолированной разработки используйте отдельный Firebase-проект и обновите
клиентские конфигурации.

Пользователи, заказы, переписки и файлы Firebase остаются в Firebase: репозиторий
содержит исходники, а не экспорт рабочей базы данных. Доступ к проекту Firebase
предоставляется отдельно через его консоль.

Секреты платежей задаются отдельно по образцу `functions/.env.example`, через
приватные переменные окружения или секреты облачной среды. Не добавляйте реальные
значения в Git. Зависимости, сборки, локальные настройки и ключи подписи исключены
через `.gitignore` и восстанавливаются при установке.

Настройка и выпуск: [FIREBASE_OAUTH_SETUP.md](FIREBASE_OAUTH_SETUP.md),
[PROD_SETUP_CHECKLIST.md](PROD_SETUP_CHECKLIST.md),
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md),
[MANUAL_TEST_PLAN.md](MANUAL_TEST_PLAN.md).
