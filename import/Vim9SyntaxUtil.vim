vim9script

# Functions {{{1
# Interface {{{2

# Purpose:{{{
#
# Derive  a  new syntax  group  (`new_group`)  from  an existing  one  (`from`),
# overriding some attributes (`new_attrs`).
#}}}
# Usage Examples:{{{
#
# To define `CommentUnderlined` with the same attributes as `Comment`, resetting
# the `term`, `cterm`, and `gui` attributes with the value `underline`:
#
#     Derive('CommentUnderlined', 'Comment', 'term=underline cterm=underline gui=underline')
#
# To define `PopupSign` with the  same attributes as `WarningMsg`, resetting the
# `guibg` or `ctermbg` attributes with the colors of the `Normal` HG:
#
#     Derive('PopupSign', 'WarningMsg', {bg: 'Normal'})
#}}}

export def Derive( #{{{3
    new_group: string,
    from: string,
    new_attrs: any,
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
    var Rep: func = (m: list<string>): string => m[0] == originalGroup ? new_group : ''
    execute 'highlight '
        .. originalDefinition->substitute(pat, Rep, 'g')
        .. ' ' .. Getattr(new_attrs)

    # We want our derived HG to persist even after we change the color scheme at runtime.{{{
    #
    # Indeed, all  color schemes run  `:highlight clear`, which might  clear our
    # custom HG.  So, we need to save some information to reset it when needed.
    #}}}
    #   OK, but why not saving the `:highlight ...` command directly?{{{
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
    var hg: dict<any> = {new_group: new_group, from: from, new: new_attrs}
    if derived_hgs->index(hg) == -1
        derived_hgs += [hg]
    endif
enddef

# We can't  write `list<dict<string>>`, because  we need to  declare `new_attrs`
# with the type `any`.
var derived_hgs: list<dict<any>>

augroup ResetDerivedHgWhenColorschemeChanges
    autocmd!
    autocmd ColorScheme * ResetDerivedHgWhenColorschemeChanges()
augroup END

def ResetDerivedHgWhenColorschemeChanges()
    for hg: dict<any> in derived_hgs
        Derive(hg.new_group, hg.from, hg.new)
    endfor
enddef
#}}}2
# Core {{{2
def Getdef(hg: string): string #{{{3
    # Why `split('\n')->filter(...)`?{{{
    #
    # The output of `:highlight ExistingHG`  can contain noise in certain circumstances
    # (e.g. `-V15/tmp/log`, `-D`, `$ sudo`...).
    # }}}
    return execute('highlight ' .. hg)
        ->split('\n')
        ->filter((_, v: string): bool => v =~ '^' .. hg)[0]
enddef

def Getattr(arg_attr: any): string #{{{3
    if typename(arg_attr) == 'string'
        return arg_attr
    elseif typename(arg_attr) =~ '^dict'
        var gui: bool = has('gui_running')
        var mode: string = gui ? 'gui' : 'cterm'
        var attr: string
        var hg: string
        [attr, hg] = arg_attr->items()[0]
        var code: string = hlID(hg)
            ->synIDtrans()
            ->synIDattr(attr, mode)
        if code =~ '^' .. (gui ? '#\x\+' : '\d\+') .. '$'
            return mode .. attr .. '=' .. code
        endif
    endif
    return ''
enddef
