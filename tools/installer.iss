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
Name: "registerfiles"; Description: "Register MediaPlayer for media files"; GroupDescription: "File associations"; Flags: checkedonce

[Files]
Source: "{#AppSourceDir}*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; Register the application
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe\shell"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe\shell\open"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\MediaPlayer.exe\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

; Register file associations for video formats
Root: HKCU; Subkey: "Software\Classes\.mp4\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.mp4"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.avi\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.avi"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.mov\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.mov"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.mkv\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.mkv"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.webm\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.webm"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.wmv\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.wmv"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.m4v\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.m4v"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.flv\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.flv"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles

; Register file associations for audio formats
Root: HKCU; Subkey: "Software\Classes\.mp3\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.mp3"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.wav\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.wav"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.flac\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.flac"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.ogg\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.ogg"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.aac\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.aac"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.wma\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.wma"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.m4a\OpenWithProgids"; ValueType: string; ValueName: "MediaPlayer.m4a"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles

; Create ProgID entries for video formats
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mp4"; ValueType: string; ValueData: "MP4 Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mp4\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mp4\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.avi"; ValueType: string; ValueData: "AVI Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.avi\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.avi\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mov"; ValueType: string; ValueData: "QuickTime Movie"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mov\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mov\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mkv"; ValueType: string; ValueData: "Matroska Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mkv\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mkv\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.webm"; ValueType: string; ValueData: "WebM Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.webm\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.webm\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wmv"; ValueType: string; ValueData: "Windows Media Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wmv\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wmv\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.m4v"; ValueType: string; ValueData: "iTunes Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.m4v\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.m4v\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.flv"; ValueType: string; ValueData: "Flash Video"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.flv\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.flv\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

; Create ProgID entries for audio formats
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mp3"; ValueType: string; ValueData: "MP3 Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mp3\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.mp3\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wav"; ValueType: string; ValueData: "Wave Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wav\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wav\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.flac"; ValueType: string; ValueData: "FLAC Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.flac\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.flac\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.ogg"; ValueType: string; ValueData: "Ogg Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.ogg\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.ogg\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.aac"; ValueType: string; ValueData: "AAC Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.aac\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.aac\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wma"; ValueType: string; ValueData: "Windows Media Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wma\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.wma\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\MediaPlayer.m4a"; ValueType: string; ValueData: "MPEG-4 Audio"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.m4a\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\MediaPlayer.m4a\shell\open\command"; ValueType: string; ValueData: """{app}\bin\MediaPlayer.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; IconFilename: "{app}\bin\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; Tasks: desktopicon; IconFilename: "{app}\bin\{#AppExeName}"

[Run]
Filename: "{app}\bin\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall