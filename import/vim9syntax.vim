vim9script

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
    open
    t
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

#     :vim9 echo getcompletion('*map', 'command')->filter((_, v) => v =~ '^[a-z]' && v != 'loadkeymap')
const MAPPING_CMDS: list<string> =<< trim END
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

const MODIFIER_CMDS: list<string> =<< trim END
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

const TAKE_EXPR_CMDS: list<string> =<< trim END
    cexpr
    lexpr
    caddexpr
    laddexpr
    cgetexpr
    lgetexpr
    echo
    echoconsole
    echoerr
    echomsg
    echon
    eval
    execute
END

const VARIOUS_SPECIAL_CMDS: list<string> =<< trim END
    augroup
    autocmd
    command
    doautoall
    doautocmd
    echohl
    export
    filetype
    global
    highlight
    import
    normal
    set
    setglobal
    setlocal
    substitute
    syntax
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
    + TAKE_EXPR_CMDS
    + VARIOUS_SPECIAL_CMDS

# Exported Functions {{{1
# Util {{{2
def Abbreviate( #{{{3
    to_abbreviate: list<string>,
    for_match: bool = false
): list<string>

    var abbreviated: list<string>
    for cmd in to_abbreviate
        var len: number
        for l in strcharlen(cmd)->range()->reverse()
            if l == 0
                continue
            endif
            if cmd->slice(0, l)->fullcommand() != cmd
                len = l
                break
            endif
        endfor
        if len == cmd->strcharlen() - 1
            abbreviated += [cmd]
        else
            abbreviated += [printf(
                '%s%s[%s]',
                cmd[: len],
                for_match ? '\%' : '',
                cmd[len + 1 :]
            )]
        endif
    endfor
    return abbreviated
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
#     syn ... B ... nextgroup=C
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
export const command_can_be_before: string =
    # after a command, we know there must be a whitespace or a newline
       '\%('
       # (possibly after a bang)
       ..     '!\=' .. '[ \t\n]\@='
       .. '\|'
       # Special Case: An Ex command in the rhs of a mapping, right after `<cmd>` or `<bar>`.
       ..     '<\%(bar\|cr\)>'
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
    .. '\%(\s*\%([-+*/%]=\|=\s\|\.\.=\)\|\_s*->\)\@!'

# option_can_be_after {{{3
# This regex should make sure that we're  in a position where a Vim option could
# appear right after.

# We  include  `-` and  `+`  in  the lookbehind  to  support  the increment  and
# decrement operators (`--` and `++`).  Example:
#
#     ++&l:foldlevel
#     ^^
export const option_can_be_after: string = '\%(^\|[-+ \t!([]\)\@1<='

# option_sigil {{{3

# sigil to refer to option value
export const option_sigil: string = '&\%([gl]:\)\='

# option_valid {{{3
# This regex  should make sure  that we're matching  valid characters for  a Vim
# option name.

export const option_valid: string = '\%('
            # name of regular option
    ..     '[a-z]\{2,}\>'
    .. '\|'
            # name of terminal option
    ..     't_[a-zA-Z0-9#%*:@_]\{2}'
    .. '\)'
#}}}2
# names {{{2
# builtin_func {{{3

def Ambiguous(): list<string>
    var cmds: list<string> = getcompletion('', 'command')
        ->filter((_, v: string): bool => v =~ '^[a-z]')
    var funcs: list<string> = getcompletion('', 'function')
        ->map((_, v: string): string => v->substitute('()\=', '', '$'))
    var ambiguous: list<string>
    for func in funcs
        if cmds->index(func) != -1
            ambiguous->add(func)
        endif
    endfor
    return ambiguous
enddef

const ambi: list<string> = Ambiguous()

export const builtin_func: string = getcompletion('', 'function')
    # keep only builtin functions
    ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
    # remove noisy trailing parens
    ->map((_, v: string): string => v->substitute('()\=$', '', ''))
    # if a function name can also be parsed as an Ex command, remove it
    ->filter((_, v: string): bool => ambi->index(v) == - 1)
    ->join(' ')

# builtin_func_ambiguous {{{3
# Functions whose names can be confused with Ex commands.
# E.g. `:eval` vs `eval()`.

export const builtin_func_ambiguous: string = ambi->join('\|')

# collation_class {{{3

export const collation_class: string =
    getcompletion('[:', 'help')
        ->filter((_, v) => v =~ '^\[:')
        ->map((_, v) => v->trim('[]:'))
        ->join('\|')

# command_address_type {{{3

export const command_address_type: string =
    getcompletion('com -addr=', 'cmdline')
        ->join('\|')

# command_complete_type {{{3

export const command_complete_type: string =
    getcompletion('com -complete=', 'cmdline')
        ->join('\|')

# command_modifier {{{3

export const command_modifier: string = MODIFIER_CMDS
    ->Abbreviate(true)
    ->join('\|')

# command_name {{{3

def CommandName(): string
    var to_abbreviate: list<string> = getcompletion('', 'command')
          ->filter((_, v: string): bool => v =~ '^[a-z]')
    for cmd in SPECIAL_CMDS
        var i: number = to_abbreviate->index(cmd)
        if i == -1
            continue
        endif
        to_abbreviate->remove(i)
    endfor

    var abbreviated: list<string> = to_abbreviate->Abbreviate()

    # this one is missing from `getcompletion()`
    abbreviated += ['addd']

    return abbreviated->join()
enddef

export const command_name: string = CommandName()

# default_highlighting_group {{{3

def DefaultHighlightingGroup(): string
    var completions: list<string> = getcompletion('hl-', 'help')
        ->map((_, v: string): string => v->substitute('^hl-', '', ''))
    for name in ['Ignore', 'Conceal', 'User1..9']
        var i: number = completions->index(name)
        completions->remove(i)
    endfor
    completions += range(2, 8)->mapnew((_, v: number): string => 'User' .. v)
    return completions->join(' ')
enddef

export const default_highlighting_group: string = DefaultHighlightingGroup()

# event {{{3

export const event: string =
    getcompletion('', 'event')
        ->join(' ')

# option {{{3

def Option(): string
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

    for opt in deprecated
        var i: number = helptags->index(opt)
        if i == -1
            continue
        endif
        helptags->remove(i)
    endfor

    return helptags
        ->map((_, v: string): string => v->trim("*'"))
        ->join()
enddef

export const option: string = Option()

# option_terminal {{{3

# terminal options with only word characters
export const option_terminal: string = (
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '^t_\w\w$')
        # `getcompletion()` can miss some terminal options during startup.
        # That's notably the case of `'t_PE'` and `'t_PS'`.
        + ['t_PE', 't_PS']
    )->join()

# option_terminal_special {{{3

# terminal options with at least 1 non-word character
export const option_terminal_special: string =
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '\W')
        ->join('\|')
