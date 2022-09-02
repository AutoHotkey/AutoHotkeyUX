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