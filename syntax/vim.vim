vim9script

# Credits: Charles E. Campbell <NcampObell@SdrPchip.AorgM-NOSPAM>
# Author of syntax plugin for Vim script legacy.

if (
    exists('b:current_syntax')
    # bail out for a file written in legacy Vim script
    || "\n" .. getline(1, 10)->join("\n") !~ '\n\s*vim9\%[script]\>'
    # Bail out if we're included from another filetype (e.g. `markdown`).{{{
    #
    # Rationale: If we're included, we don't know for which type codeblock.
    # Legacy  or Vim9?   In doubt,  let the  legacy plugin  win, to  respect the
    # principle of least astonishment.
    #}}}
    || &filetype != 'vim'
   )
   # provide an ad-hoc mechanism to let the user bypass the guard
   && !get(b:, 'want_vim9_syntax')
    finish
endif

# Requirement: Any syntax group should be prefixed with `vim9`; not `vim`.{{{
#
# To avoid  any interference from  the legacy syntax plugin,  in case we  load a
# legacy script at some point.
#
# In particular,  we don't want  the color choices we  make for Vim9  scripts to
# affect legacy Vim scripts.
# That could happen if  we use a syntax group name which is  already used in the
# legacy syntax plugin, and we load a Vim9 script file after a legacy Vim script
# file.
#
# Remember that the name  you choose for a syntax group  affects the name you'll
# have  to use  in a  `:highlight  link` command.   And while  syntax items  are
# buffer-local, highlight groups are *global*.
#
# ---
#
# Q: But what if the legacy syntax plugin also uses the `vim9` prefix?
#
# A: That should not be an issue.
#
# If we and the legacy plugin install  the same `vim9Foo` rule, we most probably
# also want the same colors.
#
# For example, right now, the legacy syntax plugin installs these groups:
#
#    - `vim9Comment`
#    - `vim9CommentLine`
#
# There is no good  reason to want different colors between a  Vim9 comment in a
# Vim9 script and a Vim9 comment in a legacy script.  That would be confusing.
#}}}
# Known limitation: The plugin does not highlight legacy functions.{{{
#
# Only the `function` and `endfunction` keywords, as well as legacy comments inside.
# We could support more; we would  need to allow `vim9StartOfLine` to start from
# the `vim9LegacyFuncBody` region:
#
#     syntax region vim9LegacyFuncBody
#         \ start=/\ze\s*(/
#         \ matchgroup=vim9DefKey
#         \ end=/^\s*\<endf\%[unction]/
#         \ contained
#         \ contains=vim9LegacyComment,vim9StartOfLine
#                                      ^-------------^
#
# But we don't do it, because there would be many subtle issues to handle, which
# would make the overall plugin too complex (e.g. literal dictionaries).
# It's not worth the  trouble: we want a plugin which  is easy to read/maintain,
# and performant.
#
# Besides, writing  a legacy function  in a Vim9 script  is a corner  case which
# we'll rarely encounter.  Also, I prefer no highlighting rather than a slightly
# broken one; and the absence of highlighting gives an easy visual clue to avoid
# any confusion between legacy and Vim9 functions.
#
# Finally, dropping the legacy syntax should give us the opportunity to optimize
# the code here and there.
#}}}
# Warning: If you change these syntax group names:{{{
#
#     vim9FuncNameBuiltin
#     vim9IsOption
#     vim9MapModKey
#
# Make sure to update `HelpTopic()` in:
#
#     ~/.vim/pack/mine/opt/doc/autoload/doc/mapping.vim
#}}}

# TODO: Try to extract as many complex regexes into importable items.
# Look for the pattern `^\s*exe\%[cute]`.

# TODO: Try to remove as many `Order:` requirements as possible.
#
# If such a requirement involves 2 rules in the same section, that should be fine.
# But  not  if it  involves  2  rules in  different  sections;  because in  that
# case,  you might  one day  re-order the  sections, and  unknowingly break  the
# requirement.
#
# To remove such a requirement, try to improve some of your regexes.

# TODO: The following  command will give  you the list  of all groups  for which
# there is at least one item matching at the top level:
#
#     $ vim /tmp/md1.md +'let b:want_vim9_syntax = 1 | syntax include @Foo syntax/vim.vim | syntax list @Foo'
#
# Check whether those items should be contained to avoid spurious matches.
# For example, right now, we match backtick expansions at the top level.
# That's wrong; this syntax is only valid where a command expects a filename.
# In the future, make sure it's  contained.  You'll first need to match commands
# expecting file arguments, then those arguments.

# TODO: Some commands accept a `++option` argument.
# Highlight it properly.  Example:
#
#                    as an assignment operator
#                    v
#     edit ++encoding=cp437
#          ^--------^^
#          as a Vim option?
#
# Same thing with `+cmd`.
#
#     :helpgrep ^:.*\[+cmd\]
#     :helpgrep ^:.*\[++opt\]

# TODO:
#                                  should be highlighted as a translated keycode?
#                                  v---v
#     nnoremap <expr> <F3> true ? '<C-A>' : '<C-B>'
#                          ^--^
#                          should be highlighted as an error?
#
# IMO, it's part of a more general issue.
# Mappings  installed from  a Vim9  script should  use the  Vim9 syntax;  that's
# probably what users would expect.  Unfortunately,  mappings are not run in the
# context  of the  script where  they  were defined.   At the  very least,  this
# pitfall should be documented.

# TODO: These command expect a pattern as argument:
#
#     :2match
#     :3match
#     :argdelete
#     :filter
#     :function /
#     :helpgrep
#     :lhelpgrep
#     :match
#     :prof[ile] func {pattern}
#     :prof[ile][!] file {pattern}
#     :sort
#     :tag
#
# Highlight it as a string.

# TODO: Some commands expect another command as argument.
# Highlight the latter properly.

# TODO: Try to simplify the values of all the `contains=` arguments.
# Remove what any cluster or syntax group which is useless.
# Try to use intermediate clusters to  group related syntax groups, and use them
# to reduce the verbosity of some `contains=`.

# TODO: Whenever we've used `syntax case ignore`, should we have enforced a specific case?
# Similar to what we did for the names of autocmds events.


# Imports {{{1

import builtin_func from 'vim9syntax.vim'
import builtin_func_ambiguous from 'vim9syntax.vim'
import collation_class from 'vim9syntax.vim'
import command_address_type from 'vim9syntax.vim'
import command_can_be_before from 'vim9syntax.vim'
import command_complete_type from 'vim9syntax.vim'
import command_modifier from 'vim9syntax.vim'
import command_name from 'vim9syntax.vim'
import default_highlighting_group from 'vim9syntax.vim'
import event from 'vim9syntax.vim'
import ex_special_characters from 'vim9syntax.vim'
import key_name from 'vim9syntax.vim'
import lambda_start from 'vim9syntax.vim'
import lambda_end from 'vim9syntax.vim'
import logical_not from 'vim9syntax.vim'
import mark_valid from 'vim9syntax.vim'
import maybe_dict_literal_key from 'vim9syntax.vim'
import most_operators from 'vim9syntax.vim'
import option from 'vim9syntax.vim'
import option_can_be_after from 'vim9syntax.vim'
import option_sigil from 'vim9syntax.vim'
import option_terminal from 'vim9syntax.vim'
import option_terminal_special from 'vim9syntax.vim'
import option_valid from 'vim9syntax.vim'
import pattern_delimiter from 'vim9syntax.vim'
import wincmd_valid from 'vim9syntax.vim'
#}}}1

# Early {{{1
# These rules need to be sourced early.
# Angle-Bracket Notation {{{2

# This could break the highlighting of an expression in a mapping between `<C-\>e` and `<CR>`.
execute 'syntax match vim9BracketNotation'
    .. ' /\c'
    # opening angle bracket
    .. '<'
    # possible modifiers
    .. '\%([scmad]-\)\{,3}'
    # key name
    .. '\%(' .. key_name .. '\)'
    # closing angle bracket
    .. '>'
    .. '/'
    .. ' contains=vim9BracketKey'
    .. ' nextgroup=vim9SetBracketEqual'
    #     set <Up>=^[OA
    #             ^
    syntax match vim9SetBracketEqual /=[[:cntrl:]]\@=/ contained nextgroup=vim9SetBracketKeycode
    #     set <Up>=^[OA
    #              ^--^
    syntax match vim9SetBracketKeycode /\S\+/ contained

# This could break the highlighting of a command after `<Bar>` (between `<Cmd>` and `<CR>`).
syntax match vim9BracketNotation /\c<Bar>/ contains=vim9BracketKey skipwhite

# This could break the highlighting of a command in a mapping (between `<Cmd>` and `<CR>`).
# Especially if `<Cmd>` is preceded by some key(s).
syntax match vim9BracketNotation /\c<Cmd>/hs=s+1
    \ contains=vim9BracketKey
    \ nextgroup=@vim9CanBeAtStartOfLine,@vim9Range,vim9RangeIntroducer2
    \ skipwhite
    syntax match vim9RangeIntroducer2 /:/ contained nextgroup=@vim9Range,vim9RangeMissingSpecifier1

# let's put this here for consistency
execute 'syntax match vim9ExSpecialCharacters'
    .. ' /\c'
    .. '<'
    ..     '\%('
    ..         ex_special_characters
    ..     '\)'
    .. '>'
    .. '/'
    .. ' contains=vim9BracketKey'

syntax match vim9BracketKey /[<>]/ contained

# Comment {{{2

# This could break the highlighting of a pattern passed as argument to a command.{{{
#
# Example:
#
#     vimgrep #pattern# ...
#             ^
#             this is not the start of an inline comment;
#             this is a delimiter surrounding a regex
#
# This can be avoided  if we install this rule early,  *and* highlight the regex
# with another rule which will come later.
#}}}
syntax match vim9Comment /\s\@1<=#.*$/ contains=@vim9CommentGroup excludenl

# Unbalanced paren {{{2

syntax match vim9OperError /[)\]}]/
# This needs to be installed early because it could break `>` when used as a comparison operator.
# We also want to disallow a hyphen before.{{{
#
# To prevent a  distracting highlighting while we're typing a  method call (wich
# is quite frequent), and we haven't typed yet the name of the function afterward.
#
# Besides, the highlighting would be applied inconsistently.
# That's because, if  the next non-whitespace character is a  head of word (even
# on a different line),  then `->` is parsed as a method call  (even if it's not
# the correct one).
#}}}
syntax match vim9OperError /-\@1<!>/

# :++ / :-- {{{2
# Order: Must come before `vim9AutocmdMod`, to not break `++nested` and `++once`.

# increment/decrement
# The `++` and `--` operators are implemented as Ex commands:{{{
#
#     echo getcompletion('[-+]', 'command')
#     ['++', '--']˜
#
# Which makes sense.  They can only appear at the start of a line.
#}}}
# Don't try to validate the argument.{{{
#
# It seems too tricky.
#
# For example, this is not valid:
#
#     ++Func()
#
# But this is valid:
#
#     var l = [1, 2, 3]
#     ++l[0]
#
# And this too:
#
#     var d = {key: 123}
#     ++d.key
#
# And this too:
#
#     ++&l:shiftwidth
#}}}
syntax match vim9Increment /\%(++\|--\)\h\@=/ contained

# Make sure the argument is valid:{{{
#
#     var n = 123
#     ++n
#       ^
#       ✔
#
#     ++Func()
#           ^^
#           ✘
#}}}
#}}}1

# Range {{{1

syntax cluster vim9Range contains=
    \ vim9RangeDelimiter,
    \ vim9RangeLnumNotation,
    \ vim9RangeMark,
    \ vim9RangeMissingSpecifier2,
    \ vim9RangeNumber,
    \ vim9RangeOffset,
    \ vim9RangePattern,
    \ vim9RangeSpecialSpecifier

# Make sure there is nothing before, to avoid a wrong match in sth like:
#     g:name = 'value'
#      ^
# Warning: If you want to use `\_s`, you need to use a lookbehind.{{{
#
#      ✘
#     vvv
#     \_s:\S\@=
#
#     \_s\@1<=:\S\@=
#     ^------^
#        ✔
#
# Otherwise, it would not  work at the start of a line,  unless the previous one
# is empty.
#}}}
syntax match vim9RangeIntroducer /\%(^\|\s\):\S\@=/
    \ contained
    \ nextgroup=@vim9Range,vim9RangeMissingSpecifier1

    # Sometimes, we might want to add a colon in front of an Ex command, even if it's not necessary.{{{
    #
    # Maybe for the sake of consistency:
    #
    #     :1,2 substitute/.../.../
    #     :3,4 substitute/.../.../
    #     :substitute/.../.../
    #     ^
    #     to get a column of colons
    #
    # Or  maybe  to   remove  an  ambiguity  where  the  next   token  could  be
    # misinterpreted as something else than an Ex command.
    #
    # ---
    #
    # Note that  we assert the presence  of a lowercase character  afterward, so
    # that  we don't  break the  highlighting  of a  colon used  in the  ternary
    # operator `?:`:
    #
    #     var name = test
    #         ? value1
    #         : value2
    #         ^
    #
    # And we don't break a range introducer either:
    #
    #     :% substitute/pat/rep/
    #     ^
    #}}}
    # Order: Must come after `vim9RangeIntroducer`.
    syntax match vim9UnambiguousColon /\s\=:[a-zA-Z]\@=/
        \ contained
        \ nextgroup=@vim9CanBeAtStartOfLine

syntax cluster vim9RangeAfterSpecifier contains=
    \ @vim9CanBeAtStartOfLine,
    \ @vim9Range,
    \ vim9Filter,
    \ vim9RangeMissingSpace

#                     v-----v v-----v
#     command MySort :<line1>,<line2> sort
syntax match vim9RangeLnumNotation /\c<line[12]>/
    \ contained
    \ contains=vim9BracketNotation,vim9UserCmdRhsEscapeSeq
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

execute 'syntax match vim9RangeMark /' .. "'" .. mark_valid .. '/'
    .. ' contained'
    .. ' nextgroup=@vim9RangeAfterSpecifier'
    .. ' skipwhite'

syntax match vim9RangeNumber /\d\+/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syntax match vim9RangeOffset /[-+]\+\d*/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syntax match vim9RangePattern +/[^/]*/+
    \ contained
    \ contains=vim9RangePatternFwdDelim
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite
syntax match vim9RangePatternFwdDelim +/+ contained

syntax match vim9RangePattern +?[^?]*?+
    \ contained
    \ contains=vim9RangePatternBwdDelim
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite
syntax match vim9RangePatternBwdDelim /?/ contained

syntax match vim9RangeSpecialSpecifier /[.$%*]/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syntax match vim9RangeDelimiter /[,;]/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier

# Ex commands {{{1
# Assert where Ex commands can match {{{2

# `vim9GenericCmd` handles most Ex commands.
# But some of  them are special.{{{
#
# Either they  – or one  of their  arguments – need  to be highlighted  in a
# certain way.   For example, `:if`  is a control  flow statement and  should be
# highighted differently than – say – `:delete`.
#
# Similarly, while `:map` is not a  control flow statement, and does not require
# a specific highlighting, its arguments do.
#}}}
# Let's list them in this cluster.
# One of them is not properly highlighted!{{{
#
# First, as mentioned before, make sure it's listed in this cluster.
# Second, make sure it's listed in `SPECIAL_CMDS` in `./import/vim9syntax.vim`.
# So that it's removed from `command_name`, and in turn from the `vim9GenericCmd` rule.
#}}}
syntax cluster vim9IsCmd contains=
    \ @vim9ControlFlow,
    \ vim9AbbrevCmd,
    \ vim9Augroup,
    \ vim9Autocmd,
    \ vim9CmdModifier,
    \ vim9CopyMove,
    \ vim9Declare,
    \ vim9DigraphsCmd,
    \ vim9DoCmds,
    \ vim9Doautocmd,
    \ vim9EchoHL,
    \ vim9Export,
    \ vim9Filetype,
    \ vim9GenericCmd,
    \ vim9Global,
    \ vim9Highlight,
    \ vim9Import,
    \ vim9LetDeprecated,
    \ vim9LuaRegion,
    \ vim9Map,
    \ vim9MarkCmd,
    \ vim9Norm,
    \ vim9PythonRegion,
    \ vim9Set,
    \ vim9Subst,
    \ vim9Syntax,
    \ vim9Unmap,
    \ vim9UserCmdDef,
    \ vim9UserCmdExe,
    \ vim9VimGrep,
    \ vim9Wincmd

# Problem: a token might look like a command, but be something else.{{{
#
# For example:
#
#     var set: bool
#     set = true
#     ^^^
#
# This is not the `:set` command.  This is just a variable.
#}}}
# Solution: Before matching a command, let's match a suitable position.{{{
#
# That is,  in addition to assert  the presence of a  name which is valid  for a
# builtin Ex command (`\<\h\w*\>`), we also want to assert some properties about
# the position at  the end of this name  which are necessary for the  name to be
# parsed as a command; like the presence of a whitespace.
#}}}

# Special Case: Some commands (like `:g` and `:s`) *can* be followed by a non-whitespace.
syntax match vim9MayBeCmd /\%(\<\h\w*\>\)\@=/
    \ contained
    \ nextgroup=vim9Global,vim9Subst

    # General case
    # Order: Must come after the previous rule handling the special case.
    execute 'syntax match vim9MayBeCmd'
        .. ' /\%(\<\h\w*\>' .. command_can_be_before .. '\)\@=/'
        .. ' contained'
        .. ' nextgroup=@vim9IsCmd'

# Now, let's build a cluster containing all groups which can appear at the start of a line.
syntax cluster vim9CanBeAtStartOfLine contains=
    \     vim9Block,
    \     vim9Comment,
    \     vim9Continuation,
    \     vim9FuncCall,
    \     vim9FuncHeader,
    \     vim9Increment,
    \     vim9LegacyFunction,
    \     vim9MayBeCmd,
    \     vim9RangeIntroducer,
    \     vim9UnambiguousColon

# Let's use it in all relevant contexts.   We won't list them all here; only the
# ones which  don't have a  dedicated section (i.e. start  of line, and  after a
# bar).
syntax match vim9StartOfLine /^/
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite
    # This rule  is useful to  disallow some constructs at  the start of  a line
    # where an expression is meant to be written.
    syntax match vim9SOLExpr /^/ contained skipwhite

syntax match vim9CmdSep /|/ skipwhite nextgroup=@vim9CanBeAtStartOfLine

# Generic {{{2

execute 'syntax keyword vim9GenericCmd' .. ' ' .. command_name .. ' contained'

syntax match vim9GenericCmd /\<z[-+^.=]\=\>/ contained

# Special {{{2
# A command is special iff it needs a special highlighting.{{{
#
# For example, `:for` – as a  control flow statement – should be highlighted
# differently than `:delete`.   Same thing for `:autocmd`; not  because it needs
# to be  highlighted differently, but because  some of its arguments  need to be
# highlighted.
#}}}
# Some commands need to be handled as special because of their argument, which can contain problematic characters.{{{
#
# This is the case of `:digraph`, `:normal`, `:mark`, `:wincmd`, ...
#
# Examples:
#
#     mark {
#     normal! >
#     wincmd +
#
# Those could be wrongly highlighted as  operators, or as errors (for unbalanced
# brackets), or break the highlighting of a subsequent command.
#
# The  solution is  to  highlight  these arguments  as  strings,  or as  special
# characters.
#
# In the case of `:normal`, it makes  sense to highlight the command argument as
# a string, because – in effect – that's what it is: a string of characters,
# just like the one we can find in a register after a recording (`:echo @q`).
#
# In the case of `:mark`, it makes  sense to highlight the argument as a special
# character,  because  that's how  we  highlight  a mark  when  used  as a  line
# specifier (in front of an Ex command name).
#}}}

# Autocmd {{{3
# `:augroup` {{{4

# The legacy syntax plugin wraps all the contents of an augroup inside a region.{{{
#
# I think it does  that to highlight a possible error, in case  we wrote the end
# statement without the starting one:
#
#         autocmd ...
#         ...
#     augroup END
#     ^---------^
#        error, because orphan
#}}}
#   We don't.{{{
#
# It creates too many issues and complexity.
# Technically, you can write any statement between the start and end of an augroup.
# That includes, for example, a function.
# But the legacy syntax plugin wrongly handles such a situation:
#
#     augroup Name | autocmd!
#         def Func()
#         ^^^
#         wrongly highlighted as an option (:def is confused with 'def')
#         enddef
#     augroup END
#
# That's because the region doesn't include the right syntax group(s).
# Finding and writing the right ones is cumbersome and brittle.
#
# Besides, the  gain is dubious; I  can't remember the  last time we did  such a
# mistake.
#
# Finally,  it's inconsistent.   Why warning  against  the missing  start of  an
# augroup, but not the missing start of a function?
#
#         eval 0
#     endfunction
#     ^---------^
#     orphan, but still highlighted as a command; not as an error
#
# It's not worth the trouble.
#}}}

syntax match vim9Augroup
    \ /\<aug\%[roup]\ze!\=\s\+\h\%(\w\|-\)*/
    \ contained
    \ nextgroup=vim9AugroupNameEnd
    \ skipwhite

#          v--v
# :augroup Name
# :augroup END
#          ^^^
syntax match vim9AugroupNameEnd /\h\%(\w\|-\)*/ contained

# `:autocmd` {{{4

# :au[tocmd] [group] {event} {pat} [++once] [++nested] {cmd}
syntax match vim9Autocmd /\<au\%[tocmd]\>/
    \ contained
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup,
    \     vim9AutocmdMod
    \ skipwhite

#           v
# :au[tocmd]! ...
syntax match vim9Autocmd /\<au\%[tocmd]\>!/he=e-1
    \ contained
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup
    \ skipwhite

# The trailing whitespace is useful to prevent a correct but still noisy/useless
# match when we simply clear an augroup.
syntax match vim9AutocmdGroup /\S\+\s\@=/
    \ contained
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase
    \ skipwhite

# Special Case: A wildcard can be used for all events.{{{
#
#     autocmd! * <buffer>
#              ^
#
# This is *not* the same syntax token as the pattern which follows an event.
#}}}
syntax match vim9AutocmdAllEvents /\*\_s\@=/
    \ contained
    \ nextgroup=vim9AutocmdPat
    \ skipwhite

syntax match vim9AutocmdPat /\S\+/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine,vim9AutocmdMod
    \ skipwhite

syntax match vim9AutocmdMod /++\%(nested\|once\)/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

# Events {{{4

syntax case ignore
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('event_wrong_case', false)
    execute 'syntax keyword vim9AutocmdEventBadCase' .. ' ' .. event
        .. ' contained'
        .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
        .. ' skipwhite'
    syntax case match
endif
# Order: Must come after `vim9AutocmdEventBadCase`.
execute 'syntax keyword vim9AutocmdEventGoodCase' .. ' ' .. event
    .. ' contained'
    .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
    .. ' skipwhite'
syntax case match

syntax match vim9AutocmdEndOfEventList /,\%(\a\+,\)*\a\+/
    \ contained
    \ contains=vim9AutocmdEventBadCase,vim9AutocmdEventGoodCase
    \ nextgroup=vim9AutocmdPat
    \ skipwhite

# `:doautocmd`, `:doautoall` {{{4

# :do[autocmd] [<nomodeline>] [group] {event} [fname]
# :doautoa[ll] [<nomodeline>] [group] {event} [fname]
syntax keyword vim9Doautocmd do[autocmd] doautoa[ll]
    \ contained
    \ nextgroup=
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup,
    \     vim9AutocmdMod
    \ skipwhite

syntax match vim9AutocmdMod /<nomodeline>/
    \ contained
    \ nextgroup=
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup
    \ skipwhite
#}}}3
# Control Flow {{{3

syntax cluster vim9ControlFlow contains=
    \ vim9BreakContinue,
    \ vim9Conditional,
    \ vim9Finish,
    \ vim9Repeat,
    \ vim9Return,
    \ vim9TryCatch

# :return
syntax keyword vim9Return retu[rn] contained nextgroup=@vim9Expr skipwhite

# :break
# :continue
syntax keyword vim9BreakContinue brea[k] con[tinue] contained skipwhite
# :finish
syntax keyword vim9Finish fini[sh] contained skipwhite

# :if
# :elseif
syntax keyword vim9Conditional if el[seif] contained nextgroup=@vim9Expr skipwhite

# :endif
syntax keyword vim9Conditional en[dif] contained skipwhite

# :for
syntax keyword vim9Repeat fo[r]
    \ contained
    \ skipwhite
    \ nextgroup=vim9RepeatForVar,vim9RepeatForVarList
    \ skipwhite

# :for [name, ...]
#      ^---------^
syntax region vim9RepeatForVarList
    \ matchgroup=vim9Sep
    \ start=/\[/
    \ end=/]/
    \ contained
    \ contains=@vim9DataTypeCluster,vim9RepeatForVar
    \ nextgroup=vim9RepeatForIn
    \ oneline
    \ skipwhite

# :for name
#      ^--^
syntax match vim9RepeatForVar /\h\w*/
    \ contained
    \ nextgroup=vim9DataType,vim9RepeatForIn
    \ skipwhite

# for name in
#          ^^
syntax keyword vim9RepeatForIn in contained

# :while
syntax keyword vim9Repeat wh[ile] contained skipwhite nextgroup=@vim9Expr

# :endfor
# :endwhile
syntax keyword vim9Repeat endfo[r] endw[hile] contained skipwhite

# :try
# :endtry
syntax keyword vim9TryCatch try endt[ry] contained

# :throw
syntax keyword vim9TryCatch th[row] contained nextgroup=@vim9Expr skipwhite

# :finally
# We can't write `:syntax keyword ...  fina[lly]`, because it would break `:final`,
# which has a different meaning.
syntax match vim9TryCatch /\<\%(fina\|finall\|finally\)\>/ contained

# :catch
syntax match vim9TryCatch /\<cat\%[ch]\>/ contained nextgroup=vim9TryCatchPattern skipwhite
execute 'syntax region vim9TryCatchPattern'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' contains=vim9TryCatchPatternDelim'
    .. ' oneline'

# Declaration {{{3

syntax keyword vim9Declare cons[t] final unl[et] var
    \ contained
    \ nextgroup=vim9ListUnpackDeclaration,vim9ReservedNames
    \ skipwhite

# NOTE: In the legacy syntax plugin, `vimLetHereDoc` contains `vimComment` and `vim9Comment`.{{{
#
# That's wrong.
#
# It causes  any text  following a double  quote at  the start of  a line  to be
# highlighted as a Vim comment.  But that's  not a comment; that's a part of the
# heredoc; i.e. a string.
#
# Besides, we apply various styles inside comments, such as bold or italics.
# It would be unexpected and distracting to see those styles in a heredoc.
#}}}
syntax region vim9HereDoc
    \ matchgroup=vim9Declare
    \ start=/\s\@1<==<<\s\+\%(trim\>\)\=\s*\z(\L\S*\)/
    \ end=/^\s*\z1$/

# Modifier {{{3

execute 'syntax match vim9CmdModifier'
    .. ' /\<\%(' .. command_modifier .. '\)\>/'
    .. ' contained'
    .. ' nextgroup=@vim9CanBeAtStartOfLine,vim9CmdBang'
    .. ' skipwhite'

syntax match vim9CmdBang /!/ contained nextgroup=@vim9CanBeAtStartOfLine skipwhite

# User {{{3
# Definition {{{4
# :command {{{5

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would break the highlighting of a possible following bang.
syntax match vim9UserCmdDef /\<com\%[mand]\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

syntax match vim9UserCmdDef /\<com\%[mand]\>!/he=e-1
    \ contained
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# error handling {{{5
# Order: should come before highlighting valid attributes.

syntax cluster vim9UserCmdAttrb contains=
    \ vim9UserCmdAttrbEqual,
    \ vim9UserCmdAttrbError,
    \ vim9UserCmdAttrbErrorValue,
    \ vim9UserCmdAttrbName,
    \ vim9UserCmdLhs

# Order: should come before the next rule highlighting errors in attribute names
# An attribute error should not break the highlighting of the following attributes.{{{
#
# Example1:
#
#     command -addrX=other -nargs=1 Cmd Func()
#                  ^       ^-----------------^
#                  ✘       highlighting should still work, in spite of the previous typo
#                  typo
#
# Example2:
#
#     command -nargs=123 -buffer Cmd Func()
#                     ^^ ^----------------^
#                     ✘  highlighting should still work, in spite of the previous error
#                     error
#}}}
syntax match vim9UserCmdAttrbErrorValue /\S\+/
    \ contained
    \ nextgroup=vim9UserCmdAttrbName
    \ skipwhite

# an invalid attribute name is an error
syntax match vim9UserCmdAttrbError /-[^ \t=]\+/
    \ contained
    \ contains=vim9UserCmdAttrbName
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# boolean attributes {{{5

syntax match vim9UserCmdAttrbName /-\%(bang\|bar\|buffer\|register\)\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# attributes with values {{{5
# = {{{6

syntax match vim9UserCmdAttrbEqual /=/ contained

# -addr {{{6

syntax match vim9UserCmdAttrbName /-addr\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbAddress,vim9UserCmdAttrbErrorValue

execute 'syntax match vim9UserCmdAttrbAddress'
    .. ' /=\%(' .. command_address_type .. '\)\>/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrbEqual'
    .. ' nextgroup=@vim9UserCmdAttrb'
    .. ' skipwhite'

# -complete {{{6

syntax match vim9UserCmdAttrbName /-complete\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbComplete,vim9UserCmdAttrbErrorValue

# -complete=arglist
# -complete=buffer
# -complete=...
execute 'syntax match vim9UserCmdAttrbComplete'
    .. ' /'
    ..     '=\%(' .. command_complete_type .. '\)'
    .. '/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrbEqual'
    .. ' nextgroup=@vim9UserCmdAttrb'
    .. ' skipwhite'

# -complete=custom,Func
# -complete=customlist,Func
syntax match vim9UserCmdAttrbComplete /=custom\%(list\)\=,\%([gs]:\)\=\%(\w\|[#.]\)*/
    \ contained
    \ contains=vim9UserCmdAttrbEqual,vim9UserCmdAttrbComma
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

syntax match vim9UserCmdAttrbComma /,/ contained

# -count {{{6

syntax match vim9UserCmdAttrbName /-count\>/
    \ contained
    \ nextgroup=
    \     @vim9UserCmdAttrb,
    \     vim9UserCmdAttrbCount,
    \     vim9UserCmdAttrbErrorValue
    \ skipwhite

syntax match vim9UserCmdAttrbCount
    \ /=\d\+/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrbEqual
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# -nargs {{{6

syntax match vim9UserCmdAttrbName /-nargs\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbNargs,vim9UserCmdAttrbErrorValue

syntax match vim9UserCmdAttrbNargs
    \ /=[01*?+]/
    \ contained
    \ contains=vim9UserCmdAttrbEqual,vim9UserCmdAttrbNargsNumber
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

syntax match vim9UserCmdAttrbNargsNumber /[01]/ contained

# -range {{{6

# `-range` is a special case:
# it can accept a value, *or* be used as a boolean.
syntax match vim9UserCmdAttrbName /-range\>/
    \ contained
    \ nextgroup=
    \     @vim9UserCmdAttrb,
    \     vim9UserCmdAttrbErrorValue,
    \     vim9UserCmdAttrbRange
    \ skipwhite

syntax match vim9UserCmdAttrbRange /=\%(%\|-\=\d\+\)/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrbEqual
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite
#}}}5
# lhs {{{5

syntax match vim9UserCmdLhs /\u\w*/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

# escape sequences in rhs {{{5

# We should limit this match to the rhs of a user command.{{{
#
# But that would add too much complexity, so we don't.
# Besides, it's unlikely we would write something like `<line1>` outside the rhs
# of a user command.
#}}}
execute 'syntax match vim9UserCmdRhsEscapeSeq'
    .. ' /'
    .. '<'
    .. '\%(q-\)\='
    # `:help <line1>`
    .. '\%(line[12]\|range\|count\|bang\|mods\|reg\|args\|f-args\|f-mods\)'
    .. '>'
    .. '/'
    .. ' contains=vim9BracketKey'
#}}}4
# Execution {{{4

syntax match vim9UserCmdExe /\u\w*/ contained nextgroup=vim9SpaceExtraAfterFuncname

# This lets Vim highlight the name of an option and its value, when we set it with `:CompilerSet`.{{{
#
#     CompilerSet mp=pandoc
#                 ^-------^
#
# See: `:help :CompilerSet`
#}}}
# But it breaks the highlighting of `:CompilerSet`.  It should be highlighted as a *user* command!{{{
#
# No, it should not.
# The fact  that its name  starts with  an uppercase does  not mean it's  a user
# command.  It's definitely not one:
#
#     :command CompilerSet
#     No user-defined commands found˜
#}}}
syntax keyword vim9Set CompilerSet contained nextgroup=vim9MayBeOptionSet skipwhite
#}}}3
# :copy / :move {{{3
# These commands need a special treatment because of the address they receive as argument.{{{
#
#     move '>+1
#           ^
#           if we highlight unbalanced brackets as error, this one should be ignored;
#           it's not an error;
#           it's a valid mark
#}}}

syntax keyword vim9CopyMove m[ove] co[py] contained nextgroup=@vim9Range skipwhite

# `:digraphs` {{{3

syntax keyword vim9DigraphsCmd dig[raphs]
    \ contained
    \ nextgroup=
    \     vim9DigraphsCharsInvalid,
    \     vim9DigraphsCharsValid,
    \     vim9DigraphsCmdBang
    \ skipwhite

syntax match vim9DigraphsCharsInvalid /\S\+/
    \ contained
    \ nextgroup=vim9DigraphsNumber
    \ skipwhite
    syntax match vim9DigraphsCmdBang /!/ contained

# A valid "characters" argument is any sequence of 2 non-whitespace characters.
# Special Case:  a bar must  be escaped,  so that it's  not parsed as  a command
# termination.
syntax match vim9DigraphsCharsValid /\s\@<=\%([^ \t|]\|\\|\)\{2}\_s\@=/
    \ contained
    \ nextgroup=vim9DigraphsNumber
    \ skipwhite
syntax match vim9DigraphsNumber /\d\+/
    \ contained
    \ nextgroup=vim9DigraphsCharsInvalid,vim9DigraphsCharsValid
    \ skipwhite

# `:*do` {{{3

syntax keyword vim9DoCmds argdo bufdo cdo cfdo ld[o] lfdo tabd[o] windo
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

# :echohl {{{3

syntax keyword vim9EchoHL echoh[l]
    \ contained
    \ nextgroup=vim9EchoHLNone,vim9Group,vim9HLGroup
    \ skipwhite

syntax case ignore
syntax keyword vim9EchoHLNone none contained
syntax case match

# :filetype {{{3

syntax match vim9Filetype /\<filet\%[ype]\%(\s\+\I\i*\)*/
    \ contained
    \ contains=vim9FTCmd,vim9FTError,vim9FTOption
    \ skipwhite

syntax match vim9FTError /\I\i*/ contained
syntax keyword vim9FTCmd filet[ype] contained
syntax keyword vim9FTOption detect indent off on plugin contained

# :global {{{3

# without a bang
execute 'syntax match vim9Global'
    .. ' /\<g\%[lobal]\>\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'
    .. ' skipwhite'

# with a bang
execute 'syntax match vim9Global'
    .. ' /\<g\%[lobal]\>!\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/he=e-1'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'
    .. ' skipwhite'

# vglobal/pat/cmd
execute 'syntax match vim9Global'
    .. ' /\<v\%[global]\>\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'

execute 'syntax region vim9GlobalPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' nextgroup=@vim9CanBeAtStartOfLine'
    .. ' oneline'
    .. ' skipwhite'

# :highlight {arguments} {{{3
# :highlight {{{4

syntax cluster vim9HighlightCluster contains=
    \ vim9Comment,
    \ vim9HiClear,
    \ vim9HiKeyList,
    \ vim9HiLink

syntax match vim9HiCtermError /\D\i*/ contained

syntax keyword vim9Highlight hi[ghlight]
    \ contained
    \ nextgroup=@vim9HighlightCluster,vim9HiBang
    \ skipwhite

syntax match vim9HiBang /!/ contained nextgroup=@vim9HighlightCluster skipwhite

syntax match vim9HiGroup /\i\+/ contained

syntax case ignore
syntax keyword vim9HiAttrib contained
    \ none bold inverse italic nocombine reverse standout strikethrough
    \ underline undercurl
syntax keyword vim9FgBgAttrib none bg background fg foreground contained
syntax case match

syntax match vim9HiAttribList /\i\+/ contained contains=vim9HiAttrib

syntax match vim9HiAttribList /\i\+,/he=e-1
    \ contained
    \ contains=vim9HiAttrib
    \ nextgroup=vim9HiAttribList

syntax case ignore
syntax keyword vim9HiCtermColor contained
    \ black blue brown cyan darkblue darkcyan darkgray darkgreen darkgrey
    \ darkmagenta darkred darkyellow gray green grey lightblue lightcyan
    \ lightgray lightgreen lightgrey lightmagenta lightred magenta red white
    \ yellow
syntax case match

syntax match vim9HiFontname /[a-zA-Z\-*]\+/ contained
syntax match vim9HiGuiFontname /'[a-zA-Z\-* ]\+'/ contained
syntax match vim9HiGuiRgb /#\x\{6}/ contained

# :highlight group key=arg ... {{{4

syntax cluster vim9HiCluster contains=
    \ vim9BracketNotation,
    \ vim9Group,
    \ vim9HiCTerm,
    \ vim9HiCtermFgBg,
    \ vim9HiCtermul,
    \ vim9HiGroup,
    \ vim9HiGui,
    \ vim9HiGuiFgBg,
    \ vim9HiGuiFont,
    \ vim9HiKeyError,
    \ vim9HiStartStop,
    \ vim9HiTerm

syntax region vim9HiKeyList
    \ start=/\i\+/
    \ skip=/\\\\\|\\|/
    \ end=/$\||/
    \ contained
    \ contains=@vim9HiCluster
    \ oneline

syntax match vim9HiKeyError /\i\+=/he=e-1 contained
syntax match vim9HiTerm /term=/he=e-1 contained nextgroup=vim9HiAttribList

syntax match vim9HiStartStop /\%(start\|stop\)=/he=e-1
    \ contained
    \ nextgroup=vim9HiTermcap,vim9MayBeOptionScoped

syntax match vim9HiCTerm /cterm=/he=e-1 contained nextgroup=vim9HiAttribList

syntax match vim9HiCtermFgBg /cterm[fb]g=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiCtermColor,
    \     vim9HiCtermError,
    \     vim9HiNmbr

syntax match vim9HiCtermul /ctermul=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiCtermColor,
    \     vim9HiCtermError,
    \     vim9HiNmbr

syntax match vim9HiGui /gui=/he=e-1 contained nextgroup=vim9HiAttribList
syntax match vim9HiGuiFont /font=/he=e-1 contained nextgroup=vim9HiFontname

syntax match vim9HiGuiFgBg /gui\%([fb]g\|sp\)=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiGroup,
    \     vim9HiGuiFontname,
    \     vim9HiGuiRgb

syntax match vim9HiTermcap /\S\+/ contained contains=vim9BracketNotation
syntax match vim9HiNmbr /\d\+/ contained

# :highlight clear {{{4

# `skipwhite` is necessary for `{group}` to be highlighted in `highlight clear {group}`.
syntax keyword vim9HiClear clear contained nextgroup=vim9HiGroup skipwhite

# :highlight link {{{4

execute 'syntax region vim9HiLink'
    .. ' matchgroup=vim9GenericCmd'
    .. ' start=/'
    .. '\%(\<hi\%[ghlight]\s\+\)\@<='
    .. '\%(\%(def\%[ault]\s\+\)\=link\>\|\<def\>\)'
    .. '/'
    .. ' end=/$/'
    .. ' contained'
    .. ' contains=@vim9HiCluster'
    .. ' oneline'
#}}}3
# :import / :export {{{3

# :import
# :export
syntax keyword vim9Import imp[ort] contained nextgroup=vim9ImportedItems skipwhite
syntax keyword vim9Export exp[ort] contained nextgroup=vim9Declare skipwhite

#        v----v
# import MyItem ...
syntax match vim9ImportedItems /\h[a-zA-Z0-9_]*/
    \ contained
    \ nextgroup=vim9ImportAsFrom
    \ skipwhite

#        v---------v
# import {My, Items} ...
syntax region vim9ImportedItems matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contained
    \ contains=vim9ImportAsFrom
    \ nextgroup=vim9ImportAsFrom
    \ skipwhite
syntax match vim9ImportedItems /\*/ contained nextgroup=vim9ImportAsFrom skipwhite

#               vv         v--v
# import MyItem as MyAlias from 'myfile.vim'
syntax keyword vim9ImportAsFrom as from contained nextgroup=vim9ImportAlias skipwhite

#                  v-----v
# import MyItem as MyAlias from 'myfile.vim'
syntax match vim9ImportAlias /\h[a-zA-Z0-9_]*/
    \ contained
    \ nextgroup=vim9ImportAsFrom
    \ skipwhite

# :inoreabbrev {{{3

syntax keyword vim9AbbrevCmd
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ contained
    \ nextgroup=@vim9MapLhs,@vim9MapMod
    \ skipwhite

# :mark {{{3

syntax keyword vim9MarkCmd ma[rk]
    \ contained
    \ nextgroup=vim9MarkCmdArgInvalid,vim9MarkCmdArgValid
    \ skipwhite

syntax match vim9MarkCmdArgInvalid /[^ \t|]\+/ contained
execute 'syntax match vim9MarkCmdArgValid /\s\@1<=' .. mark_valid .. '\_s\@=/ contained'

# :nnoremap {{{3

syntax cluster vim9MapMod contains=vim9MapMod,vim9MapModExpr
syntax cluster vim9MapLhs contains=vim9MapLhs,vim9MapLhsExpr
syntax cluster vim9MapRhs contains=vim9MapRhs,vim9MapRhsExpr

syntax match vim9Map /\<map\>!\=\ze\s*[^(]/
    \ contained
    \ nextgroup=@vim9MapLhs,vim9MapMod,vim9MapModExpr
    \ skipwhite

# Do *not* include `vim9MapLhsExpr` in the `nextgroup` argument.{{{
#
# `vim9MapLhsExpr`  is  only  possible  after  `<expr>`,  which  is  matched  by
# `vim9MapModExpr` which is included in `@vim9MapMod`.
#}}}
syntax keyword vim9Map
    \ cm[ap] cno[remap] im[ap] ino[remap] lm[ap] ln[oremap] nm[ap] nn[oremap]
    \ no[remap] om[ap] ono[remap] smap snor[emap] tno[remap] tm[ap] vm[ap]
    \ vn[oremap] xm[ap] xn[oremap]
    \ contained
    \ nextgroup=vim9MapBang,vim9MapLhs,@vim9MapMod
    \ skipwhite

syntax keyword vim9Map
    \ mapc[lear] smapc[lear] cmapc[lear] imapc[lear] lmapc[lear]
    \ nmapc[lear] omapc[lear] tmapc[lear] vmapc[lear] xmapc[lear]
    \ contained

syntax keyword vim9Unmap
    \ cu[nmap] iu[nmap] lu[nmap] nun[map] ou[nmap] sunm[ap]
    \ tunma[p] unm[ap] unm[ap] vu[nmap] xu[nmap]
    \ contained
    \ nextgroup=vim9MapBang,@vim9MapLhs,@vim9MapMod
    \ skipwhite

syntax match vim9MapLhs /\S\+/
    \ contained
    \ contains=vim9BracketNotation,vim9CtrlChar
    \ nextgroup=vim9MapRhs
    \ skipwhite

syntax match vim9MapLhsExpr /\S\+/
    \ contained
    \ contains=vim9BracketNotation,vim9CtrlChar
    \ nextgroup=vim9MapRhsExpr
    \ skipwhite

syntax match vim9MapBang /!/ contained nextgroup=@vim9MapLhs,@vim9MapMod skipwhite

execute 'syntax match vim9MapMod'
    .. ' /'
    .. '\c'
    .. '\%(<\%('
    ..         'buffer\|\%(local\)\=leader\|nowait'
    .. '\|' .. 'plug\|script\|sid\|unique\|silent'
    .. '\)>\s*\)\+'
    .. '/'
    .. ' contained'
    .. ' contains=vim9MapModErr,vim9MapModKey'
    .. ' nextgroup=vim9MapLhs'
    .. ' skipwhite'

execute 'syntax match vim9MapModExpr'
    .. ' /'
    .. '\c'
    .. '\%(<\%('
    ..         'buffer\|\%(local\)\=leader\|nowait'
    .. '\|' .. 'plug\|script\|sid\|unique\|silent'
    .. '\)>\s*\)*'
    .. '<expr>\s*'
    .. '\%(<\%('
    ..         'buffer\|\%(local\)\=leader\|nowait'
    .. '\|' .. 'plug\|script\|sid\|unique\|silent'
    .. '\)>\s*\)*'
    .. '/'
    .. ' contained'
    .. ' contains=vim9MapModErr,vim9MapModKey'
    .. ' nextgroup=vim9MapLhsExpr'
    .. ' skipwhite'

syntax case ignore
syntax keyword vim9MapModKey contained
    \ buffer expr leader localleader nowait plug script sid silent unique
syntax case match

syntax match vim9MapRhs /.*/
    \ contained
    \ contains=
    \     vim9BracketNotation,
    \     vim9CtrlChar,
    \     vim9MapCmd,
    \     vim9MapCmdlineExpr,
    \     vim9MapInsertExpr
    \ nextgroup=vim9MapRhsExtend
    \ skipnl

syntax match vim9MapRhsExpr /.*/
    \ contained
    \ contains=@vim9Expr,vim9BracketNotation,vim9CtrlChar
    \ nextgroup=vim9MapRhsExtendExpr
    \ skipnl

# `matchgroup=vim9BracketNotation` is necessary to prevent `<CR>` from being consumed by a contained item.{{{
#
# Example:
#
#                                v--v
#     nnoremap x <Cmd>normal! abc<CR>
#     nnoremap x <Cmd>doautocmd WinEnter<CR>
#                                       ^--^
#
# In the first command, `<CR>` should not be matched normal commands.
# In the second one, `<CR>` should not be matched as a file pattern in an autocmd.
#}}}
# TODO: Are there other regions where we should make sure to prevent a contained
# match in its start/end?
# We don't add `oneline` because it's convenient to break a rhs on multiple lines.{{{
#
#     nnoremap <key> <Cmd>call Foo(
#       \ arg1,
#       \ arg2,
#       \ arg3,
#       \ )
#}}}
syntax region vim9MapCmd
    \ start=/\c<Cmd>/
    \ matchgroup=vim9BracketNotation
    \ end=/\c<CR>\|<Enter>\|^\s*$/
    \ contained
    \ contains=@vim9Expr,vim9BracketNotation,vim9MapCmdBar,vim9SpecFile
    \ keepend

syntax region vim9MapInsertExpr
    \ start=/\c<C-R>=\@=/
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vim9Expr,vim9BracketNotation,vim9EvalExpr
    \ keepend
    \ oneline
syntax match vim9EvalExpr /\%(<C-R>\)\@6<==/ contained

syntax region vim9MapCmdlineExpr
    \ matchgroup=vim9BracketNotation
    \ start=/\c<C-\\>e/
    \ matchgroup=NONE
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vim9Expr,vim9BracketNotation
    \ keepend
    \ oneline

# Highlight what comes after `<Bar>` as a command:{{{
#
#     nnoremap xxx <Cmd>call FuncA() <Bar> call FuncB()<CR>
#                                          ^--^
#
# But only if it's between `<Cmd>` and `<CR>`.
# Anywhere else, we have no guarantee that we're on the command-line.
#}}}
syntax match vim9MapCmdBar /\c<Bar>/
    \ contained
    \ contains=vim9BracketNotation
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

syntax match vim9MapRhsExtend /^\s*\\.*$/ contained contains=vim9Continuation
syntax match vim9MapRhsExtendExpr /^\s*\\.*$/
    \ contained
    \ contains=@vim9Expr,vim9Continuation

# :normal {{{3

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would break the highlighting of a possible following bang.
syntax match vim9Norm /\<norm\%[al]\>/ nextgroup=vim9NormCmds contained skipwhite
syntax match vim9Norm /\<norm\%[al]\>!/he=e-1 nextgroup=vim9NormCmds contained skipwhite

syntax match vim9NormCmds /.*/ contained

# :substitute {{{3

# TODO: Why did we include `vim9BracketNotation` here?
#
# Some  of its  effects are  really  nice in  a substitution  pattern (like  the
# highlighting of capturing groups).  But I  don't think all of its effects make
# sense here.   Consider replacing it  with a  similar groups whose  effects are
# limited to the ones which make sense.
#
# Also, make sure to include it in  any pattern supplied to a command (`:catch`,
# `:global`, `:vimgrep`)...
syntax cluster vim9SubstList contains=
    \ vim9BracketNotation,
    \ vim9Collection,
    \ vim9PatRegion,
    \ vim9PatSep,
    \ vim9PatSepErr,
    \ vim9SubstRange,
    \ vim9SubstTwoBS

        syntax match vim9NotPatSep /\\\\/ contained
        syntax match vim9PatSep /\\|/ contained
        syntax match vim9PatSepErr /\\)/ contained
        syntax region vim9PatRegion
            \ matchgroup=vim9PatSepR
            \ start=/\\[z%]\=(/
            \ end=/\\)/
            \ contained
            \ contains=@vim9SubstList
            \ oneline
            \ transparent

syntax cluster vim9SubstRepList contains=
    \ vim9BracketNotation,
    \ vim9SubstSubstr,
    \ vim9SubstTwoBS

# Warning: Do *not* use `display` here.{{{
#
# It could break some subsequent highlighting.
#
# MWE:
#
#     # test script
#     def Foo()
#         substitute/(")"//
#     enddef
#     def Bar()
#     enddef
#
#     # command to execute:
#     syntax clear vim9Subst
#
# Notice that everything gets broken after the substitution command.
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vim9Subst` is defined with `display`
#}}}
execute 'syntax match vim9Subst'
    .. ' /\<s\%[ubstitute]\>\s*\ze\(' .. pattern_delimiter .. '\).\{-}\1.\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9SubstPat'

execute 'syntax region vim9SubstPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/re=e-1,me=e-1'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' nextgroup=vim9SubstRep,vim9SubstRepExpr'
    .. ' oneline'

syntax region vim9SubstRep
    \ matchgroup=vim9SubstDelim
    \ start=/\z(.\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vim9BracketNotation
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vim9SubstRepList
    \ nextgroup=vim9SubstFlagErr
    \ oneline

syntax region vim9SubstRepExpr
    \ matchgroup=vim9SubstDelim
    \ start=/\z(.\)\%(\\=\)\@=/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vim9BracketNotation
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vim9Expr,vim9EvalExpr
    \ nextgroup=vim9SubstFlagErr
    \ oneline
syntax match vim9EvalExpr /\\=/ contained

syntax region vim9Collection
    \ start=/\\\@1<!\[/
    \ skip=/\\\[/
    \ end=/\]/
    \ contained
    \ contains=vim9CollationClass
    \ transparent

syntax match vim9CollationClassErr /\[:.\{-\}:\]/ contained

execute 'syntax match vim9CollationClass'
    .. ' /\[:'
    .. '\%(' .. collation_class .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syntax match vim9SubstSubstr /\\z\=\d/ contained
syntax match vim9SubstTwoBS /\\\\/ contained
syntax match vim9SubstFlagErr /[^< \t\r|]\+/ contained contains=vim9SubstFlags
syntax match vim9SubstFlags /[&cegiIlnpr#]\+/ contained

# :syntax {arguments} {{{3
# :syntax {{{4

# Order: Must come *before* the rule setting `vim9HiGroup`.{{{
#
# Otherwise, the name of a highlight group would not be highlighted here:
#
#     syntax clear Foobar
#                  ^----^
#}}}
# Must exclude the bar for this to work:{{{
#
#     syntax clear | eval 0
#                  ^
#                  not part of a group name
#}}}
syntax match vim9GroupList /@\=[^ \t,|']\+/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep

syntax match vim9GroupList /@\=[^ \t,']*,/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep
    \ nextgroup=vim9GroupList

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would fail to match `CONTAINED`.
syntax match vim9GroupSpecial /\%(ALL\|ALLBUT\|CONTAINED\|TOP\)/ contained
syntax match vim9SynError /\i\+/ contained
syntax match vim9SynError /\i\+=/ contained nextgroup=vim9GroupList

syntax match vim9SynContains /\<contain\%(s\|edin\)/ contained nextgroup=vim9SynEqual
syntax match vim9SynEqual /=/ contained nextgroup=vim9GroupList

syntax match vim9SynKeyContainedin /\<containedin/ contained nextgroup=vim9SynEqual
syntax match vim9SynNextgroup /nextgroup/ contained nextgroup=vim9SynEqual

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
syntax match vim9Syntax /\<sy\%[ntax]\>/
    \ contained
    \ contains=vim9GenericCmd
    \ nextgroup=vim9Comment,vim9SynType
    \ skipwhite

# :syntax case {{{4

syntax keyword vim9SynType contained
    \ case skipwhite
    \ nextgroup=vim9SynCase,vim9SynCaseError

syntax match vim9SynCaseError /\i\+/ contained
syntax keyword vim9SynCase ignore match contained

# :syntax clear {{{4

# `vim9HiGroup` needs  to be in the  `nextgroup` argument, so that  `{group}` is
# highlighted in `syntax clear {group}`.
syntax keyword vim9SynType clear
    \ contained
    \ nextgroup=vim9GroupList,vim9HiGroup
    \ skipwhite

# :syntax cluster {{{4

syntax keyword vim9SynType cluster contained nextgroup=vim9ClusterName skipwhite

syntax region vim9ClusterName
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ matchgroup=vim9Sep
    \ end=/$\||/
    \ contained
    \ contains=vim9GroupAdd,vim9GroupRem,vim9SynContains,vim9SynError

syntax match vim9GroupAdd /add=/ contained nextgroup=vim9GroupList
syntax match vim9GroupRem /remove=/ contained nextgroup=vim9GroupList

# :syntax iskeyword {{{4

syntax keyword vim9SynType iskeyword contained nextgroup=vim9IskList skipwhite
syntax match vim9IskList /\S\+/ contained contains=vim9IskSep
syntax match vim9IskSep /,/ contained

# :syntax include {{{4

syntax keyword vim9SynType include contained nextgroup=vim9GroupList skipwhite

# :syntax keyword {{{4

syntax cluster vim9SynKeyGroup contains=
    \ vim9SynKeyContainedin,
    \ vim9SynKeyOpt,
    \ vim9SynNextgroup

syntax keyword vim9SynType keyword contained nextgroup=vim9SynKeyRegion skipwhite

syntax region vim9SynKeyRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ matchgroup=vim9Sep
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynKeyGroup
    \ keepend
    \ oneline

syntax match vim9SynKeyOpt
    \ /\<\%(conceal\|contained\|transparent\|skipempty\|skipwhite\|skipnl\)\>/
    \ contained

# :syntax match {{{4

syntax cluster vim9SynMtchGroup contains=
    \ vim9BracketNotation,
    \ vim9Comment,
    \ vim9MtchComment,
    \ vim9SynContains,
    \ vim9SynError,
    \ vim9SynMtchOpt,
    \ vim9SynNextgroup,
    \ vim9SynRegPat

syntax keyword vim9SynType match contained nextgroup=vim9SynMatchRegion skipwhite

syntax region vim9SynMatchRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ matchgroup=vim9Sep
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynMtchGroup
    \ keepend

execute 'syntax match vim9SynMtchOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syntax match vim9SynMtchOpt /\<cchar=/ contained nextgroup=vim9SynMtchCchar
syntax match vim9SynMtchCchar /\S/ contained

# :syntax [on|off] {{{4

syntax keyword vim9SynType enable list manual off on reset contained

# :syntax region {{{4

syntax cluster vim9SynRegPatGroup contains=
    \ vim9BracketNotation,
    \ vim9NotPatSep,
    \ vim9PatRegion,
    \ vim9PatSep,
    \ vim9PatSepErr,
    \ vim9SubstSubstr,
    \ vim9SynNotPatRange,
    \ vim9SynPatRange

syntax cluster vim9SynRegGroup contains=
    \ vim9SynContains,
    \ vim9SynMtchGrp,
    \ vim9SynNextgroup,
    \ vim9SynRegOpt,
    \ vim9SynRegStartSkipEnd

syntax keyword vim9SynType region contained nextgroup=vim9SynRegion skipwhite

syntax region vim9SynRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynRegGroup
    \ keepend

execute 'syntax match vim9SynRegOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\%(ends\)\=\|transparent\|contained\|excludenl'
    .. '\|' .. 'skipempty\|skipwhite\|display\|keepend\|oneline\|extend\|skipnl'
    .. '\|' .. 'fold'
    .. '\)\>\_s\@='
    .. '/'
    .. ' contained'

syntax match vim9SynRegStartSkipEnd /\%(start\|skip\|end\)=\@=/
    \ contained
    \ nextgroup=vim9SynEqualRegion
syntax match vim9SynEqualRegion /=/ contained nextgroup=vim9SynRegPat

syntax match vim9SynMtchGrp /matchgroup/ contained nextgroup=vim9SynEqualMtchGrp
syntax match vim9SynEqualMtchGrp /=/ contained nextgroup=vim9Group,vim9HLGroup

syntax region vim9SynRegPat
    \ start=/\z([-`~!@#$%^&*_=+;:'",./?|]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contained
    \ contains=@vim9SynRegPatGroup
    \ extend
    \ nextgroup=vim9SynPatMod,vim9SynRegStartSkipEnd
    \ skipwhite

syntax match vim9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=/
    \ contained

syntax match vim9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,/
    \ contained
    \ nextgroup=vim9SynPatMod

syntax region vim9SynPatRange start=/\[/ skip=/\\\\\|\\]/ end=/]/ contained
syntax match vim9SynNotPatRange /\\\\\|\\\[/ contained
syntax match vim9MtchComment /#[^#]\+$/ contained

# :syntax sync {{{4

syntax keyword vim9SynType sync
    \ contained
    \ nextgroup=
    \     vim9SyncC,
    \     vim9SyncError,
    \     vim9SyncLinebreak,
    \     vim9SyncLinecont,
    \     vim9SyncLines,
    \     vim9SyncMatch,
    \     vim9SyncRegion
    \ skipwhite

syntax match vim9SyncError /\i\+/ contained
syntax keyword vim9SyncC ccomment clear fromstart contained
syntax keyword vim9SyncMatch match contained nextgroup=vim9SyncGroupName skipwhite
syntax keyword vim9SyncRegion region contained nextgroup=vim9SynRegStartSkipEnd skipwhite

syntax match vim9SyncLinebreak /\<linebreaks=/
    \ contained
    \ nextgroup=vim9Number
    \ skipwhite

syntax keyword vim9SyncLinecont linecont contained nextgroup=vim9SynRegPat skipwhite
syntax match vim9SyncLines /\%(min\|max\)\=lines=/ contained nextgroup=vim9Number
syntax match vim9SyncGroupName /\h\w*/ contained nextgroup=vim9SyncKey skipwhite

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
syntax match vim9SyncKey /\<\%(groupthere\|grouphere\)\>/
    \ contained
    \ nextgroup=vim9SyncGroup
    \ skipwhite

syntax match vim9SyncGroup /\h\w*/
    \ contained
    \ nextgroup=vim9SynRegPat,vim9SyncNone
    \ skipwhite

syntax keyword vim9SyncNone NONE contained
#}}}3
# :vimgrep {{{3

# without a bang
execute 'syntax match vim9VimGrep'
    .. ' /\<l\=vim\%[grep]\%(add\)\=\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/'
    .. ' nextgroup=vim9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

# with a bang
execute 'syntax match vim9VimGrep'
    .. ' /\<l\=vim\%[grep]\%(add\)\=!\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/he=e-1'
    .. ' nextgroup=vim9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

execute 'syntax region vim9VimGrepPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' oneline'

# :wincmd {{{3

syntax keyword vim9Wincmd winc[md]
    \ contained
    \ nextgroup=vim9WincmdArgInvalid,vim9WincmdArgValid
    \ skipwhite

syntax match vim9WincmdArgInvalid /\S\+/ contained
execute 'syntax match vim9WincmdArgValid ' .. wincmd_valid .. ' contained'

# :{range}!{filter} {{{3
# `:help :range!`

# We only support `:!` when used to filter some lines in the buffer.{{{
#
# IOW, we only recognize it when it comes right after a range, which itself must
# be introduced with a colon.
#}}}
# We do not support `:!` to run an external command which needs a controlling terminal.{{{
#
# First, it would be  too tricky to distinguish this bang  command from the bang
# logical NOT operator.
#
# Second, `:terminal` is a better mechanism anyway; in your code, use it instead.
#}}}
syntax match vim9Filter /!/ contained nextgroup=vim9FilterShellCmd
syntax match vim9FilterShellCmd /.*/ contained contains=vim9FilterLastShellCmd
# TODO: Support special filenames like `%:p`, `%%`, ...

# Inside a filter command, an unescaped `!` has a special meaning:{{{
#
# From `:help :!`:
#
#    > Any '!' in {cmd} is replaced with the previous
#    > external command (see also 'cpoptions').  But not when
#    > there is a backslash before the '!', then that
#    > backslash is removed.
#}}}
syntax match vim9FilterLastShellCmd /\\\@1<!!/ display contained

#}}}1
# Functions {{{1
# User Definition {{{2
# Vim9 {{{3

execute 'syntax match vim9FuncHeader'
    .. ' /'
    .. '\<def!\=\s\+'
    .. '\%('
               # function with explicit scope (global or script-local)
    ..         '[gs]:\w\+'
               # script-local function
    .. '\|' .. '\u\w*'
               # autoload function
    .. '\|' .. '\h\w*#\%(\w\|#\)*'
    .. '\)'
    .. '\ze('
    .. '/'
    .. ' contains=vim9DefKey'
    .. ' nextgroup=vim9FuncSignature'

syntax keyword vim9DefKey def fu[nction]
    \ contained
    \ nextgroup=vim9DefBangError,vim9DefBang
# :def! is valid
syntax match vim9DefBang /!/ contained
# but only for global functions
syntax match vim9DefBangError /!\%(\s\+g:\)\@!/ contained

# Ending the  signature at `enddef`  prevents a temporary unbalanced  paren from
# causing havoc beyond the end of the function.
syntax region vim9FuncSignature
    \ matchgroup=vim9ParenSep
    \ start=/(/
    \ end=/)\|^\s*enddef\ze\s*\%(#.*\)\=$/
    \ contained
    \ contains=
    \     @vim9DataTypeCluster,
    \     @vim9ErrorSpaceArgs,
    \     @vim9Expr,
    \     vim9Comment,
    \     vim9FuncArgs,
    \     vim9OperAssign
    \ nextgroup=vim9LegacyFuncArgs
    \ skipwhite

    syntax match vim9LegacyFuncArgs /\%(:\s*\)\=\%(abort\|closure\|dict<\@!\|range\)/
        \ contained
        \ nextgroup=vim9LegacyFuncArgs
        \ skipwhite

execute 'syntax match vim9FuncArgs'
    .. ' /'
    # named argument followed by a type or an optional value
    ..     '\.\@1<!\<\h[a-zA-Z0-9_]*\%(:\s\|\s\+=\s\)\@='
    .. '\|'
    # variable arguments
    .. '\.\.\.\h[a-zA-Z0-9_]*\%(:\s\+list<\)\@='
    .. '\|'
    # ignored argument
    ..     '\<_\%(,\|)\|$\)\@='
    .. '\|'
    # ignored variable arguments
    ..     '\.\.\._\%()\|$\)\@='
    .. '/'
    .. ' contained'

syntax match vim9FuncEnd /^\s*enddef\ze\s*\%(#.*\)\=$/

# Legacy {{{3

execute 'syntax match vim9LegacyFunction'
    .. ' /'
    .. '\<fu\%[nction]!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(\w\|[#.]\)*'
    .. '\ze('
    .. '/'
    .. ' contains=vim9DefKey'
    .. ' nextgroup=vim9LegacyFuncBody'

# `vim9String` needs to be contained to prevent a string from being wrongly highlighted as a comment.
# There might be a trailing comment after `:endfunction`.{{{
#
# Typically, it might be fold markers:
#
#     function Func()
#         some code
#     endfunction " } } }
#                 ^-----^
#
# We don't want those to be highlighted as errors (because they're unbalanced).
#}}}
syntax region vim9LegacyFuncBody
    \ start=/\s*(/
    \ matchgroup=vim9DefKey
    \ end=/^\s*\<endf\%[unction]\ze\s*\%(".*\)\=$/
    \ contained
    \ contains=vim9LegacyComment,vim9String
    \ nextgroup=vim9LegacyComment
    \ skipwhite

# We  need to  support inline  comments (if  only for  a trailing  comment after
# `:endfunction`), so we can't anchor the comment to the start of the line.
syntax match vim9LegacyComment /".*/ contained
#}}}2
# User Call {{{2

# call to any kind of function (builtin + user)
execute 'syntax match vim9FuncCall'
    .. ' /\<'
    .. '\%('
    # with an explicit scope, the name can start with and contain any word character
    ..     '[bgstw]:\w\%(\w\|\.\)\+'
    .. '\|'
    # otherwise, it must start with a head of word (i.e. word character except digit);
    # afterward, it can contain any word character and `#` (for autoload functions) and `.` (for dict functions)
    ..     '\h\%(\w\|[#.]\)*'
    .. '\)'
    # Do *not* allow whitespace between the function name and the open paren.{{{
    #
    #     .. '\ze\s*('
    #            ^^^
    #
    # First, it's not allowed in Vim9 script.
    # Second, it could cause a wrong highlighting:
    #
    #     eval (1 + 2)
    #     ^--^
    #     this should not be highlighted as a function, but as a command
    #}}}
    .. '\ze('
    .. '/'
    .. ' contains=vim9FuncNameBuiltin,vim9UserFuncNameUser'

# name of user function in function call
execute 'syntax match vim9UserFuncNameUser'
    .. ' /'
    .. '\<\%('
    ..     '\%('
    ..             '[bgstw]:'
    ..     '\|' .. '\%(\c<SID>\)\@5<='
    ..     '\)'
    ..     '\w\%(\w\|\.\)\+'
    .. '\|'
    # without an explicit scope, the name of the function must start with a capital
    ..     '\u\w*'
    .. '\|'
    # unless it's an autoload or dict function
    ..     '\h\w*[#.]\%(\w\|[#.]\)*'
    .. '\)'
    .. '\ze('
    .. '/'
    .. ' contained'
    .. ' contains=vim9BracketNotation'

# Builtin Call {{{2

# Install a `:syntax keyword` rule to highlight *most* function names.{{{
#
# Except  the ones  which  are too  ambiguous,  and match  an  Ex command  (e.g.
# `eval()`, `execute()`, `function()`, ...).
#
# Rationale: We don't want to wrongly highlight `:eval` as a function.
# To remove any ambiguity, we need to assert the presence of an open paren after
# the function name.  That's only possible with a separate `:syntax match` rule.
#
# NOTE: We  don't  want to  assert  the  paren  for  *all* function  names;  the
# necessary regex would be too costly.
#}}}
execute 'syntax keyword vim9FuncNameBuiltin'
    .. ' ' .. builtin_func
    .. ' contained'

execute 'syntax match vim9FuncNameBuiltin'
    .. ' /\<\%(' .. builtin_func_ambiguous .. '\)(\@=/'
    .. ' contained'
#}}}1
# Operators {{{1

# Warning: Don't include `vim9DictMayBeLiteralKey`.{{{
#
# It could break the highlighting of a dictionary containing a lambda:
#
#     eval {
#         key: (_, v): number => 0
#                  ^^
#                  ✘
#     }
#     ^
#     ✘
#}}}
# Don't include `vim9FuncArgs` either for similar reasons.
syntax cluster vim9OperGroup contains=
    \ @vim9Expr,
    \ vim9BracketNotation,
    \ vim9Comment,
    \ vim9Continuation,
    \ vim9Oper,
    \ vim9OperAssign,
    \ vim9OperParen,
    \ vim9UserCmdRhsEscapeSeq

# `nextgroup` is necessary to prevent a dictionary from being matched as a block.{{{
#
#     var n = 12 +
#         {
#             key: 34,
#         }
#         .key
#
# ---
#
# We could also write this:
#
#     nextgroup=vim9Dict
#
# But it would create an inconsistent highlighting:
#
#     # no indentation
#     var name =
#     yank
#     ^--^
#     not matched by anything
#     (because it could be a variable name used in the rhs of an assignment)
#
#     # the lines are indented
#         var name =
#         yank
#         ^--^
#         matched as an Ex command
#
# By  using `vim9SOLExpr`,  we prevent  the `yank`  token to  be matched  in the
# second case, which is more consistent.
#
# Also, it feeds more meaningful information to the syntax plugin.
# We're telling  the latter that the  next line is  not like the other  ones; it
# expects  an expression  at it  start; thus,  many constructs  are not  allowed
# there.
#}}}
# Don't write `display` here.{{{
#
# From `:help :syn-display`, this requirement must be satisfied:
#
#    - The item does not allow other items to match that didn't match otherwise
#
# Here, it's not satisfied, because of `vim9SOLExpr`.
#
# ---
#
# In practice, it would sometimes cause spurious highlights.
#
# MWE:
#
#     # test script
#     (x ==# 0)
#     def Func()
#     enddef
#
#     # command to execute:
#     syntax clear vim9Oper
#
# Notice that everything gets broken after `(x ==# 0)`.
# In practice, that could happen if:
#
#    - `Func()` is folded (hence, not displayed)
#    - `vim9Oper` is defined with `display`
#
# Here is another example:
#
#     var n = 12 +
#         {
#             key: 34,
#         }
#         .key
#
# Pressing `vio`  (visually select column) while  the cursor is on  a whitespace
# before `{` would  sometimes cause the latter  to be matched as the  start of a
# block.
#}}}
execute 'syntax match vim9Oper'
    .. ' ' .. most_operators
    .. ' nextgroup=vim9SOLExpr'
    .. ' skipnl'
    .. ' skipwhite'

#   =
#  -=
#  +=
#  *=
#  /=
#  %=
# ..=
syntax match vim9OperAssign #\s\@1<=\%([-+*/%]\|\.\.\)\==\_s\@=#
    \ nextgroup=vim9SOLExpr
    \ skipnl
    \ skipwhite

# methods
syntax match vim9Oper /->\%(\_s*\h\)\@=/ skipwhite
# logical not
execute 'syntax match vim9Oper' .. ' ' .. logical_not .. ' display skipwhite'

# support `:` when used inside conditional `?:` operator
syntax match vim9Oper /\_s\@1<=:\_s\@=/
    \ nextgroup=vim9SOLExpr
    \ skipnl
    \ skipwhite

# But ignore `:` inside a slice, which is tricky.{{{
#
# Test your code against these lines:
#
#     eval [1 ? 2 : 3]
#                 ^
#
#     eval 1 ? 2 : 3
#                ^
#
#     eval list[1 : 2]
#                 ^
#
#     eval 1
#         ? 2
#         : 3
#         ^
#
#     eval col == 1 ? col([lnum, '$']) - 1 : col
#                                          ^
#}}}
execute 'syntax match vim9ListSliceDelimiter'
    .. ' /'
    # try to ignore a colon part of a ternary operator (used in a slice)
    .. '\%(?[^()?:]*\)\@<!'
    # the colon must be surrounded with whitespace
    .. '\s\@1<=:\s\@='
    .. '/'
    .. ' contained'
    .. ' containedin=vim9ListSlice'

# contains `@vim9ErrorSpaceArgs` to handle errors in function calls
syntax region vim9OperParen
    \ matchgroup=vim9ParenSep
    \ start=/(/
    \ end=/)/
    \ contains=
    \     @vim9ErrorSpaceArgs,
    \     @vim9OperGroup,
    \     vim9Block

# Data Types {{{1
# `vim9Expr` {{{2

syntax cluster vim9Expr contains=
    \ vim9Bool,
    \ vim9DataTypeCast,
    \ vim9Dict,
    \ vim9FuncCall,
    \ vim9Lambda,
    \ vim9LambdaArrow,
    \ vim9ListSlice,
    \ vim9MayBeOptionScoped,
    \ vim9None,
    \ vim9Null,
    \ vim9Number,
    \ vim9Oper,
    \ vim9OperParen,
    \ vim9Registers,
    \ vim9String

# Booleans / null / v:none {{{2

# Even though `v:` is useless in Vim9, we  still need it in a mapping; because a
# mapping is run in the legacy context, even when installed from a Vim9 script.
syntax match vim9Bool /\%(v:\)\=\<\%(false\|true\)\>:\@!/
syntax match vim9Null /\%(v:\)\=\<null\>:\@!/

syntax match vim9None /\<v:none\>:\@!/

# Strings {{{2

syntax region vim9String
    \ start=/"/
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ keepend
    \ oneline

# In a  syntax file, we  often build  syntax rules with  strings concatenations,
# which we then `:execute`.  Highlight the tokens inside the strings.
if expand('%:p:h:t') == 'syntax'
    syntax region vim9String
        \ start=/'/
        \ skip=/''/
        \ end=/'/
        \ contains=@vim9SynRegGroup,vim9SynExeCmd
        \ keepend
        \ oneline
    syntax match vim9SynExeCmd /\<sy\%[ntax]\>/  contained nextgroup=vim9SynExeType skipwhite
    syntax keyword vim9SynExeType keyword match region contained nextgroup=vim9SynExeGroupName skipwhite
    syntax match vim9SynExeGroupName /[^' \t]\+/ contained
else
    # Order: Must come before `vim9Number`.
    # We must not allow a digit to match after the ending quote.{{{
    #
    #     end=/'\d\@!/
    #           ^---^
    #
    # Otherwise, it  would break  the highlighting  of a  big number  which contains
    # quotes to be more readable:
    #
    #     const BIGNUMBER: number = 1'000'000
    #                                ^---^
    #                                this would be wrongly highlighted as a string,
    #                                instead of a number
    #}}}
    # We must allow a newline before a quote to support a string at the start of a line:{{{
    #
    #     'some string'->setline(1)
    #}}}
    syntax region vim9String
        \ start=/'/
        \ skip=/''/
        \ end=/'\d\@!/
        \ keepend
        \ oneline
endif

# The contents of a register is a string, and can be referred to via `@{regname}`.{{{
#
# It needs to be matched by our syntax plugin to avoid issues such as:
#
#     @" = text->join("\n")
#      ^
#      that's not the start of a string
#}}}
# Don't assert anything for the surroundings.{{{
#
# For example,  don't assume that  an `@r` expression is  necessarily surrounded
# with spaces:
#
#     Func(@r)
#         ^  ^
#
#     var l = [@r]
#             ^  ^
#
#     l->Func()
#      ^
#
# ...
#}}}
syntax match vim9Registers /@[-"0-9a-z+.:%#/=]/

# Numbers {{{2

syntax match vim9Number /\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment
    \ skipwhite

syntax match vim9Number /-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment
    \ skipwhite

syntax match vim9Number /\<0[xX]\x\+\>/ nextgroup=vim9Comment skipwhite
syntax match vim9Number /\_A\zs#\x\{6}\>/ nextgroup=vim9Comment skipwhite
syntax match vim9Number /\<0[zZ][a-fA-F0-9.]\+\>/ nextgroup=vim9Comment skipwhite
syntax match vim9Number /\<0o[0-7]\+\>/ nextgroup=vim9Comment skipwhite
syntax match vim9Number /\<0b[01]\+\>/ nextgroup=vim9Comment skipwhite

# It is possible to use single quotes inside numbers to make them easier to read:{{{
#
#     echo 1'000'000
#
# Highlight them as part of a number.
#}}}
# Warning: Do *not* use `display` here.{{{
#
# It could break some subsequent highlighting.
#
# MWE:
#
#     # test script
#     def Foo()
#         (1'2) .. ''
#     enddef
#     def Bar()
#     enddef
#
#     # command to execute:
#     syntax clear vim9Number
#
# Notice that everything gets broken starting from the number.
#
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vim9Number` is defined with `display`
#}}}
syntax match vim9Number /\d\@1<='\d\@=/ nextgroup=vim9Comment skipwhite

# Dictionaries {{{2

# Order: Must come before `vim9Block`.
syntax region vim9Dict
    \ matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contains=@vim9OperGroup,vim9DictExprKey,vim9DictMayBeLiteralKey

# In literal dictionary, highlight unquoted key names as strings.
execute 'syntax match vim9DictMayBeLiteralKey'
    .. ' ' .. maybe_dict_literal_key
    .. ' display'
    .. ' contained'
    .. ' contains=vim9DictIsLiteralKey'
    .. ' keepend'

# check the validity of the key
syntax match vim9DictIsLiteralKey /\%(\w\|-\)\+/ contained

# support expressions as keys (`[expr]`).
syntax match vim9DictExprKey /\[.\{-}]\%(:\s\)\@=/
    \ contained
    \ contains=@vim9Expr
    \ keepend

# Lambdas {{{2

execute 'syntax region vim9Lambda'
    .. ' matchgroup=vim9ParenSep'
    .. ' start=/' .. lambda_start .. '/'
    .. ' end=/' .. lambda_end .. '/'
    .. ' contains=@vim9DataTypeCluster,@vim9ErrorSpaceArgs,vim9LambdaArgs'
    .. ' keepend'
    .. ' nextgroup=@vim9DataTypeCluster'
    .. ' oneline'

syntax match vim9LambdaArgs /\.\.\.\h[a-zA-Z0-9_]*/ contained
syntax match vim9LambdaArgs /\%(:\s\)\@2<!\<\h[a-zA-Z0-9_]*/ contained

syntax match vim9LambdaArrow /\s\@1<==>\_s\@=/
    \ nextgroup=vim9LambdaDictMissingParen,vim9Block
    \ skipwhite

# Type checking {{{2

# Order: This section must come *after* the `vim9FuncCall` and `vim9UserFuncNameUser` rules.{{{
#
# Otherwise, a funcref return type in a function's header would sometimes not be
# highlighted in its entirety:
#
#     def Func(): func(): number
#                 ^-----^
#                 not highlighted
#     enddef
#}}}
syntax cluster vim9DataTypeCluster contains=
    \ vim9DataType,
    \ vim9DataTypeCast,
    \ vim9DataTypeCastComposite,
    \ vim9DataTypeCompositeLeadingColon,
    \ vim9DataTypeFuncref,
    \ vim9DataTypeListDict

# Need to support *at least* these cases:{{{
#
#     var name: type
#     var name: type # comment
#     var name: type = value
#     var name: list<string> =<< trim END
#     def Func(arg: type)
#     def Func(): type
#
#     def Func(
#         arg: type,
#         ...
#
#     (arg: type) => expr
#     (): type => expr
#}}}
execute 'syntax match vim9DataType'
    .. ' /'
    .. '\%(' .. ':\s\+' .. '\)'
    .. '\%('
               # match simple types
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)\>'
    # positive lookahead
    .. '\%('
    # the type could be at the end of a line (e.g. variable declaration without assignment)
    ..     '$'
    # it could be followed by an inline comment
    ..     '\|\s\+#'
    # it could be followed by an assignment operator (`=`, `=<<`)
    # or by an arrow (in a lambda, after its arguments)
    ..     '\|\s\+=[ \n><]'
    # it could be followed by a paren or a comma (in a function's header),
    # or by a colon (in the case of `func`),
    # or by a square bracket (`for [a: bool, b: number] in ...`)
    #                                                ^
    ..     '\|[),:\]]'
    # it could be followed by the `in` keyword in a `:for` loop
    ..     '\|\s\+in\s\+'
    .. '\)\@='
    .. '/hs=s+1'
    #       ^^^
    #       let's not highlight the colon
    .. ' nextgroup=vim9RepeatForIn'
    .. ' skipwhite'

# Composite data types need to be handled separately.
# First, let's deal with their leading colon.
syntax match vim9DataTypeCompositeLeadingColon /:\s\+\%(\%(list\|dict\)<\|func(\)\@=/
    \ nextgroup=vim9DataTypeListDict,vim9DataTypeFuncref

# Now, we can deal with the rest.
# But a list/dict/funcref type can contain  itself; this is too tricky to handle
# with a  match and a  single regex.   It's much simpler  to let Vim  handle the
# possible recursion with a region which can contain itself.
syntax region vim9DataTypeListDict
    \ matchgroup=vim9ValidSubType
    \ start=/\<\%(list\|dict\)</
    \ end=/>/
    \ contained
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ nextgroup=vim9RepeatForIn
    \ oneline
    \ skipwhite

syntax region vim9DataTypeFuncref
    \ matchgroup=vim9ValidSubType
    \ start=/\<func(/
    \ end=/)/
    \ contained
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline

# validate subtypes
execute 'syntax match vim9ValidSubType'
    # for the question mark: `func(?type)`
    .. ' /?\=\<\%('
    ..   'any'
    .. '\|blob'
    .. '\|bool'
    .. '\|channel'
    .. '\|float'
    .. '\|func(\@!'
    .. '\|job'
    .. '\|number'
    .. '\|string'
    .. '\|void'
    .. '\)\>'
    # the lookbehinds are  necessary to avoid breaking the nesting  of the outer
    # region;  which would  prevent some  trailing `>`  or `)`  to be  correctly
    # highlighted
    .. '\|'
    .. '?\=\<\%('
    ..         'd\@1<=ict<'
    .. '\|' .. 'l\@1<=ist<'
    .. '\|' .. 'f\@1<=unc(\|)'
    .. '\)'
    .. '\|'
    # support triple dot in `func(...list<type>)`
    .. '\.\.\.\%(list<\)\@='
    # support comma in `func(type1, type2)`
    .. '\|' .. ','
    .. '/'
    .. ' display'
    .. ' contained'

# support `:help type-casting` for simple types
execute 'syntax match vim9DataTypeCast'
    .. ' /<\%('
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)>'
    .. '\%([bgtw]:\)\@='
    .. '/'

# support `:help type-casting` for composite types
syntax region vim9DataTypeCastComposite
    \ matchgroup=vim9ValidSubType
    \ start=/<\%(list\|dict\)</
    \ end=/>>/
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline

syntax region vim9DataTypeCastComposite
    \ matchgroup=vim9ValidSubType
    \ start=/<func(/
    \ end=/)>/
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline
#}}}1
# Options {{{1
# Assignment commands {{{2

syntax keyword vim9Set setl[ocal] setg[lobal] se[t]
    \ contained
    \ nextgroup=vim9MayBeOptionSet
    \ skipwhite

# Names {{{2

# Note that an option value can be written right at the start of the line.{{{
#
#     &guioptions = 'M'
#     ^---------^
#}}}
execute 'syntax match vim9MayBeOptionScoped'
    .. ' /'
    ..     option_can_be_after
    ..     option_sigil
    ..     option_valid
    .. '/'
    .. ' display'
    .. ' contains=vim9IsOption,vim9OptionSigil'
    # `vim9SetEqual` would be wrong here; we need spaces around `=`
    .. ' nextgroup=vim9OperAssign'

# Don't use `display` here.{{{
#
# It  could mess  up the  buffer  when you  set  a terminal  option whose  value
# contains an opening square bracket.  The latter could be wrongly parsed as the
# start a list.
#}}}
execute 'syntax match vim9MayBeOptionSet'
    .. ' /'
    ..     option_can_be_after
    ..     option_valid
    .. '/'
    .. ' contained'
    .. ' contains=vim9IsOption'
    .. ' nextgroup=vim9SetEqual,vim9SetEqualError,vim9MayBeOptionSet,vim9SetMod'
    .. ' skipwhite'
    # White space is disallowed around the assignment operator:{{{
    #
    #                        ✘
    #                        vv
    #     setlocal foldmethod = 'expr'
    #     setlocal foldmethod=expr
    #                        ^
    #                        ✔
    #}}}
    syntax match vim9SetEqualError / [-+^]\==/ contained

syntax match vim9OptionSigil /&\%([gl]:\)\=/ contained

execute 'syntax keyword vim9IsOption'
    .. ' ' .. option
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'
    .. ' skipwhite'

execute 'syntax keyword vim9IsOption'
    .. ' ' .. option_terminal
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

execute 'syntax match vim9IsOption'
    .. ' /\V'
    .. option_terminal_special
    .. '/'
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

# Assignment operators {{{2

syntax match vim9SetEqual /[-+^]\==/
    \ contained
    \ nextgroup=vim9SetNumberValue,vim9SetStringValue

# Values + separators (`[,:]`) {{{2

execute 'syntax match vim9SetStringValue'
    .. ' /'
    .. '\%('
               # match characters with no special meaning
    ..         '[^\\ \t]'
               # match whitespace escaped with an odd number of backslashes
    .. '\|' .. '\%(\\\\\)*\\\s'
               # match backslash escaping sth else than a whitespace
    .. '\|' .. '\\\S'
    .. '\)*'
    .. '/'
    .. ' contained'
    .. ' contains=vim9SetSep'
    # necessary to support the case where a single `:set` command sets several options
    .. ' nextgroup=vim9MayBeOptionScoped,vim9MayBeOptionSet'
    .. ' oneline'
    .. ' skipwhite'

syntax match vim9SetSep /[,:]/ contained

# Order: Must come after `vim9SetStringValue`.
syntax match vim9SetNumberValue /\d\+\_s\@=/
    \ contained
    \ nextgroup=vim9MayBeOptionScoped,vim9MayBeOptionSet
    \ skipwhite

# Modifiers (e.g. `&vim`) {{{2

# Modifiers which can be appended to an option name.{{{
#
# < = set local value to global one; or remove local value (for global-local options)
# ? = show value
# ! = invert value
#}}}
# The positive lookahead is necessary to avoid a spurious highlight:{{{
#
#     nnoremap <key> <Cmd>set wrap<Bar> eval 0<CR>
#                                 ^
#                                 this is not a modifier which applies to 'wrap';
#                                 this is the start of the Vim keycode <Bar>
#}}}
syntax match vim9SetMod /\%(&\%(vim\)\=\|[<?!]\)\%(\_s\||\)\@=/
    \ contained
    \ nextgroup=vim9MayBeOptionScoped,vim9MayBeOptionSet
    \ skipwhite
#}}}1
# Blocks {{{1

# at script-level or function-level
syntax region vim9Block
    \ matchgroup=Statement
    \ start=/^\s*{$/
    \ end=/^\s*}/
    \ contains=TOP
# `contains=TOP` is really necessary.{{{
#
# You can't get away with just:
#
#     \ contains=vim9StartOfLine
#
# That would not match things like strings, which are not contained in anything:
#
#     execute 'cmd ' .. name
#             ^----^
#}}}

# In a lambda, a dictionary must be surrounded by parens.{{{
#
#                     ✘
#                     v
#     var Ref = () => {}
#     var Ref = () => ({})
#                     ^
#                     ✔
#
# ---
#
# This can also warn us about of block which is not correctly broken after `{`:
#
#                     ✘
#                     v
#     var Ref = () => { command  }
#
#                     ✔
#                     v
#     var Ref = () => {
#         command
#     }
#
# From `:help inline-function`:
#
#    > Unfortunately this means using "() => {  command  }" does not work, line
#    > breaks are always required.
#}}}
# Order: must come before the next `vim9Block` rule.
syntax match vim9LambdaDictMissingParen /{/ contained

# in lambda
# Warning: Checking that there is no open paren before is not enough.{{{
#
# For example, it would fail to ignore  this dictionary passed as an argument to
# `Func()`:
#
#     Func(arg, {
#         key: 'value',
#     })
#}}}
syntax region vim9Block
    \ matchgroup=Statement
    \ start=/\%(=>\s\+\)\@<={$/
    \ end=/^\s*}/
    \ contained
    \ contains=TOP

# Highlight commonly used Groupnames {{{1

syntax case ignore
syntax keyword vim9Group contained
    \ Boolean
    \ Character
    \ Comment
    \ Conditional
    \ Constant
    \ Debug
    \ Define
    \ Delimiter
    \ Error
    \ Exception
    \ Float
    \ Function
    \ Identifier
    \ Ignore
    \ Include
    \ Keyword
    \ Label
    \ Macro
    \ Number
    \ Operator
    \ PreCondit
    \ PreProc
    \ Repeat
    \ Special
    \ SpecialChar
    \ SpecialComment
    \ Statement
    \ StorageClass
    \ String
    \ Structure
    \ Tag
    \ Todo
    \ Type
    \ Typedef
    \ Underlined
syntax case match

# Default highlighting groups {{{1

syntax case ignore
execute 'syntax keyword vim9HLGroup contained' .. ' ' .. default_highlighting_group

# Warning: Do *not* turn this `match` into  a `keyword` rule; `conceal` would be
# wrongly interpreted as an argument to `:syntax`.
syntax match vim9HLGroup /\<conceal\>/ contained
syntax case match

# Special Filenames, Modifiers, Extension Removal {{{1

syntax match vim9SpecFile /<\%([acs]file\|abuf\)>/ nextgroup=vim9SpecFileMod

# TODO: Update these rules so that they support the Vim9 filename modifiers:
#
#     edit %
#     edit %%
#     edit %%123
#     edit %%%
#     edit %%<123
#
# You'll probably need to refactor the rules, so that they're all contained.
# This assumes that you first recognize  all commands which accept a filename as
# argument.
#
# ---
#
# Make sure the file name modifiers  are accepted only after "%", "%%", "%%123",
# "<cfile>", "<sfile>", "<afile>" and "<abuf>".
#
# Update: We currently match `<cfile>` (&friends) with `vim9ExSpecialCharacters`.
# Is that wrong?  Should we match them with `vim9SpecFile`?
#
# ---
#
# Re-read `:help cmdline-special` to make sure everything is correct.

# Do *not* allow a space to match after `%`.{{{
#
#     \s%[: ]
#          ^
#          ✘
#
# Sometimes, it would break the highlighting of the arithmetic modulo operator:
#
#     eval (1) % 2
#              ^
#
# This does  mean that  in some  cases, `%`  might be  wrongly highlighted  as a
# modulo instead of a special filename.  Contrived example:
#
#     edit % | eval 0
#          ^
#          ✘
#
# For the moment, it looks like a  corner case which we won't encounter often in
# practice, so let's not try to fix it.
#}}}
syntax match vim9SpecFile /\s%:/ms=s+1,me=e-1 nextgroup=vim9SpecFileMod
# `%` can be followed by a bar, or `<Bar>`:{{{
#
#     source % | eval 0
#              ^
#}}}
syntax match vim9SpecFile /\s%\%($\|\s*[|<]\)\@=/ms=s+1 nextgroup=vim9SpecFileMod
syntax match vim9SpecFile /\s%<\%([^ \t<>]*>\)\@!/ms=s+1,me=e-1 nextgroup=vim9SpecFileMod
# TODO: The negative lookahead is necessary to prevent a match in a mapping:{{{
#
#     nnoremap x <Cmd>argedit %<CR>
#                              ^
# Pretty sure it's needed in other similar rules around here.
# Make tests.
# Try to avoid code repetition; import a regex if necessary.
#}}}
syntax match vim9SpecFile /%%\d\+\|%<\%([^ \t<>]*>\)\@!\|%%</ nextgroup=vim9SpecFileMod
syntax match vim9SpecFileMod /\%(:[phtreS]\)\+/ contained

# Lower Priority Comments: after some vim commands... {{{1

# inline comments
# Warning: Do *not* use the `display` argument here.

syntax match vim9Comment /^\s*#.*$/ contains=@vim9CommentGroup

# Control Characters {{{1

syntax match vim9CtrlChar /[\x01-\x08\x0b\x0f-\x1f]/

# Patterns matching at start of line {{{1

syntax match vim9CommentLine /^[ \t]\+#.*$/ contains=@vim9CommentGroup

# We've tweaked the original rule.{{{
#
# A title in a Vim9 comment was not highlighted.
# https://github.com/vim/vim/issues/6599
#
# ---
#
# Also, we could not include a user name inside parens:
#
#     NOTE(user): some comment
#         ^----^
#}}}
# `hs=s+1` is necessary to not highlight the comment leader.{{{
#
#     hs=s+1
#     │  │
#     │  └ start of the matched pattern
#     └ offset for where the highlighting starts
#
# See `:help :syn-pattern-offset`:
#}}}
syntax match vim9CommentTitle /#\s*\u\%(\w\|[()]\)*\%(\s\+\u\w*\)*:/hs=s+1
    \ contained
    \ contains=@vim9CommentGroup

syntax match vim9Continuation /^\s*\\/
    \ nextgroup=
    \     vim9SynContains,
    \     vim9SynContinuePattern,
    \     vim9SynMtchGrp,
    \     vim9SynNextgroup,
    \     vim9SynRegOpt,
    \     vim9SynRegStartSkipEnd
    \ skipwhite

syntax match vim9SynContinuePattern =\s\+/[^/]*/= contained

# Backtick expansion {{{1

#     `shell command`
syntax region vim9BacktickExpansion
    \ matchgroup=Special
    \ start=/`\%([^`=]\)\@=/
    \ end=/`/
    \ oneline

#     `=Vim expr`
syntax region vim9BacktickExpansionVimExpr
    \ matchgroup=Special
    \ start=/`=/
    \ end=/`/
    \ contains=@vim9Expr
    \ oneline

# fixme/todo notices in comments {{{1

syntax keyword vim9Todo FIXME TODO contained
syntax cluster vim9CommentGroup contains=
    \ @Spell,
    \ vim9CommentTitle,
    \ vim9DictLiteralLegacyDeprecated,
    \ vim9Todo

# Embedded Scripts  {{{1
# Python {{{2

unlet! b:current_syntax
syntax include @vim9PythonScript syntax/python.vim

syntax region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/py\%[thon][3x]\=\s\+<<\s\+\z(\S\+\)$/
    \ end=/^\z1$/
    \ matchgroup=vim9Error
    \ end=/^\s\+\z1$/
    \ contains=@vim9PythonScript

syntax region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/py\%[thon][3x]\=\s\+<<$/
    \ end=/\.$/
    \ contains=@vim9PythonScript

# Lua {{{2

unlet! b:current_syntax
syntax include @vim9LuaScript syntax/lua.vim

syntax region vim9LuaRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/lua\s\+<<\s\+\z(\S\+\)$/
    \ end=/^\z1$/
    \ matchgroup=vim9Error
    \ end=/^\s\+\z1$/
    \ contains=@vim9LuaScript

syntax region vim9LuaRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/lua\s\+<<$/
    \ end=/\.$/
    \ contains=@vim9LuaScript
#}}}1
# Errors {{{1
# Deprecated syntaxes {{{2

# Even in a `:def` function, or in a Vim9 script, there might be valid legacy code.{{{
#
# After `:legacy`, or in the rhs of a mapping.
# We don't try to handle these contexts specially because those seem like corner
# cases.
#
# `:legacy` should hardly be ever used.
# And  in the  rhs of  a mapping,  it's easy  to avoid  any syntax  triggering a
# highlighting error;  just wrap the problematic  code in a `:def`  function and
# call it.
#
#     ✘
#     nnoremap <F3> <Cmd>let g:myvar = 123<CR>
#
#     ✔
#     nnoremap <F3> <Cmd>call Func()<CR>
#     def Func()
#         g:myvar = 123
#     enddef
#
# This also gives  the benefit of making  the context (legacy vs  Vim9) in which
# the code  is run explicit.   Which in turn can  fix some obscure  issues; e.g.
# when a mapping  is executed – from  a Vim9 script –  with `feedkeys()` and
# the `x` flag, the rhs is run in the Vim9 context, instead of the legacy one.
# IOW, there  is no guarantee about  the context in  which the rhs will  be run;
# unless you wrap it inside a function.
#
# ---
#
# In any  case, since these rules  might highlight valid syntaxes  as errors, we
# should have  an option  to disable  them.  We still  install them  by default,
# because those are  common errors; e.g. when copy-pasting legacy  code in a new
# Vim9 script.
#}}}
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('deprecated_syntaxes', true)

    # `:let` is deprecated.
    syntax keyword vim9LetDeprecated let contained

    # In legacy Vim script, a literal dictionary starts with `#{`.
    # This syntax is no longer valid in Vim9.
    syntax match vim9DictLiteralLegacyDeprecated /#{{\@!/
endif

syntax match vim9LegacyVarArgs /a:000/

# TODO: Handle other legacy constructs like `a:`, `l:`:
#
#     syntax match Test /\<a:\h\@=/ containedin=@vim9Expr
#     syntax match Test /&\@1<!\<l:\h\@=/ containedin=@vim9Expr
#     highlight link Test vim9Error
#
# Also:
#
#    - `...)` in a function's header
#    - eval strings
#    - lambdas (tricky)
#    - single dots for concatenation (tricky)

# TODO: Highlight `s:` as useless (`SpellRare`?).  But make it optional.
# Rationale: You probably never need it.
# Worse, you might  use it to try  and declare a script-local  variable in a
# `:def` function, which is disallowed.
# Update: You do need it for a user function starting with a lowercase...

# TODO: Highlight legacy comment leaders as an error.  Optional.

# TODO: Highlight missing types in function header as errors:
#
#     def Func(foo, bar)
#
# Exceptions: `_` and `..._`.

# TODO: Highlight `:call` as useless.
# But not after `<Cmd>` nor `<Bar>`.
#
# ---
#
# Same thing for `v:` in `v:true`, `v:false`, `v:null`.
# Although, it's  trickier, because you must  not do that in  a mapping, and
# these variables can appear anywhere (contrary to `:call`).
# Idea: Make  the highlighting  optional, and  provide a  mapping which  can
# toggle the option on-demand.
# Update: Actually,  it  should cycle  between  different  errors, until  it
# highlight them all simultaneously, then none, then the cycle repeats.
#
# ---
#
# Same thing for `#` in `==#`, `!=#`, `=~#`, `!~#`.

# TODO: Highlight this as an error:
#
#     def Func(...name: job)

# TODO: Highlight this as an error:
#
#     vvv
#     var b:name = ...
#     var g:name = ...
#     var t:name = ...
#     var v:name = ...
#     var w:name = ...
#     var &name = ...
#     var &l:name = ...
#     var &g:name = ...
#     var $ENV = ...
#     ^^^

# TODO: Highlight this as an error:
#
#     is#
#     isnot#
#     is?
#     isnot?

# TODO: Highlight these as errors:
#
#     var d = {'a' : 1, 'b' : 2, 'c' : 3}
#                 ^        ^    ^
#                 ✘        ✘    ✘
#
#     var d = {'a': 1 , 'b': 2 , 'c': 3}
#                    ^        ^
#                    ✘        ✘
#
#     var l = [1 , 2 , 3]
#               ^   ^
#               ✘   ✘
#
#     (_,v) => ...
#       ^
#       ✘

# List unpack declaration {{{2

# Declaring more than one variable at a  time, using the unpack notation, is not
# supported.  See `:help E1092`.
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('list_unpack_declaration', true)

    syntax region vim9ListUnpackDeclaration
        \ contained
        \ contains=vim9ListUnpackDeclaration
        \ end=/\]/
        \ oneline
        \ start=/\[/
endif

# Missing space / Extra space {{{2

# We don't highlight a missing whitespace around an assignment operator:{{{
#
#     var name=123     # Error!
#     var name= 123    # Error!
#     var name =123    # Error!
#
# Because it's not syntax highlighted in those cases.
# The  absence of  highlighting should  serve as  a good  enough warning  to the
# user  (provided their  color scheme  highlights assignment  operators with  an
# easy-to-notice color).
#
# Besides, handling  all the cases  (after a variable name,  after a type,  in a
# heredoc, ...) would probably require many more rules.
# And, to  be consistent, we would  need to also handle  other binary operators,
# like the arithmetic ones.  But this  would require we first parse expressions,
# which would open a can of worms.
#}}}
# We could highlight missing or extra spaces in dictionaries:{{{
#
#         ✘
#         v
#     {key:'value'}
#     {key : 'value'}
#         ^
#         ✘
#
#     {key: 'value'}
#         ^^
#         ✔
#}}}
#   But we don't.{{{
#
# It's not necessary.  If you omit a space  after the colon, or add an extra one
# before, the key  won't be highlighted as  a string, which gives  a visual clue
# that something is wrong.
#
# There might still be an issue if  you use special characters in your keys, and
# you need to put quotes around them:
#
#           ✘
#           v
#     {'a+b':'value'}
#     {'c*d' : 'value'}
#           ^
#           ✘
#
# This code is wrong, but the highlighting  won't give any warning.  IMO, it's a
# corner case  which is  not worth  supporting.  You'll  rarely write  keys with
# special characters inside, *and* forget a space or add an extra space.
#}}}

if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('missing_or_extra_space', true)

    #         ✘
    #         v
    #     Func (arg)
    syntax region vim9SpaceExtraAfterFuncname
        \ matchgroup=vim9Error
        \ start=/\s\+(/
        \ matchgroup=vim9ParenSep
        \ end=/)/
        \ contains=@vim9OperGroup
        \ contained

    #           ✘
    #           v
    #     Func(1,2)
    #     Func(1, 2)
    #            ^
    #            ✔
    syntax match vim9SpaceMissingBetweenArgs /,\S\@=/ contained

    #           ✘
    #           v
    #     Func(1 , 2)
    #     Func(1, 2)
    #           ^
    #           ✔
    syntax match vim9SpaceExtraBetweenArgs /\s\@1<=,/ display contained

    syntax cluster vim9ErrorSpaceArgs contains=
        \ vim9SpaceExtraBetweenArgs,
        \ vim9SpaceMissingBetweenArgs

    #                   need a space before
    #                   v
    #     var name = 123# Error!
    # We need to match a whitespace to avoid reporting spurious errors:{{{
    #
    #     start=/[^ \t]\@1<=#\s/
    #                        ^^
    #
    #     g:autoload#name = 123
    #               ^
    #               this is not the start of a comment,
    #               thus there is no error
    #
    # Note that this is  not entirely correct; a comment might  be followed by a
    # non-whitespace.  But in  practice, it seems like a simple  and good enough
    # solution.
    #}}}
    # And we need to ignore an error if `#` is preceded by `@`.{{{
    #
    # Because `@#` might be a reference to a register.
    #}}}
    syntax region vim9Comment
        \ matchgroup=vim9Error
        \ start=/[^ \t@]\@1<=#\s\@=/
        \ end=/$/
        \ contains=@vim9CommentGroup
        \ excludenl
        \ oneline

    # In a slice, the colon separating the 2 indexes must be surrounded with spaces:{{{
    #
    #             ✘
    #             v
    #     mylist[1:2]
    #     mylist[1 : 2]
    #             ^^^
    #              ✔
    #}}}
    # To highlight a missing space, we must first recognize a list slice.{{{
    #
    # We don't try to  distinguish a slice of a list from a  simple list, because it
    # seems too tricky.
    #
    #           mylist[1 : 2]
    #     ReturnList()[1 : 2]
    #        [1, 2, 3][1 : 2]
    #     ...
    #
    # In particular, notice the variety of characters which can appear in front of a
    # slice.
    #}}}
    syntax region vim9ListSlice
        \ matchgroup=vim9Sep
        \ start=/\[/
        \ end=/\]/
        \ contains=
        \     @vim9OperGroup,
        \     vim9ColonForVariableScope,
        \     vim9ListSlice,
        \     vim9ListSliceDelimiter,
        \     vim9SpaceMissingListSlice
    # If a colon is not prefixed with a space, it's an error.
    syntax match vim9SpaceMissingListSlice /[^ \t[]\@1<=:/ display contained
    # If a colon is not followed with a space, it's an error.
    syntax match vim9SpaceMissingListSlice /:[^ \t\]]\@=/ contained
    # Corner Case: A colon can be used in a variable name.  Ignore it.{{{
    #
    #     b:name
    #      ^
    #      ✔
    #}}}
    # Order: Out of these 3 rules, this one must come last.
    execute 'syntax match vim9ColonForVariableScope '
        .. '/'
        .. '\<[bgstvw]:'
        .. '\%('
        # There must not be an open paren right after; otherwise it might be a function name.{{{
        #
        # If we don't  disallow a paren, a call to  a user script-local function
        # inside a list slice might be wrongly highlighted as an error:
        #
        #     echo [s:func()]
        #             ^--^
       #}}}
        .. '\%(\w*\)\@>(\@!'
        .. '\|'
               # `b:` is a dictionary expression, thus might be followed by `->`
        ..     '->'
        .. '\)\@='
        .. '/'
        .. ' display'
        .. ' contained'
endif

# Octal numbers {{{2

# Warn about missing `o` in `0o` prefix in octal number.{{{
#
#    > Numbers starting with zero are not considered to be octal, only numbers
#    > starting with "0o" are octal: "0o744". |scriptversion-4|
#
# We don't  could install a  rule to  highlight the number  as an error,  but it
# would not  work everywhere  (e.g. in  an `:echo`).  We  would need  to include
# this  new group  in  other regions/matches.   It's simpler  to  just stop  the
# highlighting at the `0`.
#
#           do not highlight
#           vvv
#     echo 0765
#     echo 0o765
#          ^---^
#          *do* highlight
#}}}
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('octal_missing_o_prefix', true)

    # The  negative lookbehind  is necessary  to  ignore big  numbers which  are{{{
    # written with quotes to be more readable:
    #
    #     1'076
    #       ^^^
    #
    # Here, `076` is not a badly written octal number.
    # There is no reason to stop the highlighting at `0`.
    #}}}
    syntax match vim9Number /\%(\d'\)\@2<!\<0[0-7]\+\>/he=s+1
        \ display
        \ nextgroup=vim9Comment
        \ skipwhite
endif

# Range {{{2

# Warn about omitting whitespace between line specifier and command.{{{
#
# In addition to making the code less readable, it might confuse the syntax plugin:
#
#     :123delete
#         ^----^
#           ✘
#         not recognized as an Ex command
#
#     :123 delete
#          ^----^
#            ✔
#          recognized as an Ex command
#
# Note that this issue also affects the legacy syntax plugin.
# We could try to fix it by removing all digits from the *syntax* option 'iskeyword':
#
#     :syntax iskeyword @,_
#
# But that would cause  other issues which would require too  much extra code to
# handle.   Indeed, it  would break  all the  `syntax keyword`  rules for  words
# containing digits.   It would also change  the semantics of the  `\<` and `\>`
# atoms in all regexes used for `syntax match` and `syntax region` rules.
#}}}
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('range_missing_space', false)

    syntax match vim9RangeMissingSpace /\S\@1<=\a/ display contained
endif

# Discourage usage  of an  implicit line  specifier, because  it makes  the code
# harder to read.
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('range_missing_specifier', false)
    syntax match vim9RangeMissingSpecifier1 /[,;]/
        \ contained
        \ nextgroup=@vim9Range

    syntax match vim9RangeMissingSpecifier2 /[,;][a-zA-Z \t]\@=/
        \ contained
        \ nextgroup=@vim9CanBeAtStartOfLine
        \ skipwhite
endif

# Reserved names {{{2

if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('reserved_names', true)

    # Some names cannot be used for variables, because they're reserved:{{{
    #
    #     var true = 0
    #     var null = ''
    #     var this = []
    #     ...
    #}}}
    syntax keyword vim9ReservedNames true false null this contained
endif
#}}}1
# Synchronize (speed) {{{1

syntax sync maxlines=60
syntax sync linecont /^\s\+\\/
syntax sync match vim9AugroupSyncA groupthere NONE /\<aug\%[roup]\>\s\+END/
#}}}1

# Highlight Groups {{{1
# All highlight groups need to be defined with the `default` argument.{{{
#
# So that they survive after we change/reload the colorscheme.
# Indeed,  a  colorscheme  always  executes  `:highlight  clear`  to  reset  all
# highlighting to the defaults.  By default,  the user-defined HGs do not exist,
# so for the latter, "reset all highlighting" means:
#
#    - removing all their attributes
#
#         $ vim --cmd 'highlight WillItSurvive ctermbg=green | highlight clear | highlight WillItSurvive | cquit'
#         WillItSurvive  xxx cleared˜
#
#    - removing the links
#
#         $ vim --cmd 'highlight link WillItSurvive ErrorMsg | highlight clear | highlight WillItSurvive | cquit'
#         WillItSurvive  xxx cleared˜
#}}}

highlight def link vim9GenericCmd Statement
# Make Vim highlight user commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we  want them  to be  bold, so  that we  can't conflate  a user
# command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     highlight def link vim9UserCmdExe vim9GenericCmd
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that when the syntax item  for `vim9UserCmdExe` was defined earlier (with
# a `:syntax` command), Vim has automatically created a highlight group with the
# same name; but it's cleared:
#
#     vim9UserCmdExe      xxx cleared
#
# That's why we don't write this:
#
#     if execute('highlight vim9UserCmdExe') == ''
#                                            ^---^
#                                              ✘
#}}}
if execute('highlight vim9UserCmdExe') =~ '\<cleared$'
    import Derive from 'vim9syntaxUtil.vim'
    Derive('vim9UserFuncNameUser', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9UserCmdExe', 'vim9GenericCmd', 'term=bold cterm=bold gui=bold')
    Derive('vim9FuncHeader', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9CmdModifier', 'vim9GenericCmd', 'term=italic cterm=italic gui=italic')
endif

highlight def link vim9Error Error

highlight def link vim9AutocmdEventBadCase vim9Error
highlight def link vim9CollationClassErr vim9Error
highlight def link vim9DefBangError vim9Error
highlight def link vim9DictLiteralLegacyDeprecated vim9Error
highlight def link vim9DictMayBeLiteralKey vim9Error
highlight def link vim9DigraphsCharsInvalid vim9Error
highlight def link vim9FTError vim9Error
highlight def link vim9FuncCall vim9Error
highlight def link vim9HiAttribList vim9Error
highlight def link vim9HiCtermError vim9Error
highlight def link vim9HiKeyError vim9Error
highlight def link vim9LambdaDictMissingParen vim9Error
highlight def link vim9LegacyFuncArgs vim9Error
highlight def link vim9LegacyVarArgs vim9Error
highlight def link vim9LetDeprecated vim9Error
highlight def link vim9ListUnpackDeclaration vim9Error
highlight def link vim9MapModErr vim9Error
highlight def link vim9MarkCmdArgInvalid vim9Error
highlight def link vim9OperError vim9Error
highlight def link vim9PatSepErr vim9Error
highlight def link vim9RangeMissingSpace vim9Error
highlight def link vim9RangeMissingSpecifier1 vim9Error
highlight def link vim9RangeMissingSpecifier2 vim9Error
highlight def link vim9ReservedNames vim9Error
highlight def link vim9SetEqualError vim9Error
highlight def link vim9SpaceExtraBetweenArgs vim9Error
highlight def link vim9SpaceMissingBetweenArgs vim9Error
highlight def link vim9SpaceMissingListSlice vim9Error
highlight def link vim9SubstFlagErr vim9Error
highlight def link vim9SynCaseError vim9Error
highlight def link vim9SynCaseError vim9Error
highlight def link vim9SynError vim9Error
highlight def link vim9SyncError vim9Error
highlight def link vim9UserCmdAttrbError vim9Error
highlight def link vim9WincmdArgInvalid vim9Error

highlight def link vim9AbbrevCmd vim9GenericCmd
highlight def link vim9Augroup vim9GenericCmd
highlight def link vim9AugroupNameEnd Title
highlight def link vim9Autocmd vim9GenericCmd
highlight def link vim9AutocmdAllEvents vim9AutocmdEventGoodCase
highlight def link vim9AutocmdEventGoodCase Type
highlight def link vim9AutocmdGroup vim9AugroupNameEnd
highlight def link vim9AutocmdMod Special
highlight def link vim9AutocmdPat vim9String
highlight def link vim9BacktickExpansion vim9ShellCmd
highlight def link vim9Bool Boolean
highlight def link vim9BracketKey Delimiter
highlight def link vim9BracketNotation Special
highlight def link vim9BreakContinue vim9Repeat
highlight def link vim9Comment Comment
highlight def link vim9CommentLine vim9Comment
highlight def link vim9CommentTitle PreProc
highlight def link vim9Conditional Conditional
highlight def link vim9Continuation Special
highlight def link vim9CopyMove vim9GenericCmd
highlight def link vim9CtrlChar SpecialChar
highlight def link vim9DataType Type
highlight def link vim9DataTypeCast vim9DataType
highlight def link vim9Declare Identifier
highlight def link vim9DefKey Keyword
highlight def link vim9DictIsLiteralKey String
highlight def link vim9DigraphsCharsValid vim9String
highlight def link vim9DigraphsCmd vim9GenericCmd
highlight def link vim9DigraphsNumber vim9Number
highlight def link vim9DoCmds vim9Repeat
highlight def link vim9Doautocmd vim9GenericCmd
highlight def link vim9EchoHL vim9GenericCmd
highlight def link vim9EchoHLNone vim9Group
highlight def link vim9EvalExpr vim9OperAssign
highlight def link vim9ExSpecialCharacters vim9BracketNotation
highlight def link vim9Export vim9Import
highlight def link vim9FTCmd vim9GenericCmd
highlight def link vim9FTOption vim9SynType
highlight def link vim9FgBgAttrib vim9HiAttrib
highlight def link vim9Filter vim9GenericCmd
highlight def link vim9FilterLastShellCmd Special
highlight def link vim9FilterShellCmd vim9ShellCmd
highlight def link vim9Finish vim9Return
highlight def link vim9FuncArgs Identifier
highlight def link vim9FuncEnd vim9DefKey
highlight def link vim9FuncNameBuiltin Function
highlight def link vim9Global vim9GenericCmd
highlight def link vim9GlobalPat vim9String
highlight def link vim9Group Type
highlight def link vim9GroupAdd vim9SynOption
highlight def link vim9GroupName vim9Group
highlight def link vim9GroupRem vim9SynOption
highlight def link vim9GroupSpecial Special
highlight def link vim9HLGroup vim9Group
highlight def link vim9HereDoc vim9String
highlight def link vim9HiAttrib PreProc
highlight def link vim9HiCTerm vim9HiTerm
highlight def link vim9HiClear vim9Highlight
highlight def link vim9HiCtermFgBg vim9HiTerm
highlight def link vim9HiCtermul vim9HiTerm
highlight def link vim9HiGroup vim9GroupName
highlight def link vim9HiGui vim9HiTerm
highlight def link vim9HiGuiFgBg vim9HiTerm
highlight def link vim9HiGuiFont vim9HiTerm
highlight def link vim9HiGuiRgb vim9Number
highlight def link vim9HiNmbr Number
highlight def link vim9HiStartStop vim9HiTerm
highlight def link vim9HiTerm Type
highlight def link vim9Highlight vim9GenericCmd
highlight def link vim9Import Include
highlight def link vim9ImportAsFrom vim9Import
highlight def link vim9Increment vim9Oper
highlight def link vim9IsOption PreProc
highlight def link vim9IskSep Delimiter
highlight def link vim9LambdaArgs vim9FuncArgs
highlight def link vim9LambdaArrow vim9Sep
highlight def link vim9LegacyComment vim9Comment
highlight def link vim9Map vim9GenericCmd
highlight def link vim9MapMod vim9BracketKey
highlight def link vim9MapModExpr vim9MapMod
highlight def link vim9MapModKey Special
highlight def link vim9MarkCmd vim9GenericCmd
highlight def link vim9MarkCmdArgValid Special
highlight def link vim9MtchComment vim9Comment
highlight def link vim9None Constant
highlight def link vim9Norm vim9GenericCmd
highlight def link vim9NormCmds String
highlight def link vim9NotPatSep vim9String
highlight def link vim9Null Constant
highlight def link vim9Number Number
highlight def link vim9Oper Operator
highlight def link vim9OperAssign Identifier
highlight def link vim9OptionSigil vim9IsOption
highlight def link vim9ParenSep Delimiter
highlight def link vim9PatSep SpecialChar
highlight def link vim9PatSepR vim9PatSep
highlight def link vim9PatSepZ vim9PatSep
highlight def link vim9RangeMark Special
highlight def link vim9RangeNumber Number
highlight def link vim9RangeOffset Number
highlight def link vim9RangePattern String
highlight def link vim9RangePatternBwdDelim Delimiter
highlight def link vim9RangePatternFwdDelim Delimiter
highlight def link vim9RangeSpecialSpecifier Special
highlight def link vim9Repeat Repeat
highlight def link vim9RepeatForIn vim9Repeat
highlight def link vim9RepeatForVar vim9Declare
highlight def link vim9Return vim9DefKey
highlight def link vim9ScriptDelim Comment
highlight def link vim9Sep Delimiter
highlight def link vim9Set vim9GenericCmd
highlight def link vim9SetBracketEqual vim9OperAssign
highlight def link vim9SetBracketKeycode vim9String
highlight def link vim9SetEqual vim9OperAssign
highlight def link vim9SetMod vim9IsOption
highlight def link vim9SetNumberValue Number
highlight def link vim9SetSep Delimiter
highlight def link vim9SetStringValue String
highlight def link vim9ShellCmd PreProc
highlight def link vim9SpecFile Identifier
highlight def link vim9SpecFileMod vim9SpecFile
highlight def link vim9Special Type
highlight def link vim9String String
highlight def link vim9Subst vim9GenericCmd
highlight def link vim9SubstDelim Delimiter
highlight def link vim9SubstFlags Special
highlight def link vim9SubstPat vim9String
highlight def link vim9SubstRep vim9String
highlight def link vim9SubstSubstr SpecialChar
highlight def link vim9SubstTwoBS vim9String
highlight def link vim9SynCase Type
highlight def link vim9SynContains vim9SynOption
highlight def link vim9SynContinuePattern String
highlight def link vim9SynEqual vim9OperAssign
highlight def link vim9SynEqualMtchGrp vim9OperAssign
highlight def link vim9SynEqualRegion vim9OperAssign
highlight def link vim9SynExeCmd vim9GenericCmd
highlight def link vim9SynExeGroupName vim9GroupName
highlight def link vim9SynExeType vim9SynType
highlight def link vim9SynKeyContainedin vim9SynContains
highlight def link vim9SynKeyOpt vim9SynOption
highlight def link vim9SynMtchGrp vim9SynOption
highlight def link vim9SynMtchOpt vim9SynOption
highlight def link vim9SynNextgroup vim9SynOption
highlight def link vim9SynNotPatRange vim9SynRegPat
highlight def link vim9SynOption Special
highlight def link vim9SynPatRange vim9String
highlight def link vim9SynRegOpt vim9SynOption
highlight def link vim9SynRegPat vim9String
highlight def link vim9SynRegStartSkipEnd Type
highlight def link vim9SynType vim9Special
highlight def link vim9SyncC Type
highlight def link vim9SyncGroup vim9GroupName
highlight def link vim9SyncGroupName vim9GroupName
highlight def link vim9SyncKey Type
highlight def link vim9SyncNone Type
highlight def link vim9Syntax vim9GenericCmd
highlight def link vim9Todo Todo
highlight def link vim9TryCatch Exception
highlight def link vim9TryCatchPattern String
highlight def link vim9TryCatchPatternDelim Delimiter
highlight def link vim9Unmap vim9Map
highlight def link vim9UserCmdAttrbAddress vim9String
highlight def link vim9UserCmdAttrbAddress vim9String
highlight def link vim9UserCmdAttrbComma vim9Sep
highlight def link vim9UserCmdAttrbComplete vim9String
highlight def link vim9UserCmdAttrbEqual vim9OperAssign
highlight def link vim9UserCmdAttrbErrorValue vim9Error
highlight def link vim9UserCmdAttrbName vim9Special
highlight def link vim9UserCmdAttrbNargs vim9String
highlight def link vim9UserCmdAttrbNargsNumber vim9Number
highlight def link vim9UserCmdAttrbRange vim9String
highlight def link vim9UserCmdDef Statement
highlight def link vim9UserCmdLhs vim9UserCmdExe
highlight def link vim9UserCmdRhsEscapeSeq vim9BracketNotation
highlight def link vim9ValidSubType vim9DataType
highlight def link vim9VimGrep vim9GenericCmd
highlight def link vim9VimGrepPat vim9String
highlight def link vim9Wincmd vim9GenericCmd
highlight def link vim9WincmdArgValid vim9String
#}}}1

b:current_syntax = 'vim9'

