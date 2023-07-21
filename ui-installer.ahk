#requires AutoHotkey v2.0

#NoTrayIcon
#SingleInstance Off

#include inc\common.ahk
#include inc\ui-base.ahk
#include inc\launcher-common.ahk

class VersionInstallerGui extends AutoHotkeyUxGui {
    availableVersions := []
    installedVersions := Map()

    __new() {
        super.__new('Install AutoHotkey Versions')

        il := IL_Create(,, false)
        IL_Add(il, 'shell32.dll', 297) ; green checkmark

        availableLV := this.addListView('w200 r6 Section vAvailable', ['Latest Versions'])
        DllCall('uxtheme\SetWindowTheme', 'ptr', availableLV.hwnd, 'wstr', 'Explorer', 'ptr', 0)
        availableLV.ModifyCol(1, 'Logical')
        availableLV.SetImageList(il, 1)
        availableLV.OnEvent('ContextMenu', 'Menu')
        availableLV.Add('Icon0', 'Loading...')

        installedLV := this.addListView('wp r6 ys vInstalled', ['Versions Installed'])
        DllCall('uxtheme\SetWindowTheme', 'ptr', installedLV.hwnd, 'wstr', 'Explorer', 'ptr', 0)
        installedLV.ModifyCol(1, 'Logical')
        installedLV.Add('', 'Loading...')

        installedLV.ModifyCol(1, 'Sort AutoHdr')
    }

    ; lookup latest available versions for each minor version
    getAvailableVersions() {
        req := ComObject('Msxml2.XMLHTTP')
        req.open('GET', 'https://www.autohotkey.com/download/versions.txt')
        req.onreadystatechange := handleResponse
        req.send()

        handleResponse() {
            if (req.readyState == 4 && req.status == 200) {
                this.availableVersions := StrSplit(trim(req.responseText, ' `t`r`n'), '`n', '`r')
                this.listAvailableVersions()
            }
        }
    }

    ; display available versions
    listAvailableVersions() {
        this['Available'].Delete()

        for version in this.availableVersions {
            icon := 'Icon' . (this.installedVersions.Has(version))
            this['Available'].Add(icon, version)
        }
    }

    ; Discover and cache installed versions to determine if any of the available versions are already installed
    listInstalledVersions(refresh := false) {
        this.installedVersions.Clear()
        this['Installed'].Delete()

        for exe, info in GetUsableAutoHotkeyExes(refresh) {
            if (!this.installedVersions.Has(info.Version)) {
                this.installedVersions[info.Version] := info.Version
                this['Installed'].Add('', info.Version)
            }
        }
    }

    ; version string and the row number from the available version's listview
    installVersion(v, item) {
        ; is install-version.ahk supposed to pass a non-zero ExitCode to ExitApp when 'abort' is called?
        if (RunWait(Format('"{}" /script "{}\install-version.ahk" "{}"', A_AhkPath, A_ScriptDir, v)) != 0) {
            MsgBox('A problem was encountered while attempting to install AutoHotkey version: ' . v, 'Installation Issue')
        }
        else {
            ; update installed item to show checkmark and update list of intalled versions
            this['Available'].Modify(item, 'Icon1')
            this.listInstalledVersions(true)
        }
    }

    Menu(ctrl, item, IsRightClick, X, Y) {
        if (item) {
            version := this['Available'].GetText(item)
            managerMenu := Menu()
            managerMenu.Add('Install ' . version, (*) => this.installVersion(version, item))
            managerMenu.show(x, y)
        }
    }

    ; override show to automatically lookup versions once gui is shown
    ; didn't want to delay showing the gui due to synchronous operation
    Show(opts?) {
        super.Show(opts?)
        
        this.listInstalledVersions()
        this.getAvailableVersions()
    }
}
