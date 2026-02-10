#!/bin/bash

# Скрипт для сборки пакетов xaneo_pc (Flutter) для различных дистрибутивов Linux
# Поддерживаемые дистрибутивы: Debian, Fedora, Arch, Alpine, Void, AppImage, Tarball

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка зависимостей
check_dependencies() {
    log_info "Проверка зависимостей..."
    
    local missing_deps=()
    
    # Проверка Flutter
    if ! command -v flutter &> /dev/null; then
        missing_deps+=("flutter")
    fi
    
    # Проверка appimagetool (для AppImage)
    if ! command -v appimagetool &> /dev/null && [ ! -f "./appimagetool-x86_64.AppImage" ]; then
        log_warning "appimagetool не найден, сборка AppImage будет пропущена"
    fi
    
    # Проверка dpkg-deb (для DEB)
    if ! command -v dpkg-deb &> /dev/null; then
        log_warning "dpkg-deb не найден, сборка .deb будет пропущена"
    fi
    
    # Проверка rpmbuild (для RPM)
    if ! command -v rpmbuild &> /dev/null; then
        log_warning "rpmbuild не найден, сборка .rpm будет пропущена"
    fi
    
    # Проверка makepkg (для Arch)
    if ! command -v makepkg &> /dev/null; then
        log_warning "makepkg не найден, сборка .pkg.tar.zst будет пропущена"
    fi
    
    # Проверка abuild (для Alpine)
    if ! command -v abuild &> /dev/null; then
        log_warning "abuild не найден, сборка .apk будет пропущена"
    fi
    
    # Проверка xbps-create (для Void)
    if ! command -v xbps-create &> /dev/null; then
        log_warning "xbps-create не найден, сборка .xbps будет пропущена"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Отсутствуют следующие зависимости: ${missing_deps[*]}"
        log_info "Установите их:"
        echo "  - Flutter: https://docs.flutter.dev/get-started/install/linux"
        echo "  - appimagetool: https://github.com/AppImage/AppImageKit/releases"
        exit 1
    fi
    
    log_success "Все зависимости установлены"
}

# Функция для очистки предыдущей сборки
clean_build() {
    log_info "Очистка предыдущей сборки..."
    
    if [ -d "build" ]; then
        rm -rf build
        log_success "Папка build удалена"
    fi
    
    if [ -d "dist" ]; then
        rm -rf dist
        log_success "Папка dist удалена"
    fi
    
    if [ -d ".dart_tool" ]; then
        rm -rf .dart_tool
        log_success "Папка .dart_tool удалена"
    fi
}

# Функция для сборки Flutter приложения
build_flutter() {
    log_info "Сборка Flutter приложения..."
    
    flutter clean
    flutter pub get
    flutter build linux --release
    
    log_success "Flutter приложение собрано"
}

# Функция для создания AppDir
create_appdir() {
    log_info "Создание AppDir..."
    
    local bundle_dir="build/linux/x64/release/bundle"
    local appdir="AppDir"
    
    if [ ! -d "$bundle_dir" ]; then
        log_error "Flutter bundle не найден: $bundle_dir"
        exit 1
    fi
    
    # Создаём AppDir если его нет
    if [ ! -d "$appdir" ]; then
        mkdir -p "$appdir"
    fi
    
    # Копируем содержимое bundle в AppDir
    cp -r "$bundle_dir"/* "$appdir"/
    
    # Создаём AppRun если его нет
    if [ ! -f "$appdir/AppRun" ]; then
        cat > "$appdir/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${HERE}/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/lib:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS}"
exec "${HERE}/xaneo_pc_new" "$@"
EOF
        chmod +x "$appdir/AppRun"
    fi
    
    # Создаём .desktop файл если его нет
    if [ ! -f "$appdir/xaneo_pc.desktop" ]; then
        cat > "$appdir/xaneo_pc.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Xaneo PC
Comment=Desktop application with onboarding
Exec=xaneo_pc_new
Icon=xaneo_pc
Categories=Utility;
EOF
    fi
    
    # Создаём символическую ссылку на иконку если её нет
    if [ ! -f "$appdir/.DirIcon" ]; then
        ln -sf xaneo_pc.png "$appdir/.DirIcon"
    fi
    
    log_success "AppDir создан"
}

# Функция для создания AppImage
create_appimage() {
    log_info "Создание AppImage..."
    
    local appdir="AppDir"
    local dist_dir="dist"
    
    # Создаём папку dist
    mkdir -p "$dist_dir"
    
    # Проверяем наличие appimagetool
    if [ -f "./appimagetool-x86_64.AppImage" ]; then
        chmod +x ./appimagetool-x86_64.AppImage
        ./appimagetool-x86_64.AppImage "$appdir" "$dist_dir/xaneo_pc.AppImage"
    elif command -v appimagetool &> /dev/null; then
        appimagetool "$appdir" "$dist_dir/xaneo_pc.AppImage"
    else
        log_warning "appimagetool не найден, пропускаем создание AppImage"
        return 1
    fi
    
    if [ -f "$dist_dir/xaneo_pc.AppImage" ]; then
        log_success "AppImage создан: $dist_dir/xaneo_pc.AppImage"
    fi
}

# Функция для создания DEB пакета
create_deb() {
    log_info "Создание Debian (.deb) пакета..."
    
    if ! command -v dpkg-deb &> /dev/null; then
        log_warning "dpkg-deb не найден, пропускаем создание .deb"
        return 1
    fi
    
    local dist_dir="dist"
    local pkg_dir="$dist_dir/deb-build"
    local version="1.0.0"
    
    mkdir -p "$dist_dir"
    rm -rf "$pkg_dir"
    mkdir -p "$pkg_dir"
    
    # Создаём структуру пакета
    mkdir -p "$pkg_dir/DEBIAN"
    mkdir -p "$pkg_dir/opt/xaneo-pc"
    mkdir -p "$pkg_dir/usr/share/applications"
    mkdir -p "$pkg_dir/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "$pkg_dir/usr/bin"
    
    # Копируем файлы приложения
    cp -r AppDir/* "$pkg_dir/opt/xaneo-pc/"
    
    # Копируем .desktop файл
    cp AppDir/xaneo_pc.desktop "$pkg_dir/usr/share/applications/"
    
    # Копируем иконку
    if [ -f "AppDir/xaneo_pc.png" ]; then
        cp AppDir/xaneo_pc.png "$pkg_dir/usr/share/icons/hicolor/256x256/apps/"
    fi
    
    # Создаём символическую ссылку
    ln -sf /opt/xaneo-pc/xaneo_pc_new "$pkg_dir/usr/bin/xaneo-pc"
    
    # Создаём control файл
    cat > "$pkg_dir/DEBIAN/control" << EOF
Package: xaneo-pc
Version: $version
Architecture: amd64
Maintainer: Xaneo <info@xaneo.com>
Installed-Size: $(du -s "$pkg_dir/opt/xaneo-pc" | cut -f1)
Depends: libgtk-3-0, libglib2.0-0
Section: utils
Priority: optional
Homepage: https://xaneo.com
Description: Xaneo PC - Desktop application with onboarding
 Xaneo PC is a desktop application with onboarding features.
EOF
    
    # Создаём postinst скрипт
    cat > "$pkg_dir/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
update-desktop-database /usr/share/applications || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
exit 0
EOF
    chmod +x "$pkg_dir/DEBIAN/postinst"
    
    # Создаём prerm скрипт
    cat > "$pkg_dir/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e
exit 0
EOF
    chmod +x "$pkg_dir/DEBIAN/prerm"
    
    # Собираем пакет
    dpkg-deb --build "$pkg_dir" "$dist_dir/xaneo-pc_${version}_amd64.deb"
    
    # Удаляем временную папку
    rm -rf "$pkg_dir"
    
    if [ -f "$dist_dir/xaneo-pc_${version}_amd64.deb" ]; then
        log_success "DEB пакет создан: $dist_dir/xaneo-pc_${version}_amd64.deb"
    fi
}

# Функция для создания RPM пакета (Fedora, RHEL, CentOS)
create_rpm() {
    log_info "Создание Fedora (.rpm) пакета..."
    
    if ! command -v rpmbuild &> /dev/null; then
        log_warning "rpmbuild не найден, пропускаем создание .rpm"
        return 1
    fi
    
    local dist_dir="dist"
    local version="1.0.0"
    local release="1"
    local rpmbuild_dir="$HOME/rpmbuild"
    
    mkdir -p "$dist_dir"
    
    # Создаём структуру rpmbuild
    mkdir -p "$rpmbuild_dir"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
    
    # Создаём tar архив с исходниками
    local tar_name="xaneo-pc-${version}.tar.gz"
    tar -czf "$rpmbuild_dir/SOURCES/$tar_name" -C AppDir .
    
    # Создаём spec файл
    cat > "$rpmbuild_dir/SPECS/xaneo-pc.spec" << EOF
Name:           xaneo-pc
Version:        $version
Release:        $release%{?dist}
Summary:        Xaneo PC - Desktop application with onboarding
License:        Proprietary
URL:            https://xaneo.com
Source0:        %{name}-%{version}.tar.gz

Requires:       gtk3, glib2

%description
Xaneo PC is a desktop application with onboarding features.

%prep
%setup -q -c

%build
# No build step needed, pre-built binaries

%install
rm -rf \$RPM_BUILD_ROOT
mkdir -p \$RPM_BUILD_ROOT/opt/xaneo-pc
mkdir -p \$RPM_BUILD_ROOT/usr/share/applications
mkdir -p \$RPM_BUILD_ROOT/usr/share/icons/hicolor/256x256/apps
mkdir -p \$RPM_BUILD_ROOT/usr/bin

cp -r * \$RPM_BUILD_ROOT/opt/xaneo-pc/
cp xaneo_pc.desktop \$RPM_BUILD_ROOT/usr/share/applications/
cp xaneo_pc.png \$RPM_BUILD_ROOT/usr/share/icons/hicolor/256x256/apps/
ln -sf /opt/xaneo-pc/xaneo_pc_new \$RPM_BUILD_ROOT/usr/bin/xaneo-pc

%post
update-desktop-database /usr/share/applications || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true

%postun
update-desktop-database /usr/share/applications || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true

%files
%defattr(-,root,root,-)
/opt/xaneo-pc
/usr/share/applications/xaneo_pc.desktop
/usr/share/icons/hicolor/256x256/apps/xaneo_pc.png
/usr/bin/xaneo-pc

%changelog
* $(LC_ALL=C date +'%a %b %d %Y') Xaneo <info@xaneo.com> - $version-$release
- Initial package
EOF
    
    # Собираем пакет
    rpmbuild -ba "$rpmbuild_dir/SPECS/xaneo-pc.spec"
    
    # Копируем результат в dist
    cp "$rpmbuild_dir/RPMS/x86_64/xaneo-pc-${version}-${release}.x86_64.rpm" "$dist_dir/"
    
    if [ -f "$dist_dir/xaneo-pc-${version}-${release}.x86_64.rpm" ]; then
        log_success "RPM пакет создан: $dist_dir/xaneo-pc-${version}-${release}.x86_64.rpm"
    fi
}

# Функция для создания Arch пакета
create_arch() {
    log_info "Создание Arch (.pkg.tar.zst) пакета..."
    
    if ! command -v makepkg &> /dev/null; then
        log_warning "makepkg не найден, пропускаем создание .pkg.tar.zst"
        return 1
    fi
    
    local dist_dir="dist"
    local version="1.0.0"
    local pkgbuild_dir="$dist_dir/arch-build"
    local appdir_path="$(pwd)/AppDir"
    
    mkdir -p "$dist_dir"
    rm -rf "$pkgbuild_dir"
    mkdir -p "$pkgbuild_dir"
    
    # Создаём PKGBUILD
    cat > "$pkgbuild_dir/PKGBUILD" << EOF
pkgname=xaneo-pc
pkgver=$version
pkgrel=1
pkgdesc="Xaneo PC - Desktop application with onboarding"
arch=('x86_64')
url="https://xaneo.com"
license=('custom')
depends=('gtk3' 'glib2')

package() {
    mkdir -p "\$pkgdir/opt/xaneo-pc"
    mkdir -p "\$pkgdir/usr/share/applications"
    mkdir -p "\$pkgdir/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "\$pkgdir/usr/bin"
    
    cp -r $appdir_path/* "\$pkgdir/opt/xaneo-pc/"
    cp $appdir_path/xaneo_pc.desktop "\$pkgdir/usr/share/applications/"
    cp $appdir_path/xaneo_pc.png "\$pkgdir/usr/share/icons/hicolor/256x256/apps/"
    ln -sf /opt/xaneo-pc/xaneo_pc_new "\$pkgdir/usr/bin/xaneo-pc"
}
EOF
    
    # Собираем пакет
    cd "$pkgbuild_dir"
    makepkg -s
    cd - > /dev/null
    
    # Копируем результат в dist
    cp "$pkgbuild_dir/xaneo-pc-${version}-1-x86_64.pkg.tar.zst" "$dist_dir/"
    
    if [ -f "$dist_dir/xaneo-pc-${version}-1-x86_64.pkg.tar.zst" ]; then
        log_success "Arch пакет создан: $dist_dir/xaneo-pc-${version}-1-x86_64.pkg.tar.zst"
    fi
}

# Функция для создания Alpine APK пакета
create_alpine() {
    log_info "Создание Alpine (.apk) пакета..."
    
    if ! command -v abuild &> /dev/null; then
        log_warning "abuild не найден, пропускаем создание .apk"
        return 1
    fi
    
    local dist_dir="dist"
    local version="1.0.0"
    local pkgbuild_dir="$dist_dir/alpine-build"
    
    mkdir -p "$dist_dir"
    rm -rf "$pkgbuild_dir"
    mkdir -p "$pkgbuild_dir"
    
    # Создаём APKBUILD
    cat > "$pkgbuild_dir/APKBUILD" << EOF
# Contributor: Xaneo <info@xaneo.com>
# Maintainer: Xaneo <info@xaneo.com>
pkgname=xaneo-pc
pkgver=$version
pkgrel=0
pkgdesc="Xaneo PC - Desktop application with onboarding"
url="https://xaneo.com"
arch="x86_64"
license="custom"
depends="gtk+3.0 glib"
options="!check"

package() {
    mkdir -p "\$pkgdir/opt/xaneo-pc"
    mkdir -p "\$pkgdir/usr/share/applications"
    mkdir -p "\$pkgdir/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "\$pkgdir/usr/bin"
    
    cp -r ../AppDir/* "\$pkgdir/opt/xaneo-pc/"
    cp ../AppDir/xaneo_pc.desktop "\$pkgdir/usr/share/applications/"
    cp ../AppDir/xaneo_pc.png "\$pkgdir/usr/share/icons/hicolor/256x256/apps/"
    ln -sf /opt/xaneo-pc/xaneo_pc_new "\$pkgdir/usr/bin/xaneo-pc"
}
EOF
    
    # Собираем пакет
    cd "$pkgbuild_dir"
    abuild -r
    cd - > /dev/null
    
    # Копируем результат в dist
    if [ -f "$HOME/packages/community/x86_64/xaneo-pc-${version}-r0.apk" ]; then
        cp "$HOME/packages/community/x86_64/xaneo-pc-${version}-r0.apk" "$dist_dir/"
        log_success "Alpine пакет создан: $dist_dir/xaneo-pc-${version}-r0.apk"
    fi
}

# Функция для создания Void Linux XBPS пакета
create_void() {
    log_info "Создание Void Linux (.xbps) пакета..."
    
    if ! command -v xbps-create &> /dev/null; then
        log_warning "xbps-create не найден, пропускаем создание .xbps"
        return 1
    fi
    
    local dist_dir="dist"
    local version="1.0.0"
    local pkgbuild_dir="$dist_dir/void-build"
    
    mkdir -p "$dist_dir"
    rm -rf "$pkgbuild_dir"
    mkdir -p "$pkgbuild_dir"
    
    # Создаём template
    cat > "$pkgbuild_dir/template" << EOF
# Template file for 'xaneo-pc'
pkgname=xaneo-pc
version=$version
revision=1
build_style=meta
short_desc="Xaneo PC - Desktop application with onboarding"
maintainer="Xaneo <info@xaneo.com>"
license="custom"
homepage="https://xaneo.com"
depends="gtk+3 glib"

do_install() {
    vmkdir opt/xaneo-pc
    vmkdir usr/share/applications
    vmkdir usr/share/icons/hicolor/256x256/apps
    vmkdir usr/bin
    
    cp -r ../AppDir/* \${DESTDIR}/opt/xaneo-pc/
    cp ../AppDir/xaneo_pc.desktop \${DESTDIR}/usr/share/applications/
    cp ../AppDir/xaneo_pc.png \${DESTDIR}/usr/share/icons/hicolor/256x256/apps/
    ln -sf /opt/xaneo-pc/xaneo_pc_new \${DESTDIR}/usr/bin/xaneo-pc
}
EOF
    
    # Собираем пакет
    cd "$pkgbuild_dir"
    xbps-src pkg xaneo-pc
    cd - > /dev/null
    
    # Копируем результат в dist
    if [ -f "hostdir/binpkgs/xaneo-pc-${version}_1.x86_64.xbps" ]; then
        cp "hostdir/binpkgs/xaneo-pc-${version}_1.x86_64.xbps" "$dist_dir/"
        log_success "Void пакет создан: $dist_dir/xaneo-pc-${version}_1.x86_64.xbps"
    fi
}

# Функция для создания tarball с приложением (без FUSE)
create_tarball() {
    log_info "Создание tarball с приложением..."
    
    local dist_dir="dist"
    local version="1.0.0"
    local tarball_name="xaneo_pc-${version}-x86_64.tar.gz"
    
    mkdir -p "$dist_dir"
    
    # Создаём временную папку для tarball
    local temp_dir="$dist_dir/tarball-temp"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir/xaneo_pc-${version}-x86_64"
    
    # Копируем содержимое AppDir
    cp -r AppDir/* "$temp_dir/xaneo_pc-${version}-x86_64/"
    
    # Создаём скрипт запуска
    cat > "$temp_dir/xaneo_pc-${version}-x86_64/run.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$SCRIPT_DIR/data:$LD_LIBRARY_PATH"
export PATH="$SCRIPT_DIR:$PATH"
./xaneo_pc_new "$@"
EOF
    chmod +x "$temp_dir/xaneo_pc-${version}-x86_64/run.sh"
    
    # Создаём README
    cat > "$temp_dir/xaneo_pc-${version}-x86_64/README.txt" << 'EOF'
Xaneo PC - Desktop Application
================================

Установка и запуск:
-------------------

1. Распакуйте архив:
   tar -xzf xaneo_pc-1.0.0-x86_64.tar.gz
   cd xaneo_pc-1.0.0-x86_64

2. Запустите приложение:
   ./run.sh

Или запустите напрямую:
   ./xaneo_pc_new

Требования:
-----------
- Linux x86_64
- GTK3
- GLib2

Примечание:
----------
Этот tarball не требует FUSE и может быть запущен на любой системе Linux.
EOF
    
    # Создаём tarball
    cd "$temp_dir"
    tar -czf "../$tarball_name" "xaneo_pc-${version}-x86_64"
    cd - > /dev/null
    
    # Удаляем временную папку
    rm -rf "$temp_dir"
    
    if [ -f "$dist_dir/$tarball_name" ]; then
        local size=$(du -h "$dist_dir/$tarball_name" | cut -f1)
        log_success "Tarball создан: $dist_dir/$tarball_name ($size)"
    fi
}

# Функция для создания символических ссылок
create_symlinks() {
    log_info "Создание символических ссылок..."
    
    local dist_dir="dist"
    
    if [ ! -d "$dist_dir" ]; then
        log_warning "Папка dist не найдена, пропускаем создание ссылок"
        return
    fi
    
    cd "$dist_dir"
    
    # AppImage
    if [ -f "xaneo_pc.AppImage" ]; then
        ln -sf "xaneo_pc.AppImage" "xaneo_pc-latest.AppImage"
        log_success "Создана ссылка: xaneo_pc-latest.AppImage"
    fi
    
    # DEB
    if ls xaneo-pc_*.deb 1> /dev/null 2>&1; then
        local deb_file=$(ls xaneo-pc_*.deb | head -1)
        ln -sf "$deb_file" "xaneo_pc-latest.deb"
        log_success "Создана ссылка: xaneo_pc-latest.deb"
    fi
    
    # RPM
    if ls xaneo-pc-*.rpm 1> /dev/null 2>&1; then
        local rpm_file=$(ls xaneo-pc-*.rpm | head -1)
        ln -sf "$rpm_file" "xaneo_pc-latest.rpm"
        log_success "Создана ссылка: xaneo_pc-latest.rpm"
    fi
    
    # Arch
    if ls xaneo-pc-*.pkg.tar.zst 1> /dev/null 2>&1; then
        local arch_file=$(ls xaneo-pc-*.pkg.tar.zst | head -1)
        ln -sf "$arch_file" "xaneo_pc-latest.pkg.tar.zst"
        log_success "Создана ссылка: xaneo_pc-latest.pkg.tar.zst"
    fi
    
    # Alpine
    if ls xaneo-pc-*.apk 1> /dev/null 2>&1; then
        local alpine_file=$(ls xaneo-pc-*.apk | head -1)
        ln -sf "$alpine_file" "xaneo_pc-latest.apk"
        log_success "Создана ссылка: xaneo_pc-latest.apk"
    fi
    
    # Void
    if ls xaneo-pc-*.xbps 1> /dev/null 2>&1; then
        local void_file=$(ls xaneo-pc-*.xbps | head -1)
        ln -sf "$void_file" "xaneo_pc-latest.xbps"
        log_success "Создана ссылка: xaneo_pc-latest.xbps"
    fi
    
    # Tarball
    if ls xaneo_pc-*-x86_64.tar.gz 1> /dev/null 2>&1; then
        local tarball_file=$(ls xaneo_pc-*-x86_64.tar.gz | head -1)
        ln -sf "$tarball_file" "xaneo_pc-latest.tar.gz"
        log_success "Создана ссылка: xaneo_pc-latest.tar.gz"
    fi
    
    cd ..
}

# Функция для отображения информации о собранных пакетах
show_package_info() {
    local dist_dir="dist"
    
    if [ ! -d "$dist_dir" ]; then
        log_warning "Папка dist не найдена"
        return
    fi
    
    log_info "Собранные пакеты:"
    echo ""
    
    cd "$dist_dir"
    
    # AppImage
    if [ -f "xaneo_pc.AppImage" ]; then
        local size=$(du -h "xaneo_pc.AppImage" | cut -f1)
        echo -e "${GREEN}✓${NC} AppImage - $size"
    fi
    
    # DEB
    if ls xaneo-pc_*.deb 1> /dev/null 2>&1; then
        local deb_file=$(ls xaneo-pc_*.deb | head -1)
        local size=$(du -h "$deb_file" | cut -f1)
        echo -e "${GREEN}✓${NC} Debian (.deb) - $size"
    fi
    
    # RPM
    if ls xaneo-pc-*.rpm 1> /dev/null 2>&1; then
        local rpm_file=$(ls xaneo-pc-*.rpm | head -1)
        local size=$(du -h "$rpm_file" | cut -f1)
        echo -e "${GREEN}✓${NC} Fedora (.rpm) - $size"
    fi
    
    # Arch
    if ls xaneo-pc-*.pkg.tar.zst 1> /dev/null 2>&1; then
        local arch_file=$(ls xaneo-pc-*.pkg.tar.zst | head -1)
        local size=$(du -h "$arch_file" | cut -f1)
        echo -e "${GREEN}✓${NC} Arch (.pkg.tar.zst) - $size"
    fi
    
    # Alpine
    if ls xaneo-pc-*.apk 1> /dev/null 2>&1; then
        local alpine_file=$(ls xaneo-pc-*.apk | head -1)
        local size=$(du -h "$alpine_file" | cut -f1)
        echo -e "${GREEN}✓${NC} Alpine (.apk) - $size"
    fi
    
    # Void
    if ls xaneo-pc-*.xbps 1> /dev/null 2>&1; then
        local void_file=$(ls xaneo-pc-*.xbps | head -1)
        local size=$(du -h "$void_file" | cut -f1)
        echo -e "${GREEN}✓${NC} Void (.xbps) - $size"
    fi
    
    # Tarball
    if ls xaneo_pc-*-x86_64.tar.gz 1> /dev/null 2>&1; then
        local tarball_file=$(ls xaneo_pc-*-x86_64.tar.gz | head -1)
        local size=$(du -h "$tarball_file" | cut -f1)
        echo -e "${GREEN}✓${NC} Tarball (.tar.gz) - $size"
    fi
    
    cd ..
}

# Функция для создания контрольных сумм
create_checksums() {
    log_info "Создание контрольных сумм..."
    
    local dist_dir="dist"
    
    if [ ! -d "$dist_dir" ]; then
        log_warning "Папка dist не найдена, пропускаем создание контрольных сумм"
        return
    fi
    
    cd "$dist_dir"
    
    # Создаём SHA256 контрольные суммы для всех файлов
    sha256sum * > SHA256SUMS.txt 2>/dev/null || true
    
    if [ -f "SHA256SUMS.txt" ]; then
        log_success "Контрольные суммы созданы: SHA256SUMS.txt"
    fi
    
    cd ..
}

# Функция для создания архива с пакетами
create_archive() {
    local version=${1:-"1.0.0"}
    local archive_name="xaneo_pc-${version}-linux-packages.tar.gz"
    
    log_info "Создание архива с пакетами: $archive_name"
    
    if [ ! -d "dist" ]; then
        log_warning "Папка dist не найдена, пропускаем создание архива"
        return
    fi
    
    tar -czf "$archive_name" dist/
    
    if [ -f "$archive_name" ]; then
        local size=$(du -h "$archive_name" | cut -f1)
        log_success "Архив создан: $archive_name ($size)"
    fi
}

# Главная функция
main() {
    echo "=========================================="
    echo "  Сборка пакетов xaneo_pc (Flutter)"
    echo "=========================================="
    echo ""
    
    # Парсинг аргументов
    local package_type="all"
    local clean=false
    local create_symlinks_flag=false
    local create_checksums_flag=false
    local create_archive_flag=false
    local version="1.0.0"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean|-c)
                clean=true
                shift
                ;;
            --symlinks|-s)
                create_symlinks_flag=true
                shift
                ;;
            --checksums|-k)
                create_checksums_flag=true
                shift
                ;;
            --archive|-a)
                create_archive_flag=true
                shift
                ;;
            --version|-v)
                version="$2"
                shift 2
                ;;
            all|appimage|deb|rpm|arch|alpine|void|tarball)
                package_type="$1"
                shift
                ;;
            *)
                log_error "Неизвестный аргумент: $1"
                echo ""
                echo "Использование: $0 [опции] [тип_пакета]"
                echo ""
                echo "Типы пакетов:"
                echo "  all      - все пакеты (по умолчанию)"
                echo "  appimage - AppImage (требует FUSE)"
                echo "  deb      - Debian (.deb)"
                echo "  rpm      - Fedora/RHEL/CentOS (.rpm)"
                echo "  arch     - Arch Linux (.pkg.tar.zst)"
                echo "  alpine   - Alpine Linux (.apk)"
                echo "  void     - Void Linux (.xbps)"
                echo "  tarball  - Tarball (.tar.gz) - не требует FUSE"
                echo ""
                echo "Опции:"
                echo "  --clean, -c          - очистить перед сборкой"
                echo "  --symlinks, -s       - создать символические ссылки"
                echo "  --checksums, -k      - создать контрольные суммы"
                echo "  --archive, -a        - создать архив с пакетами"
                echo "  --version, -v <версия>  - версия для архива"
                exit 1
                ;;
        esac
    done
    
    # Выполнение
    if [ "$clean" = true ]; then
        clean_build
        echo ""
    fi
    
    check_dependencies
    echo ""
    
    build_flutter
    echo ""
    
    create_appdir
    echo ""
    
    case $package_type in
        "all")
            create_appimage
            create_deb
            create_rpm
            create_arch
            create_alpine
            create_void
            create_tarball
            ;;
        "appimage")
            create_appimage
            ;;
        "deb")
            create_deb
            ;;
        "rpm")
            create_rpm
            ;;
        "arch")
            create_arch
            ;;
        "alpine")
            create_alpine
            ;;
        "void")
            create_void
            ;;
        "tarball")
            create_tarball
            ;;
    esac
    echo ""
    
    if [ "$create_symlinks_flag" = true ]; then
        create_symlinks
        echo ""
    fi
    
    if [ "$create_checksums_flag" = true ]; then
        create_checksums
        echo ""
    fi
    
    if [ "$create_archive_flag" = true ]; then
        create_archive "$version"
        echo ""
    fi
    
    show_package_info
    
    echo ""
    log_success "Сборка завершена!"
    echo "Пакеты находятся в папке: dist/"
}

# Запуск
main "$@"
