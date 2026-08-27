#!/bin/bash

# Сборка Flutter приложения с Impeller и предкомпиляцией шейдеров
# Impeller - новый рендеринг-движок Flutter с предкомпиляцией шейдеров

echo "🚀 Сборка с Impeller и предкомпиляцией шейдеров..."

# Включаем Impeller через переменную окружения
export FLUTTER_IMPELLER=1

# Очищаем предыдущую сборку
flutter clean

# Получаем зависимости
flutter pub get

# Локализации хранятся в lib/l10n и содержат вручную расширенные ключи,
# которых пока нет в ARB. Не запускаем gen-l10n: он перезапишет эти файлы.

# Собираем приложение с предкомпиляцией шейдеров
flutter build linux --release --enable-impeller

echo "✅ Сборка завершена!"
echo "📁 Результат: build/linux/x64/release/bundle/"
