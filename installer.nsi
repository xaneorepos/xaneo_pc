# installer.nsi
!include "FileFunc.nsh"

# Define fallback versions if not passed from command line
!ifndef VERSION
  !define VERSION "1.0.0.0"
!endif
!ifndef DISPLAY_VERSION
  !define DISPLAY_VERSION "1.0.0"
!endif

Name "Xaneo PC Setup"
OutFile "dist\xaneo_pc-${DISPLAY_VERSION}-windows-setup.exe"
SilentInstall silent
RequestExecutionLevel user

# Version Information for Windows File Explorer / Properties
VIProductVersion "${VERSION}"
VIAddVersionKey "ProductName" "Xaneo PC Setup"
VIAddVersionKey "CompanyName" "Xaneo"
VIAddVersionKey "LegalCopyright" "Copyright © Xaneo"
VIAddVersionKey "FileDescription" "Xaneo PC Setup"
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
  ExecWait '"$PLUGINSDIR\installer_app.exe" $Parameters' $0
  
  # Return the exit code of installer_app.exe to caller
  SetErrorLevel $0
SectionEnd
