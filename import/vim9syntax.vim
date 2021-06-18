vim9script noclear

# Functions {{{1
# Interface {{{2

# Purpose:{{{
#
# Derive a  new syntax group  (`to`) from  an existing one  (`from`), overriding
# some attributes (`newAttributes`).
#}}}
# Usage Examples:{{{
#
#     # create `CommentUnderlined` from `Comment`; override the `term`, `cterm`, and `gui` attributes
#
#         Derive('CommentUnderlined', 'Comment', 'term=underline cterm=underline gui=underline')
#
#     # create `PopupSign` from `WarningMsg`; override the `guibg` or `ctermbg` attribute,
#     # using the colors of the `Normal` HG
#
#         Derive('PopupSign', 'WarningMsg', {bg: 'Normal'})
#}}}

export def Derive( #{{{3
    to: string,
    from: string,
    # TODO(Vim9): `arg_newAttributes: any` → `arg_newAttributes: string|dict<string>`
    arg_newAttributes: any,
)
    var originalDefinition: string = Getdef(from)
    if originalDefinition =~ '\<cleared\>'
        return
    endif
    var originalGroup: string
    # if the `from` syntax group is linked to another group, we need to resolve the link
    if originalDefinition =~ ' links to \S\+$'
        # Why the `while` loop?{{{
        #
        # Well, we don't know how many links there are; there may be more than one.
        # That is, the  `from` syntax group could be linked  to `A`, which could
        # be linked to `B`, ...
        #}}}
        var g: number = 0 | while originalDefinition =~ ' links to \S\+$' && g < 9 | ++g
            var link: string = originalDefinition->matchstr(' links to \zs\S\+$')
            originalDefinition = Getdef(link)
            originalGroup = link
        endwhile
    else
        originalGroup = from
    endif
    var pat: string = '^' .. originalGroup .. '\|xxx'
    var Rep: func = (m: list<string>): string => m[0] == originalGroup ? to : ''
    var newAttributes: string = Getattr(arg_newAttributes)
    exe 'hi '
        .. originalDefinition->substitute(pat, Rep, 'g')
        .. ' ' .. newAttributes

    # We want our derived HG to persist even after we change the color scheme at runtime.{{{
    #
    # Indeed, all  color schemes run `:hi  clear`, which might clear  our custom
    # HG.  So, we need to save some information to reset it when needed.
    #}}}
    #   Ok, but why not saving the `:hi ...` command directly?{{{
    #
    # If we change the color scheme, we want to *re*-derive the HG.
    # For example, suppose we've run:
    #
    #     Derive('Ulti', 'Visual', 'term=bold cterm=bold gui=bold')
    #
    # `Visual`  doesn't  have the  same  attributes  from  one color  scheme  to
    # another.  The next time we change the  color scheme, we can't just run the
    # exact same command as  we did for the previous one.   We need to re-invoke
    # `Derive()` with the same arguments.
    #}}}
    var hg: dict<any> = {to: to, from: from, new: arg_newAttributes}
    if index(derived_hgs, hg) == -1
        derived_hgs += [hg]
    endif
enddef

# We   can't   write   `list<dict<string>>`,   because  we   need   to   declare
# `arg_newAttributes` with the type `any`.
var derived_hgs: list<dict<any>>

augroup ResetDerivedHgWhenColorschemeChanges | au!
    au ColorScheme * ResetDerivedHgWhenColorschemeChanges()
augroup END

def ResetDerivedHgWhenColorschemeChanges()
    for hg in derived_hgs
        Derive(hg.to, hg.from, hg.new)
    endfor
enddef
#}}}2
# Core {{{2
def Getdef(hg: string): string #{{{3
    # Why `split('\n')->filter(...)`?{{{
    #
    # The output of `:hi ExistingHG`  can contain noise in certain circumstances
    # (e.g. `-V15/tmp/log`, `-D`, `$ sudo`...).
    # }}}
    return execute('hi ' .. hg)
        ->split('\n')
        ->filter((_, v: string): bool => v =~ '^' .. hg)[0]
enddef

def Getattr(arg_attr: any): string #{{{3
    # TODO(Vim9): `arg_attr: any` → `arg_attr: string|dict<string>`
    if typename(arg_attr) == 'string'
        return arg_attr
    elseif typename(arg_attr) =~ '^dict'
        var gui: bool = has('gui_running') || &termguicolors
        var mode: string = gui ? 'gui' : 'cterm'
        var attr: string
        var hg: string
        [attr, hg] = items(arg_attr)[0]
        var code: string = hlID(hg)
        ->synIDtrans()
        ->synIDattr(attr, mode)
        if code =~ '^' .. (gui ? '#\x\+' : '\d\+') .. '$'
            return mode .. attr .. '=' .. code
        endif
    endif
    return ''
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
    import
    normal
    set
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

const SPECIAL_CMDS: list<string> = VARIOUS_SPECIAL_CMDS
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
    eval readfile($VIMRUNTIME .. '/doc/options.txt')
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
export const option_terminal: string =
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '^t_\w\w$')
        ->join()

# option_terminal_special {{{2

# terminal options with at least 1 non-word character
export const option_terminal_special: string =
    getcompletion('t_', 'option')
        ->filter((_, v: string): bool => v =~ '\W')
        ->join('\|')
