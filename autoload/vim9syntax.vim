vim9script noclear

# builtin_func {{{1

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

var builtin_func: string

def vim9syntax#BuiltinFunc(): string
    if builtin_func != ''
        return builtin_func
    endif

    builtin_func = getcompletion('', 'function')
        # keep only builtin functions
        ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
        # remove noisy trailing parens
        ->map((_, v: string): string => v->substitute('()\=$', '', ''))
        # if a function name can also be parsed as an Ex command, remove it
        ->filter((_, v: string): bool => ambi->index(v) == - 1)
        ->join(' ')
    return builtin_func
enddef

# builtin_func_ambiguous {{{1
# Functions whose names can be confused with Ex commands.
# E.g. `:eval` vs `eval()`.

var builtin_func_ambiguous: string

def vim9syntax#BuiltinFuncAmbiguous(): string
    if builtin_func_ambiguous != ''
        return builtin_func_ambiguous
    endif

    builtin_func_ambiguous = ambi->join('\|')
    return builtin_func_ambiguous
enddef

# collation_class {{{1

var collation_class: string

def vim9syntax#CollationClass(): string
    if collation_class != ''
        return collation_class
    endif

    collation_class = getcompletion('[:', 'help')
        ->filter((_, v) => v =~ '^\[:')
        ->map((_, v) => v->trim('[]:'))
        ->join('\|')
    return collation_class
enddef

# command_address_type {{{1

var command_address_type: string

def vim9syntax#CommandAddressType(): string
    if command_address_type != ''
        return command_address_type
    endif

    command_address_type = getcompletion('com -addr=', 'cmdline')->join('\|')
    return command_address_type
enddef

# command_complete_type {{{1

var command_complete_type: string

def vim9syntax#CommandCompleteType(): string
    if command_complete_type != ''
        return command_complete_type
    endif

    command_complete_type = getcompletion('com -complete=', 'cmdline')->join('\|')
    return command_complete_type
enddef

# command_modifier {{{1

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

var command_modifier: string

def vim9syntax#CommandModifer(): string
    if command_modifier != ''
        return command_modifier
    endif

    command_modifier = MODIFIER_CMDS
        ->Abbreviate(true)
        ->join('\|')
    return command_modifier
enddef

def Abbreviate(
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

# command_name {{{1

const DEPRECATED_CMDS: list<string> =<< trim END
    append
    change
    insert
    k
    let
    open
    t
END

const VARIOUS_SPECIAL_CMDS: list<string> =<< trim END
    augroup
    autocmd
    command
    doautoall
    doautocmd
    echohl
    export
    global
    highlight
    import
    normal
    set
    setlocal
    substitute
    syntax
    z
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

const EXPECT_EXPR_CMDS: list<string> =<< trim END
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

const SPECIAL_CMDS: list<string> =
      VARIOUS_SPECIAL_CMDS
    + CONTROL_FLOW_CMDS
    + DECLARE_CMDS
    + EXPECT_EXPR_CMDS
    + MAPPING_CMDS

var command_name: string

def vim9syntax#CommandName(): string
    if command_name != ''
        return command_name
    endif

    var to_abbreviate: list<string> = getcompletion('', 'command')
          ->filter((_, v: string): bool => v =~ '^[a-z]')
    for cmd in DEPRECATED_CMDS
      + MODIFIER_CMDS
      # This one is special.{{{
      #
      #     :fina   = :finally
      #     :final  = :final
      #     :finall = :finally
      #
      # As you can see, `:final` uses a slot which it shoudn't.
      # If `:abc`  is the abbreviation of  `:abcdef`, then the same  is true for
      # any command in-between; that is `:abcd` and `:abcde`.
      #
      # Anyway,  because of  this inconsistency,  we need  to handle  `:finally`
      # manually.
      #}}}
      + ['finally']
      + SPECIAL_CMDS
        var i: number = to_abbreviate->index(cmd)
        if i == -1
            continue
        endif
        to_abbreviate->remove(i)
    endfor

    var abbreviated: list<string> = to_abbreviate->Abbreviate()

    abbreviated += [
        # this one is missing from `getcompletion()`
        'addd',
        # as said earlier, this one needs to be handled manually
        'fina[lly]'
    ]

    command_name = abbreviated->join()
    return command_name
enddef

# default_highlighting_group {{{1

var default_highlighting_group: string

def vim9syntax#DefaultHighlightingGroup(): string
    if default_highlighting_group != ''
        return default_highlighting_group
    endif

    var completions: list<string> = getcompletion('hl-', 'help')
        ->map((_, v: string): string => v->substitute('^hl-', '', ''))
    for name in ['Ignore', 'Conceal', 'User1..9']
        var i: number = completions->index(name)
        completions->remove(i)
    endfor
    completions += range(2, 8)->mapnew((_, v: number): string => 'User' .. v)
    default_highlighting_group = completions->join(' ')
    return default_highlighting_group
enddef

# event {{{1

var event: string

def vim9syntax#Event(): string
    if event != ''
        return event
    endif

    event = getcompletion('', 'event')->join(' ')
    return event
enddef

# option {{{1

var option: string

def vim9syntax#Option(): string
    if option != ''
        return option
    endif

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

    option = helptags
        ->map((_, v: string): string => v->trim("*'"))
        ->join()
    return option
enddef

# option_terminal {{{1

# terminal options with only word characters
var option_terminal: string

def vim9syntax#OptionTerminal(): string
    if option_terminal != ''
        return option_terminal
    endif

    option_terminal = (
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '^t_\w\w$')
        # `getcompletion()` can miss some terminal options during startup.
        # That's notably the case of `'t_PE'` and `'t_PS'`.
        + ['t_PE', 't_PS']
    )->join()

    return option_terminal
enddef

# option_terminal_special {{{1

# terminal options with at least 1 non-word character
var option_terminal_special: string

def vim9syntax#OptionTerminalSpecial(): string
    if option_terminal_special != ''
        return option_terminal_special
    endif

    option_terminal_special = getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '\W')
        ->join('\|')
    return option_terminal_special
enddef

