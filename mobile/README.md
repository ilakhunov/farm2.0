# Farm Mobile (Flutter)

Flutter приложение MVP с входом по SMS, локализацией (uz/ru/en) и подготовкой под farmer / shop режимы.

## Структура

- `lib/main.dart` — точка входа, подключение локализаций.
- `lib/core/localization` — загрузка переводов из JSON.
- `lib/features/auth/view` — экраны авторизации (ввод телефона, OTP).
- `assets/translations` — тексты интерфейса на трёх языках.

## Быстрый старт

```bash
# Требуется установленный Flutter SDK (3.3+)
cd /home/tandyvip/projects/farm2.0/mobile
flutter pub get
flutter run
```

Для локальной разработки нужно настроить `.env` в бэкенде и указать базовый URL в Dio-клиенте (добавим на следующих этапах).

## TODO
- Подключить Dio и вызывать `/api/v1/auth/send-otp` и `/verify-otp`.
- Добавить выбор роли (фермер/магазин) и регистрацию юридических данных.
- Реализовать роутинг в личные кабинеты.
