; This script is intended for indirect use via commands registered by install.ahk.
; It can also be compiled as a replacement for AutoHotkey.exe, so tools which run
; scripts by executing AutoHotkey.exe can benefit from automatic version selection.
#requires AutoHotkey v2.0-beta.3

;@Ahk2Exe-SetDescription AutoHotkey Launcher
#SingleInstance Off
#NoTrayIcon

#include inc\identify.ahk
#include inc\launcher-common.ahk

A_AllowMainWindow := true
SetWorkingDir A_InitialWorkingDir

Main

Main() {
    switches := []
    while A_Args.length {
        arg := A_Args.RemoveAt(1)
        if SubStr(arg,1,1) != '/' {
            ScriptPath := arg
            break
        }
        if arg = '/runwith' { ; Launcher-only switch
            A_Args.runwith := A_Args.RemoveAt(1)
            continue
        }
        switches.push(arg)
        if arg ~= 'i)^/(iLib|include)$' && A_Args.length
            switches.push(A_Args.RemoveAt(1))
    }
    if !IsSet(ScriptPath)
        && !FileExist(ScriptPath := A_ScriptDir "\AutoHotkey.ahk")
        && !FileExist(ScriptPath := A_MyDocuments "\AutoHotkey.ahk") {
        ; TODO: something more useful?
        if FileExist(A_ScriptDir "\AutoHotkey.chm")
            Run 'hh.exe "ms-its:' A_ScriptDir '\AutoHotkey.chm::/docs/Welcome.htm"',, 'Max'
        else
            Run 'https://lexikos.github.io/v2/docs/Welcome.htm'
        ExitApp
    }
    if ScriptPath = '*'
        ExitApp 2 ; FIXME: code would need to be read in and then passed to the real AutoHotkey
    IdentifyAndLaunch ScriptPath, A_Args, switches
}

IdentifyAndLaunch(ScriptPath, args, switches) {
    code := FileRead(ScriptPath, 'UTF-8')
    identify() {
        if RegExMatch(code, "im)^[ `t]*#Requires[ `t]+AutoHotkey[ `t]v(?<ver>\S+)", &m)
            return {v: m.ver, r: "#Requires"}
        if ConfigRead('Launcher', 'Identify', true)
            return IdentifyBySyntax(code)
        return {v: 0, r: "syntax-checking is disabled"}
    }
    i := identify()
    v := i.v || ConfigRead('Launcher', 'Fallback', "")
    trace "![Launcher] version " (v || "unknown") " -- " i.r
    if !v {
        exe := PromptMajorVersion(ScriptPath)
        if exe
            section := "v" GetMajor(exe.Version)
    }
    else {
        exe := GetRequiredOrPreferredExe(v)
    }
    if !exe
        exe := TryToInstallVersion(v, i.v ? i.r : '', ScriptPath)
    if exe {
        if GetMajor(exe.Version) = 1 && ConfigRead('Launcher\v1', 'UTF8', false)
            switches.InsertAt(1, '/CP65001')
        ExitApp LaunchScript(exe.Path, ScriptPath, args, switches).exitCode
    }
    ExitApp 2
}

TryToInstallVersion(v, r, ScriptPath) {
    SplitPath ScriptPath, &name
    m := ' script you are trying to run requires AutoHotkey v' v ', which is not installed.`n`nScript:`t' name
    m := !(r && r != '#Requires') ? 'The' m : 'It looks like the' m '`nRule:`t' r
    if downloadable := IsNumber(v) || VerCompare(v, '1.1.24.02') >= 0 {
        ; Get current version compatible with v.
        bv := v = 1 ? '1.1' : IsInteger(v) ? v '.0' : RegExReplace(v, '^\d+(?:\.\d+)?\b\K.*')
        req := ComObject('Msxml2.XMLHTTP')
        req.open('GET', Format('https://www.autohotkey.com/download/{}/version.txt', bv), false)
        req.send()
        if req.status = 200 && RegExMatch(cv := req.responseText, '^\d+\.[\w\+\-\.]+$') && VerCompare(cv, v) >= 0
            m .= '`n`nWe can try to download and install AutoHotkey v' cv ' for you, while retaining the ability to use the versions already installed.`n`nDownload and install AutoHotkey v' cv '?'
        else
            downloadable := false
    }
    ; TODO: detect admin requirement and apply UAC icon
    if MsgBox(m, 'AutoHotkey', downloadable ? 'Iconi y/n' : 'Icon!') != 'yes'
        return false
    if RunWait(Format('"{}" /script "{}\install-version.ahk" "{}"', A_AhkPath, A_ScriptDir, cv)) != 0
        return false
    return exe := GetRequiredOrPreferredExe(v)
}

GetRequiredOrPreferredExe(v) {
    section := 'Launcher\v' GetMajor(v)
    userv := ConfigRead(section, 'Version', "")
    prefer := A_Args.HasProp('runwith') ? A_Args.runwith : ''
    prefer .= ',' (ConfigRead(section, 'Build', (A_Is64bitOS ? "64," : "") "!ANSI"))
    prefer .= ',' (ConfigRead(section, 'UIA', false) ? 'UIA' : '!UIA')
    if vexact := (userv != "" && (IsInteger(v) || VerCompare(v, userv) < 0))
        v := userv
    return LocateExeByVersion(v, vexact, Trim(prefer, ','))
}

LocateExeByVersion(v, vexact:=false, prefer:='!UIA, 64, !ANSI') {
    ; trace '![Launcher] Attempting to locate v' v '; prefer ' prefer
    majorVer := GetMajor(v), best := '', bestscore := 0
    IsInteger(v) && v .= '-' ; Allow pre-release versions.
    for ,f in GetUsableAutoHotkeyExes() {
        try {
            relation := VerCompare(f.Version, v)
            if vexact ? relation != 0 : (relation < 0 || GetMajor(f.Version) > majorVer) {
                ; trace '![Launcher] Skipping v' f.Version ': ' f.Path
                continue
            }
            if !vexact && best {
                relation := VerCompare(f.Version, best.Version)
                if relation < 0 {
                    ; trace '![Launcher] Skipping v' f.Version ': ' f.Path
                    continue
                }
                if relation > 0
                    bestscore := 0
            }
            fscore := 0
            Loop Parse prefer, ",", " " {
                fscore <<= 1
                if A_LoopField != "" && !matchPref(f.Description, A_LoopField)
                    continue
                fscore |= 1
            }
            ; trace '![Launcher] ' fscore ' v' f.Version ' ' f.Path
            if bestscore <= fscore  ; <= vs < because it tends to prefer 64 over 32, U over A (if unspecified).
                bestscore := fscore, best := f
        }
        catch as e {
            trace "-[Launcher] " type(e) " checking file " A_LoopFileName ": " e.message
            trace "-[Launcher] " e.file ":" e.line
        }
    }
    return best
    matchPref(desc, pref) => SubStr(pref,1,1) != "!" ? InStr(desc, pref) : !InStr(desc, SubStr(pref,2))
}

PromptMajorVersion(ScriptPath:="") {
    majors := LocateMajorVersions()
    switch majors.Count {
    case 1:
        for , f in majors
            return f
    case 0:
        trace '-[Launcher] Failed to locate any interpreters; fallback to launcher'
        return {Path: A_AhkPath, Version: A_AhkVersion}
    }
    ; TODO: improve UI
    m := Menu()
    if ScriptPath != "" {
        SplitPath ScriptPath, &ScriptPath
        m.Add("Open " ScriptPath " with", (*) => 0)
        m.Disable('1&')
    }
    selected := ''
    for , f in majors
        m.Add(f.Version, ((f, *) => selected := f).Bind(f))
    m.Show()
    if !selected {
        trace '[Launcher] No version selected from menu'
        ExitApp
    }
    return selected
}

LocateMajorVersions(filePattern:='', fileLoopOpt:='R') {
    majors := Map()
    Loop 2
        if f := GetRequiredOrPreferredExe(A_Index)
            majors[A_Index] := f
    return majors
}

class Handle {
    __new(ptr:=0) => this.ptr := ptr
    __delete() => DllCall("CloseHandle", "ptr", this)
}

LaunchScript(exe, ahk, args:="", switches:="", encoding:="UTF-8") {
    ; Pass our own stdin/stdout handles (if any) to the child process.
    hStdIn  := DllCall("GetStdHandle", "uint", -10, "ptr")
    hStdOut := DllCall("GetStdHandle", "uint", -11, "ptr")
    hStdErr := DllCall("GetStdHandle", "uint", -12, "ptr")
    
    ; Build command line to execute.
    makeArgs(args) {
        r := ''
        for arg in args is object ? args : [args]
            r .= ' ' (arg ~= '\s' ? '"' arg '"' : arg)
        return r
    }
    switches := makeArgs(switches)
    cmd := Format('"{1}"{2} "{3}"{4}', exe, switches, ahk, makeArgs(args))
    trace '>[Launcher] ' cmd
    
    ; For RunWait, stdout redirection, /validate, etc. to have the best chance of working,
    ; let the launcher exit early only if it can detect that it was executed from Explorer
    ; or the parent process appears to have exited already.
    waitClose := true
    hParent := 0
    if IsSet(ProcessGetParent) {
        try {
            ; (PROCESS_QUERY_LIMITED_INFORMATION := 0x1000) | (SYNCHRONIZE := 0x100000)
            if hParent := DllCall("OpenProcess", "uint", 0x101000, "int", false
                , "uint", parentPid := ProcessGetParent(), "ptr")
                hParent := Handle(hParent)
            waitClose := hParent && (parentName := ProcessGetName(parentPid)) != "explorer.exe"
        }
        catch as e
            trace '![Launcher] Failure checking parent process: ' e.Message
    }

    try {
        proc := RunWithHandles(cmd, {in: hStdIn, out: hStdOut, err: hStdErr})
    }
    catch OSError as e {
        if e.Number != 740 ; ERROR_ELEVATION_REQUIRED
            throw
        trace '![Launcher] elevation required; handles will not be redirected'
        cmd := RegExReplace(cmd, ' /ErrorStdOut(?:=\S*)?')
        Run cmd
        ExitApp
    }
    
    if waitClose {
        ; Wait for either the child process or our parent process (if determined) to terminate.
        NumPut 'ptr', proc.hProcess.ptr, 'ptr', hParent ? hParent.ptr : 0, waitHandles := Buffer(A_PtrSize*2)
        loop {
            Sleep -1
            waitResult := DllCall("MsgWaitForMultipleObjects", "uint", 1 + (hParent != 0), "ptr", waitHandles, "int", 0, "uint", -1, "uint", 0x04FF)
        } until waitResult = 0 || waitResult = 1
    }
    
    DllCall("GetExitCodeProcess", "ptr", proc.hProcess, "uint*", &exitCode:=0)
    if trace.Enabled {
        ; We have to return something numeric for ExitApp, so currently exitCode is left as 259
        ; if the process is still running.
        if exitCode = 259 && DllCall("WaitForSingleObject", "ptr", proc.hProcess, "uint", 0) = 258 { ; STILL_ACTIVE = 259, WAIT_TIMEOUT = 258
            if !(hParent ?? 1) || (waitResult ?? -1) = 1
                trace '>[Launcher] Process launched; now exiting because parent process has terminated.'
            else if (parentName ?? "") = "explorer.exe"
                trace '>[Launcher] Process launched; now exiting because parent is explorer.exe.'
            else
                trace '>[Launcher] Process launched; launcher exiting early.'
        }
        else        
            trace '>[Launcher] Exit code: ' exitCode
    }
    
    return {exitCode: exitCode}
}

RunWithHandles(cmd, handles, workingDir:="") {
    static STARTUPINFO_SIZE := A_PtrSize=8 ? 104 : 68
        , STARTUPINFO_dwFlags := A_PtrSize=8 ? 60 : 44
        , STARTUPINFO_hStdInput := A_PtrSize=8 ? 80 : 56
        , STARTF_USESTDHANDLES := 0x100
        , PROCESS_INFORMATION_SIZE := A_PtrSize=8 ? 24 : 16
    HandleValue(p) => HasProp(handles, p) && (IsInteger(h := handles.%p%) ? h : h.Ptr)
    si := Buffer(STARTUPINFO_SIZE, 0)
    NumPut("uint", STARTUPINFO_SIZE, si)
    NumPut("uint", STARTF_USESTDHANDLES, si, STARTUPINFO_dwFlags)
    NumPut("ptr", HandleValue("in")
         , "ptr", HandleValue("out")
         , "ptr", HandleValue("err")
         , si, STARTUPINFO_hStdInput)
    pi := Buffer(PROCESS_INFORMATION_SIZE)
    if !DllCall("CreateProcess", "ptr", 0, "str", cmd, "ptr", 0, "int", 0, "int", true
                , "int", 0x08000000, "int", 0, "ptr", workingDir ? StrPtr(workingDir) : 0
                , "ptr", si, "ptr", pi)
        throw OSError(, -1, cmd)
    return { hProcess: Handle(NumGet(pi, 0, "ptr"))
           , hThread: Handle(NumGet(pi, A_PtrSize, "ptr"))
           , pid: NumGet(pi, A_PtrSize*2, "uint") }
}
