import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ─────────────────────────────────────────────────────────────
// Win32 Registry constants
// ─────────────────────────────────────────────────────────────

const int _HKEY_CURRENT_USER = 0x80000001;
const int _KEY_WRITE = 0x20006;
const int _REG_SZ = 1;
const int _REG_OPTION_NON_VOLATILE = 0;

// ─────────────────────────────────────────────────────────────
// Win32 FFI bindings
// ─────────────────────────────────────────────────────────────

final _advapi32 = DynamicLibrary.open('advapi32.dll');
final _ole32 = DynamicLibrary.open('ole32.dll');

// RegCreateKeyExW
typedef _RegCreateKeyExWNative = Int32 Function(
  IntPtr hKey,
  Pointer<Utf16> lpSubKey,
  Uint32 reserved,
  Pointer<Utf16> lpClass,
  Uint32 dwOptions,
  Uint32 samDesired,
  Pointer lpSecurityAttributes,
  Pointer<IntPtr> phkResult,
  Pointer<Uint32> lpdwDisposition,
);
typedef _RegCreateKeyExWDart = int Function(
  int hKey,
  Pointer<Utf16> lpSubKey,
  int reserved,
  Pointer<Utf16> lpClass,
  int dwOptions,
  int samDesired,
  Pointer lpSecurityAttributes,
  Pointer<IntPtr> phkResult,
  Pointer<Uint32> lpdwDisposition,
);
final _RegCreateKeyExW =
    _advapi32.lookupFunction<_RegCreateKeyExWNative, _RegCreateKeyExWDart>(
        'RegCreateKeyExW');

// RegSetValueExW
typedef _RegSetValueExWNative = Int32 Function(
  IntPtr hKey,
  Pointer<Utf16> lpValueName,
  Uint32 reserved,
  Uint32 dwType,
  Pointer lpData,
  Uint32 cbData,
);
typedef _RegSetValueExWDart = int Function(
  int hKey,
  Pointer<Utf16> lpValueName,
  int reserved,
  int dwType,
  Pointer lpData,
  int cbData,
);
final _RegSetValueExW =
    _advapi32.lookupFunction<_RegSetValueExWNative, _RegSetValueExWDart>(
        'RegSetValueExW');

// RegCloseKey
typedef _RegCloseKeyNative = Int32 Function(IntPtr hKey);
typedef _RegCloseKeyDart = int Function(int hKey);
final _RegCloseKey =
    _advapi32.lookupFunction<_RegCloseKeyNative, _RegCloseKeyDart>(
        'RegCloseKey');

// CoInitializeEx
typedef _CoInitializeExNative = Int32 Function(
    Pointer pvReserved, Uint32 dwCoInit);
typedef _CoInitializeExDart = int Function(Pointer pvReserved, int dwCoInit);
final _CoInitializeEx =
    _ole32.lookupFunction<_CoInitializeExNative, _CoInitializeExDart>(
        'CoInitializeEx');



// ─────────────────────────────────────────────────────────────
// Registry helpers
// ─────────────────────────────────────────────────────────────

/// Writes a string value to HKCU registry.
/// [subKey] e.g. r'Software\Microsoft\Windows\CurrentVersion\Uninstall\Xaneo'
/// [valueName] e.g. 'DisplayName'
/// [value] e.g. 'Xaneo'
bool registrySetString(String subKey, String valueName, String value) {
  final pSubKey = subKey.toNativeUtf16();
  final phkResult = calloc<IntPtr>();
  final pdwDisposition = calloc<Uint32>();

  try {
    final createResult = _RegCreateKeyExW(
      _HKEY_CURRENT_USER,
      pSubKey,
      0,
      nullptr,
      _REG_OPTION_NON_VOLATILE,
      _KEY_WRITE,
      nullptr,
      phkResult,
      pdwDisposition,
    );

    if (createResult != 0) return false;

    final hKey = phkResult.value;
    final pValueName = valueName.toNativeUtf16();
    // REG_SZ data includes the null terminator
    final pValue = value.toNativeUtf16();
    final cbData = (value.length + 1) * 2; // UTF-16: 2 bytes per char + null

    final setResult = _RegSetValueExW(
      hKey,
      pValueName,
      0,
      _REG_SZ,
      pValue,
      cbData,
    );

    calloc.free(pValueName);
    calloc.free(pValue);
    _RegCloseKey(hKey);

    return setResult == 0;
  } finally {
    calloc.free(pSubKey);
    calloc.free(phkResult);
    calloc.free(pdwDisposition);
  }
}

// ─────────────────────────────────────────────────────────────
// Shortcut creation via IShellLink COM
// ─────────────────────────────────────────────────────────────

// GUIDs
// CLSID_ShellLink = {00021401-0000-0000-C000-000000000046}
// IID_IShellLinkW = {000214F9-0000-0000-C000-000000000046}
// IID_IPersistFile = {0000010B-0000-0000-C000-000000000046}

// CoCreateInstance
typedef _CoCreateInstanceNative = Int32 Function(
  Pointer<GUID> rclsid,
  Pointer pUnkOuter,
  Uint32 dwClsContext,
  Pointer<GUID> riid,
  Pointer<Pointer> ppv,
);
typedef _CoCreateInstanceDart = int Function(
  Pointer<GUID> rclsid,
  Pointer pUnkOuter,
  int dwClsContext,
  Pointer<GUID> riid,
  Pointer<Pointer> ppv,
);
final _CoCreateInstance =
    _ole32.lookupFunction<_CoCreateInstanceNative, _CoCreateInstanceDart>(
        'CoCreateInstance');

// GUID struct
base class GUID extends Struct {
  @Uint32()
  external int data1;
  @Uint16()
  external int data2;
  @Uint16()
  external int data3;
  @Uint8()
  external int data4_0;
  @Uint8()
  external int data4_1;
  @Uint8()
  external int data4_2;
  @Uint8()
  external int data4_3;
  @Uint8()
  external int data4_4;
  @Uint8()
  external int data4_5;
  @Uint8()
  external int data4_6;
  @Uint8()
  external int data4_7;
}

Pointer<GUID> _allocGUID(
    int d1, int d2, int d3, List<int> d4) {
  final guid = calloc<GUID>();
  guid.ref.data1 = d1;
  guid.ref.data2 = d2;
  guid.ref.data3 = d3;
  guid.ref.data4_0 = d4[0];
  guid.ref.data4_1 = d4[1];
  guid.ref.data4_2 = d4[2];
  guid.ref.data4_3 = d4[3];
  guid.ref.data4_4 = d4[4];
  guid.ref.data4_5 = d4[5];
  guid.ref.data4_6 = d4[6];
  guid.ref.data4_7 = d4[7];
  return guid;
}

/// Creates a Windows shortcut (.lnk) file using IShellLink COM interface.
/// This is the native Win32 way — no PowerShell needed.
/// Returns true on success.
bool createShortcut({
  required String shortcutPath,
  required String targetPath,
  String? iconPath,
  String? description,
}) {
  // Initialize COM (COINIT_APARTMENTTHREADED = 0x2)
  _CoInitializeEx(nullptr, 0x2);

  final clsidShellLink =
      _allocGUID(0x00021401, 0x0000, 0x0000, [0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46]);
  final iidShellLink =
      _allocGUID(0x000214F9, 0x0000, 0x0000, [0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46]);
  final iidPersistFile =
      _allocGUID(0x0000010B, 0x0000, 0x0000, [0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46]);

  final ppShellLink = calloc<Pointer>();

  try {
    // CLSCTX_INPROC_SERVER = 0x1
    var hr = _CoCreateInstance(
        clsidShellLink, nullptr, 0x1, iidShellLink, ppShellLink);
    if (hr < 0) return false;

    final pShellLink = ppShellLink.value;
    // IShellLinkW vtable: QueryInterface(0), AddRef(1), Release(2),
    //   GetPath(3), GetIDList(4), SetIDList(5), GetDescription(6),
    //   SetDescription(7), GetWorkingDirectory(8), SetWorkingDirectory(9),
    //   GetArguments(10), SetArguments(11), GetHotkey(12), SetHotkey(13),
    //   GetShowCmd(14), SetShowCmd(15), GetIconLocation(16), SetIconLocation(17),
    //   SetRelativePath(18), Resolve(19), SetPath(20)

    final vtable = pShellLink.cast<Pointer<IntPtr>>().value;

    // SetPath (index 20)
    final setPath = Pointer<NativeFunction<Int32 Function(Pointer, Pointer<Utf16>)>>.fromAddress(
        (vtable.cast<IntPtr>() + 20).value);
    final pTargetPath = targetPath.toNativeUtf16();
    hr = setPath.asFunction<int Function(Pointer, Pointer<Utf16>)>()(
        pShellLink, pTargetPath);
    calloc.free(pTargetPath);
    if (hr < 0) return false;

    // SetIconLocation (index 17)
    if (iconPath != null) {
      final setIconLocation =
          Pointer<NativeFunction<Int32 Function(Pointer, Pointer<Utf16>, Int32)>>.fromAddress(
              (vtable.cast<IntPtr>() + 17).value);
      final pIconPath = iconPath.toNativeUtf16();
      setIconLocation.asFunction<int Function(Pointer, Pointer<Utf16>, int)>()(
          pShellLink, pIconPath, 0);
      calloc.free(pIconPath);
    }

    // SetDescription (index 7)
    if (description != null) {
      final setDescription =
          Pointer<NativeFunction<Int32 Function(Pointer, Pointer<Utf16>)>>.fromAddress(
              (vtable.cast<IntPtr>() + 7).value);
      final pDescription = description.toNativeUtf16();
      setDescription.asFunction<int Function(Pointer, Pointer<Utf16>)>()(
          pShellLink, pDescription);
      calloc.free(pDescription);
    }

    // QueryInterface for IPersistFile
    final queryInterface =
        Pointer<NativeFunction<Int32 Function(Pointer, Pointer<GUID>, Pointer<Pointer>)>>
            .fromAddress((vtable.cast<IntPtr>() + 0).value);
    final ppPersistFile = calloc<Pointer>();
    hr = queryInterface.asFunction<int Function(Pointer, Pointer<GUID>, Pointer<Pointer>)>()(
        pShellLink, iidPersistFile, ppPersistFile);
    if (hr < 0) {
      calloc.free(ppPersistFile);
      return false;
    }

    final pPersistFile = ppPersistFile.value;
    final pfVtable = pPersistFile.cast<Pointer<IntPtr>>().value;

    // IPersistFile::Save (index 6 in IPersistFile vtable)
    // Save(LPCOLESTR pszFileName, BOOL fRemember)
    final save = Pointer<NativeFunction<Int32 Function(Pointer, Pointer<Utf16>, Int32)>>
        .fromAddress((pfVtable.cast<IntPtr>() + 6).value);
    final pShortcutPath = shortcutPath.toNativeUtf16();
    hr = save.asFunction<int Function(Pointer, Pointer<Utf16>, int)>()(
        pPersistFile, pShortcutPath, 1);
    calloc.free(pShortcutPath);

    // Release IPersistFile
    final pfRelease = Pointer<NativeFunction<Uint32 Function(Pointer)>>.fromAddress(
        (pfVtable.cast<IntPtr>() + 2).value);
    pfRelease.asFunction<int Function(Pointer)>()(pPersistFile);
    calloc.free(ppPersistFile);

    // Release IShellLink
    final slRelease = Pointer<NativeFunction<Uint32 Function(Pointer)>>.fromAddress(
        (vtable.cast<IntPtr>() + 2).value);
    slRelease.asFunction<int Function(Pointer)>()(pShellLink);

    return hr >= 0;
  } finally {
    calloc.free(ppShellLink);
    calloc.free(clsidShellLink);
    calloc.free(iidShellLink);
    calloc.free(iidPersistFile);
  }
}

// ─────────────────────────────────────────────────────────────
// High-level helpers used by installer
// ─────────────────────────────────────────────────────────────

/// Creates desktop and Start Menu shortcuts + writes uninstall registry entries.
/// This replaces the PowerShell script that was previously used.
/// Returns a map of operation -> success/failure for logging.
Map<String, bool> setupInstallation({
  required String installPath,
  required String uninstallerPath,
}) {
  final results = <String, bool>{};
  final exePath = '$installPath\\xaneo.exe';
  
  // 1. Desktop shortcut
  final userProfile = Platform.environment['USERPROFILE'] ?? '';
  final desktopShortcut = '$userProfile\\Desktop\\Xaneo.lnk';
  results['Desktop shortcut'] = createShortcut(
    shortcutPath: desktopShortcut,
    targetPath: exePath,
    iconPath: exePath,
    description: 'Xaneo',
  );

  // 2. Start Menu shortcut
  final appData = Platform.environment['APPDATA'] ?? '';
  final startMenuShortcut =
      '$appData\\Microsoft\\Windows\\Start Menu\\Programs\\Xaneo.lnk';
  // Ensure parent dir exists
  final startMenuDir = Directory(
      '$appData\\Microsoft\\Windows\\Start Menu\\Programs');
  if (!startMenuDir.existsSync()) {
    startMenuDir.createSync(recursive: true);
  }
  results['Start Menu shortcut'] = createShortcut(
    shortcutPath: startMenuShortcut,
    targetPath: exePath,
    iconPath: exePath,
    description: 'Xaneo',
  );

  // 3. Registry uninstall entries
  const regSubKey =
      r'Software\Microsoft\Windows\CurrentVersion\Uninstall\Xaneo';
  
  results['Registry: DisplayName'] =
      registrySetString(regSubKey, 'DisplayName', 'Xaneo');
  results['Registry: DisplayIcon'] =
      registrySetString(regSubKey, 'DisplayIcon', exePath);
  results['Registry: UninstallString'] =
      registrySetString(regSubKey, 'UninstallString', '"$uninstallerPath\\xaneo_uninstaller.exe"');
  results['Registry: Publisher'] =
      registrySetString(regSubKey, 'Publisher', 'Xaneo');
  results['Registry: InstallLocation'] =
      registrySetString(regSubKey, 'InstallLocation', installPath);

  return results;
}
