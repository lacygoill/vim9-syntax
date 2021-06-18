vim9script noclear

# Config {{{1

const OPTFILE: list<string> = readfile($VIMRUNTIME .. '/doc/options.txt')

# Init {{{1

var event_names: string
var collation_class_names: string
var command_address_names: string
var command_complete_names: string
var command_modifier_names: string
var default_highlighting_group_names: string

var option_names: string
var term_option_names: string
var term_option_names_with_nonkw: string

var builtin_funcnames: string
# list of functions whose names can be confused with Ex commands
# (e.g. `:eval` vs `eval()`)
var ambiguous_funcnames: list<string>
def Ambiguous()
    var cmds: list<string> = getcompletion('', 'command')
        ->filter((_, v: string): bool => v =~ '^[a-z]')
    var funcs: list<string> = getcompletion('', 'function')
        ->map((_, v: string): string => v->substitute('()\=', '', '$'))
    for func in funcs
        if cmds->index(func) != -1
            ambiguous_funcnames->add(func)
        endif
    endfor
enddef
Ambiguous()

var command_names: string

const DEPRECATED_CMDS: list<string> =<< trim END
    append
    change
    insert
    k
    let
    open
    t
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

const NEED_FIX_CMDS: list<string> =<< trim END
    final
    finally
END

# `:s` is a special command.{{{
#
# We need it to be matched with a `:syn match` rule;
# not with a `:syn keyword` one.
# Otherwise, we  wouldn't be  able to  correctly highlight the  `s:` scope  in a
# function's header; that's because a `:syn  keyword` rule has priority over all
# `:syn match` rules, regardless of the orderin which they're installed.
#
# ---
#
# Don't worry, `:s` will be still highlighted thanks to a `:syn match` rule.
#}}}
# Same thing for `:g`, `:if`, ...
const SPECIAL_CMDS: list<string> =<< trim END
    augroup
    autocmd
    doautocmd
    doautoall
    command
    normal
    global
    substitute
    set
    z
    if
    elseif
    endif
    for
    endfor
    try
    catch
    throw
    endtry
    while
    endwhile
    echo
    echoconsole
    echohl
    echomsg
    eval
    execute
    const
    final
    unlet
    var
    import
    export
    syntax
    cmap
    cnoremap
    imap
    inoremap
    lmap
    lnoremap
    nmap
    nnoremap
    noremap
    omap
    onoremap
    smap
    snoremap
    tnoremap
    tmap
    vmap
    vnoremap
    xmap
    xnoremap
    mapclear
    smapclear
    cmapclear
    imapclear
    lmapclear
    nmapclear
    omapclear
    tmapclear
    vmapclear
    xmapclear
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
END

# Functions {{{1
# Interface {{{2
def vim9syntax#getBuiltinFunctionNames(only_ambiguous = false): string #{{{3
    if only_ambiguous
        return ambiguous_funcnames->join('\|')
    endif

    if builtin_funcnames != ''
        return builtin_funcnames
    else
        var builtin_funclist: list<string> = getcompletion('', 'function')
            # keep only builtin functions
            ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
            # remove noisy trailing parens
            ->map((_, v: string): string => v->substitute('()\=$', '', ''))
            # if a function name can also be parsed as an Ex command, remove it
            ->filter((_, v: string): bool => ambiguous_funcnames->index(v) == - 1)

        builtin_funcnames = builtin_funclist->join(' ')
    endif
    return builtin_funcnames
enddef

def vim9syntax#getCollationClassNames(): string #{{{3
    if collation_class_names != ''
        return collation_class_names
    endif
    collation_class_names = getcompletion('[:', 'help')
        ->filter((_, v) => v =~ '^\[:')
        ->map((_, v) => v->trim('[]:'))
        ->join('\|')
    return collation_class_names
enddef

def vim9syntax#getCommandAddressNames(): string #{{{3
    if command_address_names != ''
        return command_address_names
    endif
    command_address_names = getcompletion('com -addr=', 'cmdline')
        ->join('\|')
    return command_address_names
enddef

def vim9syntax#getCommandCompleteNames(): string #{{{3
    if command_complete_names != ''
        return command_complete_names
    endif
    command_complete_names = getcompletion('com -complete=', 'cmdline')
        ->join('\|')
    return command_complete_names
enddef

def vim9syntax#getCommandModifierNames(): string #{{{3
    if command_modifier_names != ''
        return command_modifier_names
    endif
    command_modifier_names = MODIFIER_CMDS
        ->Abbreviate(true)
        ->join('\|')
    return command_modifier_names
enddef

def vim9syntax#getCommandNames(): string #{{{3
    if command_names != ''
        return command_names
    endif

    var to_abbreviate: list<string> = getcompletion('', 'command')
          ->filter((_, v: string): bool => v =~ '^[a-z]')
    for cmd in DEPRECATED_CMDS + MODIFIER_CMDS + NEED_FIX_CMDS + SPECIAL_CMDS
        var i: number = to_abbreviate->index(cmd)
        if i == -1
            continue
        endif
        to_abbreviate->remove(i)
    endfor

    var abbreviated: list<string> = to_abbreviate->Abbreviate()

    var missing: list<string> =<< trim END
        addd
        fina[lly]
        in
    END
    abbreviated += missing

    command_names = abbreviated->join()
    return command_names
enddef

def vim9syntax#getDefaultHighlightingGroupNames(): string #{{{3
    if default_highlighting_group_names != ''
        return default_highlighting_group_names
    endif
    var completions: list<string> = getcompletion('hl-', 'help')
        ->map((_, v: string): string => v->substitute('^hl-', '', ''))
    for name in ['Ignore', 'Conceal', 'User1..9']
        var i: number = completions->index(name)
        completions->remove(i)
    endfor
    completions += range(2, 8)->mapnew((_, v: number): string => 'User' .. v)
    default_highlighting_group_names = completions->join(' ')
    return default_highlighting_group_names
enddef

def vim9syntax#getEventNames(): string #{{{3
    if event_names != ''
        return event_names
    else
        event_names = getcompletion('', 'event')
            ->join(' ')
    endif
    return event_names
enddef

def vim9syntax#getOptionNames(): string #{{{3
    if option_names != ''
        return option_names
    endif

    var helptags: list<string>
    eval OPTFILE
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

    option_names = helptags
        ->map((_, v: string): string => v->trim("*'"))
        ->join()
    return option_names
enddef

def vim9syntax#installTerminalOptionsRules() #{{{3
    if has('vim_starting')
        # We need to  delay the installation of the rules  for terminal options,
        # because not all of them can be given by `getcompletion()` while Vim is
        # starting.
        au VimEnter * InstallTerminalOptionsRules()
    else
        InstallTerminalOptionsRules()
    endif
enddef

def InstallTerminalOptionsRules()
    var args: string = ' contained'
        .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

    exe 'syn keyword vim9IsOption '
        .. GetTerminalOptionNames()
        .. args

    exe 'syn match vim9IsOption '
        .. GetTerminalOptionNames(false)
        .. args
enddef

def GetTerminalOptionNames(keyword_only = true): string
    # terminal options with only keyword characters
    if keyword_only
        if term_option_names != ''
            return term_option_names
        endif
        term_option_names = getcompletion('t_', 'option')
            ->filter((_, v: string): bool => v =~ '^t_\w\w$')
            ->join()
        return term_option_names

    # terminal options with one or several NON-keyword characters
    else

        if term_option_names_with_nonkw != ''
            return term_option_names_with_nonkw
        endif
        var opts: list<string> = getcompletion('t_', 'option')
            ->filter((_, v: string): bool => v =~ '\W')
        term_option_names_with_nonkw = '/\V' .. opts->join('\|') .. '/'
        return term_option_names_with_nonkw
    endif
enddef
#}}}2
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
