; This script "builds" the regex pattern used by the launcher, runs tests
; to ensure errors haven't been introduced, and writes identify_regex.ahk.
#requires AutoHotkey v2.0

v1_block_comment := '(?m:^[ `t]*/\*(?:.*\R?)+?(?:[ `t]*\*/|.*\Z))'
    ;#region tests
    assert_match v1_block_comment, '
    (
        ; comment
        /* first line */
        second line
        */
        MsgBox()
        `t/* another
        `t*/
    )', ['
    (
        /* first line */
        second line
        */
    )', '
    (
        `t/* another
        `t*/
    )']
    assert_match v1_block_comment, '/* foo', '/* foo'
    assert_match v1_block_comment, '
    (
        /*
            DetectHiddenWindows, On
    )', '
    (
        /*
            DetectHiddenWindows, On
    )'
    assert_match v1_block_comment, '/* foo */`nbar', '/* foo */`nbar'
    ;#endregion

line_comment := '(?<![^ `t`r`n]);.*'
    ;#region tests
    assert_match line_comment, '
    (
        MsgBox() ; Foo
        x := "; semicolon"
        ; line comment
    )', ['; Foo', '; line comment']
    ;#endregion

skip := '(*SKIP)(?!)'
ws0 := '[ `t]*+'
ws1 := '[ `t]++'
sol_ws := '(?m:^' ws0 ')'
eol := '(?=' ws0 '(?:' line_comment ')?(?m:$))'

; Valid options are actually only checked to exclude it as a continuation line.
; If :: is NOT enclosed in quotes, it can't be a valid expression so is not
; interpreted as continuation, but instead as a hotstring even with invalid options.
; This doesn't take into account that v2 takes the first unescaped :: while v1 takes
; the last :: (except that in a sequence of 3+ colons, it ignores the last : if odd).
hs_label := ':[[:alnum:]\?\*\- ]*:.*(?<!``)::'
hs_label_or_autoreplace := iif('?=:[^\:`r`n]*[xX]', hs_label, hs_label '.*')
    ;#region tests
    assert_match hs_label, ':*:btw::by the way', ':*:btw::'
    assert_match hs_label, ':B0*:abbrev::iation', ':B0*:abbrev::'
    assert_match hs_label, '::foo`:::bar', '::foo:::'
    assert_match hs_label, '::foo:::bar', '::foo:::'
    assert_match 'm)^' hs_label_or_autoreplace, '
    (
        :*:btw::by the way
        :?x*:``:``:::typed_hotkey()
    )', [':*:btw::by the way', ':?x*:``:``:::']
    ;#endregion

hk_key := '(?>\w+|[^ `t`r`n])'
hk_label := '(?:[<>*~$!^+#]*' hk_key '|~?' hk_key ' & ~?' hk_key ')(?i:[ `t]+up)?::'
    ;#region tests
    assert_match sol_ws hk_label, '^!<+>#enter::MsgBox "::"', '^!<+>#enter::'
    assert_match sol_ws hk_label, '~a & b::MsgBox "::"', '~a & b::'
    assert_no_match sol_ws hk_label, 'a & ^b::'
    ;#endregion

; For use inside a character class.
v2_name_chars := '\w[:^ascii:]', v1_name_chars := v2_name_chars '#@$',
v2_operators := '<>=/|^,?:\.+\-*&!~'
v2_op_terminators := v2_operators ' `t()\[\]{}%'
; For reference - any character not included in the previous two is invalid in an expression.
v2_illegal_chars := '#$;@\\\x01-\x08\x0a-\x1f\x7f'
; Character class matching a single character.
v1_name_char := '[' v1_name_chars ']', v2_name_char := '[' v2_name_chars ']'
; A sequence of name chars.
v1_name := v1_name_char '++', v2_name := v2_name_char '++'
    ;#region tests
    assert_match v2_name, 'abc_123 #enter v@r', ['abc_123', 'enter', 'v', 'r']
    assert_match v1_name, 'abc_123 #enter v@r', ['abc_123', '#enter', 'v@r']
    ;#endregion

v1_deref := '%' v1_name '%'
v1_var := '(?>' v1_name '|' v1_deref ')++'
    ;#region tests
    assert_match v1_deref, 'xyz%i% = %val%1', ['%i%', '%val%']
    assert_match v1_var, 'xyz%i% = %val%1', ['xyz%i%', '%val%1']
    ;#endregion

; v1 labels can literally be anything matching this pattern (except directly in a class
; definition, where they're not valid), after hotkeys and hotstrings have been parsed.
; This includes a::b:, :: alone, a=b:, a:=b:, etc.
v1_label := '[^ ,```r`n]+(?<!:):' eol
v2_label := v2_name ':' eol
    ;#region tests
    teststr_label := '
    (
        ^a:
        ^b::
        label:
        :C:hotstring::
        (label):
        it's-a-label:
    )'
    assert_match sol_ws v1_label, teststr_label, ['^a:', 'label:', '(label):', "it's-a-label:"]
    assert_match sol_ws v2_label, teststr_label, 'label:'
    ;#endregion

v1_qstr := '(?>"[^"\r\n]*")+' ; Repeats to handle escape-by-doubling.
v2_qstr := '(?>
    (Join| `
        "(?>[^"`\r\n]|`["'`])*+"
        '(?>[^'`\r\n]|`["'`])*+'(*:v2-sq)
    ))'
    ;#region tests
    assert_match v1_qstr, 'x := "one" . "two""``" "three"', ['"one"', '"two""``"', '"three"']
    assert_match v2_qstr, '"1" "``"" "`'"""' . " '3' '`"' '``''", ['"1"', '"``""', '"`'"', '""', "'3'", "'`"'", "'``''"]
    ;#endregion

v1_expr_framing_chars := '\[\]{}()"'
v2_expr_framing_chars := v1_expr_framing_chars "%'"
    
; This matches a sequence of characters and quoted strings valid in a v2 expression.
; Use with a negative lookahead to detect lines which can't be valid v2 expressions,
; but might have valid v1 *unquoted strings* (e.g. Send #e).
line_of_v2_expr_chars := alt('[' v2_name_chars v2_op_terminators ']++', v2_qstr, '[`'"].*') '*+' eol
    ;#region tests
    assert_match 'm)^' line_of_v2_expr_chars, '
    (
        Clipboard := ""
        Send #e
        Run C:\File.ext
        Run cmd
        $var := 1
    )', ['Clipboard := ""', 'Run cmd']
    ;#endregion

unquoted_send_syntax := ws0 alt(
        '\^',
        alt(
            '(?!\{)[' v2_name_chars v2_op_terminators ']',
            v2_qstr
        ) '*+\{' ws0 alt('\w+', '.') '(?:' ws1 '\w+)?' ws0 '\}'
    )
    ;#region tests
    assert_match 'Send ' unquoted_send_syntax, '
    (
        Send ^c
        Send a^b
        Send a{b 2}c
        Send {a:b}.a
        Send {{}
        Send {}}
        Send {x: {}}
    )', ['Send ^', 'Send a{b 2}', 'Send {{}', 'Send {}}']
    ;#endregion

assign_op := '(?>[\:\+\-\*/\.\|&\^]|<<|>>|//)='

; Returns (?:a|b) - a non-capturing group pattern with alternation.
alt(a, b, p*) {
    r := '(?:' a '|' b
    for v in p
        r .= '|' v
    return r ')'
}

; Returns (*:n), equivalent to (*MARK:n).
mark(n) => '(*:' n ')'
mark_v1(n) => mark('v1-' n)
mark_v2(n) => mark('v2-' n)
end_either(n) => mark(n)
end_v1(n) => mark_v1(n)
end_v2(n) => mark_v2(n)

; Returns (?(c)t|f) - a conditional pattern.
iif(c,t:='',f:='') => '(?(' c ')' t (f='' ? '' : '|' f) ')'

pcre_callout(m,c,p,hs,*) => MsgBox('Callout ' c '`n' m.0 '`n`nin`n' hs)

classification_regex := (
    '(?(DEFINE)'
        '(?<line_comment>' line_comment ')'
        '(?<block_comment>' v1_block_comment ')'
        '(?<eol>(?=' ws0 '(?&line_comment)?(?m:$)))'
        '(?<tosol>'  ; Matches trailing whitespace, blank lines and comments up to the next non-blank line.
            alt(
                '(?&eol).*\R',
                '(?&block_comment)'
            ) '++'
        ')'
        '(?<toeol>'  ; Matches the remainder of the line, excluding trailing whitespace/comment.
            alt('[^ `t`r`n]++', ws0 '(?!(?&eol))') '*+'
        ')'
        '(?<contsec>'
            ws0 '\((?i:Join[^ `t`r`n]*+|(?&line_comment)|[^ `t`r`n()]++|[ `t]++)*+\R'
            '(?:' ws0 '(?!\)).*\R)*+'
            ws0 '\)'
        ')'
        '(?<solcont>'
            ws0 alt(
                ',(?!::| +& )',
                '[' v2_operators '](?![^"`'`r`n]*?' alt('".*?::(?!.*?")', "'.*?::(?!.*?')", '::') ')',
                '(?i:AND|OR)(?=[ `t])'
            )
        ')'
        '(?<eolcont>'  ; Matches if at the end of a line which ends with a v2 continuation operator.
            '(?&eol)' alt(
                '(?<ec_bad>(?<=:=)|(?<=[:,]))',
                '(?<=[' v2_operators '](?<!\+\+|--))',
                '(?<=(?<![' v2_name_chars '\.])(?i:OR|IS|AS|IN))',
                '(?<=(?<![' v2_name_chars '\.])(?i:AND|NOT))',
                '(?<=(?<![' v2_name_chars '\.])(?i:CONTAINS))'
            ) '(?&tosol)' alt('(?&contsec)', iif('ec_bad', '', mark_v2('cle')))
            ; ec_bad: : , := at end of line is excluded from marking v2-cle because some v1
            ;  scripts erroneously omit the right-hand subexpression, but the interpreter is
            ;  permissive enough that it generally has the intended effect.  It still causes
            ;  continuation because otherwise a v2 script using it that way might have
            ;  subsequent lines misidentified.
        ')'
        '(?<v1_cont>'
            '(?&tosol)' alt(
                '(?&solcont)(?&subexp)',  ; Not &exp, as the "caller" of &v1_cont may need to handle ",".
                ws0 ',' ws0 '(?=%)(?&pct)',  ; This handles "% expression", which (?&exp) doesn't match.
                '(?&contsec)(?&ambig)'
            )
        ')'
        '(?<v1_fin>'  ; Eats the remainder of the line and potential v1 continuation lines.
            '(?:.*+(?&v1_cont))*.*+'
        ')'
        '(?<ambig>'  ; As above, but for ambiguous lines.
            ; It could be a v2 expression, so any lines that it would continue onto must also be matched
            ; to avoid falsely identifying expressions like "somevar," on subsequent lines; but override
            ; mark since it's accurate only if the line really is an expression, which is uncertain.
            ; One limitation is that some unambiguous cases are marked as ambiguous, such as when a line
            ; starts with ", % expression".
            alt('(?&exp)', '(?&v1_cont)', '.*+') '++' mark('~')
        ')'
        '(?<pct>'  ; Currently only handles percent-space.
            '(?=%[ `t])'
            alt('(?&subexp)(?&exp)', '(?&v1_fin)' mark_v1('pct'))
        ')'
        '(?<expm>'
            ; This is mostly for debugging, to show that the line was identified as an expression.
            mark('exp') '(?&exp)'
        ')'
        '(?<v1_lines>'  ; Matches the remainder of a v1 line and any potential v1 continuation.
            '(?&toeol)(?:(?&tosol)' alt('(?&solcont)', '(?&contsec)') '(?&v1_lines))?'
        ')'
        '(?<otb>'  ; For v2 continuation purposes, OTB can't be preceded by an operator.
            '(?<![<>=/|^,?:\.*&!~])'
            '(?<!(?<!\+)\+)'
            '(?<!(?<!\-)\-)'
            ws0 '\{(?&eol)'
        ')'
        '(?<enclf>'  ; Separate subroutine works around a PCRE (*MARK) bug.
            '\R' alt('(?&contsec)', '(?!(?&solcont))' mark_v2('cbe'), '')
        ')'
        '(?<encex>'  ; An enclosed expression, allowing continuation.
            alt('[, `t]++', '(?&enclf)', '(?&subexp)', '(?&line_comment)') '*+'
        ')'
        '(?<v2_exm>'  ; Separate subroutine works around a PCRE (*MARK) bug.
            '%'
            ; This has some additional complexity to avoid matching "% foo, % bar"
            ; as a double-deref, but allow "% foo, bar %" where %% acts like ().
            ; The former would be an invalid expression in v2, but % force-expr in v1.
            alt('[^,`r`n;' v2_expr_framing_chars ']*+', ',(?!' ws0 '%)', '(?&subexp)') '*+'
            '%' mark_v2('pct')
            '|'
            '=>' mark_v2('fat')
        ')'
        '(?<subexp>(?:(?!(?&otb))(?&eolcont)?' ws0 alt(
            '[^ `t;,`r`n=' v2_expr_framing_chars ']++', ; Excludes whitespace so there won't be trailing whitespace.
            '\((?&encex)\)',
            '\[(?&encex)\]',
            '\{(?&encex)\}',
            v2_qstr,
            ; This recognizes the most basic form of multi-line single-quoted string,
            ; which should be reasonably safe since interpretation of the end quote is
            ; less dependent on continuation options than in v1:
            "'(?&tosol)(?&contsec)'(*:v2-sq)",
            '(?<!\.)%' v2_name '%', ; v1-safe deref.
            '(?&v2_exm)',
            '=', ; Matched only after considering =>.
            '(?&v1_cont)'
        ) ')++)'
        '(?<exp>(?:(?&subexp)|' ws0 ',|(?&eol))++(?&otb)?)'
    ')') . alt(
    ws0 '(?&line_comment)' skip,
    '(?m:^)[ `t{}]*' alt( ; Start of line
        v1_block_comment skip,
        hk_label alt(
            ; Remapping actually permits the ~$<>* modifiers, but they are just passed to Send.
            ; This also matches some ambiguous cases, but that's fine as we just want to ignore
            ; them (and any legitimate target key): 1) a::CommandOrKey, 2) a::{.
            '[<>*~$!^+#]*' hk_key '(?&eol)' end_either('remap?'),
            ; v2 hotkeys are functions, and require an opening brace or explicit function def
            ; unless they are single-line or stacked with other hotkeys.  Detection of the next
            ; line is kept simple since it's better to leave it unidentified than get it wrong.
            '(?&eol)(?!(?&tosol)' ws0 alt('[\{#]', '.*?::', v2_name '\(') ')' end_v1('hk'),
            end_either('hotkey')
        ),
        hs_label_or_autoreplace end_either('hotstring'),
        v2_label end_either('label'),
        v1_label end_v1('lbl'),
        '#' alt(
            '\w+,',  ; Comma placement not valid in v2.
            ; Check for #NoEnv and #If/#IfWin because they're very common.
            ; Check for #CommentFlag and similar to prevent parsing issues.
            ; Assignments like #NoEnv:=1 aren't ruled out here since they are not valid in v2.
            '(?i:NoEnv|If|CommentFlag|Delimiter|DerefChar|EscapeChar)'
        ) '(?&v1_fin)' end_v1('dir'),
        '#(?i:HotIf)' mark_v2('dir') '(?&exp)?',
        '#(?i:Include(?:Again)?)[ `t]+(?&v1_fin)' end_either('dir'), ; Unamibiguous; does not permit v2-style continuation, but sometimes ends with '>'.
        '#\w+(?![^ `t`r`n])(?&ambig)' end_either('dir?'), ; Ambiguous - "#CommentFlag :=" would be a directive but "#Var :=" would be assignment in v1.
        '(?<=[{}])' skip
    ),
    ws0 alt( ; Statements
        ; Everything in v2 not already handled above must use expression syntax or a subset,
        ; so the presence of an "invalid" character is an easy indicator that this is not a
        ; valid v2 script (we assume it's a valid v1 script).  Doing this early avoids the
        ; need to handle the v1-specific name chars ($@#) in subsequent patterns.
        '(?!' line_of_v2_expr_chars ')(?&v1_fin)' end_v1('char'),
        '(?i:else|try|finally)(?![^ `t`r`n])' ws0 '\{?' skip,  ; Skip these to permit a same-line statement.
        '(?i:return|for|while|until|throw|switch)' ws1 '(?&expm)',
        '(?i:local|global|static)(?!' v1_name_char ')' alt(
            ; Detect 'local x := y' as an expression and call exp to check for ' and =>.
            ; ':=' is required rather than '=', though only for the first var since verifying
            ; the rest would be fairly complicated, and it's not very common to mix operators.
            ws1 v2_name alt(
                '(?=\()(?&exp)' end_v2('kw'),  ; Static method.
                ws0 '\{(?&eol)' end_v2('kw'),  ; Static property.
                '(?!' ws0 '=)(?&expm)'
            ),
            '(?&eol)' end_either('assume'),
            ; The remaining cases are:
            ; - 'local.x', 'local:=1', etc. which are valid in v1 but not v2.
            ; - 'local x = y' which is valid in v1, but v2 requires :=.
            ; - 'local $x := y' would be if not handled by v1-char above.
            '(?&v1_fin)' end_v1('kw')  ; Use of reserved word not valid in v2.
        ),
        '(?i:if)' ws1 alt(  ; Some kind of 'if' other than 'if(without-leading-space)'.
            v1_var alt(
                ; 'if x is y' is not covered here because any valid v1 if-is is also a valid v2 expression.
                ws1 '(?i:not' ws1 ')?(?i:in|contains|between)' ws1 '(?&v1_fin)' end_v1('if'),
                ws0 '(?:[<>]=?|!?=)(?&ambig)'  ; Ambiguous, even for 'if a =' due to EOL continuation.
            ),
            '(?&expm)'
        ),
        v2_name alt( ; Starting with a word
            ws0 '=' alt(  ; Could be v1 literal assignment.
                '>(?&ambig)',  ; Could be v2 => property definition.
                '.*?\?.+?:.*(?&ambig)',  ; Could be v2 ternary.
                '(?&v1_fin)' end_v1('ass')
            ),
            ; For simplicity, the following doesn't permit comments between the parameter list and '{',
            ; and doesn't validate balanced ()[], since ){ or ]{ at the end of the line would be an error
            ; if this isn't a function/property definition.
            '[\(\[](?=.*[\)\]][ `t`r`n]*\{)'  ; Function definition (or invalid).
                '(?:' ws0 v2_name ws0 '(?::=(?&subexp))?' ws0 ',)*+'  ; Skip non-ByRef parameters with optional := default.
                ws0 alt(
                    '(?i:ByRef)' ws1 v2_name_char mark_v1('ref'),
                    '&' mark_v2('ref'),
                    v2_name ws0 '=' mark_v1('def'),
                    '\*' ws0 '[\)\]]' mark_v2('vfn')
                ) '.*',
            '(?='
                '[\(\[\.\?]|'  ; Function or property expression or definition, or method/property call.
                ws0 assign_op  ; Assignment expression.
            ')(?&expm)',
            ',(?&v1_fin)' end_v1('cmd'),  ; Comma not valid in v2, so assume it's a valid v1 command.
            '(?&eol)(?&ambig)',  ; Statement or command with no parameters, but could be followed by continuation.
            ws1 alt(
                unquoted_send_syntax '(?&v1_fin)' end_v1('send'),  ; Something like Send ^c or Send {key}.
                ; Detect % prefix conservatively, skipping past parameters only if they do not
                ; contain ()[]{}%"', since those would affect the meaning of subsequent characters,
                ; but would be dependent on whether the parameter is an expression by default.
                '(?:[^`r`n,' v2_expr_framing_chars ']*+,' ws0 ')*+(?&pct)',
                '(?&ambig)' end_either('cmd?'),  ; Function call statement (v2) or command (v1).
            )
        ),
        alt('\+\+', '--') '(?&expm)',
        ; Evaluation generally shouldn't reach this last rule, but having it ensures the next match
        ; attempt starts at the beginning of the next line or group of lines, not the next character.
        '.(?&ambig)' end_either('!!')
    )
)

#include identify-tests.ahk

if A_LineFile = A_ScriptFullPath {
    ; Write the condensed regex pattern to file.
    ; FileOpen("identify.regex", "w", "UTF-8-RAW").Write(classification_regex)
    rx := classification_regex
    rx := StrReplace(rx, "``", "````")
    rx := StrReplace(rx, "`r", "``r")
    rx := StrReplace(rx, "`n", "``n")
    rx := StrReplace(rx, "`t", "``t")
    FileOpen("..\inc\identify_regex.ahk", "w", "UTF-8-RAW")
        .Write("get_identify_regex() => '`r`n(`r`n" rx "`r`n)'`r`n")
    ; Debug
    code := FileRead('C:\Data\Scripts\Scriptlets\~.ahk')
    for m in matches(code, classification_regex)
        print (m.mark || '?') '`t' RegExReplace(m.0, '\R\K', '`t')
}

matches(s, r) {
    p := 1
    next(&m) {
        if !RegExMatch(s, r, &m, p)
            return false
        p := m.Pos + m.Len
        return true
    }
    return next
}

assert_match(r, h, a:=unset) {
    if !IsSet(a) {
        if !RegExMatch(h, r, &m)
            throw Error("No match", -1)
        return
    }
    if a is String
        a := [a]
    p := 1, i := 0
    while p := RegExMatch(h, r, &m, p) {
        p += m.Len, ++i
        if i > a.Length || a[i] !== m.0
            throw Error("Incorrect match", -1, m.0)
    }
    if i != a.Length
        throw Error("Not matched", -1, a[i+1])
}

assert_no_match(r, h) {
    if RegExMatch(h, r, &m)
        throw Error("Incorrect match", -1, m.0)
}


print(s) {
    try
        FileAppend s "`n", "*"
    catch
        OutputDebug s "`n"
}