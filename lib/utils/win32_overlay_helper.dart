import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────
// Win32 Overlay Window Helper (for Telegram-style popups)
// Applies WS_EX_TOOLWINDOW (hide from taskbar/alt-tab)
// and WS_EX_NOACTIVATE (prevent stealing focus)
// ─────────────────────────────────────────────────────────────

final _user32 = DynamicLibrary.open('user32.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

// GetActiveWindow
typedef _GetActiveWindowNative = IntPtr Function();
typedef _GetActiveWindowDart = int Function();
final _GetActiveWindow =
    _user32.lookupFunction<_GetActiveWindowNative, _GetActiveWindowDart>('GetActiveWindow');

// GetCurrentProcessId
typedef _GetCurrentProcessIdNative = Uint32 Function();
typedef _GetCurrentProcessIdDart = int Function();
final _GetCurrentProcessId =
    _kernel32.lookupFunction<_GetCurrentProcessIdNative, _GetCurrentProcessIdDart>('GetCurrentProcessId');

// GetWindowThreadProcessId
typedef _GetWindowThreadProcessIdNative = Uint32 Function(IntPtr hWnd, Pointer<Uint32> lpdwProcessId);
typedef _GetWindowThreadProcessIdDart = int Function(int hWnd, Pointer<Uint32> lpdwProcessId);
final _GetWindowThreadProcessId =
    _user32.lookupFunction<_GetWindowThreadProcessIdNative, _GetWindowThreadProcessIdDart>('GetWindowThreadProcessId');

// EnumWindows
typedef _EnumWindowsProcNative = Uint32 Function(IntPtr hWnd, IntPtr lParam);
typedef _EnumWindowsNative = Uint32 Function(Pointer<NativeFunction<_EnumWindowsProcNative>> lpEnumFunc, IntPtr lParam);
typedef _EnumWindowsDart = int Function(Pointer<NativeFunction<_EnumWindowsProcNative>> lpEnumFunc, int lParam);
final _EnumWindows =
    _user32.lookupFunction<_EnumWindowsNative, _EnumWindowsDart>('EnumWindows');

// GetWindowLongPtrW
typedef _GetWindowLongPtrWNative = IntPtr Function(IntPtr hWnd, Int32 nIndex);
typedef _GetWindowLongPtrWDart = int Function(int hWnd, int nIndex);
final _GetWindowLongPtrW =
    _user32.lookupFunction<_GetWindowLongPtrWNative, _GetWindowLongPtrWDart>('GetWindowLongPtrW');

// SetWindowLongPtrW
typedef _SetWindowLongPtrWNative = IntPtr Function(IntPtr hWnd, Int32 nIndex, IntPtr dwNewLong);
typedef _SetWindowLongPtrWDart = int Function(int hWnd, int nIndex, int dwNewLong);
final _SetWindowLongPtrW =
    _user32.lookupFunction<_SetWindowLongPtrWNative, _SetWindowLongPtrWDart>('SetWindowLongPtrW');

// SetWindowPos
typedef _SetWindowPosNative = Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter, Int32 X, Int32 Y, Int32 cx, Int32 cy, Uint32 uFlags);
typedef _SetWindowPosDart = int Function(int hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy, int uFlags);
final _SetWindowPos =
    _user32.lookupFunction<_SetWindowPosNative, _SetWindowPosDart>('SetWindowPos');

int? _findProcessHwnd() {
  final currentPid = _GetCurrentProcessId();
  final pPid = calloc<Uint32>();
  int foundHwnd = 0;

  int enumCallback(int hwnd, int lParam) {
    _GetWindowThreadProcessId(hwnd, pPid);
    if (pPid.value == currentPid) {
      foundHwnd = hwnd;
      return 0; // Stop enumeration
    }
    return 1; // Continue
  }

  final nativeCallback = Pointer.fromFunction<_EnumWindowsProcNative>(enumCallback, 0);
  _EnumWindows(nativeCallback, 0);
  calloc.free(pPid);

  return foundHwnd != 0 ? foundHwnd : null;
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
