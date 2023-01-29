vim9script

# Interface {{{1
export def Derive( # {{{2
        new_group: string,
        from: string,
        new_attrs: dict<any>,
        )
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
#     Derive('CommentUnderlined', 'Comment', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
#
# To define `PopupSign` with the  same attributes as `WarningMsg`, resetting the
# `guibg` or `ctermbg` attributes with the colors of the `Normal` HG:
#
#     Derive('PopupSign', 'WarningMsg', {bg: 'Normal'})
#}}}

    var from_def: dict<any> = hlget(from, true)->get(0,  {})
    if from_def->get('cleared')
        return
    endif
    highlights->add(from_def->extend({name: new_group, default: true})->extend(new_attrs))
    highlights->hlset()

    # Make sure  the derived highlight groups  persist even if the  color scheme
    # changes, and the Vim syntax plugin is not re-sourced.
    autocmd_add([{
        cmd: 'highlights->hlset()',
        event: 'ColorScheme',
        group: 'DeriveHighlightGroups',
        once: true,
        pattern: '*',
        replace: true,
    }])
enddef

var highlights: list<dict<any>>

export def HighlightUserTypes() # {{{2
    var buf: number = bufnr('%')

    # remove existing text properties to start from a clean state
    if prop_type_list({bufnr: buf})->index('vim9_user_type') >= 0
        {types: 'vim9_user_type', bufnr: buf, all: true}
            ->prop_remove(1, line('$'))
    endif
    # add property type
    if prop_type_get('vim9UserType', {bufnr: buf}) == {}
        prop_type_add('vim9UserType', {highlight: 'vim9UserType', bufnr: buf})
    endif

    #    `:help :type`
    #    `:help Vim9-using-interface`
    #    > The interface name can be used as a type:
    var pat: string = '\%(^\||\)\s*\%(type\|\%(export\s\+\)\=interface\)\s\+\zs\u\w*'
    var lines: list<string> = getline(1, '$')
    var user_types: string = lines
        ->copy()
        ->map((_, line: string) => line->matchstr(pat))
        ->filter((_, type: string): bool => type != '')
        ->join('\|')
    if user_types == ''
        return
    endif

    # let's find out the positions of all the user types
    var pos: list<list<number>>
    # iterate over the lines of the buffer
    for [lnum: number, line: string] in lines->items()
        var old_start: number = -1
        # iterate over user types on a given line
        while true
            # look for a user type
            var [user_type: string, start: number, end: number] =
                matchstrpos(line, user_types, old_start + 1)

            # bail out if there aren't (anymore)
            if start == -1
                break
            endif

            # ignore a user type inside a comment or a string
            if InCommentOrString(lnum, start)
                continue
            endif

            # remember  where the  last user  type started  (useful in  the next
            # iteration to find the next user type on the same line)
            old_start = start

            # save position of text property
            pos->add([lnum + 1, start, lnum + 1, end + 1])
        endwhile
    endfor

    # finally, add text properties
    prop_add_list({bufnr: buf, type: 'vim9UserType'}, pos)
enddef
# }}}1
# Util {{{1
def InCommentOrString(lnum: number, col: number): bool # {{{2
    for synID: number in synstack(lnum, col)
        if synIDattr(synID, 'name') =~ '\ccomment\|string\|heredoc'
            return true
        endif
    endfor

    return false
enddef

