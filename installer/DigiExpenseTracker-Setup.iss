; Inno Setup Script for Digi Expense Tracker
; Generated for Windows Desktop Application

#define MyAppName "Digi Expense Tracker"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Munavvar Kavanur"
#define MyAppURL "https://github.com/Munavvar-kavanur/Digi-Wallet"
#define MyAppExeName "digi_expense_tracker.exe"
#define MyAppId "{{B8A5C9E2-4F3D-4A1B-9E2C-7D8F6A3B5C1E}"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Output settings
OutputDir=..\release
OutputBaseFilename=DigiExpenseTracker-Setup-v{#MyAppVersion}
; Compression settings
Compression=lzma2/max
SolidCompression=yes
; Visual settings
WizardStyle=modern
SetupIconFile=app_icon.ico
; Privileges
PrivilegesRequired=admin
; Architecture
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Uninstall settings
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
; License (optional - uncomment if you have a license file)
; LicenseFile=..\LICENSE.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Main executable
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Flutter DLL
Source: "..\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
; Data folder and all its contents
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
; Start Menu icons
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; Desktop icon (optional, based on user choice)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; Quick Launch icon (optional, based on user choice)
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Option to run the application after installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Custom code can be added here for additional installation logic

function InitializeSetup(): Boolean;
begin
  Result := True;
end;
