#define AppName       "MediaPlayer"
#define AppSourceDir  "..\build\MediaPlayer\"
#define AppExeName    "MediaPlayer.exe"
#define                MajorVersion    
#define                MinorVersion    
#define                RevisionVersion    
#define                BuildVersion    
#define TempVersion    GetVersionComponents(AppSourceDir + "bin\" + AppExeName, MajorVersion, MinorVersion, RevisionVersion, BuildVersion)
#define AppVersion     str(MajorVersion) + "." + str(MinorVersion) + "." + str(RevisionVersion)
#define AppPublisher  "Odizinne"
#define AppURL        "https://github.com/Odizinne/MediaPlayer"
#define AppIcon       "..\Resources\icons\icon.ico"
#define CurrentYear   GetDateTimeString('yyyy','','')

[Setup]
AppId={{6664da82-c290-45b4-8861-406d4b684ec8}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}

VersionInfoDescription={#AppName} installer
VersionInfoProductName={#AppName}
VersionInfoVersion={#AppVersion}

AppCopyright=(c) {#CurrentYear} {#AppPublisher}

UninstallDisplayName={#AppName} {#AppVersion}
UninstallDisplayIcon={app}\bin\{#AppExeName}
AppPublisher={#AppPublisher}

AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}

ShowLanguageDialog=yes
UsePreviousLanguage=no
LanguageDetectionMethod=uilanguage

WizardStyle=modern

DisableProgramGroupPage=yes
DisableWelcomePage=yes

SetupIconFile={#AppIcon}

DefaultGroupName={#AppName}
DefaultDirName={localappdata}\Programs\{#AppName}

PrivilegesRequired=lowest
OutputBaseFilename=MediaPlayer_installer
Compression=lzma
SolidCompression=yes
UsedUserAreasWarning=no

[Languages]
Name: "english";    MessagesFile: "compiler:Default.isl"
Name: "french";     MessagesFile: "compiler:Languages\French.isl"
Name: "german";     MessagesFile: "compiler:Languages\German.isl"
Name: "italian";    MessagesFile: "compiler:Languages\Italian.isl"
Name: "korean";     MessagesFile: "compiler:Languages\Korean.isl"
Name: "russian";    MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "registerfiles"; Description: "Register MediaPlayer as default image viewer"; GroupDescription: "File associations"; Flags: checkedonce

[Files]
Source: "{#AppSourceDir}*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; Register the application
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe\shell"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe\shell\open"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

; Register file associations for common image formats
Root: HKCU; Subkey: "Software\Classes\.jpg\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.jpg"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.jpeg\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.jpeg"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.png\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.png"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.gif\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.gif"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.bmp\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.bmp"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.tiff\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.tiff"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.tif\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.tif"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.webp\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.webp"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles

; Create ProgID entries for each format
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.jpg"; ValueType: string; ValueData: "JPEG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.jpg\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.jpg\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.jpeg"; ValueType: string; ValueData: "JPEG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.jpeg\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.jpeg\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.png"; ValueType: string; ValueData: "PNG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.png\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.png\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.gif"; ValueType: string; ValueData: "GIF Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.gif\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.gif\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.bmp"; ValueType: string; ValueData: "Bitmap Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.bmp\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.bmp\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.tiff"; ValueType: string; ValueData: "TIFF Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.tiff\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.tiff\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.tif"; ValueType: string; ValueData: "TIFF Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.tif\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.tif\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.webp"; ValueType: string; ValueData: "WebP Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.webp\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.webp\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; IconFilename: "{app}\bin\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; Tasks: desktopicon; IconFilename: "{app}\bin\{#AppExeName}"

[Run]
Filename: "{app}\bin\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall