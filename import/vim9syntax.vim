vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1

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

export def Derive( #{{{2
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
#}}}1
# Core {{{1
def Getdef(hg: string): string #{{{2
    # Why `split('\n')->filter(...)`?{{{
    #
    # The output of `:hi ExistingHG`  can contain noise in certain circumstances
    # (e.g. `-V15/tmp/log`, `-D`, `$ sudo`...).
    # }}}
    return execute('hi ' .. hg)
        ->split('\n')
        ->filter((_, v: string): bool => v =~ '^' .. hg)[0]
enddef

def Getattr(arg_attr: any): string #{{{2
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

