A_AllowMainWindow := true
if A_AhkPath != A_ScriptDir '\AutoHotkeyUX.exe' {
    ; Standalone, compiled or test mode: locate InstallDir via registry
    DirExist(ROOT_DIR := RegRead('HKCU\SOFTWARE\AutoHotkey', 'InstallDir', ""))
        ||  (ROOT_DIR := RegRead('HKLM\SOFTWARE\AutoHotkey', 'InstallDir', ""))
}
if (ROOT_DIR ?? "") = "" || !DirExist(ROOT_DIR)
    Loop Files A_ScriptDir '\..', 'D'
        ROOT_DIR := A_LoopFileFullPath

if !trace.Enabled := RegRead('HKCU\Software\AutoHotkey', 'Trace', false)
    trace.DefineProp 'call', {call: (*) => ''}

#include config.ahk

; This must match the ID set on the AutoHotkey Dash shortcut (for SHAddToRecentDocs):
DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "wstr", "AutoHotkey.AutoHotkey")

trace(s) {
    try
        FileAppend s "`n", "*"
    catch
        OutputDebug s "`n"
}
