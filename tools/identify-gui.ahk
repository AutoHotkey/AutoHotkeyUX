; This is a utility script meant for testing IdentifyBySyntax().
; It scans all .ahk files in a directory and subdirectories, and
; shows the detected version and list of matched subpatterns.
; Double-click a list item to show how each line-group is matched.
#requires AutoHotkey v2.0

#NoTrayIcon

#include ..\inc\identify.ahk

class IdentifyGui extends Gui {
    __new() {
        static width := 780
        super.__new(, "Identify AutoHotkey Version", this)
        this.OnEvent('Escape', (*) => this.Destroy())
        btn := this.AddButton(, "&Browse")
        btn.OnEvent('Click', 'Browse')
        btn.GetPos(,, &btnwidth)
        this.AddEdit('vPath ReadOnly yp w' (width - this.MarginX - btnwidth))
        lv := this.AddListView('vLV r25 xm w' width, ["Name", "Path", "Version", "Reason"])
        lv.OnEvent('DoubleClick', 'ChooseFile')
    }
    Browse(*) {
        this.Opt '+OwnDialogs'
        path := FileSelect('D3')
        this.Opt '-OwnDialogs'
        if path = ''
            return
        this['Path'].Value := path
        this['LV'].Delete()
        start := A_TickCount
        this.ReadFiles(path '\*.ahk')
        MsgBox Format("Read {1} files in {2:.03f} seconds", this['LV'].GetCount(), (A_TickCount - start) / 1000)
    }
    ReadFiles(pattern) {
        lv := this['LV']
        Loop Files pattern, 'FR' {
            try
                i := IdentifyBySyntax(FileRead(A_LoopFileFullPath, 'UTF-8'))
            catch Error as e
                i := {v: '', r: e.Message}
            lv.Add(, A_LoopFileName, A_LoopFileDir, i.v, i.r)
            if A_Index = 1
                lv.ModifyCol()
        }
        Loop 4
            lv.ModifyCol(A_Index, 'AutoHdr')
    }
    Show() {
        super.Show()
        this.Browse()
    }
    ChooseFile(lv, row, *) {
        path := lv.GetText(row, 2) '\' lv.GetText(row, 1)
        ;Run 'edit "' path '"'
        TelltaleGui(path).Show()
    }
}

class TelltaleGui extends Gui {
    __new(filename) {
        static width := 600
        SplitPath filename, &name
        super.__new(, "Telltales for " name, this)
        this.OnEvent('Escape', (*) => this.Destroy())
        this.AddEdit('vEdit ReadOnly w' width, filename)
        this.AddButton(, "&Edit")
            .OnEvent('Click', (*) => Run('edit "' filename '"'))
        this.AddButton('yp', "Open &Folder")
            .OnEvent('Click', (*) => Run('explorer.exe /select,"' filename '"'))
        this.AddListView('vLV xm r25 w' width, ["Mark", "Line", "Match"])
        this.ReadFile(filename)
    }
    ReadFile(filename) {
        lv := this['LV']
        code := FileRead(filename, 'UTF-8')
        static identify_regex := get_identify_regex()
        p := 1, ln := 1
        while RegExMatch(code, identify_regex, &m, p) {
            StrReplace(SubStr(code, p, m.Pos - p), '`n', '`n', true, &lc)
            lv.Add(, m.Mark, ln += lc, m.0)
            StrReplace(m.0, '`n', '`n', true, &lc), ln += lc
            p := m.Pos + m.Len
        }
        Loop lv.GetCount()
            lv.ModifyCol(A_Index, 'AutoHdr')
    }
}

IdentifyGui().Show()