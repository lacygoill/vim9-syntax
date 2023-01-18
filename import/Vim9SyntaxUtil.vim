vim9script

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

export def Derive(
        new_group: string,
        from: string,
        new_attrs: dict<any>,
        )
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
