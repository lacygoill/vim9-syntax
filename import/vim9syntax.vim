vim9script

# Functions {{{1
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
# Variables {{{1
# builtin_func {{{2

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

# builtin_func_ambiguous {{{2
# Functions whose names can be confused with Ex commands.
# E.g. `:eval` vs `eval()`.

export const builtin_func_ambiguous: string = ambi->join('\|')

# collation_class {{{2

export const collation_class: string =
    getcompletion('[:', 'help')
        ->filter((_, v) => v =~ '^\[:')
        ->map((_, v) => v->trim('[]:'))
        ->join('\|')

# command_address_type {{{2

export const command_address_type: string =
    getcompletion('com -addr=', 'cmdline')
        ->join('\|')

# command_complete_type {{{2

export const command_complete_type: string =
    getcompletion('com -complete=', 'cmdline')
        ->join('\|')

# command_modifier {{{2

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

export const command_modifier: string = MODIFIER_CMDS
    ->Abbreviate(true)
    ->join('\|')

# command_name {{{2

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

def CommandName(): string
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

    return abbreviated->join()
enddef

export const command_name: string = CommandName()

# default_highlighting_group {{{2

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

# event {{{2

export const event: string =
    getcompletion('', 'event')
        ->join(' ')

# option {{{2

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

# option_terminal {{{2

# terminal options with only word characters
export const option_terminal: string = (
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '^t_\w\w$')
        # `getcompletion()` can miss some terminal options during startup.
        # That's notably the case of `'t_PE'` and `'t_PS'`.
        + ['t_PE', 't_PS']
    )->join()

# option_terminal_special {{{2

# terminal options with at least 1 non-word character
export const option_terminal_special: string =
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '\W')
        ->join('\|')
