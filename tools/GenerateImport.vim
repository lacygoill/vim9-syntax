vim9script noclear

if $MYVIMRC != ''
    var sfile: string = expand('<sfile>:t')
    var msg: list<string> =<< trim eval END
        This script must be sourced without any custom configuration:

            $ vim -Nu NONE -S {sfile}
    END
    popup_notification(msg, {pos: 'center'})
    finish
endif

# Declarations {{{1

const ABBREV_CMDS: list<string> =<< trim END
    abbreviate
    abclear
    cabbrev
    cabclear
    cnoreabbrev
    cunabbrev
    iabbrev
    iabclear
    inoreabbrev
    iunabbrev
    noreabbrev
    unabbreviate
END

const CONTROL_FLOW_CMDS: list<string> =<< trim END
    if
    else
    elseif
    endif
    for
    endfor
    while
    endwhile
    try
    catch
    finally
    throw
    endtry
    return
    break
    continue
    finish
END

const DECLARE_CMDS: list<string> =<< trim END
    const
    final
    unlet
    var
END

const DEPRECATED_CMDS: list<string> =<< trim END
    append
    change
    insert
    k
    let
    mode
    open
    t
    xit
END

const DO_CMDS: list<string> =<< trim END
    argdo
    bufdo
    cdo
    cfdo
    ldo
    lfdo
    tabdo
    windo
END

#     :vim9cmd echo getcompletion('*map', 'command')->filter((_, v) => v =~ '^[a-z]' && v != 'loadkeymap')
const MAPPING_CMDS: list<string> =<< trim END
    map
    cmap
    imap
    lmap
    nmap
    omap
    smap
    tmap
    vmap
    xmap
    cnoremap
    inoremap
    lnoremap
    nnoremap
    noremap
    onoremap
    snoremap
    tnoremap
    vnoremap
    xnoremap
    cunmap
    iunmap
    lunmap
    nunmap
    ounmap
    sunmap
    tunmap
    unmap
    vunmap
    xunmap
    cmapclear
    imapclear
    lmapclear
    mapclear
    nmapclear
    omapclear
    smapclear
    tmapclear
    vmapclear
    xmapclear
END

#     :helpgrep ^:\%({command}\|{cmd}\)
const MODIFIER_CMDS: list<string> =<< trim END
    aboveleft
    belowright
    botright
    browse
    confirm
    hide
    keepalt
    keepjumps
    keepmarks
    keeppatterns
    leftabove
    legacy
    lockmarks
    noautocmd
    noswapfile
    rightbelow
    sandbox
    silent
    tab
    topleft
    unsilent
    verbose
    vertical
    vim9cmd
END

const VARIOUS_SPECIAL_CMDS: list<string> =<< trim END
    augroup
    autocmd
    command
    cd
    chdir
    lcd
    lchdir
    tcd
    tchdir
    copy
    digraphs
    doautoall
    doautocmd
    echohl
    export
    filetype
    global
    vglobal
    highlight
    import
    lua
    mark
    move
    normal
    python
    python3
    pythonx
    set
    setglobal
    setlocal
    substitute
    syntax
    vimgrep
    vimgrepadd
    lvimgrep
    lvimgrepadd
    wincmd
    z
END

const SPECIAL_CMDS: list<string> =
      ABBREV_CMDS
    + CONTROL_FLOW_CMDS
    + DECLARE_CMDS
    + DEPRECATED_CMDS
    + DO_CMDS
    + MAPPING_CMDS
    + MODIFIER_CMDS
    + VARIOUS_SPECIAL_CMDS

# Util Functions {{{1
def Shorten( #{{{2
    to_shorten: list<string>,
    for_match: bool = false
): list<string>

    var shortened: list<string>
    for cmd: string in to_shorten
        var len: number
        var cannot_be_shortened: bool
        for l: number in strcharlen(cmd)->range()->reverse()
            if l == 0
                continue
            endif
            try
                if cmd->slice(0, l)->fullcommand() != cmd
                    len = l
                    break
                endif
            # E1065: Command cannot be shortened: con
            catch /^Vim\%((\a\+)\)\=:E1065:/
                if l == cmd->strcharlen()
                    cannot_be_shortened = true
                else
                    len = l
                endif
                break
            endtry
        endfor
        if cannot_be_shortened || len == cmd->strcharlen() - 1
            shortened += [cmd]
        else
            shortened += [printf(
                '%s%s[%s]',
                cmd[: len],
                for_match ? '\%' : '',
                cmd[len + 1 :]
            )]
        endif
    endfor
    return shortened
enddef

def AppendSection(what: string, match_rule = false) #{{{2
# `match_rule` is on when we want the import file to join the items in a heredoc
# with `\|`, instead of a space; which is necessary for `:syntax match` rules.

    # The `:if` block decides whether we want to write a simple string or a heredoc.
    # For some tokens, we just want to write a (possibly complex) regex:{{{
    #
    #     export const command_can_be_before: string = '...'
    #}}}
    # For other tokens, we want to write a (possibly long) list of names, via a heredoc:{{{
    #
    #     const builtin_func_list: list<string> =<< trim END
    #         abs
    #         acos
    #         add
    #         ...
    #     END
    #     export const builtin_func: string = builtin_func_list->join()
    #
    # A heredoc makes it  easier to review a list and  check whether it contains
    # anything wrong.  In particular if it's sorted.
    #}}}

    var lines: list<string> = ['', '# ' .. what .. ' {{' .. '{1', '']
    if what->eval()->typename() =~ '^list'
        lines += ['const ' .. what .. '_list: list<string> =<< trim END']
            + eval(what)
                # to suppress `E741: Value is locked: map() argument`
                ->copy()
                ->map((_, v: string): string => '    ' .. v)
            + ['END', '']
            + ['export const ' .. what .. ': string = '
                .. what .. '_list->join(' .. (match_rule ? '"\\|"' : '') .. ')']
    else
        lines += ['export const ' .. what .. ': string = ' .. eval(what)->string()]
    endif
    lines->writefile(IMPORT_FILE, 'a')
enddef

#}}}1
# Exported Variables {{{1
# regexes {{{2
# command_can_be_before {{{3

# This regex should make sure that we're in a position where an Ex command could
# appear right before.
# Warning: Do *not* consume any token.{{{
#
# Only use lookarounds to assert something about the current position.
# If you consume a token, and it turns  out that it's indeed a command, then –
# to highlight it – you'll need to include a syntax group:
#
#     set option=value
#     ^^^
#     vim9Set ⊂ vim9MayBeCmd
#
# This  creates a  stack which  might be  problematic for  a group  defined with
# `nextgroup=`.  Suppose that `B ⊂ A`:
#
#        BBB
#     AAAAAAAAA
#
# And you want `C` to match after `B`, so you define the latter like this:
#
#     syntax ... B ... nextgroup=C
#
# If `C` goes beyond `A`, Vim will extend the latter:
#
#        BBBCCCCCC
#     AAAAAAAAAAAA
#              ^^^
#              extended
#
# That's because Vim  wants `C` to be  contained in `A`, just  like its neighbor
# `B`.  But that fails if `B` has consumed the end of `A`:
#
#           BBB
#     AAAAAAAAA
#             ^
#             ✘
#
# Here, Vim won't match `C` after `B`,  because it would need to extend `A`; but
# it can't, because it has reached its end: there's nothing left to extend.
#
# In practice,  it means  that you  wouldn't be able  to highlight  arguments of
# complex  commands  (like  `:autocmd`  or  `:syntax`).   There  might  be  some
# workarounds,  but  they  come  with  their own  pitfalls,  and  add  too  much
# complexity.
#}}}

const command_can_be_before: string =
    # after a command, we know there must be a whitespace or a newline
       '\%('
       ..     '[ \t\n]\@='
       .. '\|'
       # Special Case: An Ex command in the rhs of a mapping, right after `<ScriptCmd>` or `<Bar>`.
       ..     '\c<\%(bar\|cr\)>'
       .. '\)'
    # but there must *not* be a binary operator
    # Warning: Try not to break the highlighting of a command whose first argument is the register `=`.{{{
    #
    # That's why it's  important to match a  space after `=`; so  that `:put` is
    # correctly highlighted when used to put an expression:
    #
    #     put =1 + 2
    #
    # But not when used as a variable name:
    #
    #     var put: number
    #     put = 1 + 2
    #}}}
    .. '\%('
    ..     '\s*\%([-+*/%]=\|=\s\|=<<\|\.\.=\)'
    .. '\|'
    ..     '\_s*\%('
    ..     '->'
    .. '\|'
    ..     '[-+*/%]'
    # Need to match at least 1 space to avoid breaking the highlighting of a pattern passed as argument to a command.{{{
    #
    # Example:
    #
    #     catch /pattern/
    #
    # This does mean that  the pattern can't start with a space,  but IMO it's a
    # corner case which doesn't warrant a fix  (at least for now).  We can still
    # write `\s` instead.
    #
    #            ✘
    #            v
    #     catch / pattern/
    #     catch /\spattern/
    #            ^^
    #            ✔
    #
    # Or, if we *really* want a space, and not a tab, we can write `[ ]`.
    #
    #     catch /[ ]pattern/
    #            ^^^
    #}}}
    ..     '\%(\s\+\)\@>'
    # necessary to be able to match `source` in `source % | eval 0` or `source % <Bar> eval 0`
    ..     '[^|<]'
    .. '\)'
    .. '\)\@!'

# increment_invalid {{{3

# This regex should match an increment/decrement operator used with an invalid expression.{{{
#
# For example:
#
#     ++Func()
#       ^----^
#         ✘
#}}}

const increment_invalid: string = '\%(++\|--\)'
    # let's assert what should *not* be matched
    .. '\%('
    # from now on, we must describe what *is* valid
    ..     '\%('
    # a simple variable identifier (`++name`)
    ..         '\%([bgstvw]:\)\=\h\w*'
    # or an option name (`++&shiftwidth`)
    ..         '\|'
    ..         '&\%([lg]:\)\=[a-z]\{2,}'
    ..     '\)'
    # it must be at the end of a line, or followed by a bracket/bar/dot{{{
    #
    #     # bracket
    #           v
    #     ++list[0]
    #       ^-----^
    #        ✔
    #
    #     # bar
    #            v
    #     ++name | ...
    #
    #     # dot
    #           v
    #     ++dict.key
    #       ^------^
    #          ✔
    #
    # We don't try to describe what follows the bracket or dot, because it seems
    # too complex.   IOW, our regex  is not perfect,  but should be  good enough
    # most of the time.
    #}}}
    ..     '\s*\_[[|.]'
    .. '\)\@!'

# lambda_start, lambda_end {{{3

# closing paren of arguments:
#
#     var Lambda = (a, b) => a + b
#                       ^

const lambda_end: string = ')'
    # start a lookbehind to assert the presence of the necessary arrow
    .. '\ze'
    # there could be a return type before
    .. '\%(:.\{-}\)\='
    # the arrow
    #     var Lambda = (a, b) => a + b
    #                         ^^
    .. '\s\+=>'

# opening paren of arguments:
#
#     var Lambda = (a, b) => a + b
#                  ^
const lambda_start: string = '('
    # start a lookbehind to assert the presence of arguments
    .. '\ze'
    # start a group to make the arguments optional
    .. '\%('
    # first argument
    .. '\s*\h\w*'
    # what follows can be complex
    .. '\%('
    # for now, we just say that it's not an opening paren
    ..     '[^(]'
    .. '\|'
    # or if it is, it must be preceded by `func` (used as a type)
    ..     '\%(\<func\)\@4<=('
    .. '\)'
    # obviously, the arguments can contain several characters;
    # so, let's repeat this group
    .. '*'
    # Special Case: the first argument might be `..._`.
    # It's a special case because it's not matched by `\h\w*`.
    .. '\|' .. '\s*\.\.\._'
    # all these arguments are optional; the lambda could have none
    .. '\)\='
    .. lambda_end->substitute('\\ze', '', '')
# If you change this regex, make sure the lambda doesn't start from the wrong paren in these lines:{{{
#
#           ✘
#           v
#     l->map((_, v) => ...
#            ^
#            ✔
#
#     ✘
#     v
#     (l1 + l2)->map((_, v) => 0)
#                    ^
#                    ✔
#
#               ✘
#        v-------------v
#     Foo(name)->Bar((v) => v)
#                    ^------^
#                       ✔
#
#                   ✘
#               v--------v
#     substitute(a, b, (m) => '', '')
#                      ^^^
#                       ✔
#
#     range(123)->map((..._) => v + 1)
#                      ^--^
#                      should be highlighted as an argument
#
# Also:
#
#     echo ((): number => 0)()
#               ^----^
#               this should be highlighted as a data type
#
# This is a special case, because the  lambda has no arguments, and is contained
# inside another syntax item (`vim9OperParen`).
#}}}

# logical_not {{{3

# This regex should match most binary operators.

const logical_not: string = '/'
    # Don't highlight `!` when used after a command name:{{{
    #
    #     packadd!
    #            ^
    #
    # Note that we still want to highlight `!` when preceded by a paren:
    #
    #     echo 'aaa' .. (!empty(...) ? ... : ...)
    #                   ^^
    # }}}
    .. '\w\@1<!'
    .. '!'
    # don't break the highlighting of `~`/`=` in `!~`/`!=`
    .. '[~=]\@!'
    # support `!!` which can turn any type of expression into a boolean
    .. '!*'
    .. '/'

# mark_valid {{{3

# This regex should match the names of all valid local marks (without the `'` prefix).
# See `:help mark-motions`; the whole section, down to `:help jump-motions`.

const mark_valid: string = '[a-zA-Z''[\]<>0-9"^.(){}]'

# maybe_dict_literal_key {{{3

# This should  match a sequence  of non-whitespace which  could be written where
# a literal key in a dictionary is expected.
# It should not match a valid key, because we want to highlight possible errors.

const maybe_dict_literal_key: string = '/'
    # Start of positive lookbehind.{{{
    #
    # Actually, it's not entirely correct.  This would be simpler and better:
    #
    #     \%([\n{,]\s*\)\@<=
    #
    # But it would also be more expensive (10x last time I checked).
    # Which doesn't  seem like a  big deal, because the  regex is not  used that
    # often; but still, for the moment, let's try an optimized regex.
    #
    # ---
    #
    # As an example, this lookbehind prevents the highlighting of `2` here:
    #
    #     var d = {
    #         key: 1 ? 2: 3
    #     }
    #
    # But not here:
    #
    #     var d = {
    #         key: 1 ?  2: 3
    #     }
    #
    # Note that both of these snippets are wrong, because `:` should be preceded
    # by a space.  Still, this is a common temporary mistake; when it occurs, it
    # might be distracting to see a token (like a number) wrongly highlighted as
    # a string.
    #}}}
    .. '\%('
    # there must be the start of a line or the start of a dictionary before a key
    ..    '[{\n]'
    .. '\|'
    # Or there must be some space.{{{
    #
    # But if there is, it should not preceded by a non-whitespace, unless it's a
    # comma  (separating items),  a  curly  brace (start  of  dictionary), or  a
    # backslash (continuation line).
    #}}}
    ..    '[^ \t\n,{\\]\@1<!' .. '\s'
    .. '\)\@1<='
    # the key itself
    .. '[^ \t{(''"]\+'
    # There must be a colon and a space afterward for this to have any chance of being a key.
    .. '\ze\%(:\_s\)\@='
    .. '/'

# most_operators {{{3

# This regex should match most binary operators.

const most_operators: string = '"'
    # there must be a space before
    .. '\%(\_s\)\@1<='
    .. '\%('
           # arithmetic operators
    ..     '[-+*/%]'
           # concatenation operator
    ..     '\|' .. '\.\.'
           # logical operators
    ..     '\|' .. '||\|&&'
           # null coalescing operator
    ..     '\|' .. '??'
           # `?` in ternary operator
    ..     '\|' .. '?'
           # bitwise shift operators
    ..     '\|' .. '<<\|>>'
           # comparison operators
    ..     '\|' .. '\%(' .. '[=!]=\|[<>]=\=\|[=!]\~\|is\|isnot' .. '\)'
           # optional modifier to respect or ignore the case
    ..     '[?#]\='
    .. '\)'
    # there must be a whitespace after
    .. '\_s\@='
    # There should be an expression after.{{{
    #
    # But an expression cannot start with a bar, nor with `<`.
    # It's most probably a special argument to some command:
    #
    #         v
    #     Cmd + | eval 0
    #     nnoremap <key> <ScriptCmd>Cmd + <Bar> eval 0<CR>
    #                                   ^
    #}}}
    .. '\%(\s*[|<]\)\@!'
    .. '"'

# pattern_delimiter {{{3

const pattern_delimiter: string =
    # let's discard invalid delimiters
    '[^'
    # Warning: keep this part at the start, so that `-` is not parsed as in `a-z`.
    # Ambiguity with `->` method call.{{{
    #
    # Suppose you have a variable named `g`, to which you apply a method call:
    #
    #     this is not the global command
    #     ✘
    #     v
    #     g->substitute('-', '', '')
    #      ^             ^
    #      ✘             ✘
    #      those are not delimiters around a pattern
    #
    # `g` would be confused with the  global command, and the dashes with delimiters
    # around its pattern.
    #}}}
    .. '-'
    # Ambiguity with assignment operators.{{{
    #
    # Example:
    #
    #     var s: number = 40
    #
    #         pat  rep flags
    #        v---v vvv vv
    #     s /= 20 / 2 / 2
    #       ^     ^   ^
    #       delimiters
    #
    # The last line could be wrongly highlighted as a substitution command.
    # In reality, it's a number assignment which does this:
    #
    #     s /= 20 / 2 / 2
    #     ⇔
    #     s /= 10 / 2
    #     ⇔
    #     s /= 5
    #     ⇔
    #     s = s / 5
    #     ⇔
    #     s = 40 / 5
    #     ⇔
    #     s = 8
    #}}}
    .. '+*/%.'
    # Ambiguity with `:` used as separator between namespace and variable name.{{{
    #
    #     g:pattern:command
    #     g:variable
    #
    # See `:help vim9-gotchas`.
    #
    # Don't try to be smart and find a fix for this.
    # It's trickier than it seems.
    # For example:
    #
    #     g:a+b:command
    #        ^
    #
    # This is a  valid global command, because  there is no ambiguity  with a global
    # variable; thanks to `+` which is a non word character.
    # But watch this:
    #
    #     g:name = {key: 'value'}
    #       ^---------^
    #       this is not a pattern
    #
    # I don't think it's possible for a simple regex to determine the nature of what
    # follows `g:`: a pattern vs a variable name.
    #}}}
    .. ':'
    # Not reliable:{{{
    #
    #     $ vim -Nu NONE +'vim9cmd g #pat# ls'
    #     Pattern not found: pat˜
    #     ✔
    #
    #     $ vim -Nu NONE +'vim9cmd filter #pat# ls'
    #     E476: Invalid command: vim9 filter #pat# ls˜
    #     ✘
    #
    # Besides, let's  be consistent;  if in legacy,  the comment  leader doesn't
    # work, that should remain true in Vim9.
    #}}}
    .. '#'
    # a delimiter cannot be a whitespace (obviously)
    .. ' \t'
    # `:help pattern-delimiter`
    # In Vim9, `"` is still not a valid delimiter:{{{
    #
    #     ['aba bab']->repeat(3)->setline(1)
    #     silent! substitute/nowhere//
    #     :% s"b"B"g
    #     E486: Pattern not found: nowhere˜
    #}}}
    .. '[:alnum:]\"|'
    # end of assertion
    .. ']\@='
    # now we have the guarantee that the next character (whatever it is) is a valid delimiter
    .. '.'
    # We still want to support a few delimiters (especially the popular `/`).{{{
    #
    # But for these,  we need to make  sure that the start of  the pattern won't
    # cause any  trouble.  Mainly, we need  to assert that it  can't be confused
    # with an assignment operator (nor a method call).
    #}}}
    #   We could support `.`, but we don't, because it's too tricky.{{{
    #
    #     .. '\|' .. '\.\%(\.=\s\)\@!'
    #
    # Test against this:
    #
    #     s.key ..= 'xxx'
    #      ^    ^^
    #
    # `s` would be wrongly matched as `:substitute`, and the dots as its pattern delimiters.
    # In reality, `s` is a dictionary.
    #}}}
    .. '\|' .. '->\@!\%(=\s\)\@!'
    .. '\|' .. '[+*/%]\%(=\s\)\@!'

# option_can_be_after {{{3

# This regex should make sure that we're  in a position where a Vim option could
# appear right after.

const option_can_be_after: string = '\%(\%('
    .. '^'
    ..     '\|'
    .. '['
    # Support the increment and decrement operators (`--` and `++`).{{{
    #
    # Example:
    #
    #     ++&l:foldlevel
    #     ^^
    #}}}
    ..     '-+'
    ..     ' \t!(['
    # Support an option after `<ScriptCmd>` or `Bar`.{{{
    #
    # Example:
    #
    #     nnoremap <F3> <ScriptCmd>&operatorfunc = Opfunc<CR>g@
    #                              ^-----------^
    #}}}
    ..     '>'
    .. ']'
    .. '\)\@1<='
    .. '\|'
    # support an expression in an `eval` heredoc
    ..     '{\@1<='
    .. '\)'

# option_modifier {{{3

# This regex should make sure that we're  in a position where a Vim option could
# appear right after.

const option_modifier: string =
    '\%('
    ..     '&\%(vim\)\='
    ..     '\|'
    ..     '[<?!]'
    .. '\)'
    # Necessary to avoid a spurious highlight:{{{
    #
    #     nnoremap <key> <ScriptCmd>set wrap<Bar> eval 0 + 0<CR>
    #                                       ^
    #                                       this is not a modifier which applies to 'wrap';
    #                                       this is the start of the Vim keycode <Bar>
    #}}}
    .. '\%(\_s\||\)\@='

# option_sigil {{{3

# sigil to refer to option value

const option_sigil: string = '&\%([gl]:\)\='

# option_valid {{{3

# This regex  should make sure  that we're matching  valid characters for  a Vim
# option name.

const option_valid: string = '\%('
            # name of regular option
    ..     '[a-z]\{2,}\>'
    .. '\|'
            # name of terminal option
    ..     't_[a-zA-Z0-9#%*:@_]\{2}'
    .. '\)'

# wincmd_valid {{{3

# This regex should make sure that we're giving a valid argument to `:wincmd`.

def WincmdValid(): string
    var cmds: list<string> = getcompletion('^w', 'help')
        ->filter((_, v: string): bool => v =~ '^CTRL-W_..\=$')
        ->map((_, v: string) => v->matchstr('CTRL-W_\zs.*'))
        ->sort()
        ->uniq()

    var one_char_cmds: list<string> = cmds
        ->copy()
        ->filter((_, v: string): bool => v->len() == 1)
    var two_char_cmds: list<string> = cmds
        ->copy()
        ->filter((_, v: string): bool => v->len() == 2)

    # `|` is missing
    one_char_cmds += ['|']

    for problematic: string in ['-', ']']
        one_char_cmds->remove(one_char_cmds->index(problematic))
    endfor

    return '/'
        .. '\s\@1<='
        .. '\%('
        # when including back the valid `-` and `]` commands,
        # we need to make sure they don't break the regex
        ..     '[' .. '-\]' .. one_char_cmds->join('') .. ']'
        .. '\|'
        ..     two_char_cmds->join('\|')
        .. '\)'
        .. '\_s\@='
        .. '/'
enddef

const wincmd_valid: string = WincmdValid()
#}}}2
# names {{{2
# builtin_func {{{3

def Ambiguous(): list<string>
    var cmds: list<string> = getcompletion('', 'command')
        ->filter((_, v: string): bool => v =~ '^[a-z]')
    var funcs: list<string> = getcompletion('', 'function')
        ->map((_, v: string) => v->substitute('()\=', '', '$'))
    var ambiguous: list<string>
    for func: string in funcs
        if cmds->index(func) != -1
            ambiguous->add(func)
        endif
    endfor
    return ambiguous
enddef

const ambiguous: list<string> = Ambiguous()

const builtin_func: list<string> = getcompletion('', 'function')
    # keep only builtin functions
    ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
    # remove noisy trailing parens
    ->map((_, v: string) => v->substitute('()\=$', '', ''))
    # if a function name can also be parsed as an Ex command, remove it
    ->filter((_, v: string): bool => ambiguous->index(v) == - 1)

# builtin_func_ambiguous {{{3

# Functions whose names can be confused with Ex commands.
# E.g. `:eval` vs `eval()`.
const builtin_func_ambiguous: list<string> = ambiguous

# collation_class {{{3

const collation_class: list<string> =
    getcompletion('[:', 'help')
        ->filter((_, v: string): bool => v =~ '^\[:')
        ->map((_, v: string) => v->trim('[]:'))
        ->sort()

# command_address_type {{{3

const command_address_type: list<string> = getcompletion('command -addr=', 'cmdline')

# command_complete_type {{{3

const command_complete_type: list<string> = getcompletion('command -complete=', 'cmdline')

# command_modifier {{{3

const command_modifier: list<string> = MODIFIER_CMDS->Shorten(true)

# command_name {{{3

def CommandName(): list<string>
    var to_shorten: list<string> = getcompletion('', 'command')
          ->filter((_, v: string): bool => v =~ '^[a-z]')
    for cmd: string in SPECIAL_CMDS
        var i: number = to_shorten->index(cmd)
        if i == -1
            continue
        endif
        to_shorten->remove(i)
    endfor

    var shortened: list<string> = to_shorten->Shorten()

    # this one is missing from `getcompletion()`
    shortened += ['addd']

    return shortened
enddef

const command_name: list<string> = CommandName()

# default_highlighting_group {{{3

def DefaultHighlightingGroup(): list<string>
    var completions: list<string> = getcompletion('hl-', 'help')
        ->map((_, v: string) => v->substitute('^hl-', '', ''))
    for name: string in ['Ignore', 'Conceal', 'User1..9']
        var i: number = completions->index(name)
        completions->remove(i)
    endfor
    completions += range(2, 8)->map((_, v: number): string => 'User' .. v)
    return completions->sort()
enddef

const default_highlighting_group: list<string> = DefaultHighlightingGroup()

# event {{{3

const event: list<string> = getcompletion('', 'event')

# ex_special_characters {{{3

# `:help cmdline-special`
const ex_special_characters: list<string> =
    getcompletion(':<', 'help')[1 :]
        ->map((_, v: string) => v->trim(':<>'))

# key_name {{{3

def KeyName(): list<string>
    var completions: list<string> = getcompletion('set <', 'cmdline')
        ->map((_, v: string) => v->trim('<>'))
        ->filter((_, v: string): bool => v !~ '^t_' && v !~ '^F\d\+$')

    # `Nop` and `SID` are missing
    completions->add('Nop')->add('SID')
    # for some reason, `Tab` is suggested twice
    completions->remove(completions->index('Tab'))
    # those keys are special, and need to be handled with dedicated rules
    completions->remove(completions->index('Bar'))
    completions->remove(completions->index('Cmd'))

    return completions->sort()
        + ['F\d\{1,2}']
        #     <F12>
        #      ^^^
        # Need a broad pattern to support special characters:{{{
        #
        #     <C-A>
        #        ^
        #     <C-3>
        #        ^
        #     <C-\>
        #        ^
        #     <C-]>
        #        ^
        #     <C-é>
        #        ^
        #}}}
        + ['.']
enddef

const key_name: list<string> = KeyName()

# option {{{3

def Option(): list<string>
    var helptags: list<string>
    readfile($VIMRUNTIME .. '/doc/options.txt')
        ->join()
        ->substitute('\*''[a-z]\{2,\}''\*',
            (m: list<string>): string => !!helptags->add(m[0]) ? '' : '', 'g')

    var deprecated: list<string> =<< trim END
        *'biosk'*
        *'bioskey'*
        *'consk'*
        *'conskey'*
        *'fe'*
        *'nobiosk'*
        *'nobioskey'*
        *'noconsk'*
        *'noconskey'*
    END

    for opt: string in deprecated
        var i: number = helptags->index(opt)
        if i == -1
            continue
        endif
        helptags->remove(i)
    endfor

    return helptags
        ->map((_, v: string) => v->trim("*'"))
enddef

const option: list<string> = Option()

# option_terminal {{{3

# terminal options with only word characters
const option_terminal: list<string> =
    # getting all terminal options is trickier than it seems;
    # let's use 2 sources to cover as much ground as possible
    (getcompletion('t_', 'option') + getcompletion('t_', 'help'))
        ->filter((_, v: string): bool => v =~ '^t_\w\w$')
        ->sort()
        ->uniq()

# option_terminal_special {{{3

# terminal options with at least 1 non-word character
const option_terminal_special: list<string> =
    (getcompletion('t_', 'option') + getcompletion('t_', 'help'))
        ->map((_, v: string) => v->trim("'"))
        ->filter((_, v: string): bool => v =~ '\W')
        ->sort()
        ->uniq()
#}}}1

const IMPORT_FILE: string = expand('<sfile>:p:h:h') .. '/import/vim9Language.vim'
var header: list<string> =<< trim END
    vim9script

    # DO NOT EDIT THIS FILE DIRECTLY.
    # It is meant to be generated by ./tools/%s
END
header[-1] = header[-1]->substitute('%s', expand('<sfile>:p:t'), '')
header->writefile(IMPORT_FILE)

AppendSection('builtin_func')
AppendSection('builtin_func_ambiguous', true)
AppendSection('collation_class', true)
AppendSection('command_address_type', true)
AppendSection('command_can_be_before')
AppendSection('command_complete_type', true)
AppendSection('command_modifier', true)
AppendSection('command_name')
AppendSection('default_highlighting_group')
AppendSection('event')
AppendSection('ex_special_characters', true)
AppendSection('increment_invalid')
AppendSection('key_name', true)
AppendSection('lambda_end')
AppendSection('lambda_start')
AppendSection('logical_not')
AppendSection('mark_valid')
AppendSection('maybe_dict_literal_key')
AppendSection('most_operators')
AppendSection('option')
AppendSection('option_can_be_after')
AppendSection('option_modifier')
AppendSection('option_sigil')
AppendSection('option_terminal')
AppendSection('option_terminal_special', true)
AppendSection('option_valid')
AppendSection('pattern_delimiter')
AppendSection('wincmd_valid')

execute 'edit ' .. IMPORT_FILE
