# uninstaller.nsi
!include "FileFunc.nsh"

Name "Xaneo PC Uninstall"
OutFile "installer_app\build\windows\x64\runner\Release\xaneo_uninstaller.exe"
SilentInstall silent
RequestExecutionLevel user

Section
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  
  # Extract all files from the Release folder (packed during build)
  File /r "installer_app\build\windows\x64\runner\Release\*.*"
  
  # Run the custom Flutter uninstaller and wait for it to exit
  # We pass --uninstall so it launches in uninstall mode
  ExecWait '"$PLUGINSDIR\installer_app.exe" --uninstall' $0
  
  # If the exit code is 0 (user confirmed), proceed with native deletion
  IntCmp $0 0 perform_delete
  Quit
  
  perform_delete:
    # 1. Remove Registry entries
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Xaneo_PC"
    
    # 2. Remove shortcuts
    Delete "$DESKTOP\Xaneo PC.lnk"
    Delete "$SMPROGRAMS\Xaneo PC.lnk"
    
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
