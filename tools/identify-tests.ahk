; This file contains automated tests for identify-build.ahk.
#include identify-build.ahk

tests := [

{m: 'remap?', t: [
    'a::b',
    'a::return',
    'a::^!+#enter',
    'a::{'
]},
{m: 'v1-hk', t: [
    'a::`nreturn',
    'a::`n;comment`nreturn',
    '+#k:: `; TODO`nreturn'
]},
{m: 'hotkey', t: [
    'a::`nf(){',
    'a::`n{',
    'a::`n;comment`n{',
    '#+k:: `; TODO`n{'
]},
{m: 'label', t: [
    'label:',
    '  some_label:  ',
    '  some_label:  `;comment'
]},
{m: 'v1-lbl', t: [
    '(label):',
    '^a:'
]},
{m: 'v1-dir', t: [
    '#NoEnv',
    '#IfWinActive Some window.',
    '#InputLevel, 1'
]},
{m: 'v2-dir', t: [
    '#HotIf',
    '#HotIf fun()'
]},
{m: 'dir?', t: [
    '#InputLevel 2',
    '#UseHook'
]},
{m: 'v1-char', t: [
    'Send #e',
    'Run C:\File.ext',
    '$var := 1'
]},
{m: 'exp', t: [
    'local x := y',
    'global x += 1',
    'if (a = b)',
    'if(a = b)',
    'if !a',
    'if a.b = c',
    'fun(a=1)',
    'fun(ByRef, a)',
    'fun(ByRef a)',
    'obj[a]',
    'App.Quit',
    'obj.prop := 1',
    'tern? ar:y',
    'var := value',
    'var += 1',
    '++foo',
    'DllCall("Fn"`n,"int", a)',
    'try fn()',
    '    if DllCall("IsClipboardFormatAvailable", "uint", 15)`n'
    '    && !DllCall("IsClipboardFormatAvailable", "uint", 1) `; CF_TEXT',
    'if (a`nand b)'
]},
{m: 'v1-kw', t: [
    'local.x := y',
    'local x = y',
    'global:=1',
    'global := 2'
]},
{m: 'v2-kw', t: [
    'static methd()'
]},
{m: 'assume', t: [
    'local',
    'global `;comment',
    'Static`n'
]},
{m: 'v1-ref', t: [
    'fun(Byref a){',
    'fun(a, Byref b){',
    'fun(a, Byref b)`n{',
    'fun(a := true, ByRef b:="", c := 1){'
]},
{m: 'v1-def', t: [
    'fun(a=1){',
    'Func(a,b=""){',
    'fun(a,b="", c=1)`n{'
]},
{m: 'v2-ref', t: [
    'fun(&a) {',
    'fun(a,&b){',
    'fun(a:=1, &b:=unset){'
]},
{m: 'v2-vfn', t: [
    'EventHandler(*){',
    'EventHandler(a, arg2, *) {'
]},
{m: 'v1-cmd', t: [
    'MsgBox, Hello'
], f: [
    'Functions := [`nMsgBox,`nInputBox`n]'
]},
{m: 'v1-send', t: ['
(Join','
    Send ^c
    Send a{b 2}c
    Send {{}
    Send {}}
    Send {Esc}
    Send Hello, world{!}
    Send +{enter 2}
)'], f: ['
(Join','
    SendRaw "{Esc}"
    SendRaw '{Esc}'
    SendRaw "^a"
    Send {a:b}.a
    Send {x: {}}
    Send a^b
)']},
{m: 'v1-pct', t: [
    'MsgBox % expression',
    'MsgBox % foo(a)',
    'MsgBox % foo(a, b), % bar',
    'WinSet ExStyle, % newxs, ahk_id %hwnd%'
]},
{m: 'v1-pct', t: ['
(
    MsgBox % a
    Send % b
)', '
(
    MsgBox % a
        , % b
)',
    'Loop % a//b `;%'
]},
{m: 'v2-pct', t: [
    'MsgBox % a %',
    'MsgBox % a, b %',
    'f(a.%b%)',
    'f(% a %)'
], f: [
    'WinSet ExStyle, % newxs, ahk_id %hwnd%'
]},
{m: 'v2-cbe', t: [
    'a(`n)',
    'MsgBox(`n"Text"`n)',
    'x := (`na,`nb`n)'
]},
{m: 'v2-sq', t: [
    "a := 'b'",
    "Run('cmd')",
    'DllCall("Function"`n,' "'int', 1)",
    "return 'string'",
    "x := '`n(`nfoo`n)'"
]},
{m: 'v2-fat', t: [
    'f(a => a)',
    'f() => r',
    'prop[prm] => this.value'
], f: [
    'get => 42',
    'var=>text<'
]},
{m: 'v2-cle', t: [
    'x := y +`nz'
], f: [
    'MsgBox 0,`nSend, Title',
    'x := a ? b :`nMsgBox',
    'a :=`nb()'
]},
; regression tests
{m: 'v2-cbe', t: [], f: [
    '
    (
    if (A
        && B)
        MsgBox
    LButton::
    )'
]},
{v: 0, t: [
    '
    (
        static view := {
            (Join,
                65406: "Lines"
                65407: "Variables"
                65408: "Hotkeys"
                65409: "KeyHistory"
            `)}
    )',
    'x :=`n(`n"foo"`n)',
    'if (a`nand b)'
]},
{v: 2, t: [
    'static prop {'
]},
{v: 1, t: [
    'MsgBox % ""`n . "", a => b'
]},
{v: 1, t: [
   'MsgBox % "Text" `n . "", % "Title"'
]},
{v: 2, t: [
    'MsgBox % "Text" `n . "" % "Title"'
]},
{v: 0, t: [
    'f("a"`n,,"b")'
]},
{v: 2, t: [
    'f("a"`n,,`n"b")'
]},
{v: 0, t: [ ; Regression test for PCRE error -21 (recursion limit)
    'B64 := "iVBORw0KGgoAAAANSUhEUgAAAIAAAAArCAYAAACw5YDmAAABN2lDQ1BBZG9iZSBSR0IgKDE5OTgpAAAokZWPv0rDUBSHvxtFxaFWCOLgcCdRUGzVwYxJW4ogWKtDkq1JQ5ViEm6uf/oQjm4dXNx9AidHwUHxCXwDxamDQ4QMBYvf9J3fORzOAaNi152GUYbzWKt205Gu58vZF2aYAoBOmKV2q3UAECdxxBjf7wiA10277jTG+38yH6ZKAyNguxtlIYgK0L/SqQYxBMygn2oQD4CpTto1EE9AqZf7G1AKcv8ASsr1fBBfgNlzPR+MOcAMcl8BTB1da4Bakg7UWe9Uy6plWdLuJkEkjweZjs4zuR+HiUoT1dFRF8jvA2AxH2w3HblWtay99X/+PRHX82Vun0cIQCw9F1lBeKEuf1UYO5PrYsdwGQ7vYXpUZLs3cLcBC7dFtlqF8hY8Dn8AwMZP/fNTP8gAAAAJcEhZcwAATOUAAEzlAXXO8JUAAAdRaVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJBZG9iZSBYTVAgQ29yZSA1LjYtYzE0MiA3OS4xNjA5MjQsIDIwMTcvMDcvMTMtMDE6MDY6MzkgICAgICAgICI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnhtcD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIiB4bXA6Q3JlYXRvclRvb2w9IkFkb2JlIFBob3Rvc2hvcCAyMi4wIChNYWNpbnRvc2gpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyMC0xMi0wM1QxNzowNzoyMiswOTowMCIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMC0xMi0yM1QxMDo0NzozOC0wNjowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjAtMTItMjNUMTA6NDc6MzgtMDY6MDAiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6ZDFhODJlODYtNmZlYy00ODRiLTg2ZjktYWUzNGI0OWI1Yzk1IiB4bXBNTTpEb2N1bWVudElEPSJhZG9iZTpkb2NpZDpwaG90b3Nob3A6MGUzMTIyZmUtZmZlZS1lZDRiLTk1NDktNjEwOTQyMDhjYjBmIiB4bXBNTTpPcmlnaW5hbERvY3VtZW50SUQ9InhtcC5kaWQ6MDdhODNkOTctNjYzNS00YjQzLTlkYzAtMjVlNjEwYmMxNzViIiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIiBwaG90b3Nob3A6SUNDUHJvZmlsZT0iQWRvYmUgUkdCICgxOTk4KSIgZGM6Zm9ybWF0PSJpbWFnZS9wbmciPiA8eG1wTU06SGlzdG9yeT4gPHJkZjpTZXE+IDxyZGY6bGkgc3RFdnQ6YWN0aW9uPSJjcmVhdGVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjA3YTgzZDk3LTY2MzUtNGI0My05ZGMwLTI1ZTYxMGJjMTc1YiIgc3RFdnQ6d2hlbj0iMjAyMC0xMi0wM1QxNzowNzoyMiswOTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjAgKE1hY2ludG9zaCkiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOmU5NzAwZGVhLWRiMWItNGVkYS1iNzAwLTIzYTIzNTVlZTRiMyIgc3RFdnQ6d2hlbj0iMjAyMC0xMi0wM1QxNzowNzoyMiswOTowMCIgc3RFdnQ6c29mdHdhcmVBZ2VudD0iQWRvYmUgUGhvdG9zaG9wIDIyLjAgKE1hY2ludG9zaCki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"'
]},
{v: 0, t: [
    'if(Key = -1){'
]},
{v: 0, t: [
    'while(Key = -1){'
]},
{v: 0, t: ['::x::`n(`n``:``*``:EntryShortcutHere``:``:EntryHere`n)']},
]

run_tests
run_tests() {
    tests_failed := 0
    for test in tests {
        if test.HasProp('m')
            test_mk(test, test.m)
        if test.HasProp('v')
            test_v(test, test.v)
    }
    test_mk(test, mk) {
        if test.HasProp('t')
        for str in test.t {
            if !RegExMatch(str, classification_regex, &m)
                test_failed('expected ' mk, str)
            else if m.Mark != mk
                test_failed('expected ' mk ', got ' m.Mark, str)
            else while m.Pos + m.Len < StrLen(str)
                if RegExMatch(str, classification_regex, &m, m.Pos + m.Len) && InStr(m.Mark, 'v') && m.Mark != mk
                    test_failed('matched ' mk ', but also ' m.Mark, str)
                else
                    break
        }
        if test.HasProp('f')
        for str in test.f {
            for m in matches(str, classification_regex)
                if m.Mark = mk
                    test_failed('unexpected ' mk, str)
        }
    }
    test_v(test, v) {
        if test.HasProp('t')
        for str in test.t {
            for m in matches(str, classification_regex) {
                if v && InStr(m.Mark, v)
                    continue 2
                else if SubStr(m.Mark,1,1) = 'v' {
                    test_failed('expected v' v ', got ' m.Mark, str)
                    continue 2
                }
            }
            if v
                test_failed('expected v' v, str)
        }
        if test.HasProp('f')
        for str in test.f {
            for m in matches(str, classification_regex) {
                if InStr(m.Mark, v)
                    test_failed('unexpected v' v, str)
            }
        }
    }
    test_failed(reason, str) {
        ++tests_failed
        print 'FAIL`t' reason '`n' RegExReplace(str, 'm)^', '`t')
    }
    if tests_failed
        ExitApp
    else if A_LineFile = A_ScriptFullPath
        print 'all tests passed'
}