# installer.nsi
!include "FileFunc.nsh"

# Define fallback versions if not passed from command line
!ifndef VERSION
  !define VERSION "1.0.0.0"
!endif
!ifndef DISPLAY_VERSION
  !define DISPLAY_VERSION "1.0.0"
!endif

Name "Xaneo Setup"
OutFile "dist\xaneo-${DISPLAY_VERSION}-windows-setup.exe"
Icon "installer_app\windows\runner\resources\app_icon.ico"
SilentInstall silent
RequestExecutionLevel user

# Version Information for Windows File Explorer / Properties
VIProductVersion "${VERSION}"
VIAddVersionKey "ProductName" "Xaneo Setup"
VIAddVersionKey "CompanyName" "net.xaneo"
VIAddVersionKey "LegalCopyright" "Copyright © 2026 net.xaneo"
VIAddVersionKey "FileDescription" "Xaneo Setup"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${DISPLAY_VERSION}"

Var Parameters

Section
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  
  # Extract all files recursively from the Release folder
  File /r "installer_app\build\windows\x64\runner\Release\*.*"
  
  # Get command line arguments passed to this installer wrapper
  ${GetParameters} $Parameters
  
  # Run the custom Flutter installer and wait for it to exit
  ExecWait '"$PLUGINSDIR\xaneo_installer.exe" $Parameters' $0
  
  # Return the exit code of xaneo_installer.exe to caller
  SetErrorLevel $0
SectionEnd
