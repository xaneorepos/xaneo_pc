import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────
// Win32 Overlay Window Helper (for Telegram-style popups)
// Applies WS_EX_TOOLWINDOW (hide from taskbar/alt-tab)
// and WS_EX_NOACTIVATE (prevent stealing focus)
// ─────────────────────────────────────────────────────────────

// Lazy DynamicLibrary bindings (only accessed when running on Windows)
DynamicLibrary? _user32Lib;
DynamicLibrary? _kernel32Lib;
DynamicLibrary? _dwmapiLib;

DynamicLibrary get _user32 =>
    _user32Lib ??= DynamicLibrary.open('user32.dll');
DynamicLibrary get _kernel32 =>
    _kernel32Lib ??= DynamicLibrary.open('kernel32.dll');
DynamicLibrary get _dwmapi =>
    _dwmapiLib ??= DynamicLibrary.open('dwmapi.dll');

// Function pointers (lazy loaded)
typedef _GetActiveWindowNative = IntPtr Function();
typedef _GetActiveWindowDart = int Function();
late final _GetActiveWindow =
    _user32.lookupFunction<_GetActiveWindowNative, _GetActiveWindowDart>('GetActiveWindow');

typedef _FindWindowWNative = IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef _FindWindowWDart = int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
late final _FindWindowW =
    _user32.lookupFunction<_FindWindowWNative, _FindWindowWDart>('FindWindowW');

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

typedef _GetForegroundWindowNative = IntPtr Function();
typedef _GetForegroundWindowDart = int Function();
late final _GetForegroundWindow =
    _user32.lookupFunction<_GetForegroundWindowNative, _GetForegroundWindowDart>('GetForegroundWindow');

typedef _GetWindowTextLengthWNative = Int32 Function(IntPtr hWnd);
typedef _GetWindowTextLengthWDart = int Function(int hWnd);
late final _GetWindowTextLengthW =
    _user32.lookupFunction<_GetWindowTextLengthWNative, _GetWindowTextLengthWDart>('GetWindowTextLengthW');

base class MARGINS extends Struct {
  @Int32()
  external int cxLeftWidth;
  @Int32()
  external int cxRightWidth;
  @Int32()
  external int cyTopHeight;
  @Int32()
  external int cyBottomHeight;
}

base class RECT extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

base class ACCENTPOLICY extends Struct {
  @Int32()
  external int nAccentState;
  @Int32()
  external int nFlags;
  @Int32()
  external int nColor;
  @Int32()
  external int nAnimationId;
}

base class WINCOMPATTRDATA extends Struct {
  @Int32()
  external int nAttribute;
  external Pointer<ACCENTPOLICY> pData;
  @Uint32()
  external int ulDataSize;
}

typedef _DwmExtendFrameIntoClientAreaNative = Int32 Function(IntPtr hWnd, Pointer<MARGINS> pMarInset);
typedef _DwmExtendFrameIntoClientAreaDart = int Function(int hWnd, Pointer<MARGINS> pMarInset);
late final _DwmExtendFrameIntoClientArea =
    _dwmapi.lookupFunction<_DwmExtendFrameIntoClientAreaNative, _DwmExtendFrameIntoClientAreaDart>('DwmExtendFrameIntoClientArea');

typedef _SetParentNative = IntPtr Function(IntPtr hWndChild, IntPtr hWndNewParent);
typedef _SetParentDart = int Function(int hWndChild, int hWndNewParent);
late final _SetParent =
    _user32.lookupFunction<_SetParentNative, _SetParentDart>('SetParent');

typedef _SystemParametersInfoWNative = Int32 Function(Uint32 uiAction, Uint32 uiParam, Pointer<RECT> pvParam, Uint32 fWinIni);
typedef _SystemParametersInfoWDart = int Function(int uiAction, int uiParam, Pointer<RECT> pvParam, int fWinIni);
late final _SystemParametersInfoW =
    _user32.lookupFunction<_SystemParametersInfoWNative, _SystemParametersInfoWDart>('SystemParametersInfoW');

typedef _SetWindowCompositionAttributeNative = Int32 Function(IntPtr hwnd, Pointer<WINCOMPATTRDATA> data);
typedef _SetWindowCompositionAttributeDart = int Function(int hwnd, Pointer<WINCOMPATTRDATA> data);
// SetWindowCompositionAttribute is undocumented, but exported by user32.dll on Win10/11
late final _SetWindowCompositionAttribute =
    _user32.lookupFunction<_SetWindowCompositionAttributeNative, _SetWindowCompositionAttributeDart>('SetWindowCompositionAttribute');

int? findWindowByTitle(String title) {
  if (!Platform.isWindows) return null;
  final titlePtr = title.toNativeUtf16();
  try {
    int hwnd = _FindWindowW(nullptr, titlePtr);
    if (hwnd != 0) return hwnd;
  } finally {
    calloc.free(titlePtr);
  }
  return null;
}

/// Applies Win32 extended and standard window styles to convert a desktop window
/// into a true frameless, non-activating tool overlay (Telegram-style popup).
void applyOverlayStyleWin32ToHwnd(int hwnd, {bool show = true}) {
  if (!Platform.isWindows || hwnd == 0) return;
  try {
    // 1. Делаем фон окна прозрачным на уровне Win32 (устраняет белую вспышку)
    // ACCENT_ENABLE_TRANSPARENTGRADIENT = 2
    final policy = calloc<ACCENTPOLICY>();
    policy.ref.nAccentState = 2; 
    policy.ref.nFlags = 2;
    policy.ref.nColor = 0;
    policy.ref.nAnimationId = 0;

    final data = calloc<WINCOMPATTRDATA>();
    data.ref.nAttribute = 19; // WCA_ACCENT_POLICY
    data.ref.pData = policy;
    data.ref.ulDataSize = sizeOf<ACCENTPOLICY>();

    try {
      _SetWindowCompositionAttribute(hwnd, data);
    } catch (_) {
      // Игнорируем ошибку на старых ОС
    } finally {
      calloc.free(policy);
      calloc.free(data);
    }

    // 2. Enable DWM glass/alpha transparency (removes black box render artifact)
    final margins = calloc<MARGINS>();
    margins.ref.cxLeftWidth = -1;
    margins.ref.cxRightWidth = -1;
    margins.ref.cyTopHeight = -1;
    margins.ref.cyBottomHeight = -1;
    _DwmExtendFrameIntoClientArea(hwnd, margins);
    calloc.free(margins);

    const int GWL_STYLE = -16;
    const int GWL_EXSTYLE = -20;

    // Remove window decorations (Titlebar, resize border, minimize/maximize buttons, sysmenu)
    const int WS_CAPTION = 0x00C00000;
    const int WS_THICKFRAME = 0x00040000;
    const int WS_MINIMIZEBOX = 0x00020000;
    const int WS_MAXIMIZEBOX = 0x00010000;
    const int WS_SYSMENU = 0x00080000;
    const int WS_POPUP = 0x80000000;

    int style = _GetWindowLongPtrW(hwnd, GWL_STYLE);
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    style |= WS_POPUP;
    _SetWindowLongPtrW(hwnd, GWL_STYLE, style);

    // Extended window styles (Hide from taskbar & Alt-Tab, non-activating, always on top)
    const int WS_EX_TOOLWINDOW = 0x00000080;
    const int WS_EX_NOACTIVATE = 0x08000000;
    const int WS_EX_TOPMOST = 0x00000008;
    const int WS_EX_APPWINDOW = 0x00040000;

    int exStyle = _GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
    exStyle |= (WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TOPMOST);
    exStyle &= ~WS_EX_APPWINDOW;

    _SetWindowLongPtrW(hwnd, GWL_EXSTYLE, exStyle);

    // 3. Calculate desktop screen work area (excluding Windows taskbar)
    const int SPI_GETWORKAREA = 0x0030;
    final rect = calloc<RECT>();
    _SystemParametersInfoW(SPI_GETWORKAREA, 0, rect, 0);

    int workRight = rect.ref.right;
    int workBottom = rect.ref.bottom;
    calloc.free(rect);

    // Target overlay size (360 x 135)
    int width = 360;
    int height = 135;
    int posX = workRight - width - 16;
    int posY = workBottom - height - 16;

    // Apply position, size, TOPMOST, NOACTIVATE, and FRAMECHANGED
    const int HWND_TOPMOST = -1;
    const int SWP_NOACTIVATE = 0x0010;
    const int SWP_SHOWWINDOW = 0x0040;
    const int SWP_HIDEWINDOW = 0x0080;
    const int SWP_FRAMECHANGED = 0x0020;

    _SetWindowPos(
      hwnd,
      HWND_TOPMOST,
      posX, posY, width, height,
      SWP_NOACTIVATE | SWP_FRAMECHANGED | (show ? SWP_SHOWWINDOW : SWP_HIDEWINDOW),
    );
  } catch (e) {
    debugPrint('applyOverlayStyleWin32ToHwnd error: $e');
  }
}

int? findOverlayHwndByTitle(String uniqueTitle) {
  if (!Platform.isWindows) return null;
  return findWindowByTitle(uniqueTitle);
}

void showOverlayWindowWin32(String uniqueTitle) {
  if (!Platform.isWindows) return;
  int? hwnd = findOverlayHwndByTitle(uniqueTitle);
  if (hwnd != null) {
    const int HWND_TOPMOST = -1;
    const int SWP_NOACTIVATE = 0x0010;
    const int SWP_SHOWWINDOW = 0x0040;
    const int SWP_NOMOVE = 0x0002;
    const int SWP_NOSIZE = 0x0001;

    _SetWindowPos(
      hwnd,
      HWND_TOPMOST,
      0, 0, 0, 0,
      SWP_NOACTIVATE | SWP_SHOWWINDOW | SWP_NOMOVE | SWP_NOSIZE,
    );
  }
}
