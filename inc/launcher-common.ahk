
GetExeInfo(exe) {
    if !(verSize := DllCall("version\GetFileVersionInfoSize", "str", exe, "uint*", 0, "uint"))
        || !DllCall("version\GetFileVersionInfo", "str", exe, "uint", 0, "uint", verSize, "ptr", verInfo := Buffer(verSize))
        throw OSError()
    prop := {Path: exe}
    static Properties := {
        Version: 'FileVersion',
        Description: 'FileDescription',
        ProductName: 'ProductName'
    }
    for propName, infoName in Properties.OwnProps()
        if DllCall("version\VerQueryValue", "ptr", verInfo, "str", "\StringFileInfo\040904b0\" infoName, "ptr*", &p:=0, "uint*", &len:=0)
            prop.%propName% := StrGet(p, len)
        else throw OSError()
    if InStr(exe, '_UIA')
        prop.Description .= ' UIA'
    prop.Version := RegExReplace(prop.Version, 'i)[a-z]{2,}\K(?=\d)', '.') ; Hack-fix for erroneous version numbers (AutoHotkey_H v2.0-beta3-H...)
    return prop
}

IsUsableAutoHotkey(exeinfo) {
    return InStr(exeinfo.Description, 'AutoHotkey') && !(
        InStr(exeinfo.Description, '64') && !A_Is64bitOS ||
        InStr(exeinfo.Description, 'Launcher') 
    )
}

GetMajor(v) {
    Loop Parse, v, '.-+'
        return Integer(A_LoopField)
    throw ValueError('Invalid version number', -1, v)
}
