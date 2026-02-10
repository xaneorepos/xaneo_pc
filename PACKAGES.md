# Пакеты xaneo_pc

## Сводка собранных пакетов

| Пакет | Размер | Дистрибутив | Требует FUSE |
|-------|--------|-------------|--------------|
| AppImage | 16M | Любой Linux | ✅ Да |
| RPM | 8.8M | Fedora/RHEL/CentOS | ❌ Нет |
| Arch (.pkg.tar.zst) | 9.3M | Arch Linux | ❌ Нет |
| Tarball (.tar.gz) | 16M | Любой Linux | ❌ Нет |
| APK | 15M | Alpine Linux | ❌ Нет |
| Nix | 393B | NixOS | ❌ Нет |
| DEB | 15M | Debian/Ubuntu | ❌ Нет |

## Установка пакетов

### AppImage (требует FUSE)

```bash
chmod +x dist/xaneo_pc-latest.AppImage
./dist/xaneo_pc-latest.AppImage
```

### Fedora/RHEL/CentOS (.rpm)

```bash
sudo dnf install dist/xaneo_pc-latest.rpm
# или для старых версий:
sudo yum install dist/xaneo_pc-latest.rpm
```

### Arch Linux (.pkg.tar.zst)

```bash
sudo pacman -U dist/xaneo_pc-latest.pkg.tar.zst
```

### Debian/Ubuntu (.deb)

```bash
sudo dpkg -i dist/xaneo_pc-latest.deb
sudo apt-get install -f  # если есть зависимости
```

### Alpine Linux (.apk)

```bash
sudo apk add --allow-untrusted dist/xaneo_pc-latest.apk
```

### NixOS (.nix)

```bash
nix-env -i dist/xaneo_pc-latest.nix
```

### Tarball (.tar.gz) - не требует FUSE

```bash
tar -xzf dist/xaneo_pc-latest.tar.gz
cd xaneo_pc-1.0.0-x86_64
./run.sh
```

## Контрольные суммы

Все контрольные суммы находятся в файле `dist/SHA256SUMS.txt`.

Проверка контрольной суммы:
```bash
cd dist
sha256sum -c SHA256SUMS.txt
```

## Скрипт сборки

Для пересборки пакетов используйте скрипт `build_flutter_packages.sh`:

```bash
# Собрать все пакеты
./build_flutter_packages.sh all

# Собрать конкретный тип пакета
./build_flutter_packages.sh appimage  # AppImage
./build_flutter_packages.sh rpm       # Fedora/RHEL/CentOS
./build_flutter_packages.sh arch      # Arch Linux
./build_flutter_packages.sh tarball   # Tarball (без FUSE)

# С опциями
./build_flutter_packages.sh all --symlinks --checksums
```

## Зависимости для сборки

- **Flutter** - для сборки приложения
- **appimagetool** - для создания AppImage (опционально)
- **rpmbuild** - для создания RPM (опционально)
- **makepkg** - для создания Arch пакетов (опционально)
- **dpkg-deb** - для создания DEB (опционально)
- **abuild** - для создания APK (опционально)
- **xbps-create** - для создания XBPS (опционально)

## Структура проекта

```
xaneo_pc/
├── build_flutter_packages.sh  # Скрипт сборки пакетов
├── PACKAGES.md                # Документация по пакетам
├── BUILD.md                   # Документация по сборке
├── dist/                      # Собранные пакеты
│   ├── xaneo_pc.AppImage
│   ├── xaneo-pc-1.0.0-1.x86_64.rpm
│   ├── xaneo-pc-1.0.0-1-x86_64.pkg.tar.zst
│   ├── xaneo_pc-1.0.0-x86_64.tar.gz
│   ├── xaneo_pc-1.0.0-x86_64.apk
│   ├── xaneo_pc.nix
│   ├── xaneo-pc_1.0.0_amd64.deb
│   ├── SHA256SUMS.txt
│   └── xaneo_pc-latest.*       # Символические ссылки
├── AppDir/                    # Структура для AppImage
├── lib/                       # Исходный код Flutter
├── linux/                     # Конфигурация Linux
└── assets/                    # Ресурсы приложения
```

## Примечания

- **AppImage** требует FUSE для запуска. Если FUSE недоступен, используйте tarball.
- **Tarball** - универсальный вариант, не требует FUSE и может быть запущен на любой системе Linux.
- Размеры пакетов могут незначительно отличаться в зависимости от версии и настроек сборки.
- Проект оптимизирован только для Linux, папки для других платформ удалены.
