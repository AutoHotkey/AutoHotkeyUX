ROOT_DIR := RegRead("HKLM\SOFTWARE\AutoHotkey", "InstallDir", "")
if ROOT_DIR = "" || !DirExist(ROOT_DIR)
    Loop Files A_ScriptDir '\..', 'D'
        ROOT_DIR := A_LoopFileFullPath
AUTOHOTKEY_EXE_PATTERN := ROOT_DIR '\AutoHotkey*.exe'
AHK2EXE_PATH := ROOT_DIR "\Compiler\Ahk2Exe.exe"
AHK_PROGID := "AutoHotkeyScript"
SCRIPT_FILES_FILTER := "Script Files (*.ahk)"

#include config.ahk

trace(s) {
    try
        FileAppend s "`n", "*"
    catch
        OutputDebug s "`n"
}
