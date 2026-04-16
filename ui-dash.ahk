; Dash: AutoHotkey's "main menu".
; Run the script to show the GUI.
#include inc\bounce-v1.ahk
/* v1 stops here */
#requires AutoHotkey v2.0

#NoTrayIcon
#SingleInstance Force

#include inc\ui-base.ahk
#include ui-launcherconfig.ahk
#include ui-editor.ahk
#include ui-newscript.ahk
#include install.ahk

DashRegKey := 'HKCU\Software\AutoHotkey\Dash'

class AutoHotkeyDashGui extends AutoHotkeyUxGui {
    __new() {
        super.__new("AutoHotkey Dash")

        lv := this.AddListMenu('vLV LV0x40 w250', ["Name", "Desc"])
        lv.OnEvent("Click", "ItemClicked")
        lv.OnEvent("ItemFocus", "ItemFocused")
        lv.OnNotify(-155, "KeyPressed")
        
        this.AddButton("xp yp wp yp Hidden Default").OnEvent("Click", "EnterPressed")
        
        il := IL_Create(,, true)
        lv.SetImageList(il, 0)
        il2 := IL_Create(,, false)
        lv.SetImageList(il2, 1)
        addIcon(p*) =>(IL_Add(il, p*), IL_Add(il2, p*))
        
        lv.Add("Icon" addIcon(A_AhkPath, 2)
            , "New script", "Create a script or manage templates")
        lv.Add("Icon" addIcon("imageres.dll", -111)
            , "Compile", "Open Ahk2Exe - convert .ahk to .exe")
        lv.Add("Icon" addIcon("imageres.dll", -99)
            , "Help files (F1)")
        lv.Add("Icon" addIcon(A_ScriptDir '\inc\spy.ico', 1)
            , "Window spy")
        lv.Add("Icon" addIcon("imageres.dll", -116)
            , "Launch settings", "Configure how .ahk files are opened")
        lv.Add("Icon" addIcon("notepad.exe", 1)
            , "Editor settings", "Set your default script editor")
        ; lv.Add("Icon" addIcon("mmc.exe")
        ;     , "Maintenance", "Repair settings or add/remove versions")
        ; lv.Add(, "Auto-start", "Run scripts automatically at logon")
        ; lv.Add(, "Downloads", "Get related tools")
        
        lv.AutoSize()
        lv.GetPos(, &y, &w, &h)
        
        if !RegRead(DashRegKey, 'SuppressIntro', false) {
            this.SetFont('s12')
            this.AddText('yp x+m', "Welcome!")
            this.SetFont('s9')
            this.AddText('xp vIntroText', "This is the Dash. It provides access to tools, settings and help files.")
            this.AddText('xp', "To learn how to use AutoHotkey, refer to:")
            this.AddLink('xp', "
            (
            `s   • <a href="Program.htm">Using the Program</a>
                • <a href="howto/WriteHotkeys.htm">How to Write Hotkeys</a>
                • <a href="howto/SendKeys.htm">How to Send Keystrokes</a>
                • <a href="howto/RunPrograms.htm">How to Run Programs</a>
                • <a href="howto/ManageWindows.htm">How to Manage Windows</a>
                • <a href="index.htm#Quick_Reference">Quick Reference</a>
            )").OnEvent('Click', 'LinkClicked')
            
            checkBox := this.AddCheckbox('Checked', "Show this info next time")
            checkBox.GetPos(,,, &hc)
            checkBox.Move(, h - hc)
            checkBox.OnEvent('Click', 'SetIntroPref')
            
        }
        
        this.Show("Hide h" (h + this.MarginY*2))
        
        if RegRead(DashRegKey, 'CheckForUpdates', false)
            CheckAvailableVersions(receiveVersions)
        receiveVersions(v) {
            if v := IsUpdateAvailable(v)
                this.ShowUpdateBanner(v)
        }
    }
    
    ShowUpdateBanner(version) {
        if !DllCall('IsWindowVisible', 'uint', this.Hwnd)
            return
        
        this.newVersion := version
        
        this['LV'].GetPos(, &y,, &h)
        this.GetClientPos(,, &gw, &gh)
        this.AddText(Format('vUpdateBanner Backgroundb8e2e7 x0 y{} w{} h30', gh, gw))
        
        ; SysLink controls do not support transparent backgrounds it seems
        updateLink := this.AddLink('vUpdateLink yp+5 Backgroundb8e2e7', Format('<a>Update available to: {}</a>', this.newVersion))
        updateLink.OnEvent('Click', 'UpdateVersion')
        updateLink.GetPos(,, &uw)
        updateLink.Move(gw // 2 - uw // 2)
        
        this.Show('h' gh + 30)
    }
    
    LinkClicked(ctrl, id, href) {
        if FileExist(chm := ROOT_DIR '\v2\AutoHotkey.chm')
            Run 'hh.exe "ms-its:' chm '::docs/' href '"'
        else
            Run 'https://www.autohotkey.com/docs/v2/' href
    }
    
    SetIntroPref(checkBox, *) {
        if checkBox.Value { ; Show intro
            try RegDelete(DashRegKey, 'SuppressIntro')
        } else
            RegWrite(true, 'REG_DWORD', DashRegKey, 'SuppressIntro')
    }
    
    KeyPressed(lv, lParam) {
        switch NumGet(lParam, A_PtrSize * 3, "Short") {
        case 0x70: ; F1
            ShowHelpFile()
        }
    }
    
    EnterPressed(*) {
        lv := this["LV"]
        this.ItemClicked(lv, lv.GetNext(,'F'))
    }
    
    ItemClicked(lv, item) {
        switch item && RegExReplace(lv.GetText(item), ' .*') {
        case "New":
            NewScriptGui.Show()
        case "Compile":
            if WinExist("Ahk2Exe ahk_class AutoHotkeyGUI")
                WinActivate
            else if FileExist(ROOT_DIR '\Compiler\Ahk2Exe.exe')
                Run '"' ROOT_DIR '\Compiler\Ahk2Exe.exe"'
            else
                Run Format('"{1}" /script "{2}\install-ahk2exe.ahk"', A_AhkPath, A_ScriptDir)
        case "Help":
            ShowHelpFile()
        case "Window":
            try {
                Run '"' A_MyDocuments '\AutoHotkey\WindowSpy.ahk"'
                return
            }
            static AHK_FILE_WINDOWSPY := 0xFF7A ; 65402
            static WM_COMMAND := 0x111 ; 273
            SendMessage WM_COMMAND, AHK_FILE_WINDOWSPY, 0, A_ScriptHwnd
            if WinWait("Window Spy ahk_class AutoHotkeyGUI",, 1)
                WinActivate
        case "Launch":
            LauncherConfigGui.Show()
        case "Editor":
            DefaultEditorGui.Show()
        }
    }
    
    ItemFocused(lv, item) {
        static WM_CHANGEUISTATE := 0x127 ; 295
        SendMessage WM_CHANGEUISTATE, 0x10001, 0, lv
    }

    UpdateVersion(*) {
        if (RunWait(Format('"{}" /script "{}\install-version.ahk" "{}"', A_AhkPath, A_ScriptDir, this.newVersion))) {
            ; Error installing
        } else {
            this['UpdateLink'].Enabled := false
            this['UpdateBanner'].GetPos(, &top)
            this.Show("h" top)
        }
    }
}

ShowHelpFile() {
    SetWorkingDir ROOT_DIR
    main := Map(), sub := Map()
    other := Map(), other.CaseSense := "off"
    hashes := ReadHashes('UX\installed-files.csv', item => item.Path ~= 'i)\.chm$')
    Loop Files "*.chm", "FR" {
        SplitPath A_LoopFilePath,, &dir,, &name
        if name = "AutoHotkey" {
            if !(f := hashes.Get(A_LoopFilePath, false))
                continue
            v := GetMajor(f.Version)
            if !(cur := main.Get(v, false)) || VerCompare(cur.Version, f.Version) < 0
                main[v] := f
            sub[f.Version] := f
        }
        else
            other[A_LoopFilePath] := name (dir != "" && name != dir ? " (" dir ")" : "")
    }
    
    if sub.Count = 1 && other.Count = 0 {
        for , f in main { ; Don't bother showing online options in this case.
            Run f.Path
            return
        }   
    }
    
    m := Menu()
    if main.Count {
        m.Add "Offline help", (*) => 0
        m.Disable "1&"
    }
    for , f in main {
        m.Add "v&" f.Version, openIt.Bind(f.Path)
        sub.Delete(f.Version)
    }
    if sub.Count {
        subm := Menu()
        for , f in sub
            subm.Insert "1&", "v" f.Version, openIt.Bind(f.Path)
        m.Add "More", subm
    }
    
    m.Add "Online help", (*) => 0
    m.Disable "Online help"
    prefix := main.Count ? "v" : "v&"
    m.Add prefix "1.1", (*) => Run("https://www.autohotkey.com/docs/v1/")
    m.Add prefix "2.0", (*) => Run("https://www.autohotkey.com/docs/v2/")
    
    if other.Count {
        m.Add "Other files", (*) => 0
        m.Disable "Other files"
    }
    for f, t in other
        m.Add t, openIt.Bind(f)
    
    m.Show
    openIt(f, *) => Run(f)
}

; Lookup latest available versions for each minor version
CheckAvailableVersions(successCallback) {
    try {
        req := ComObject('Msxml2.XMLHTTP')
        req.open('GET', 'https://www.autohotkey.com/download/versions.txt', true)
        req.onreadystatechange := readyStateChange
        req.send()
    }
    readyStateChange() {
        if req.readyState != 4
            return
        req.onreadystatechange := ComValue(13,0)
        v := req.status = 200 ? req.responseText : ""
        if v ~= '^(\d\..*\R)+$'
            successCallback(StrSplit(Trim(v, '`r`n'), '`n', '`r'))
    }
}

; Determine whether any one of the available versions is an update
IsUpdateAvailable(verAvailable) {
    inst := Installation()
    inst.ResolveInstallDir()
    verInstalled := inst.GetComponents().maxes
    
    verMax := ""
    for v in verInstalled
        verMax := v

    ; Find a version to suggest:
    ;  - Bug-fix update for an installed minor version
    ;  - New minor version greater than any installed, and not alpha
    verToSuggest := ""
    for v in verAvailable {
        vm := RegExReplace(v, '^\d+\.\d+\b\K.*')
        vi := verInstalled.Get(vm, "")
        if VerCompare(v, '>' vi) && (vi != "" || VerCompare(v, '>' verMax) && VerCompare(v, '>' vm '-b')) {
            verToSuggest := v
            if vi != ""
                break ; Stop at the first version which is a bug-fix update for an installed version
        }
    }

    return verToSuggest
}

AutoHotkeyDashGui.Show()
