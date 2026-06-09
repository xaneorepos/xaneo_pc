import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

const String _kFontFamily = 'Inter';

class LogManager {
  static final List<String> _logs = [];
  static String get logFilePath => '${Directory.systemTemp.path}\\xaneo_installer.log';

  static Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$timestamp] $message';
    _logs.add(line);
    print(line);
    try {
      final file = File(logFilePath);
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (e) {
      print('Failed to write log to file: $e');
    }
  }

  static List<String> get logs => _logs;

  static Future<void> clearLogFile() async {
    try {
      final file = File(logFilePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

Future<void> runDiagnostics() async {
  await LogManager.clearLogFile();
  await LogManager.log('=== Xaneo Setup Diagnostics Start ===');
  await LogManager.log('OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  await LogManager.log('Executable: ${Platform.resolvedExecutable}');
  await LogManager.log('Working directory: ${Directory.current.path}');
  await LogManager.log('Temp Directory: ${Directory.systemTemp.path}');

  // Try checking assets
  try {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    await LogManager.log('AssetManifest loaded successfully. Length: ${manifestContent.length}');
    if (manifestContent.contains('Inter-Regular.ttf')) {
      await LogManager.log('Inter-Regular.ttf is listed in AssetManifest.');
    } else {
      await LogManager.log('WARNING: Inter-Regular.ttf NOT found in AssetManifest!');
    }
  } catch (e) {
    await LogManager.log('Error reading AssetManifest.json: $e');
  }

  // Try loading fonts manually
  try {
    await LogManager.log('Attempting manual font loading via FontLoader...');
    final fontLoader = FontLoader('Inter');
    
    await LogManager.log('Loading Inter-Regular...');
    final regularBytes = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    await LogManager.log('Inter-Regular size: ${regularBytes.lengthInBytes} bytes');
    fontLoader.addFont(Future.value(regularBytes));
    
    await LogManager.log('Loading Inter-Medium...');
    final mediumBytes = await rootBundle.load('assets/fonts/Inter-Medium.ttf');
    await LogManager.log('Inter-Medium size: ${mediumBytes.lengthInBytes} bytes');
    fontLoader.addFont(Future.value(mediumBytes));
    
    await LogManager.log('Loading Inter-Bold...');
    final boldBytes = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    await LogManager.log('Inter-Bold size: ${boldBytes.lengthInBytes} bytes');
    fontLoader.addFont(Future.value(boldBytes));
    
    await fontLoader.load();
    await LogManager.log('FontLoader successfully loaded Inter fonts!');
  } catch (e) {
    await LogManager.log('FontLoader FAILED: $e');
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run diagnostics first
  await runDiagnostics();
  
  await LogManager.log('Window manager ensureInitialized...');
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
  await LogManager.log('Mode: ${isUninstall ? "Uninstall" : "Install"}');
  await LogManager.log('Arguments: $args');
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
        fontFamily: _kFontFamily,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(fontFamily: _kFontFamily, color: Color(0xFFE0E0E0), fontSize: 14),
          labelLarge: TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      home: isUninstall ? const UninstallerScreen() : const InstallerScreen(),
    );
  }
}

void _showLogsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Row(
              children: [
                const Icon(Icons.bug_report_outlined, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Diagnostic Logs', style: TextStyle(color: Colors.white, fontFamily: _kFontFamily)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          LogManager.logs.join('\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'Log File: ${LogManager.logFilePath}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: _kFontFamily),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: LogManager.logs.join('\n')));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied to clipboard')),
                      );
                    }
                  } catch (e) {
                    LogManager.log('Clipboard error: $e');
                  }
                },
                child: const Text('Copy All', style: TextStyle(color: Colors.white, fontFamily: _kFontFamily)),
              ),
              TextButton(
                onPressed: () {
                  Process.run('notepad.exe', [LogManager.logFilePath]);
                },
                child: const Text('Open in Notepad', style: TextStyle(color: Colors.white, fontFamily: _kFontFamily)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.grey, fontFamily: _kFontFamily)),
              ),
            ],
          );
        },
      );
    },
  );
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
    'ko': {'title': 'Xaneo PC 설정', 'welcome': 'Xaneo PC에 오신 것을 환영합니다', 'install': '설치', 'installing': '설치 중...', 'done': '설치 완료', 'launch': 'Xaneo PC 실행', 'cancel': '취소', 'path': '설치 경로', 'browse': '찾а보기'},
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
      await LogManager.log('=== Installation Started ===');
      await LogManager.log('Selected Install Path: $_installPath');
      final targetDir = Directory(_installPath);
      if (!targetDir.existsSync()) {
        await LogManager.log('Creating target directory...');
        targetDir.createSync(recursive: true);
        await LogManager.log('Target directory created.');
      } else {
        await LogManager.log('Target directory already exists.');
      }

      final exeDir = File(Platform.resolvedExecutable).parent.path;
      await LogManager.log('Exe directory: $exeDir');
      final zipPath = '$exeDir\\data\\flutter_assets\\assets\\xaneo_pc.zip';
      await LogManager.log('Zip file path: $zipPath');
      
      if (!File(zipPath).existsSync()) {
        throw 'Zip file not found at $zipPath';
      }
      
      final bytes = File(zipPath).readAsBytesSync();
      await LogManager.log('Zip file read success. Size: ${bytes.length} bytes.');
      
      await LogManager.log('Decoding Zip archive...');
      final archive = ZipDecoder().decodeBytes(bytes);
      await LogManager.log('Zip archive decoded. Total files: ${archive.length}');
      
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
      await LogManager.log('Extraction complete.');

      // Copy uninstaller (which is this installer itself!)
      final uninstallerDir = Directory('${targetDir.path}\\Uninstaller');
      await LogManager.log('Copying uninstaller to ${uninstallerDir.path}...');
      if (!uninstallerDir.existsSync()) uninstallerDir.createSync(recursive: true);
      
      final srcDir = Directory(exeDir);
      await _copyDirectory(srcDir, uninstallerDir);
      await LogManager.log('Uninstaller files copied.');
      
      final copiedExe = File('${uninstallerDir.path}\\installer_app.exe');
      if (copiedExe.existsSync()) {
        copiedExe.renameSync('${uninstallerDir.path}\\xaneo_uninstaller.exe');
        await LogManager.log('Renamed installer_app.exe to xaneo_uninstaller.exe');
      } else {
        await LogManager.log('WARNING: installer_app.exe not found in copied files!');
      }

      // Save install path for the uninstaller to read later
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('install_path', targetDir.path);
      await LogManager.log('Saved install path to SharedPreferences: ${targetDir.path}');

      // Also write install path to a file inside Uninstaller dir (as backup)
      final pathFile = File('${uninstallerDir.path}\\install_path.txt');
      await pathFile.writeAsString(targetDir.path);
      await LogManager.log('Saved install path to install_path.txt');

      // Create Shortcuts & Registry via in-memory PowerShell (avoid dropping .ps1 file)
      final installCmd = '''
\$WshShell = New-Object -comObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("\$env:USERPROFILE\\Desktop\\Xaneo PC.lnk")
\$Shortcut.TargetPath = "${targetDir.path}\\xaneo_pc.exe"
\$Shortcut.IconLocation = "${targetDir.path}\\xaneo_pc.exe"
\$Shortcut.Save()

\$StartMenuShortcut = \$WshShell.CreateShortcut("\$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Xaneo PC.lnk")
\$StartMenuShortcut.TargetPath = "${targetDir.path}\\xaneo_pc.exe"
\$StartMenuShortcut.IconLocation = "${targetDir.path}\\xaneo_pc.exe"
\$StartMenuShortcut.Save()

\$RegPath = "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Xaneo_PC"
New-Item -Path \$RegPath -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "DisplayName" -Value "Xaneo PC" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "DisplayIcon" -Value "${targetDir.path}\\xaneo_pc.exe" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "UninstallString" -Value '"${uninstallerDir.path}\\xaneo_uninstaller.exe" --uninstall' -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "Publisher" -Value "Xaneo" -PropertyType String -Force | Out-Null
New-ItemProperty -Path \$RegPath -Name "InstallLocation" -Value "${targetDir.path}" -PropertyType String -Force | Out-Null
''';

      await LogManager.log('Running installation configuration script in-memory via PowerShell...');
      final result = await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', installCmd]);
      
      await LogManager.log('PowerShell exit code: ${result.exitCode}');
      if (result.stdout.toString().trim().isNotEmpty) {
        await LogManager.log('PowerShell stdout: ${result.stdout}');
      }
      if (result.stderr.toString().trim().isNotEmpty) {
        await LogManager.log('PowerShell stderr: ${result.stderr}');
      }

      await LogManager.log('=== Installation Finished Successfully ===');
      setState(() {
        _done = true;
        _status = t('done');
      });
    } catch (e) {
      await LogManager.log('ERROR during installation: $e');
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
                Text(t('title'), style: const TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 14)),
                const Spacer(),
                if (!_installing)
                  DropdownButton<String>(
                    value: _lang,
                    dropdownColor: const Color(0xFF2A2A2A),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language, color: Colors.white, size: 16),
                    style: const TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'ru', child: Text('Русский', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'ar', child: Text('العربية', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'es', child: Text('Español', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'fr', child: Text('Français', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'ja', child: Text('日本語', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'ko', child: Text('한국어', style: TextStyle(fontFamily: _kFontFamily))),
                      DropdownMenuItem(value: 'zh', child: Text('中文', style: TextStyle(fontFamily: _kFontFamily))),
                    ],
                    onChanged: (v) {
                      if (v != null) _setLang(v);
                    },
                  ),
                const SizedBox(width: 16),
                TextButton.icon(
                  icon: const Icon(Icons.bug_report_outlined, color: Colors.grey, size: 16),
                  label: const Text('Logs', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: _kFontFamily)),
                  onPressed: () => _showLogsDialog(context),
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
                      style: const TextStyle(fontFamily: _kFontFamily, fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    if (!_installing && !_done) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('path'), style: const TextStyle(fontFamily: _kFontFamily, color: Colors.grey, fontSize: 12)),
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
                                  child: Text(_installPath, style: const TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
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
                                child: Text(t('browse'), style: const TextStyle(fontFamily: _kFontFamily)),
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
                            child: Text(t('install'), style: const TextStyle(fontFamily: _kFontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            ),
                            onPressed: () => windowManager.close(),
                            child: Text(t('cancel'), style: const TextStyle(fontFamily: _kFontFamily, fontSize: 16)),
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
                            style: const TextStyle(fontFamily: _kFontFamily, color: Colors.grey, fontSize: 14),
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
                        child: Text(t('launch'), style: const TextStyle(fontFamily: _kFontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
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
  bool _done = false;
  String _status = '';

  final Map<String, Map<String, String>> _locales = {
    'en': {'title': 'Xaneo PC Uninstall', 'prompt': 'Are you sure you want to uninstall Xaneo PC?', 'uninstall': 'Uninstall', 'cancel': 'Cancel', 'removing': 'Removing files...', 'done': 'Xaneo PC has been uninstalled.'},
    'ru': {'title': 'Удаление Xaneo PC', 'prompt': 'Вы уверены, что хотите удалить Xaneo PC?', 'uninstall': 'Удалить', 'cancel': 'Отмена', 'removing': 'Удаление файлов...', 'done': 'Xaneo PC удален.'},
    'ar': {'title': 'إلغاء تثبيت Xaneo PC', 'prompt': 'هل أنت متأكد أنك تريد إلغاء تثبيت Xaneo PC؟', 'uninstall': 'إلغاء التثبيت', 'cancel': 'إلغاء', 'removing': 'جاري إزالة الملفات...', 'done': 'تم إلغاء تثبيت Xaneo PC.'},
    'es': {'title': 'Desinstalar Xaneo PC', 'prompt': '¿Estás seguro de que quieres desinstalar Xaneo PC?', 'uninstall': 'Desinstalar', 'cancel': 'Cancelar', 'removing': 'Eliminando archivos...', 'done': 'Xaneo PC ha sido desinstalado.'},
    'fr': {'title': 'Désinstaller Xaneo PC', 'prompt': 'Êtes-vous sûr de vouloir désinstaller Xaneo PC ?', 'uninstall': 'Désinstaller', 'cancel': 'Annuler', 'removing': 'Suppression des fichiers...', 'done': 'Xaneo PC a été désinstallé.'},
    'ja': {'title': 'Xaneo PC アンインストール', 'prompt': 'Xaneo PC をアンインストールしてもよろしいですか？', 'uninstall': 'アンインストール', 'cancel': 'キャンセル', 'removing': 'ファイルを削除중...', 'done': 'Xaneo PC はアンインストールされました。'},
    'ko': {'title': 'Xaneo PC 제거', 'prompt': 'Xaneo PC를 제거하시겠습니까?', 'uninstall': '제거', 'cancel': '취소', 'removing': '파일 삭제 중...', 'done': 'Xaneo PC가 제거되었습니다.'},
    'zh': {'title': 'Xaneo PC 卸载', 'prompt': '您确定要卸载 Xaneo PC 吗？', 'uninstall': '卸载', 'cancel': '取消', 'removing': '正在删除文件...', 'done': 'Xaneo PC 已卸载。'},
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

  Future<String> _resolveInstallPath() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    await LogManager.log('Resolving install path...');
    await LogManager.log('Exe parent directory: $exeDir');

    // 1. Try reading install_path.txt written by installer
    final pathFile = File('$exeDir\\install_path.txt');
    await LogManager.log('Checking path file: ${pathFile.path}');
    if (pathFile.existsSync()) {
      final path = pathFile.readAsStringSync().trim();
      await LogManager.log('Path file content: "$path"');
      if (path.isNotEmpty && Directory(path).existsSync()) {
        await LogManager.log('Resolved path from install_path.txt: $path');
        return path;
      } else {
        await LogManager.log('Path from file is empty or directory does not exist.');
      }
    } else {
      await LogManager.log('install_path.txt does not exist.');
    }

    // 2. Try reading from registry
    try {
      await LogManager.log('Querying registry for InstallLocation...');
      final result = await Process.run('powershell', [
        '-NoProfile', '-Command',
        '(Get-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Xaneo_PC" -Name "InstallLocation" -ErrorAction SilentlyContinue).InstallLocation',
      ]);
      final regPath = result.stdout.toString().trim();
      await LogManager.log('Registry path result: "$regPath"');
      if (regPath.isNotEmpty && Directory(regPath).existsSync()) {
        await LogManager.log('Resolved path from registry: $regPath');
        return regPath;
      }
    } catch (e) {
      await LogManager.log('Registry query error: $e');
    }

    // 3. Fallback: exe is in Uninstaller subfolder, parent is install dir
    final parentDir = Directory(exeDir).parent.path;
    await LogManager.log('Fallback to parent directory: $parentDir');
    return parentDir;
  }

  Future<void> _uninstall() async {
    setState(() {
      _uninstalling = true;
      _status = t('removing');
    });

    try {
      await LogManager.log('=== Uninstall Started ===');
      final targetDir = await _resolveInstallPath();
      await LogManager.log('Final Resolved Uninstall Path: $targetDir');
      
      final tempDir = Directory.systemTemp.path;
      final myPid = pid;
      await LogManager.log('Current PID: $myPid, Temp Dir: $tempDir');

      final psCommand = '''
\$LogFile = "${Directory.systemTemp.path}\\xaneo_installer.log"
function WriteLog(\$msg) {
  try {
    \$ts = Get-Date -Format "HH:mm:ss"
    Add-Content -Path \$LogFile -Value "[\$ts] [PowerShell] \$msg" -ErrorAction SilentlyContinue
  } catch {}
}

WriteLog "Detached cleanup script started. targetDir = $targetDir, targetPid = $myPid"

# Wait for the uninstaller process to exit
WriteLog "Waiting for uninstaller process (PID $myPid) to exit..."
try {
  \$proc = Get-Process -Id $myPid -ErrorAction SilentlyContinue
  if (\$proc -ne \$null) {
    # Wait up to 10 seconds for clean exit
    \$exited = \$proc.WaitForExit(10000)
    if (\$exited) {
      WriteLog "Uninstaller process has exited."
    } else {
      WriteLog "WARNING: WaitForExit timed out! Process is still running."
    }
  } else {
    WriteLog "Uninstaller process (PID $myPid) not found (already exited?)"
  }
} catch {
  WriteLog "Error waiting for PID $myPid: \$_"
}

# Wait additional 2 seconds to make sure locks are freed
Start-Sleep -Seconds 2

# Remove shortcuts
WriteLog "Removing Desktop shortcut..."
try {
  Remove-Item -Path "\$env:USERPROFILE\\Desktop\\Xaneo PC.lnk" -Force -ErrorAction Stop
  WriteLog "Desktop shortcut removed successfully."
} catch {
  WriteLog "Desktop shortcut removal failed: \$_"
}

WriteLog "Removing Start Menu shortcut..."
try {
  Remove-Item -Path "\$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Xaneo PC.lnk" -Force -ErrorAction Stop
  WriteLog "Start Menu shortcut removed successfully."
} catch {
  WriteLog "Start Menu shortcut removal failed: \$_"
}

# Remove registry entry
WriteLog "Removing registry Uninstall key..."
try {
  Remove-Item -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Xaneo_PC" -Recurse -Force -ErrorAction Stop
  WriteLog "Registry Uninstall key removed successfully."
} catch {
  WriteLog "Registry Uninstall key removal failed: \$_"
}

# Remove install directory with retry
\$target = "$targetDir"
WriteLog "Attempting to remove target directory: \$target"
if (Test-Path \$target) {
  for (\$i = 1; \$i -le 10; \$i++) {
    WriteLog "Attempt \$i to delete target directory..."
    try {
      Remove-Item -Path \$target -Recurse -Force -ErrorAction Stop
      WriteLog "Target directory deleted successfully on attempt \$i."
      break
    } catch {
      WriteLog "Attempt \$i failed: \$_"
      # List remaining files to see what is blocking
      try {
        \$files = Get-ChildItem -Path \$target -Recurse -File -ErrorAction SilentlyContinue
        if (\$files -ne \$null -and \$files.Count -gt 0) {
          \$fileNames = \$files | ForEach-Object { \$_.FullName }
          WriteLog "Remaining locked files: (\$fileNames -join ', ')"
        }
      } catch {}
      Start-Sleep -Seconds 2
    }
  }
} else {
  WriteLog "Target directory does not exist or was already deleted."
}

WriteLog "Cleanup finished."
''';

      await LogManager.log('Starting detached PowerShell cleanup command...');
      await Process.start(
        'powershell',
        ['-WindowStyle', 'Hidden', '-NoProfile', '-NonInteractive', '-Command', psCommand],
        mode: ProcessStartMode.detached,
      );
      await LogManager.log('Detached PowerShell cleanup process started.');

      setState(() {
        _done = true;
        _status = t('done');
      });

      await LogManager.log('Exiting uninstaller in 2 seconds...');
      await Future.delayed(const Duration(seconds: 2));
      await windowManager.close();
      exit(0);
    } catch (e) {
      await LogManager.log('ERROR during uninstallation: $e');
      setState(() {
        _uninstalling = false;
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
                Text(t('title'), style: const TextStyle(fontFamily: _kFontFamily, color: Colors.white, fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.bug_report_outlined, color: Colors.grey, size: 16),
                  label: const Text('Logs', style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: _kFontFamily)),
                  onPressed: () => _showLogsDialog(context),
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
                    Icon(
                      _done ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      size: 64,
                      color: _done ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _done ? t('done') : (_uninstalling ? _status : t('prompt')),
                      style: const TextStyle(fontFamily: _kFontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (!_uninstalling && !_done)
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
                            child: Text(t('uninstall'), style: const TextStyle(fontFamily: _kFontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            ),
                            onPressed: () => windowManager.close(),
                            child: Text(t('cancel'), style: const TextStyle(fontFamily: _kFontFamily, fontSize: 16)),
                          ),
                        ],
                      ),
                    if (_uninstalling && !_done)
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
