import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────
// Win32 Overlay Window Helper (for Telegram-style popups)
// Applies WS_EX_TOOLWINDOW (hide from taskbar/alt-tab)
// and WS_EX_NOACTIVATE (prevent stealing focus)
// ─────────────────────────────────────────────────────────────

int _targetPid = 0;
int _foundHwnd = 0;

// Top-level static function required for Pointer.fromFunction
int _enumWindowsCallback(int hwnd, int lParam) {
  if (!Platform.isWindows) return 0;
  final pPid = calloc<Uint32>();
  try {
    _GetWindowThreadProcessId(hwnd, pPid);
    if (pPid.value == _targetPid) {
      _foundHwnd = hwnd;
      return 0; // Stop enumeration
    }
  } finally {
    calloc.free(pPid);
  }
  return 1; // Continue
}

// Lazy DynamicLibrary bindings (only accessed when running on Windows)
DynamicLibrary? _user32Lib;
DynamicLibrary? _kernel32Lib;

DynamicLibrary get _user32 =>
    _user32Lib ??= DynamicLibrary.open('user32.dll');
DynamicLibrary get _kernel32 =>
    _kernel32Lib ??= DynamicLibrary.open('kernel32.dll');

// Function pointers (lazy loaded)
typedef _GetActiveWindowNative = IntPtr Function();
typedef _GetActiveWindowDart = int Function();
late final _GetActiveWindow =
    _user32.lookupFunction<_GetActiveWindowNative, _GetActiveWindowDart>('GetActiveWindow');

typedef _GetCurrentProcessIdNative = Uint32 Function();
typedef _GetCurrentProcessIdDart = int Function();
late final _GetCurrentProcessId =
    _kernel32.lookupFunction<_GetCurrentProcessIdNative, _GetCurrentProcessIdDart>('GetCurrentProcessId');

typedef _GetWindowThreadProcessIdNative = Uint32 Function(IntPtr hWnd, Pointer<Uint32> lpdwProcessId);
typedef _GetWindowThreadProcessIdDart = int Function(int hWnd, Pointer<Uint32> lpdwProcessId);
late final _GetWindowThreadProcessId =
    _user32.lookupFunction<_GetWindowThreadProcessIdNative, _GetWindowThreadProcessIdDart>('GetWindowThreadProcessId');

typedef _EnumWindowsProcNative = Uint32 Function(IntPtr hWnd, IntPtr lParam);
typedef _EnumWindowsNative = Uint32 Function(Pointer<NativeFunction<_EnumWindowsProcNative>> lpEnumFunc, IntPtr lParam);
typedef _EnumWindowsDart = int Function(Pointer<NativeFunction<_EnumWindowsProcNative>> lpEnumFunc, int lParam);
late final _EnumWindows =
    _user32.lookupFunction<_EnumWindowsNative, _EnumWindowsDart>('EnumWindows');

typedef _GetWindowLongPtrWNative = IntPtr Function(IntPtr hWnd, Int32 nIndex);
typedef _GetWindowLongPtrWDart = int Function(int hWnd, int nIndex);
late final _GetWindowLongPtrW =
    _user32.lookupFunction<_GetWindowLongPtrWNative, _GetWindowLongPtrWDart>('GetWindowLongPtrW');

typedef _SetWindowLongPtrWNative = IntPtr Function(IntPtr hWnd, Int32 nIndex, IntPtr dwNewLong);
typedef _SetWindowLongPtrWDart = int Function(int hWnd, int nIndex, int dwNewLong);
late final _SetWindowLongPtrW =
    _user32.lookupFunction<_SetWindowLongPtrWNative, _SetWindowLongPtrWDart>('SetWindowLongPtrW');

typedef _SetWindowPosNative = Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter, Int32 X, Int32 Y, Int32 cx, Int32 cy, Uint32 uFlags);
typedef _SetWindowPosDart = int Function(int hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy, int uFlags);
late final _SetWindowPos =
    _user32.lookupFunction<_SetWindowPosNative, _SetWindowPosDart>('SetWindowPos');

int? _findProcessHwnd() {
  if (!Platform.isWindows) return null;
  _targetPid = _GetCurrentProcessId();
  _foundHwnd = 0;

  final nativeCallback = Pointer.fromFunction<_EnumWindowsProcNative>(_enumWindowsCallback, 0);
  _EnumWindows(nativeCallback, 0);

  return _foundHwnd != 0 ? _foundHwnd : null;
}

/// Applies Win32 extended window styles to convert a desktop window
/// into a true non-activating tool overlay (Telegram-style popup).
void applyOverlayStyleWin32() {
  if (!Platform.isWindows) return;
  try {
    int hwnd = _GetActiveWindow();
    if (hwnd == 0) {
      hwnd = _findProcessHwnd() ?? 0;
    }
    if (hwnd == 0) return;

    const int GWL_EXSTYLE = -20;
    const int WS_EX_TOOLWINDOW = 0x00000080;
    const int WS_EX_NOACTIVATE = 0x08000000;
    const int WS_EX_TOPMOST = 0x00000008;
    const int WS_EX_APPWINDOW = 0x00040000;

    int exStyle = _GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    exStyle |= (WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TOPMOST);
    exStyle &= ~WS_EX_APPWINDOW;

    _SetWindowLongPtrW(hwnd, GWL_EXSTYLE, exStyle);

    // Apply TOPMOST and NOACTIVATE
    const int HWND_TOPMOST = -1;
    const int SWP_NOSIZE = 0x0001;
    const int SWP_NOMOVE = 0x0002;
    const int SWP_NOACTIVATE = 0x0010;
    const int SWP_SHOWWINDOW = 0x0040;

    _SetWindowPos(
      hwnd,
      HWND_TOPMOST,
      0, 0, 0, 0,
      SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
    );
  } catch (e) {
    debugPrint('applyOverlayStyleWin32 error: $e');
  }
}
