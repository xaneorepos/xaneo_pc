import 'dart:io';

/// Linux updates must replace the installed package, rather than run a
/// temporary portable copy which desktop launchers will never use.
class LinuxPackageUpdater {
  static String? packageExtension(String osRelease) {
    final values = <String, String>{};
    for (final line in osRelease.split('\n')) {
      final match = RegExp(r'^(ID|ID_LIKE)=(.*)$').firstMatch(line.trim());
      if (match != null) {
        values[match[1]!] = match[2]!.replaceAll(RegExp('["\']'), '');
      }
    }
    final ids = '${values['ID'] ?? ''} ${values['ID_LIKE'] ?? ''}'
        .toLowerCase()
        .split(RegExp(r'\s+'));
    if (ids.any({'debian', 'ubuntu'}.contains)) return '.deb';
    if (ids.any({'fedora', 'rhel', 'centos'}.contains)) return '.rpm';
    return null;
  }

  static String? selectDownload(Iterable<String> urls, String osRelease) {
    final extension = packageExtension(osRelease);
    if (extension == null) return null;
    for (final url in urls) {
      if (Uri.parse(url).path.toLowerCase().endsWith(extension)) return url;
    }
    return null;
  }

  static String readOsRelease() {
    for (final path in ['/etc/os-release', '/usr/lib/os-release']) {
      try {
        return File(path).readAsStringSync();
      } on FileSystemException {
        // Try the fallback provided by the distribution.
      }
    }
    return '';
  }

  static Future<void> install(
    String path, {
    String? osRelease,
    Future<ProcessResult> Function(String, List<String>)? run,
  }) async {
    final extension = packageExtension(osRelease ?? readOsRelease());
    if (extension == null || !path.toLowerCase().endsWith(extension)) {
      throw StateError(
        'Нет подходящего DEB/RPM-пакета для этого дистрибутива. '
        'Установите обновление вручную со страницы релиза.',
      );
    }
    // Use the package manager so dependencies, launchers and package metadata
    // are updated together. Await it: starting a GUI installer is not success.
    final command = extension == '.deb' ? 'apt-get' : 'dnf';
    final args = [command, 'install', '-y', File(path).absolute.path];
    final result = await (run ?? ((exe, args) => Process.run(exe, args)))(
      'pkexec',
      args,
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        'pkexec',
        args,
        'Установка обновления не завершена: ${result.stderr}',
        result.exitCode,
      );
    }
  }
}
