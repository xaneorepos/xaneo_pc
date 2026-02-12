#!/bin/bash

# Запуск Flutter приложения с включённым Impeller для Linux
# Impeller - новый рендеринг-движок Flutter с предкомпиляцией шейдеров

# Включаем Impeller через переменную окружения
export FLUTTER_IMPELLER=1

# Запускаем приложение
flutter run -d linux "$@"
