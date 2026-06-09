import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
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

  runApp(const InstallerApp());
}

class InstallerApp extends StatelessWidget {
  const InstallerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.white,
      ),
      home: const InstallerScreen(),
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

  final Map<String, Map<String, String>> _locales = {
    'en': {'title': 'Xaneo PC Setup', 'welcome': 'Welcome to Xaneo PC', 'install': 'Install', 'installing': 'Installing...', 'done': 'Installation Complete', 'launch': 'Launch Xaneo PC', 'cancel': 'Cancel'},
    'ru': {'title': 'Установка Xaneo PC', 'welcome': 'Добро пожаловать в Xaneo PC', 'install': 'Установить', 'installing': 'Установка...', 'done': 'Установка завершена', 'launch': 'Запустить Xaneo PC', 'cancel': 'Отмена'},
    'ar': {'title': 'إعداد Xaneo PC', 'welcome': 'مرحبا بك في Xaneo PC', 'install': 'تثبيت', 'installing': 'جارٍ التثبيت...', 'done': 'اكتمل التثبيت', 'launch': 'تشغيل Xaneo PC', 'cancel': 'إلغاء'},
    'es': {'title': 'Instalación de Xaneo PC', 'welcome': 'Bienvenido a Xaneo PC', 'install': 'Instalar', 'installing': 'Instalando...', 'done': 'Instalación completada', 'launch': 'Iniciar Xaneo PC', 'cancel': 'Cancelar'},
    'fr': {'title': 'Installation de Xaneo PC', 'welcome': 'Bienvenue sur Xaneo PC', 'install': 'Installer', 'installing': 'Installation...', 'done': 'Installation terminée', 'launch': 'Lancer Xaneo PC', 'cancel': 'Annuler'},
    'ja': {'title': 'Xaneo PC セットアップ', 'welcome': 'Xaneo PCへようこそ', 'install': 'インストール', 'installing': 'インストール中...', 'done': 'インストール完了', 'launch': 'Xaneo PC を起動', 'cancel': 'キャンセル'},
    'ko': {'title': 'Xaneo PC 설정', 'welcome': 'Xaneo PC에 오신 것을 환영합니다', 'install': '설치', 'installing': '설치 중...', 'done': '설치 완료', 'launch': 'Xaneo 실행', 'cancel': '취소'},
    'zh': {'title': 'Xaneo PC 安装', 'welcome': '欢迎使用 Xaneo PC', 'install': '安装', 'installing': '正在安装...', 'done': '安装完成', 'launch': '启动 Xaneo PC', 'cancel': '取消'},
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

  Future<void> _setLang(String l) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l);
    setState(() {
      _lang = l;
    });
  }

  String t(String key) => _locales[_lang]?[key] ?? _locales['en']![key]!;

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _status = t('installing');
    });

    try {
      final appDataDir = await getApplicationSupportDirectory();
      final targetDir = Directory('${appDataDir.path}\\Xaneo_PC');
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
        await Future.delayed(const Duration(milliseconds: 1)); // allow UI update
      }

      final ps1 = File('${targetDir.path}\\create_shortcut.ps1');
      await ps1.writeAsString('''
\$WshShell = New-Object -comObject WScript.Shell
\$Shortcut = \$WshShell.CreateShortcut("\$env:USERPROFILE\\Desktop\\Xaneo PC.lnk")
\$Shortcut.TargetPath = "${targetDir.path}\\xaneo_pc_new.exe"
\$Shortcut.IconLocation = "${targetDir.path}\\xaneo_pc_new.exe"
\$Shortcut.Save()

\$StartMenuShortcut = \$WshShell.CreateShortcut("\$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Xaneo PC.lnk")
\$StartMenuShortcut.TargetPath = "${targetDir.path}\\xaneo_pc_new.exe"
\$StartMenuShortcut.IconLocation = "${targetDir.path}\\xaneo_pc_new.exe"
\$StartMenuShortcut.Save()
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

  void _launchApp() {
    getApplicationSupportDirectory().then((appDataDir) {
      final targetDir = '${appDataDir.path}\\Xaneo_PC';
      Process.run('$targetDir\\xaneo_pc_new.exe', []);
      windowManager.close();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = _lang == 'ar';
    
    return Scaffold(
      body: Column(
        children: [
          // Title bar
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
          
          // Content
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
                    const SizedBox(height: 48),
                    
                    if (!_installing && !_done)
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
