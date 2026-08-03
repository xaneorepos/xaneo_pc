# uninstaller.nsi
!include "FileFunc.nsh"

Name "Xaneo Uninstall"
OutFile "installer_app\build\windows\x64\runner\Release\xaneo_uninstaller.exe"
Icon "installer_app\windows\runner\resources\app_icon.ico"
SilentInstall silent
RequestExecutionLevel user

VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "Xaneo Uninstaller"
VIAddVersionKey "CompanyName" "net.xaneo"
VIAddVersionKey "LegalCopyright" "Copyright © 2026 net.xaneo"
VIAddVersionKey "FileDescription" "Xaneo Uninstaller"

Section
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  
  # Extract all files from the Release folder (packed during build)
  File /r "installer_app\build\windows\x64\runner\Release\*.*"
  
  # Run the custom Flutter uninstaller and wait for it to exit
  # We pass --uninstall so it launches in uninstall mode
  ExecWait '"$PLUGINSDIR\xaneo_installer.exe" --uninstall' $0
  
  # If the exit code is 0 (user confirmed), proceed with native deletion
  IntCmp $0 0 perform_delete
  Quit
  
  perform_delete:
    # 1. Remove Registry entries
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Xaneo"
    
    # 2. Remove shortcuts
    Delete "$DESKTOP\Xaneo.lnk"
    Delete "$SMPROGRAMS\Xaneo.lnk"
    
    # 3. Read install path from install_path.txt
    ClearErrors
    FileOpen $1 "$EXEDIR\install_path.txt" r
    IfErrors fallback
    FileRead $1 $2
    FileClose $1
    
    # If the path is empty, use the fallback parent folder deletion
    StrCmp $2 "" fallback
    
    # Delete the directory recursively
    RMDir /r "$2"
    Goto end
    
  fallback:
    # Fallback: delete the parent directory of $EXEDIR (since uninstaller runs from $INSTDIR\Uninstaller)
    RMDir /r "$EXEDIR\.."
    
  end:
SectionEnd
