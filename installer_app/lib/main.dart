import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 500),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  bool isUninstall = args.contains('--uninstall');
  runApp(InstallerApp(isUninstall: isUninstall));
}

class InstallerApp extends StatelessWidget {
  final bool isUninstall;
  const InstallerApp({Key? key, required this.isUninstall}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.white,
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Inter',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: isUninstall ? const UninstallerScreen() : const InstallerScreen(),
    );
  }
}

class InstallerScreen extends StatefulWidget {
  const InstallerScreen({Key? key}) : super(key: key);

  @override
  State<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends State<InstallerScreen> {
  String _lang = 'en';
  double _progress = 0.0;
  String _status = '';
  bool _installing = false;
  bool _done = false;
  String _installPath = '';

  final Map<String, Map<String, String>> _locales = {
    'en': {'title': 'Xaneo PC Setup', 'welcome': 'Welcome to Xaneo PC', 'install': 'Install', 'installing': 'Installing...', 'done': 'Installation Complete', 'launch': 'Launch Xaneo PC', 'cancel': 'Cancel', 'path': 'Install Location', 'browse': 'Browse'},
    'ru': {'title': 'Установка Xaneo PC', 'welcome': 'Добро пожаловать в Xaneo PC', 'install': 'Установить', 'installing': 'Установка...', 'done': 'Установка завершена', 'launch': 'Запустить Xaneo PC', 'cancel': 'Отмена', 'path': 'Путь установки', 'browse': 'Обзор'},
    'ar': {'title': 'إعداد Xaneo PC', 'welcome': 'مرحبا بك في Xaneo PC', 'install': 'تثبيت', 'installing': 'جارٍ التثبيت...', 'done': 'اكتمل التثبيت', 'launch': 'تشغيل Xaneo PC', 'cancel': 'إلغاء', 'path': 'مسار التثبيت', 'browse': 'تصفح'},
    'es': {'title': 'Instalación de Xaneo PC', 'welcome': 'Bienvenido a Xaneo PC', 'install': 'Instalar', 'installing': 'Instalando...', 'done': 'Instalación completada', 'launch': 'Iniciar Xaneo PC', 'cancel': 'Cancelar', 'path': 'Ruta de instalación', 'browse': 'Explorar'},
    'fr': {'title': 'Installation de Xaneo PC', 'welcome': 'Bienvenue sur Xaneo PC', 'install': 'Installer', 'installing': 'Installation...', 'done': 'Installation terminée', 'launch': 'Lancer Xaneo PC', 'cancel': 'Annuler', 'path': "Chemin d'installation", 'browse': 'Parcourir'},
    'ja': {'title': 'Xaneo PC セットアップ', 'welcome': 'Xaneo PCへようこそ', 'install': 'インストール', 'installing': 'インストール中...', 'done': 'インストール完了', 'launch': 'Xaneo PC を起動', 'cancel': 'キャンセル', 'path': 'インストール先', 'browse': '参照'},
    'ko': {'title': 'Xaneo PC 설정', 'welcome': 'Xaneo PC에 오신 것을 환영합니다', 'install': '설치', 'installing': '설치 중...', 'done': '설치 완료', 'launch': 'Xaneo PC 실행', 'cancel': '취소', 'path': '설치 경로', 'browse': '찾아보기'},
    'zh': {'title': 'Xaneo PC 安装', 'welcome': '欢迎使用 Xaneo PC', 'install': '安装', 'installing': '正在安装...', 'done': '安装完成', 'launch': '启动 Xaneo PC', 'cancel': '取消', 'path': '安装路径', 'browse': '浏览'},
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    String? envAppdata = Platform.environment['LOCALAPPDATA'];
    setState(() {
      _lang = prefs.getString('lang') ?? 'en';
      if (envAppdata != null) {
        _installPath = '$envAppdata\\Xaneo_PC';
      } else {
        _installPath = 'C:\\Xaneo_PC';
      }
    });
  }

  Future<void> _setLang(String l) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l);
    setState(() {
      _lang = l;
    });
  }

  String t(String key) => _locales[_lang]?[key] ?? _locales['en']![key]!;

  Future<void> _pickPath() async {
    String? result = await FilePicker.getDirectoryPath();
    if (result != null) {
      setState(() {
        _installPath = '$result\\Xaneo_PC';
      });
    }
  }

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _status = t('installing');
    });

    try {
      final targetDir = Directory(_installPath);
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final zipPath = '$exeDir\\data\\flutter_assets\\assets\\xaneo_pc.zip';
      
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      int total = archive.length;
      int current = 0;

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File('${targetDir.path}\\$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('${targetDir.path}\\$filename').createSync(recursive: true);
        }
        current++;
        setState(() {
          _progress = current / total;
        });
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Copy uninstaller (which is this installer itself!)
      final uninstallerDir = Directory('${targetDir.path}\\Uninstaller');
      if (!uninstallerDir.existsSync()) uninstallerDir.createSync(recursive: true);
      
      final srcDir = Directory(exeDir);
      await _copyDirectory(srcDir, uninstallerDir);
      
      final copiedExe = File('${uninstallerDir.path}\\installer_app.exe');
      if (copiedExe.existsSync()) {
        copiedExe.renameSync('${uninstallerDir.path}\\xaneo_uninstaller.exe');
      }

      // Add to Registry for Apps & Features
      final regCmd = '''
\$RegPath = "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Xaneo_PC"
New-Item -Path \$RegPath -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "DisplayName" -Value "Xaneo PC" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "DisplayIcon" -Value "${targetDir.path}\\xaneo_pc.exe" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "UninstallString" -Value "\`"${uninstallerDir.path}\\xaneo_uninstaller.exe\`" --uninstall" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "Publisher" -Value "Xaneo" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "InstallLocation" -Value "${targetDir.path}" -PropertyType String -Force | Out-Null
''';

      // Shortcuts
      final ps1 = File('${targetDir.path}\\install_scripts.ps1');
      await ps1.writeAsString('''
\$WshShell = New-Object -comObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("\$env:USERPROFILE\\Desktop\\Xaneo PC.lnk")
\$Shortcut.TargetPath = "${targetDir.path}\\xaneo_pc.exe"
\$Shortcut.IconLocation = "${targetDir.path}\\xaneo_pc.exe"
\$Shortcut.Save()

\$StartMenuShortcut = \$WshShell.CreateShortcut("\$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Xaneo PC.lnk")
\$StartMenuShortcut.TargetPath = "${targetDir.path}\\xaneo_pc.exe"
\$StartMenuShortcut.IconLocation = "${targetDir.path}\\xaneo_pc.exe"
\$StartMenuShortcut.Save()

$regCmd
''');
      await Process.run('powershell', ['-ExecutionPolicy', 'Bypass', '-File', ps1.path]);
      
      setState(() {
        _done = true;
        _status = t('done');
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirName = entity.path.split(Platform.pathSeparator).last;
        var newDirectory = Directory('${destination.absolute.path}\\$newDirName');
        await newDirectory.create();
        await _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        var fileName = entity.path.split(Platform.pathSeparator).last;
        await entity.copy('${destination.path}\\$fileName');
      }
    }
  }

  void _launchApp() {
    Process.run('$_installPath\\xaneo_pc.exe', []);
    windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = _lang == 'ar';
    
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 40,
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.computer, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(t('title'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                if (!_installing)
                  DropdownButton<String>(
                    value: _lang,
                    dropdownColor: const Color(0xFF2A2A2A),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language, color: Colors.white, size: 16),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ru', child: Text('Русский')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'ja', child: Text('日本語')),
                      DropdownMenuItem(value: 'ko', child: Text('한국어')),
                      DropdownMenuItem(value: 'zh', child: Text('中文')),
                    ],
                    onChanged: (v) {
                      if (v != null) _setLang(v);
                    },
                  ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch, size: 64, color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      _done ? t('done') : t('welcome'),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    if (!_installing && !_done) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('path'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(_installPath, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _pickPath,
                                child: Text(t('browse')),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _install,
                            child: Text(t('install'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            ),
                            onPressed: () => windowManager.close(),
                            child: Text(t('cancel'), style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                      
                    if (_installing && !_done)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${(_progress * 100).toInt()}% - $_status',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                      
                    if (_done)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _launchApp,
                        child: Text(t('launch'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UninstallerScreen extends StatefulWidget {
  const UninstallerScreen({Key? key}) : super(key: key);

  @override
  State<UninstallerScreen> createState() => _UninstallerScreenState();
}

class _UninstallerScreenState extends State<UninstallerScreen> {
  String _lang = 'en';
  bool _uninstalling = false;
  String _status = '';

  final Map<String, Map<String, String>> _locales = {
    'en': {'title': 'Xaneo PC Uninstall', 'prompt': 'Are you sure you want to uninstall Xaneo PC?', 'uninstall': 'Uninstall', 'cancel': 'Cancel', 'removing': 'Removing files...'},
    'ru': {'title': 'Удаление Xaneo PC', 'prompt': 'Вы уверены, что хотите удалить Xaneo PC?', 'uninstall': 'Удалить', 'cancel': 'Отмена', 'removing': 'Удаление файлов...'},
    'ar': {'title': 'إلغاء تثبيت Xaneo PC', 'prompt': 'هل أنت متأكد أنك تريد إلغاء تثبيت Xaneo PC؟', 'uninstall': 'إلغاء التثبيت', 'cancel': 'إلغاء', 'removing': 'جاري إزالة الملفات...'},
    'es': {'title': 'Desinstalar Xaneo PC', 'prompt': '¿Estás seguro de que quieres desinstalar Xaneo PC?', 'uninstall': 'Desinstalar', 'cancel': 'Cancelar', 'removing': 'Eliminando archivos...'},
    'fr': {'title': 'Désinstaller Xaneo PC', 'prompt': 'Êtes-vous sûr de vouloir désinstaller Xaneo PC ?', 'uninstall': 'Désinstaller', 'cancel': 'Annuler', 'removing': 'Suppression des fichiers...'},
    'ja': {'title': 'Xaneo PC アンインストール', 'prompt': 'Xaneo PC をアンインストールしてもよろしいですか？', 'uninstall': 'アンインストール', 'cancel': 'キャンセル', 'removing': 'ファイルを削除中...'},
    'ko': {'title': 'Xaneo PC 제거', 'prompt': 'Xaneo PC를 제거하시겠습니까?', 'uninstall': '제거', 'cancel': '취소', 'removing': '파일 삭제 중...'},
    'zh': {'title': 'Xaneo PC 卸载', 'prompt': '您确定要卸载 Xaneo PC 吗？', 'uninstall': '卸载', 'cancel': '取消', 'removing': '正在删除文件...'},
  };

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('lang') ?? 'en';
    });
  }

  String t(String key) => _locales[_lang]?[key] ?? _locales['en']![key]!;

  Future<void> _uninstall() async {
    setState(() {
      _uninstalling = true;
      _status = t('removing');
    });

    try {
      final exePath = File(Platform.resolvedExecutable).parent;
      final targetDir = exePath.parent.path;
      final tempDir = Directory.systemTemp.path;
      
      final ps1 = File('$tempDir\\do_uninstall.ps1');
      await ps1.writeAsString('''
Start-Sleep -Seconds 2
Remove-Item -Path "\$env:USERPROFILE\\Desktop\\Xaneo PC.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "\$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Xaneo PC.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Xaneo_PC" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$targetDir" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "\$MyInvocation.MyCommand.Path" -Force -ErrorAction SilentlyContinue
''');
      
      await Process.start(
        'powershell',
        ['-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', ps1.path],
        mode: ProcessStartMode.detached,
        workingDirectory: tempDir,
      );
      
      windowManager.close();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = _lang == 'ar';
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 40,
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(t('title'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    Text(
                      _uninstalling ? _status : t('prompt'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (!_uninstalling)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _uninstall,
                            child: Text(t('uninstall'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            ),
                            onPressed: () => windowManager.close(),
                            child: Text(t('cancel'), style: const TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    if (_uninstalling)
                      const CircularProgressIndicator(color: Colors.redAccent),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
