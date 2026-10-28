import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaneo/services/linux_package_updater.dart';

void main() {
  const urls = [
    'https://example.org/xaneo.AppImage',
    'https://example.org/xaneo_1.1.7_amd64.deb',
    'https://example.org/xaneo-1.1.7.x86_64.rpm',
  ];

  test('selects native packages regardless of AppImage asset order', () {
    for (final os in [
      'ID=ubuntu\nID_LIKE=debian',
      'ID=linuxmint\nID_LIKE="ubuntu debian"',
      'ID=debian',
    ]) {
      expect(LinuxPackageUpdater.selectDownload(urls, os), urls[1]);
    }
    for (final os in ['ID=fedora', "ID=rocky\nID_LIKE='rhel centos fedora'"]) {
      expect(LinuxPackageUpdater.selectDownload(urls, os), urls[2]);
    }
  });

  test('missing or unsupported native package opens release page instead', () {
    expect(LinuxPackageUpdater.selectDownload(urls, 'ID=arch'), isNull);
    expect(LinuxPackageUpdater.selectDownload(urls, ''), isNull);
    expect(
      LinuxPackageUpdater.selectDownload([urls[0], urls[1]], 'ID=fedora'),
      isNull,
    );
  });

  test(
    'installs through the native package manager with a literal path',
    () async {
      for (final distro in ['ubuntu', 'fedora']) {
        final extension = distro == 'ubuntu' ? 'deb' : 'rpm';
        final package = '/tmp/update with spaces/xaneo.$extension';
        await LinuxPackageUpdater.install(
          package,
          osRelease: 'ID=$distro',
          run: (executable, arguments) async {
            expect(executable, 'pkexec');
            expect(arguments, [
              distro == 'ubuntu' ? 'apt-get' : 'dnf',
              'install',
              '-y',
              package,
            ]);
            return ProcessResult(1, 0, '', '');
          },
        );
      }
    },
  );

  test(
    'cancellation and package manager failures propagate to update UI',
    () async {
      for (final code in [1, 126, 127]) {
        await expectLater(
          LinuxPackageUpdater.install(
            '/tmp/xaneo.rpm',
            osRelease: 'ID=fedora',
            run: (_, args) async => ProcessResult(1, code, '', 'failed'),
          ),
          throwsA(isA<ProcessException>()),
        );
      }
    },
  );

  test(
    'rejects AppImage and foreign packages before running anything',
    () async {
      for (final path in ['/tmp/xaneo.AppImage', '/tmp/xaneo.deb']) {
        await expectLater(
          LinuxPackageUpdater.install(
            path,
            osRelease: 'ID=fedora',
            run: (_, args) async {
              fail('Must not run an incompatible update');
            },
          ),
          throwsStateError,
        );
      }
    },
  );
}
