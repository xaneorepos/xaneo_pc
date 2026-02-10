# Сборка пакетов xaneo_pc

Этот скрипт предназначен для автоматической сборки пакетов приложения xaneo_pc для различных дистрибутивов Linux.

## Поддерживаемые дистрибутивы

| Дистрибутив | Тип пакета | Команда установки |
|--------------|-----------|-------------------|
| Debian/Ubuntu | `.deb` | `sudo dpkg -i xaneo_pc-latest.deb` |
| Fedora/RHEL/CentOS | `.rpm` | `sudo dnf install xaneo_pc-latest.rpm` |
| Arch Linux | `.pkg.tar.zst` | `sudo pacman -U xaneo_pc-latest.pkg.tar.zst` |
| Alpine Linux | `.apk` | `sudo apk add --allow-untrusted xaneo_pc-latest.apk` |
| NixOS | `.nix` | `nix-env -i xaneo_pc.nix` |
| Любой Linux | `.AppImage` | `chmod +x xaneo_pc-latest.AppImage && ./xaneo_pc_latest.AppImage` |
| Любой Linux | `.tgz` | `tar -xzf xaneo_pc-1.0.0-x86_64.tgz` |

## Использование

### Базовая сборка всех пакетов

```bash
./build_all.sh
```

### Сборка конкретного типа пакета

```bash
./build.sh appimage  # AppImage
./build.sh deb       # Debian
./build.sh rpm       # Fedora
./build.sh arch      # Arch
./build.sh apk       # Alpine
./build.sh nix       # NixOS
./build.sh bundle    # Linux bundle
```

### Опции

| Опция | Короткий | Описание |
|-------|---------|-----------|
| `--clean` | `-c` | Очистить предыдущую сборку перед началом |
| `--symlinks` | `-s` | Создать символические ссылки с суффиком `-latest` |
| `--checksums` | `-k` | Создать файл контрольных сумм SHA256 |
| `--archive` | `-a` | Создать архив со всеми пакетами |
| `--version` | `-v` | Указать версию для архива |

### Примеры

```bash
# Очистить и собрать все пакеты
./build_all.sh --clean

# Собрать только AppImage и создать ссылки
./build_all.sh appimage --symlinks

# Собрать все пакеты с контрольными суммами и архивом
./build_all.sh --checksums --archive --version 1.0.0

# Быстрая пересборка без очистки
./build_all.sh deb
```

## Зависимости

Для работы скрипта требуются:

- **Flutter** — для сборки приложения
- **Electron-forge** — для создания пакетов
- **Dart** — включён в состав Flutter

### Установка зависимостей

```bash
# Flutter
# https://docs.flutter.dev/get-started/install/linux

# Electron-forge
npm install -g electron-forge
```

## Структура выходной директории

После сборки в папке `dist/` будут созданы следующие файлы:

```
dist/
├── xaneo-pc_1.0.0_amd64.deb          # Debian/Ubuntu
├── xaneo_pc-1.0.0-1.x86_64.rpm          # Fedora/RHEL/CentOS
├── xaneo_pc-1.0.0-1-x86_64.pkg.tar.zst   # Arch Linux
├── xaneo_pc-1.0.0-x86_64.apk            # Alpine Linux
├── xaneo_pc.AppImage                     # Универсальный AppImage
├── xaneo_pc.nix                          # NixOS
├── xaneo_pc-1.0.0-x86_64.tgz           # Tarball
├── SHA256SUMS.txt                       # Контрольные суммы
├── xaneo_pc-latest.deb                    # Ссылка на .deb
├── xaneo_pc-latest.rpm                    # Ссылка на .rpm
├── xaneo_pc-latest.pkg.tar.zst            # Ссылка на Arch пакет
└── xaneo_pc-latest.AppImage              # Ссылка на AppImage
```

## Установка пакетов

### Debian/Ubuntu

```bash
sudo dpkg -i xaneo_pc-latest.deb
```

### Fedora/RHEL/CentOS

```bash
sudo dnf install xaneo_pc-latest.rpm
# или для старых версий:
sudo yum install xaneo_pc-latest.rpm
```

### Arch Linux

```bash
sudo pacman -U xaneo_pc-latest.pkg.tar.zst
```

### Alpine Linux

```bash
sudo apk add --allow-untrusted xaneo_pc-latest.apk
```

### NixOS

```bash
nix-env -i xaneo_pc-latest.nix
```

### AppImage (универсальный)

```bash
chmod +x xaneo_pc-latest.AppImage
./xaneo_pc-latest.AppImage
```

### Tarball

```bash
tar -xzf xaneo_pc-1.0.0-x86_64.tgz
cd xaneo_pc-1.0.0-x86_64
./xaneo_pc_new
```

## Устранение пакетов

### Debian/Ubuntu

```bash
sudo dpkg -r xaneo-pc
```

### Fedora/RHEL/CentOS

```bash
sudo dnf remove xaneo-pc
```

### Arch Linux

```bash
sudo pacman -R xaneo-pc
```

### Alpine Linux

```bash
sudo apk del xaneo-pc
```

## Troubleshooting

### Ошибка "flutter: command not found"

Убедитесь, что Flutter добавлен в PATH:

```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Ошибка "electron-forge: command not found"

Установите electron-forge глобально:

```bash
npm install -g electron-forge
```

### Ошибка при сборке RPM

Убедитесь, что установлены зависимости для RPM:

```bash
sudo dnf install rpm-build
```

### Ошибка при сборке DEB

Убедитесь, что установлены зависимости для DEB:

```bash
sudo apt-get install build-essential
```

## Автоматизация

### Сборка при каждом коммите (Git hook)

Добавьте в `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./build_all.sh deb
```

### CI/CD пример (GitHub Actions)

```yaml
name: Build Linux Packages

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install electron-forge
        run: npm install -g electron-forge
        
      - name: Build packages
        run: ./build_all.sh --clean --symlinks --checksums
        
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: linux-packages
          path: dist/
```

## Лицензия

Этот скрипт распространяется под той же лицензией, что и сам проект xaneo_pc.
