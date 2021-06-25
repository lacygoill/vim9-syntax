vim9script

# Credits: Charles E. Campbell <NcampObell@SdrPchip.AorgM-NOSPAM>
# Author of syntax plugin for Vim script legacy.

if exists('b:current_syntax')
    # bail out for a file written in legacy Vim script
    || "\n" .. getline(1, 10)->join("\n") !~ '\n\s*vim9\%[script]\>'
    # bail out if we're included from another filetype (e.g. `markdown`)
    || &filetype != 'vim'
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
# have to use in a `:hi link` command.  And while syntax items are buffer-local,
# highlight groups are *global*.
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
# Only the `fu` and `endfu` keywords, as well as legacy comments inside.
# We could support more; we would  need to allow `vim9StartOfLine` to start from
# the `vim9LegacyFuncBody` region:
#
#     syn region vim9LegacyFuncBody
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
# Look for the pattern `^exe`.

# TODO: Try to remove as many `Order:` requirements as possible.
#
# If such a requirement involves 2 rules in the same section, that should be fine.
# But  not  if it  involves  2  rules in  different  sections;  because in  that
# case,  you might  one day  re-order the  sections, and  unknowingly break  the
# requirement.
#
# To remove such a requirement, try to improve some of your regexes.

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
#                             should be highlighted as a translated keycode?
#                             v---v
#     nno <expr> <F3> true ? '<c-a>' : '<c-b>'
#                     ^--^
#                     should be highlighted as an error?
#
# IMO, it's part of a more general issue.
# Mappings  installed from  a Vim9  script should  use the  Vim9 syntax;  that's
# probably what users would expect.  Unfortunately,  mappings are not run in the
# context  of the  script where  they  were defined.   At the  very least,  this
# pitfall should be documented.

# TODO: These command expect a pattern as argument:
#
#     :vimgrep
#     :vimgrepadd
#     :lvimgrep
#     :lvimgrepadd
#     :2match
#     :3match
#     :argdelete
#     :filter
#     :fu /
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

# TODO: Whenever we've used `syn case ignore`, should we have enforced a specific case?
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
import logical_not from 'vim9syntax.vim'
import most_operators from 'vim9syntax.vim'
import option from 'vim9syntax.vim'
import option_can_be_after from 'vim9syntax.vim'
import option_sigil from 'vim9syntax.vim'
import option_terminal from 'vim9syntax.vim'
import option_terminal_special from 'vim9syntax.vim'
import option_valid from 'vim9syntax.vim'
import pattern_delimiter from 'vim9syntax.vim'
#}}}1

# Early {{{1
# These rules need to be sourced early.
# Angle-Bracket Notation {{{2

# This could break the highlighting of a command after `<bar>` (between `<cmd>` and `<cr>`).
syn match vim9Notation /\c<bar>/ contains=vim9Bracket skipwhite

# This could break the highlighting of a command in a mapping (between `<cmd>` and `<cr>`).
# Especially if `<cmd>` is preceded by some key(s).
syn match vim9Notation /\c<cmd>/
    \ contains=vim9Bracket
    \ nextgroup=@vim9CanBeAtStartOfLine,@vim9Range

# This could break the highlighting of an expression in a mapping between `<c-\>e` and `<cr>`.
exe 'syn match vim9Notation'
    .. ' /'
    .. '\c\%(\\\|<lt>\)\='
    .. '<' .. '\%([scamd]-\)\{,3}x\='
    .. '\%('
    # TODO: Build the pattern programmatically:
    #
    #     echo getcompletion('set <', 'cmdline')
    #         ->filter((_, v: string): bool => v !~ '^<t_')
    #
    # There are many completions.
    # Consider using nested keywords to be faster.
    .. 'f\d\{1,2}\|[^ \t:]\|cr\|lf\|linefeed\|return\|k\=del\%[ete]'
    .. '\|' .. 'bs\|backspace\|tab\|esc\|right\|left\|help\|undo\|insert\|ins'
    .. '\|' .. 'mouse\|k\=home\|k\=end\|kplus\|kminus\|kdivide\|kmultiply'
    .. '\|' .. 'focus\%(gained\|lost\)'
    .. '\|' .. 'kenter\|kpoint\|space\|k\=\%(page\)\=\%(\|down\|up\|k\d\>\)'
    .. '\|' .. 'paste\%(end\|start\)'
    .. '\|' .. 'sgrmouse\%(release\)\='
    .. '\)' .. '>'
    .. '/'
    .. ' contains=vim9Bracket'

# This could break the highlighting of an expression in a mapping between `<c-r>=` and `<cr>`.
syn match vim9Notation /\c\%(\\\|<lt>\)\=<c-r>[0-9a-z"%#:.\-=]\@=/ contains=vim9Bracket

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
syn match vim9Comment /\s\@1<=#.*$/ contains=@vim9CommentGroup excludenl
# Unbalanced paren {{{2

# This could break `>` when used as a comparison operator.
syn match vim9OperError /[>)\]}]/
#}}}1

# Range {{{1

syn cluster vim9Range contains=
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
syn match vim9RangeIntroducer /\%(^\|\s\):\S\@=/
    \ contained
    \ nextgroup=@vim9Range,vim9RangeMissingSpecifier1

    # Sometimes, we might want to add a colon in front of an Ex command, even if it's not necessary.{{{
    #
    # Maybe for the sake of consistency:
    #
    #     :1,2 s/.../.../
    #     :3,4 s/.../.../
    #     :s/.../.../
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
    #     :% s/pat/rep/
    #     ^
    #}}}
    # Order: Must come after `vim9RangeIntroducer`.
    syn match vim9UnambiguousColon /\s\=:[a-zA-Z]\@=/
        \ contained
        \ nextgroup=@vim9CanBeAtStartOfLine

syn cluster vim9RangeAfterSpecifier contains=
    \ @vim9CanBeAtStartOfLine,
    \ @vim9Range,
    \ vim9Filter,
    \ vim9RangeMissingSpace

#                 v-----v v-----v
#     com MySort :<line1>,<line2> sort
syn match vim9RangeLnumNotation /\c<line[12]>/
    \ contained
    \ contains=vim9Notation
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangeMark /'[a-zA-Z0-9<>()[\]{}]/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangeNumber /\d\+/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangeOffset /[-+]\+\d*/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangePattern +/[^/]*/+
    \ contained
    \ contains=vim9RangePatternFwdDelim
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite
syn match vim9RangePatternFwdDelim +/+ contained

syn match vim9RangePattern +?[^?]*?+
    \ contained
    \ contains=vim9RangePatternBwdDelim
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite
syn match vim9RangePatternBwdDelim /?/ contained

syn match vim9RangeSpecialSpecifier /[.$%*]/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangeDelimiter /[,;]/
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
syn cluster vim9IsCmd contains=
    \ @vim9ControlFlow,
    \ vim9AbbrevCmd,
    \ vim9Augroup,
    \ vim9Autocmd,
    \ vim9CmdModifier,
    \ vim9Declare,
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
    \ vim9Norm,
    \ vim9PythonRegion,
    \ vim9Set,
    \ vim9Subst,
    \ vim9Syntax,
    \ vim9Unmap,
    \ vim9UserCmdDef,
    \ vim9UserCmdExe,
    \ vim9VimGrep

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
syn match vim9MayBeCmd /\%(\<\h\w*\>\)\@=/
    \ contained
    \ nextgroup=vim9Global,vim9Subst

    # General case
    # Order: Must come after the previous rule handling the special case.
    exe 'syn match vim9MayBeCmd'
        .. ' /\%(\<\h\w*\>' .. command_can_be_before .. '\)\@=/'
        .. ' contained'
        .. ' nextgroup=@vim9IsCmd'

# Now, let's build a cluster containing all groups which can appear at the start of a line.
syn cluster vim9CanBeAtStartOfLine contains=
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
syn match vim9StartOfLine /^/
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

syn match vim9CmdSep /|/ skipwhite nextgroup=@vim9CanBeAtStartOfLine

# Generic {{{2

exe 'syn keyword vim9GenericCmd' .. ' ' .. command_name .. ' contained'

syn match vim9GenericCmd /\<z[-+^.=]\=\>/ contained

# Special {{{2
# A command is special iff it needs a special highlighting.{{{
#
# For example, `:for` – as a  control flow statement – should be highlighted
# differently than `:delete`.   Same thing for `:autocmd`; not  because it needs
# to be  highlighted differently, but because  some of its arguments  need to be
# highlighted.
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
#     augroup Name | au!
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
#     endfu
#     ^---^
#     orphan, but still highlighted as a command; not as an error
#
# It's not worth the trouble.
#}}}

syn match vim9Augroup
    \ /\<aug\%[roup]\ze!\=\s\+\h\%(\w\|-\)*/
    \ contained
    \ nextgroup=vim9AugroupNameEnd
    \ skipwhite

#          v--v
# :augroup Name
# :augroup END
#          ^^^
syn match vim9AugroupNameEnd /\h\%(\w\|-\)*/ contained

# `:autocmd` {{{4

# :au[tocmd] [group] {event} {pat} [++once] [++nested] {cmd}
syn match vim9Autocmd /\<au\%[tocmd]\>/
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
syn match vim9Autocmd /\<au\%[tocmd]\>!/he=e-1
    \ contained
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup
    \ skipwhite

# The trailing whitespace is useful to prevent a correct but still noisy/useless
# match when we simply clear an augroup.
syn match vim9AutocmdGroup /\S\+\s\@=/
    \ contained
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase
    \ skipwhite

# Special Case: A wildcard can be used for all events.{{{
#
#     au! * <buffer>
#         ^
#
# This is *not* the same syntax token as the pattern which follows an event.
#}}}
syn match vim9AutocmdAllEvents /\*\_s\@=/
    \ contained
    \ nextgroup=vim9AutocmdPat
    \ skipwhite

syn match vim9AutocmdPat /\S\+/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine,vim9AutocmdMod
    \ skipwhite

syn match vim9AutocmdMod /++\%(nested\|once\)/
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

# Events {{{4

# TODO: Hide the bad case error behind an option.
syn case ignore
exe 'syn keyword vim9AutocmdEventBadCase' .. ' ' .. event
    .. ' contained'
    .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
    .. ' skipwhite'
syn case match

# Order: Must come after `vim9AutocmdEventBadCase`.
exe 'syn keyword vim9AutocmdEventGoodCase' .. ' ' .. event
    .. ' contained'
    .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
    .. ' skipwhite'

syn match vim9AutocmdEndOfEventList /,\%(\a\+,\)*\a\+/
    \ contained
    \ contains=vim9AutocmdEventBadCase,vim9AutocmdEventGoodCase
    \ nextgroup=vim9AutocmdPat
    \ skipwhite

# `:doautocmd`, `:doautoall` {{{4

# :do[autocmd] [<nomodeline>] [group] {event} [fname]
# :doautoa[ll] [<nomodeline>] [group] {event} [fname]
syn keyword vim9Doautocmd do[autocmd] doautoa[ll]
    \ contained
    \ nextgroup=
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup,
    \     vim9AutocmdMod
    \ skipwhite

syn match vim9AutocmdMod /<nomodeline>/
    \ nextgroup=
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup
    \ skipwhite
#}}}3
# Control Flow {{{3

syn cluster vim9ControlFlow contains=
    \ vim9BreakContinue,
    \ vim9Conditional,
    \ vim9Finish,
    \ vim9Repeat,
    \ vim9Return,
    \ vim9TryCatch

# :return
syn keyword vim9Return retu[rn] contained nextgroup=@vim9Expr skipwhite

# :break
# :continue
syn keyword vim9BreakContinue brea[k] con[tinue] contained skipwhite
# :finish
syn keyword vim9Finish fini[sh] contained skipwhite

# :if
# :elseif
syn keyword vim9Conditional if el[seif] contained nextgroup=@vim9Expr skipwhite

# :endif
syn keyword vim9Conditional en[dif] contained skipwhite

# :for
syn keyword vim9Repeat fo[r] contained skipwhite nextgroup=vim9RepeatForVar skipwhite

#           vv
# :for name in ...
# :for [name, ...] in ...
#                  ^^
syn match vim9RepeatForVar /\S\+/ contained nextgroup=vim9RepeatForIn skipwhite
syn region vim9RepeatForVar
    \ matchgroup=vim9Sep
    \ start=/\[/
    \ end=/]/
    \ contained
    \ nextgroup=vim9RepeatForIn
    \ skipwhite
syn keyword vim9RepeatForIn in contained

# :while
syn keyword vim9Repeat wh[ile] contained skipwhite nextgroup=@vim9Expr

# :endfor
# :endwhile
syn keyword vim9Repeat endfo[r] endw[hile] contained skipwhite

# :try
# :endtry
syn keyword vim9TryCatch try endt[ry] contained

# :throw
syn keyword vim9TryCatch th[row] contained nextgroup=@vim9Expr skipwhite

# :finally
# We can't write `:syn keyword ...  fina[lly]`, because it would break `:final`,
# which has a different meaning.
syn match vim9TryCatch /\<\%(fina\|finall\|finally\)\>/ contained

# :catch
syn match vim9TryCatch /\<cat\%[ch]\>/ contained nextgroup=vim9TryCatchPattern skipwhite
exe 'syn region vim9TryCatchPattern'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' contains=vim9TryCatchPatternDelim'
    .. ' oneline'

# Declaration {{{3

syn keyword vim9Declare cons[t] final unl[et] var
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
syn region vim9HereDoc
    \ matchgroup=vim9Declare
    \ start=/\s\@1<==<<\s\+\%(trim\>\)\=\s*\z(\L\S*\)/
    \ end=/^\s*\z1$/

syn match vim9EnvVar /\$[A-Z_][A-Z0-9_]*/

# Modifier {{{3

exe 'syn match vim9CmdModifier'
    .. ' /\<\%(' .. command_modifier .. '\)\>/'
    .. ' contained'
    .. ' nextgroup=@vim9CanBeAtStartOfLine,vim9CmdBang'
    .. ' skipwhite'

syn match vim9CmdBang /!/ contained nextgroup=@vim9CanBeAtStartOfLine skipwhite

# User {{{3
# Definition {{{4
# :command {{{5

# Warning: Do not turn `:syn match` into `:syn keyword`.
# It would break the highlighting of a possible following bang.
syn match vim9UserCmdDef /\<com\%[mand]\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

syn match vim9UserCmdDef /\<com\%[mand]\>!/he=e-1
    \ contained
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# error handling {{{5
# Order: should come before highlighting valid attributes.

syn cluster vim9UserCmdAttrb contains=
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
#     com -addrX=other -nargs=1 Cmd Func()
#              ^       ^-----------------^
#              ✘       highlighting should still work, in spite of the previous typo
#              typo
#
# Example2:
#
#     com -nargs=123 -buffer Cmd Func()
#                 ^^ ^----------------^
#                 ✘  highlighting should still work, in spite of the previous error
#                 error
#}}}
syn match vim9UserCmdAttrbErrorValue /\S\+/
    \ contained
    \ nextgroup=vim9UserCmdAttrbName
    \ skipwhite

# an invalid attribute name is an error
syn match vim9UserCmdAttrbError /-[^ \t=]\+/
    \ contained
    \ contains=vim9UserCmdAttrbName
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# boolean attributes {{{5

syn match vim9UserCmdAttrbName /-\%(bang\|bar\|buffer\|register\)\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# attributes with values {{{5
# = {{{6

syn match vim9UserCmdAttrbEqual /=/ contained

# -addr {{{6

syn match vim9UserCmdAttrbName /-addr\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbAddress,vim9UserCmdAttrbErrorValue

exe 'syn match vim9UserCmdAttrbAddress'
    .. ' /=\%(' .. command_address_type .. '\)\>/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrbEqual'
    .. ' nextgroup=@vim9UserCmdAttrb'
    .. ' skipwhite'

# -complete {{{6

syn match vim9UserCmdAttrbName /-complete\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbComplete,vim9UserCmdAttrbErrorValue

# -complete=arglist
# -complete=buffer
# -complete=...
exe 'syn match vim9UserCmdAttrbComplete'
    .. ' /'
    ..     '=\%(' .. command_complete_type .. '\)'
    .. '/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrbEqual'
    .. ' nextgroup=@vim9UserCmdAttrb'
    .. ' skipwhite'

# -complete=custom,Func
# -complete=customlist,Func
syn match vim9UserCmdAttrbComplete /=custom\%(list\)\=,\%([gs]:\)\=\%(\w\|[#.]\)*/
    \ contained
    \ contains=vim9UserCmdAttrbEqual,vim9UserCmdAttrbComma
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

syn match vim9UserCmdAttrbComma /,/ contained

# -count {{{6

syn match vim9UserCmdAttrbName /-count\>/
    \ contained
    \ nextgroup=
    \     @vim9UserCmdAttrb,
    \     vim9UserCmdAttrbCount,
    \     vim9UserCmdAttrbErrorValue
    \ skipwhite

syn match vim9UserCmdAttrbCount
    \ /=\d\+/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrbEqual
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

# -nargs {{{6

syn match vim9UserCmdAttrbName /-nargs\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbNargs,vim9UserCmdAttrbErrorValue

syn match vim9UserCmdAttrbNargs
    \ /=[01*?+]/
    \ contained
    \ contains=vim9UserCmdAttrbEqual,vim9UserCmdAttrbNargsNumber
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite

syn match vim9UserCmdAttrbNargsNumber /[01]/ contained

# -range {{{6

# `-range` is a special case:
# it can accept a value, *or* be used as a boolean.
syn match vim9UserCmdAttrbName /-range\>/
    \ contained
    \ nextgroup=
    \     @vim9UserCmdAttrb,
    \     vim9UserCmdAttrbErrorValue,
    \     vim9UserCmdAttrbRange
    \ skipwhite

syn match vim9UserCmdAttrbRange /=\%(%\|-\=\d\+\)/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrbEqual
    \ nextgroup=@vim9UserCmdAttrb
    \ skipwhite
#}}}5
# lhs / rhs {{{5

syn match vim9UserCmdLhs /\u\w*/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite
#}}}4
# Execution {{{4

syn match vim9UserCmdExe /\u\w*/ contained nextgroup=vim9SpaceExtraAfterFuncname

# This lets Vim highlight the name of an option and its value, when we set it with `:CompilerSet`.{{{
#
#     CompilerSet mp=pandoc
#                 ^-------^
#
# See: `:h :CompilerSet`
#}}}
# But it breaks the highlighting of `:CompilerSet`.  It should be highlighted as a *user* command!{{{
#
# No, it should not.
# The fact  that its name  starts with  an uppercase does  not mean it's  a user
# command.  It's definitely not one:
#
#     :com CompilerSet
#     No user-defined commands found˜
#}}}
syn keyword vim9Set CompilerSet contained nextgroup=vim9MayBeOptionSet skipwhite
#}}}3
# `:*do` {{{3

syn keyword vim9DoCmds argdo bufdo cdo cfdo ld[o] lfdo tabd[o] windo
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

# :echohl {{{3

syn keyword vim9EchoHL echoh[l]
    \ contained
    \ nextgroup=vim9EchoHLNone,vim9Group,vim9HLGroup
    \ skipwhite

syn case ignore
syn keyword vim9EchoHLNone none contained
syn case match

# :filetype {{{3

syn match vim9Filetype /\<filet\%[ype]\%(\s\+\I\i*\)*/
    \ contained
    \ contains=vim9FTCmd,vim9FTError,vim9FTOption
    \ skipwhite

syn match vim9FTError /\I\i*/ contained
syn keyword vim9FTCmd filet[ype] contained
syn keyword vim9FTOption detect indent off on plugin contained

# :global {{{3

# g/pat/cmd
exe 'syn match vim9Global'
    .. ' /\<g\%[lobal]\>!\=\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'
    .. ' skipwhite'

# v/pat/cmd
exe 'syn match vim9Global'
    .. ' /\<v\%[global]\>\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'

exe 'syn region vim9GlobalPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' nextgroup=@vim9CanBeAtStartOfLine'
    .. ' oneline'

# :highlight {arguments} {{{3
# :highlight {{{4

syn cluster vim9HighlightCluster contains=
    \ vim9Comment,
    \ vim9HiClear,
    \ vim9HiKeyList,
    \ vim9HiLink

syn match vim9HiCtermError /\D\i*/ contained

syn keyword vim9Highlight hi[ghlight]
    \ contained
    \ nextgroup=@vim9HighlightCluster,vim9HiBang
    \ skipwhite

syn match vim9HiBang /!/ contained nextgroup=@vim9HighlightCluster skipwhite

syn match vim9HiGroup /\i\+/ contained

syn case ignore
syn keyword vim9HiAttrib contained
    \ none bold inverse italic nocombine reverse standout strikethrough
    \ underline undercurl
syn keyword vim9FgBgAttrib none bg background fg foreground contained
syn case match

syn match vim9HiAttribList /\i\+/ contained contains=vim9HiAttrib

syn match vim9HiAttribList /\i\+,/he=e-1
    \ contained
    \ contains=vim9HiAttrib
    \ nextgroup=vim9HiAttribList

syn case ignore
syn keyword vim9HiCtermColor contained
    \ black blue brown cyan darkblue darkcyan darkgray darkgreen darkgrey
    \ darkmagenta darkred darkyellow gray green grey lightblue lightcyan
    \ lightgray lightgreen lightgrey lightmagenta lightred magenta red white
    \ yellow
syn case match

syn match vim9HiFontname /[a-zA-Z\-*]\+/ contained
syn match vim9HiGuiFontname /'[a-zA-Z\-* ]\+'/ contained
syn match vim9HiGuiRgb /#\x\{6}/ contained

# :highlight group key=arg ... {{{4

syn cluster vim9HiCluster contains=
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
    \ vim9HiTerm,
    \ vim9Notation

syn region vim9HiKeyList
    \ start=/\i\+/
    \ skip=/\\\\\|\\|/
    \ end=/$\||/
    \ contained
    \ contains=@vim9HiCluster
    \ oneline

syn match vim9HiKeyError /\i\+=/he=e-1 contained
syn match vim9HiTerm /term=/he=e-1 contained nextgroup=vim9HiAttribList

syn match vim9HiStartStop /\%(start\|stop\)=/he=e-1
    \ contained
    \ nextgroup=vim9HiTermcap,vim9MayBeOptionScoped

syn match vim9HiCTerm /cterm=/he=e-1 contained nextgroup=vim9HiAttribList

syn match vim9HiCtermFgBg /cterm[fb]g=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiCtermColor,
    \     vim9HiCtermError,
    \     vim9HiNmbr

syn match vim9HiCtermul /ctermul=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiCtermColor,
    \     vim9HiCtermError,
    \     vim9HiNmbr

syn match vim9HiGui /gui=/he=e-1 contained nextgroup=vim9HiAttribList
syn match vim9HiGuiFont /font=/he=e-1 contained nextgroup=vim9HiFontname

syn match vim9HiGuiFgBg /gui\%([fb]g\|sp\)=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiGroup,
    \     vim9HiGuiFontname,
    \     vim9HiGuiRgb

syn match vim9HiTermcap /\S\+/ contained contains=vim9Notation
syn match vim9HiNmbr /\d\+/ contained

# :highlight clear {{{4

# `skipwhite` is necessary for `{group}` to be highlighted in `hi clear {group}`.
syn keyword vim9HiClear clear contained nextgroup=vim9HiGroup skipwhite

# :highlight link {{{4

exe 'syn region vim9HiLink'
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
syn keyword vim9Import imp[ort] contained nextgroup=vim9ImportedItems skipwhite
syn keyword vim9Export exp[ort] contained nextgroup=vim9Declare skipwhite

#        v----v
# import MyItem ...
syn match vim9ImportedItems /\h[a-zA-Z0-9_]*/
    \ contained
    \ nextgroup=vim9ImportAsFrom
    \ skipwhite

#        v---------v
# import {My, Items} ...
syn region vim9ImportedItems matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contained
    \ contains=vim9ImportAsFrom
    \ nextgroup=vim9ImportAsFrom
    \ skipwhite
syn match vim9ImportedItems /\*/ contained nextgroup=vim9ImportAsFrom skipwhite

#               vv         v--v
# import MyItem as MyAlias from 'myfile.vim'
syn keyword vim9ImportAsFrom as from contained nextgroup=vim9ImportAlias skipwhite

#                  v-----v
# import MyItem as MyAlias from 'myfile.vim'
syn match vim9ImportAlias /\h[a-zA-Z0-9_]*/
    \ contained
    \ nextgroup=vim9ImportAsFrom
    \ skipwhite

# :inoreabbrev {{{3

syn keyword vim9AbbrevCmd
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ contained
    \ nextgroup=@vim9MapLhs,@vim9MapMod
    \ skipwhite

# :nnoremap {{{3

syn cluster vim9MapMod contains=vim9MapMod,vim9MapModExpr
syn cluster vim9MapLhs contains=vim9MapLhs,vim9MapLhsExpr
syn cluster vim9MapRhs contains=vim9MapRhs,vim9MapRhsExpr

syn match vim9Map /\<map\>!\=\ze\s*[^(]/
    \ contained
    \ nextgroup=@vim9MapLhs,vim9MapMod,vim9MapModExpr
    \ skipwhite

# Do *not* include `vim9MapLhsExpr` in the `nextgroup` argument.{{{
#
# `vim9MapLhsExpr`  is  only  possible  after  `<expr>`,  which  is  matched  by
# `vim9MapModExpr` which is included in `@vim9MapMod`.
#}}}
syn keyword vim9Map
    \ cm[ap] cno[remap] im[ap] ino[remap] lm[ap] ln[oremap] nm[ap] nn[oremap]
    \ no[remap] om[ap] ono[remap] smap snor[emap] tno[remap] tm[ap] vm[ap]
    \ vn[oremap] xm[ap] xn[oremap]
    \ contained
    \ nextgroup=vim9MapBang,vim9MapLhs,@vim9MapMod
    \ skipwhite

syn keyword vim9Map
    \ mapc[lear] smapc[lear] cmapc[lear] imapc[lear] lmapc[lear]
    \ nmapc[lear] omapc[lear] tmapc[lear] vmapc[lear] xmapc[lear]
    \ contained

syn keyword vim9Unmap
    \ cu[nmap] iu[nmap] lu[nmap] nun[map] ou[nmap] sunm[ap]
    \ tunma[p] unm[ap] unm[ap] vu[nmap] xu[nmap]
    \ contained
    \ nextgroup=vim9MapBang,@vim9MapLhs,@vim9MapMod
    \ skipwhite

syn match vim9MapLhs /\S\+/
    \ contained
    \ contains=vim9CtrlChar,vim9Notation
    \ nextgroup=vim9MapRhs
    \ skipwhite

syn match vim9MapLhsExpr /\S\+/
    \ contained
    \ contains=vim9CtrlChar,vim9Notation
    \ nextgroup=vim9MapRhsExpr
    \ skipwhite

syn match vim9MapBang /!/ contained nextgroup=@vim9MapLhs,@vim9MapMod skipwhite

exe 'syn match vim9MapMod'
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

exe 'syn match vim9MapModExpr'
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

syn case ignore
syn keyword vim9MapModKey contained
    \ buffer expr leader localleader nowait plug script sid silent unique
syn case match

syn match vim9MapRhs /.*/
    \ contained
    \ contains=
    \     vim9CtrlChar,
    \     vim9MapCmd,
    \     vim9MapCmdlineExpr,
    \     vim9MapInsertExpr,
    \     vim9Notation
    \ nextgroup=vim9MapRhsExtend
    \ skipnl

syn match vim9MapRhsExpr /.*/
    \ contained
    \ contains=@vim9Expr,vim9CtrlChar,vim9Notation
    \ nextgroup=vim9MapRhsExtendExpr
    \ skipnl

syn region vim9MapCmd
    \ start=/\c<cmd>/
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9Expr,vim9MapCmdBar,vim9Notation,vim9SpecFile
    \ keepend
    \ oneline

syn region vim9MapInsertExpr
    \ start=/\c<c-r>=\@=/
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9Expr,vim9EvalExpr,vim9Notation
    \ keepend
    \ oneline
syn match vim9EvalExpr /\%(<c-r>\)\@6<==/ contained

syn region vim9MapCmdlineExpr
    \ matchgroup=vim9Notation
    \ start=/\c<c-\\>e/
    \ matchgroup=NONE
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9Expr,vim9Notation
    \ keepend
    \ oneline

# Highlight what comes after `<bar>` as a command:{{{
#
#     nno xxx <cmd>call FuncA() <bar> call FuncB()<cr>
#                                     ^--^
#
# But only if it's between `<cmd>` and `<cr>`.
# Anywhere else, we have no guarantee that we're on the command-line.
#}}}
syn match vim9MapCmdBar /\c<bar>/
    \ contained
    \ contains=vim9Notation
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

syn match vim9MapRhsExtend /^\s*\\.*$/ contained contains=vim9Continuation
syn match vim9MapRhsExtendExpr /^\s*\\.*$/
    \ contained
    \ contains=@vim9Expr,vim9Continuation

# :normal {{{3

# Warning: Do not turn `:syn match` into `:syn keyword`.
# It would break the highlighting of a possible following bang.
syn match vim9Norm /\<norm\%[al]\>/ nextgroup=vim9NormCmds contained skipwhite
syn match vim9Norm /\<norm\%[al]\>!/he=e-1 nextgroup=vim9NormCmds contained skipwhite

# in a mapping, stop before the `<cr>` which executes `:norm`
syn region vim9NormCmds start=/./ end=/$\|\ze\c<cr>/ contained oneline

# :substitute {{{3

# TODO: Why did we include `vim9Notation` here?
#
# Some  of its  effects are  really  nice in  a substitution  pattern (like  the
# highlighting of capturing groups).  But I  don't think all of its effects make
# sense here.   Consider replacing it  with a  similar groups whose  effects are
# limited to the ones which make sense.
#
# Also, make sure to include it in  any pattern supplied to a command (`:catch`,
# `:global`, `:vimgrep`)...
syn cluster vim9SubstList contains=
    \ vim9Collection,
    \ vim9Notation,
    \ vim9PatRegion,
    \ vim9PatSep,
    \ vim9PatSepErr,
    \ vim9SubstRange,
    \ vim9SubstTwoBS

syn cluster vim9SubstRepList contains=
    \ vim9Notation,
    \ vim9SubstSubstr,
    \ vim9SubstTwoBS

# Warning: Do *not* use `display` here.{{{
#
# It could break some subsequent highlighting.
#
# MWE:
#
#     # test script
#     vim9script
#     def Foo()
#         s/(")"//
#     enddef
#     def Bar()
#     enddef
#
#     # command to execute:
#     syn clear vim9Subst
#
# Notice that everything gets broken after the substitution command.
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vim9Subst` is defined with `display`
#}}}
exe 'syn match vim9Subst'
    .. ' /\<s\%[ubstitute]\>\s*\ze\(' .. pattern_delimiter .. '\).\{-}\1.\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9SubstPat'

exe 'syn region vim9SubstPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/re=e-1,me=e-1'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' nextgroup=vim9SubstRep'
    .. ' oneline'

syn region vim9SubstRep
    \ matchgroup=vim9SubstDelim
    \ start=/\z(.\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vim9Notation
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9SubstRepList
    \ nextgroup=vim9SubstFlagErr
    \ oneline

syn region vim9SubstRep
    \ matchgroup=vim9SubstDelim
    \ start=/\z(.\)\%(\\=\)\@=/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vim9Notation
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9Expr,vim9EvalExpr
    \ nextgroup=vim9SubstFlagErr
    \ oneline
syn match vim9EvalExpr /\\=/ contained

syn region vim9Collection
    \ start=/\\\@1<!\[/
    \ skip=/\\\[/
    \ end=/\]/
    \ contained
    \ contains=vim9CollationClass
    \ transparent

syn match vim9CollationClassErr /\[:.\{-\}:\]/ contained

exe 'syn match vim9CollationClass'
    .. ' /\[:'
    .. '\%(' .. collation_class .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syn match vim9SubstSubstr /\\z\=\d/ contained
syn match vim9SubstTwoBS /\\\\/ contained
syn match vim9SubstFlagErr /[^< \t\r|]\+/ contained contains=vim9SubstFlags
syn match vim9SubstFlags /[&cegiIlnpr#]\+/ contained

# :syntax {arguments} {{{3
# :syntax {{{4

# Order: Must come *before* the rule setting `vim9HiGroup`.{{{
#
# Otherwise, the name of a highlight group would not be highlighted here:
#
#     syn clear Foobar
#               ^----^
#}}}
# Must exclude the bar for this to work:{{{
#
#     syn clear | eval 0
#               ^
#               not part of a group name
#}}}
syn match vim9GroupList /@\=[^ \t,|']\+/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep

syn match vim9GroupList /@\=[^ \t,']*,/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep
    \ nextgroup=vim9GroupList

# Warning: Do not turn `:syn match` into `:syn keyword`.
# It would fail to match `CONTAINED`.
syn match vim9GroupSpecial /\%(ALL\|ALLBUT\|CONTAINED\|TOP\)/ contained
syn match vim9SynError /\i\+/ contained
syn match vim9SynError /\i\+=/ contained nextgroup=vim9GroupList

syn match vim9SynContains /\<contain\%(s\|edin\)/ contained nextgroup=vim9SynEqual
syn match vim9SynEqual /=/ contained nextgroup=vim9GroupList

syn match vim9SynKeyContainedin /\<containedin/ contained nextgroup=vim9SynEqual
syn match vim9SynNextgroup /nextgroup/ contained nextgroup=vim9SynEqual

# Warning: Do not turn `:syn match` into `:syn keyword`.
syn match vim9Syntax /\<sy\%[ntax]\>/
    \ contained
    \ contains=vim9GenericCmd
    \ nextgroup=vim9Comment,vim9SynType
    \ skipwhite

# :syntax case {{{4

syn keyword vim9SynType contained
    \ case skipwhite
    \ nextgroup=vim9SynCase,vim9SynCaseError

syn match vim9SynCaseError /\i\+/ contained
syn keyword vim9SynCase ignore match contained

# :syntax clear {{{4

# `vim9HiGroup` needs  to be in the  `nextgroup` argument, so that  `{group}` is
# highlighted in `syn clear {group}`.
syn keyword vim9SynType clear
    \ contained
    \ nextgroup=vim9GroupList,vim9HiGroup
    \ skipwhite

# :syntax cluster {{{4

syn keyword vim9SynType cluster contained nextgroup=vim9ClusterName skipwhite

syn region vim9ClusterName
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ matchgroup=vim9Sep
    \ end=/$\||/
    \ contained
    \ contains=vim9GroupAdd,vim9GroupRem,vim9SynContains,vim9SynError

syn match vim9GroupAdd /add=/ contained nextgroup=vim9GroupList
syn match vim9GroupRem /remove=/ contained nextgroup=vim9GroupList

# :syntax iskeyword {{{4

syn keyword vim9SynType iskeyword contained nextgroup=vim9IskList skipwhite
syn match vim9IskList /\S\+/ contained contains=vim9IskSep
syn match vim9IskSep /,/ contained

# :syntax include {{{4

syn keyword vim9SynType include contained nextgroup=vim9GroupList skipwhite

# :syntax keyword {{{4

syn cluster vim9SynKeyGroup contains=
    \ vim9SynKeyContainedin,
    \ vim9SynKeyOpt,
    \ vim9SynNextgroup

syn keyword vim9SynType keyword contained nextgroup=vim9SynKeyRegion skipwhite

syn region vim9SynKeyRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ matchgroup=vim9Sep
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynKeyGroup
    \ keepend
    \ oneline

syn match vim9SynKeyOpt
    \ /\<\%(conceal\|contained\|transparent\|skipempty\|skipwhite\|skipnl\)\>/
    \ contained

# :syntax match {{{4

syn cluster vim9SynMtchGroup contains=
    \ vim9Comment,
    \ vim9MtchComment,
    \ vim9Notation,
    \ vim9SynContains,
    \ vim9SynError,
    \ vim9SynMtchOpt,
    \ vim9SynNextgroup,
    \ vim9SynRegPat

syn keyword vim9SynType match contained nextgroup=vim9SynMatchRegion skipwhite

syn region vim9SynMatchRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ matchgroup=vim9Sep
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynMtchGroup
    \ keepend

exe 'syn match vim9SynMtchOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syn match vim9SynMtchOpt /\<cchar=/ contained nextgroup=vim9SynMtchCchar
syn match vim9SynMtchCchar /\S/ contained

# :syntax [on|off] {{{4

syn keyword vim9SynType enable list manual off on reset contained

# :syntax region {{{4

syn cluster vim9SynRegPatGroup contains=
    \ vim9NotPatSep,
    \ vim9Notation,
    \ vim9PatRegion,
    \ vim9PatSep,
    \ vim9PatSepErr,
    \ vim9SubstSubstr,
    \ vim9SynNotPatRange,
    \ vim9SynPatRange

syn cluster vim9SynRegGroup contains=
    \ vim9SynContains,
    \ vim9SynMtchGrp,
    \ vim9SynNextgroup,
    \ vim9SynRegOpt,
    \ vim9SynRegStartSkipEnd

syn keyword vim9SynType region contained nextgroup=vim9SynRegion skipwhite

syn region vim9SynRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynRegGroup
    \ keepend

exe 'syn match vim9SynRegOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\%(ends\)\=\|transparent\|contained\|excludenl'
    .. '\|' .. 'skipempty\|skipwhite\|display\|keepend\|oneline\|extend\|skipnl'
    .. '\|' .. 'fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syn match vim9SynRegStartSkipEnd /\%(start\|skip\|end\)=\@=/
    \ contained
    \ nextgroup=vim9SynEqualRegion
syn match vim9SynEqualRegion /=/ contained nextgroup=vim9SynRegPat

syn match vim9SynMtchGrp /matchgroup/ contained nextgroup=vim9SynEqualMtchGrp
syn match vim9SynEqualMtchGrp /=/ contained nextgroup=vim9Group,vim9HLGroup

syn region vim9SynRegPat
    \ start=/\z([-`~!@#$%^&*_=+;:'",./?|]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contained
    \ contains=@vim9SynRegPatGroup
    \ extend
    \ nextgroup=vim9SynPatMod,vim9SynRegStartSkipEnd
    \ skipwhite

syn match vim9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=/
    \ contained

syn match vim9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,/
    \ contained
    \ nextgroup=vim9SynPatMod

syn region vim9SynPatRange start=/\[/ skip=/\\\\\|\\]/ end=/]/ contained
syn match vim9SynNotPatRange /\\\\\|\\\[/ contained
syn match vim9MtchComment /#[^#]\+$/ contained

# :syntax sync {{{4

syn keyword vim9SynType sync
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

syn match vim9SyncError /\i\+/ contained
syn keyword vim9SyncC ccomment clear fromstart contained
syn keyword vim9SyncMatch match contained nextgroup=vim9SyncGroupName skipwhite
syn keyword vim9SyncRegion region contained nextgroup=vim9SynRegStartSkipEnd skipwhite

syn match vim9SyncLinebreak /\<linebreaks=/
    \ contained
    \ nextgroup=vim9Number
    \ skipwhite

syn keyword vim9SyncLinecont linecont contained nextgroup=vim9SynRegPat skipwhite
syn match vim9SyncLines /\%(min\|max\)\=lines=/ contained nextgroup=vim9Number
syn match vim9SyncGroupName /\h\w*/ contained nextgroup=vim9SyncKey skipwhite

# Warning: Do not turn `:syn match` into `:syn keyword`.
syn match vim9SyncKey /\<\%(groupthere\|grouphere\)\>/
    \ contained
    \ nextgroup=vim9SyncGroup
    \ skipwhite

syn match vim9SyncGroup /\h\w*/
    \ contained
    \ nextgroup=vim9SynRegPat,vim9SyncNone
    \ skipwhite

syn keyword vim9SyncNone NONE contained
#}}}3
# :vimgrep {{{3

exe 'syn match vim9VimGrep'
    .. ' /\<vim\%[grep]\ze\s*\(' .. pattern_delimiter .. '\).\{-}\1/'
    .. ' nextgroup=vim9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

exe 'syn region vim9VimGrepPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' oneline'

# :{range}!{filter} {{{3
# `:h :range!`

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
# Second, `:term` is a better mechanism anyway; in your code, use it instead.
#}}}
syn match vim9Filter /!/ contained nextgroup=vim9FilterShellCmd
syn match vim9FilterShellCmd /.*/ contained contains=vim9FilterLastShellCmd
# TODO: Support special filenames like `%:p`, `%%`, ...

# Inside a filter command, an unescaped `!` has a special meaning:{{{
#
# From `:h :!`:
#
#    > Any '!' in {cmd} is replaced with the previous
#    > external command (see also 'cpoptions').  But not when
#    > there is a backslash before the '!', then that
#    > backslash is removed.
#}}}
syn match vim9FilterLastShellCmd /\\\@1<!!/ display contained

# :++ / :-- {{{3

# increment/decrement
# The `++` and `--` operators are implemented as Ex commands:{{{
#
#     echo getcompletion('[-+]', 'command')
#     ['++', '--']˜
#
# Which makes sense.  They can only appear at the start of a line.
#}}}
syn match vim9Increment /\%(++\|--\)\h\@=/ contained nextgroup=vim9IncrementInvalid skipwhite

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
syn match vim9IncrementInvalid /[^ \t\n|]*/ contained contains=vim9IncrementValid
syn match vim9IncrementValid /\w\+/ contained
#}}}1
# Functions {{{1
# User Definition {{{2
# Vim9 {{{3

exe 'syn match vim9FuncHeader'
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

syn keyword vim9DefKey def fu[nction]
    \ contained
    \ nextgroup=vim9DefBangError,vim9DefBang
# :def! is valid
syn match vim9DefBang /!/ contained
# but only for global functions
syn match vim9DefBangError /!\%(\s\+g:\)\@!/ contained

# Ending the  signature at `enddef`  prevents a temporary unbalanced  paren from
# causing havoc beyond the end of the function.
syn region vim9FuncSignature
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

exe 'syn match vim9FuncArgs'
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

syn match vim9FuncEnd /^\s*enddef\ze\s*\%(#.*\)\=$/

# Legacy {{{3

exe 'syn match vim9LegacyFunction'
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
syn region vim9LegacyFuncBody
    \ start=/\s*(/
    \ matchgroup=vim9DefKey
    \ end=/^\s*\<endf\%[unction]\ze\s*\%(".*\)\=$/
    \ contained
    \ contains=vim9LegacyComment,vim9String
    \ nextgroup=vim9LegacyComment
    \ skipwhite

# We  need to  support inline  comments (if  only for  a trailing  comment after
# `:endfunction`), so we can't anchor the comment to the start of the line.
syn match vim9LegacyComment /".*/ contained
#}}}2
# User Call {{{2

# call to any kind of function (builtin + user)
exe 'syn match vim9FuncCall'
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
exe 'syn match vim9UserFuncNameUser'
    .. ' /'
    .. '\<\%('
    ..     '\%('
    ..             '[bgstw]:'
    ..     '\|' .. '\%(\c<sid>\)\@5<='
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
    .. ' contains=vim9Notation'

# Builtin Call {{{2

# Install a `:syn keyword` rule to highlight *most* function names.{{{
#
# Except  the ones  which  are too  ambiguous,  and match  an  Ex command  (e.g.
# `eval()`, `execute()`, `function()`, ...).
#
# Rationale: We don't want to wrongly highlight `:eval` as a function.
# To remove any ambiguity, we need to assert the presence of an open paren after
# the function name.  That's only possible with a separate `:syn match` rule.
#
# NOTE: We  don't  want to  assert  the  paren  for  *all* function  names;  the
# necessary regex would be too costly.
#}}}
exe 'syn keyword vim9FuncNameBuiltin'
    .. ' ' .. builtin_func
    .. ' contained'

exe 'syn match vim9FuncNameBuiltin'
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
syn cluster vim9OperGroup contains=
    \ @vim9Expr,
    \ vim9Comment,
    \ vim9Continuation,
    \ vim9Notation,
    \ vim9Oper,
    \ vim9OperAssign,
    \ vim9OperParen

# We need to match a dict with `nextgroup`.{{{
#
# To give it priority over a block:
#
#     var n = 12 +
#         {
#             key: 34,
#         }
#         .key
#}}}
exe 'syn match vim9Oper'
    .. ' ' .. most_operators
    .. ' display'
    .. ' nextgroup=vim9Dict'
    .. ' skipnl'
    .. ' skipwhite'

#   =
#  -=
#  +=
#  *=
#  /=
#  %=
# ..=
# `nextgroup` is necessary to prevent a dictionary from being matched as a block.{{{
#
#     var d =
#         {
#             key: 123,
#         }
#}}}
syn match vim9OperAssign #\s\@1<=\%([-+*/%]\|\.\.\)\==\_s\@=#
    \ display
    \ nextgroup=vim9Dict
    \ skipnl
    \ skipwhite

# methods
syn match vim9Oper /->\%(\_s*\h\)\@=/ skipwhite
# logical not
exe 'syn match vim9Oper' .. ' ' .. logical_not .. ' display skipwhite'

# support `:` when used inside conditional `?:` operator
# But we need to ignore `:` inside a slice, which is tricky.{{{
#
# For the moment, we use an imperfect regex.
# We just  make sure that `:`  is preceded by a  `?`, while no `[`  can be found
# in-between, to support this kind of code:
#
#     eval 1 ? 2 : 3
#                ^
#
# While ignoring this:
#
#     eval list[1 : 2]
#                 ^
#
# *Or* we make sure that only whitespace precede the colon, to support:
#
#     eval 1
#         ? 2
#         : 3
#         ^
#}}}
syn match vim9Oper /\%(?[^[]*\s\|^\s\+\)\@<=:\_s\@=/
    \ display
    \ nextgroup=vim9Dict
    \ skipnl
    \ skipwhite

# contains `@vim9ErrorSpaceArgs` to handle errors in function calls
syn region vim9OperParen
    \ matchgroup=vim9ParenSep
    \ start=/(/
    \ end=/)/
    \ contains=
    \     @vim9ErrorSpaceArgs,
    \     @vim9OperGroup,
    \     vim9Block

# Data Types {{{1
# `vim9Expr` {{{2

syn cluster vim9Expr contains=
    \ vim9Bool,
    \ vim9DataTypeCast,
    \ vim9Dict,
    \ vim9EnvVar,
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
    \ vim9String

# Booleans / null / v:none {{{2

# Even though `v:` is useless in Vim9, we  still need it in a mapping; because a
# mapping is run in the legacy context, even when installed from a Vim9 script.
syn match vim9Bool /\%(v:\)\=\<\%(false\|true\)\>:\@!/
syn match vim9Null /\%(v:\)\=\<null\>:\@!/

syn match vim9None /\<v:none\>:\@!/

# Strings {{{2

syn match vim9String /[^(,]'[^']\{-}\zs'/

# Try to catch strings, if nothing else matches (therefore it must precede the others!)
# vim9EscapeBrace handles ["]  []"] (ie. "s don't terminate string inside [])
syn region vim9EscapeBrace
    \ start=/[^\\]\%(\\\\\)*\[\zs\^\=\]\=/
    \ skip=/\\\\\|\\\]/
    \ end=/]/me=e-1
    \ contained
    \ oneline
    \ transparent

syn match vim9PatSepErr /\\)/ contained
syn match vim9PatSep /\\|/ contained

syn region vim9PatSepZone
    \ matchgroup=vim9PatSepZ
    \ start=/\\%\=\ze(/
    \ skip=/\\\\/
    \ end=/\\)\|[^\\]['"]/
    \ contained
    \ contains=@vim9StringGroup
    \ oneline

syn region vim9PatRegion
    \ matchgroup=vim9PatSepR
    \ start=/\\[z%]\=(/
    \ end=/\\)/
    \ contained
    \ contains=@vim9SubstList
    \ oneline
    \ transparent

syn match vim9NotPatSep /\\\\/ contained

syn cluster vim9StringGroup contains=
    \ @Spell,
    \ vim9EscapeBrace,
    \ vim9NotPatSep,
    \ vim9PatSep,
    \ vim9PatSepErr,
    \ vim9PatSepZone

syn region vim9String
    \ start=/[^a-zA-Z>!\\@]\@1<="/
    \ skip=/\\\\\|\\"/
    \ matchgroup=vim9StringEnd
    \ end=/"/
    \ contains=@vim9StringGroup
    \ keepend
    \ oneline

# In a  syntax file, we  often build  syntax rules with  strings concatenations,
# which we then `:execute`.  Highlight the tokens inside the strings.
if expand('%:p:h:t') == 'syntax'
    syn region vim9String
        \ start=/[^a-zA-Z>!\\@]\@1<='/
        \ end=/'/
        \ contains=@vim9SynRegGroup,vim9SynExeCmd
        \ keepend
        \ oneline
    syn match vim9SynExeCmd /\<sy\%[ntax]\>/  contained nextgroup=vim9SynExeType skipwhite
    syn keyword vim9SynExeType keyword match region contained nextgroup=vim9SynExeGroupName skipwhite
    syn match vim9SynExeGroupName /[^' \t]\+/ contained
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
    syn region vim9String
        \ start=/[^a-zA-Z>!\\@]\@1<='/
        \ end=/'\d\@!/
        \ keepend
        \ oneline
endif

syn region vim9String
    \ start=/=\@1<=!/
    \ skip=/\\\\\|\\!/
    \ end=/!/
    \ contains=@vim9StringGroup
    \ oneline

syn region vim9String
    \ start=/=\@1<=+/
    \ skip=/\\\\\|\\+/
    \ end=/+/
    \ contains=@vim9StringGroup
    \ oneline

syn match vim9String /"[^"]*\\$/ contained nextgroup=vim9StringCont skipnl
syn match vim9StringCont /\%(\\\\\|.\)\{-}[^\\]"/ contained

# Numbers {{{2

syn match vim9Number /\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /\<0[xX]\x\+\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\%(^\|\A\)\zs#\x\{6}\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\<0[zZ][a-fA-F0-9.]\+\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\<0o[0-7]\+\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\<0b[01]\+\>/ nextgroup=vim9Comment skipwhite

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
#     vim9script
#     def Foo()
#         (1'2) .. ''
#     enddef
#     def Bar()
#     enddef
#
#     # command to execute:
#     syn clear vim9Number
#
# Notice that everything gets broken starting from the number.
#
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vim9Number` is defined with `display`
#}}}
syn match vim9Number /\d\@1<='\d\@=/ nextgroup=vim9Comment skipwhite

# Dictionaries {{{2

# Order: Must come before `vim9Block`.
syn region vim9Dict
    \ matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contains=@vim9OperGroup,vim9DictExprKey,vim9DictMayBeLiteralKey

# In literal dictionary, highlight unquoted key names as strings.
syn match vim9DictMayBeLiteralKey /\%(^\|[ \t{]\)\@1<=[^ \t{('"]\+\ze\%(:\s\)\@=/
    \ display
    \ contained
    \ contains=vim9DictIsLiteralKey
    \ keepend

# check the validity of the key
syn match vim9DictIsLiteralKey /\%(\w\|-\)\+/ contained

# support expressions as keys (`[expr]`).
syn match vim9DictExprKey /\[.\{-}]\%(:\s\)\@=/
    \ contained
    \ contains=@vim9Expr
    \ keepend

# Lambdas {{{2

# We need to assert the presence of an argument at the start of the lambda.{{{
#
# So that we don't start from the wrong paren:
#
#           ✘
#           v
#     l->map((_, v) => ...
#            ^
#            ✔
#
#     ✘
#     v
#     (l1 + l2)->map((_, v) => 0)
#                    ^
#                    ✔
#
# ---
#
# When matching the closing paren, we can't stop immediately.
# Otherwise, we would match this:
#
#     Foo(name)->Bar((v) => v)
#        ^-------------^
#
# That's why we need to assert  that the arrow must follow immediately (although
# possibly with a type in-between):
#
#     \%(:.\{-}\)\=\s\+=>
#}}}
syn region vim9Lambda
    \ matchgroup=vim9ParenSep
    \ start=/(\ze\s*\h\w*\%([,:]\|\s*)\%(:.\{-}\)\=\s\+=>\)/
    \ end=/)\ze\%(:.\{-}\)\=\s\+=>/
    \ contains=@vim9DataTypeCluster,@vim9ErrorSpaceArgs,vim9LambdaArgs
    \ keepend
    \ nextgroup=@vim9DataTypeCluster
    \ oneline

syn match vim9LambdaArgs /\.\.\.\h[a-zA-Z0-9_]*/ contained
syn match vim9LambdaArgs /\%(:\s\)\@2<!\<\h[a-zA-Z0-9_]*/ contained

syn match vim9LambdaArrow /\s\@1<==>\_s\@=/
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
syn cluster vim9DataTypeCluster contains=
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
exe 'syn match vim9DataType'
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
    # or by a colon (in the case of `func`)
    ..     '\|[),:]'
    .. '\)\@='
    .. '/hs=s+1'
    #       ^^^
    #       let's not highlight the colon

# Composite data types need to be handled separately.
# First, let's deal with their leading colon.
syn match vim9DataTypeCompositeLeadingColon /:\s\+\%(\%(list\|dict\)<\|func(\)\@=/
    \ nextgroup=vim9DataTypeListDict,vim9DataTypeFuncref

# Now, we can deal with the rest.
# But a list/dict/funcref type can contain  itself; this is too tricky to handle
# with a  match and a  single regex.   It's much simpler  to let Vim  handle the
# possible recursion with a region which can contain itself.
syn region vim9DataTypeListDict
    \ matchgroup=vim9ValidSubType
    \ start=/\<\%(list\|dict\)</
    \ end=/>/
    \ contained
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline

syn region vim9DataTypeFuncref
    \ matchgroup=vim9ValidSubType
    \ start=/\<func(/
    \ end=/)/
    \ contained
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline

# validate subtypes
exe 'syn match vim9ValidSubType'
    .. ' /\<\%('
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
    .. '\<\%('
    ..         'd\@1<=ict<'
    .. '\|' .. 'l\@1<=ist<'
    .. '\|' .. 'f\@1<=unc(\|)'
    .. '\)'
    .. '/'
    .. ' display'
    .. ' contained'

# support `:h type-casting` for simple types
exe 'syn match vim9DataTypeCast'
    .. ' /<\%('
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)>'
    .. '\%([bgtw]:\)\@='
    .. '/'

# support `:h type-casting` for composite types
syn region vim9DataTypeCastComposite
    \ matchgroup=vim9ValidSubType
    \ start=/<\%(list\|dict\)</
    \ end=/>>/
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline

syn region vim9DataTypeCastComposite
    \ matchgroup=vim9ValidSubType
    \ start=/<func(/
    \ end=/)>/
    \ contains=vim9DataTypeFuncref,vim9DataTypeListDict,vim9ValidSubType
    \ oneline
#}}}1
# Options {{{1
# Assignment commands {{{2

syn keyword vim9Set setl[ocal] setg[lobal] se[t]
    \ contained
    \ nextgroup=vim9MayBeOptionSet
    \ skipwhite

# Names {{{2

# Note that an option value can be written right at the start of the line.{{{
#
#     &guioptions = 'M'
#     ^---------^
#}}}
exe 'syn match vim9MayBeOptionScoped'
    .. ' /'
    ..     option_can_be_after
    ..     option_sigil
    ..     option_valid
    .. '/'
    .. ' display'
    .. ' contains=vim9IsOption,vim9OptionSigil'
    # `vim9SetEqual` would be wrong here; we need spaces around `=`
    .. ' nextgroup=vim9OperAssign'

exe 'syn match vim9MayBeOptionSet'
    .. ' /'
    ..     option_can_be_after
    ..     option_valid
    .. '/'
    .. ' display'
    .. ' contained'
    .. ' contains=vim9IsOption'
    .. ' nextgroup=vim9SetEqual,vim9MayBeOptionSet,vim9SetMod'
    .. ' skipwhite'

syn match vim9OptionSigil /&\%([gl]:\)\=/ contained

exe 'syn keyword vim9IsOption'
    .. ' ' .. option
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'
    .. ' skipwhite'

exe 'syn keyword vim9IsOption'
    .. ' ' .. option_terminal
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

exe 'syn match vim9IsOption'
    .. ' /\V'
    .. option_terminal_special
    .. '/'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

# Assignment operators {{{2

syn match vim9SetEqual /[-+^]\==/
    \ contained
    \ nextgroup=vim9SetNumberValue,vim9SetStringValue

# Values + separators (`[,:]`) {{{2

exe 'syn match vim9SetStringValue'
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

syn match vim9SetSep /[,:]/ contained

# Order: Must come after `vim9SetStringValue`.
syn match vim9SetNumberValue /\d\+\_s\@=/
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
#     nno <key> <cmd>set wrap<bar> eval 0<cr>
#                            ^
#                            this is not a modifier which applies to 'wrap';
#                            this is the start of the Vim keycode <bar>
#}}}
syn match vim9SetMod /\%(&\%(vim\)\=\|[<?!]\)\%(\_s\||\)\@=/
    \ contained
    \ nextgroup=vim9MayBeOptionScoped,vim9MayBeOptionSet
    \ skipwhite
#}}}1
# Blocks {{{1

# at script-level or function-level
syn region vim9Block
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
#     exe 'cmd ' .. name
#         ^----^
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
# From `:h inline-function`:
#
#    > Unfortunately this means using "() => {  command  }" does not work, line
#    > breaks are always required.
#}}}
# Order: must come before the next `vim9Block` rule.
syn match vim9LambdaDictMissingParen /{/ contained

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
syn region vim9Block
    \ matchgroup=Statement
    \ start=/\%(=>\s\+\)\@<={$/
    \ end=/^\s*}/
    \ contained
    \ contains=TOP

# Highlight commonly used Groupnames {{{1

syn case ignore
syn keyword vim9Group contained
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
syn case match

# Default highlighting groups {{{1

syn case ignore
exe 'syn keyword vim9HLGroup contained' .. ' ' .. default_highlighting_group

# Warning: Do *not* turn this `match` into  a `keyword` rule; `conceal` would be
# wrongly interpreted as an argument to `:syntax`.
syn match vim9HLGroup /\<conceal\>/ contained
syn case match

# Special Filenames, Modifiers, Extension Removal {{{1

syn match vim9SpecFile /<c\%(word\|WORD\)>/ nextgroup=vim9SpecFileMod

syn match vim9SpecFile /<\%([acs]file\|amatch\|abuf\)>/
    \ nextgroup=vim9SpecFileMod

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
# ---
#
# Re-read `:h cmdline-special` to make sure everything is correct.

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
#     e % | eval 0
#       ^
#       ✘
#
# For the moment, it looks like a  corner case which we won't encounter often in
# practice, so let's not try to fix it.
#}}}
syn match vim9SpecFile /\s%:/ms=s+1,me=e-1 nextgroup=vim9SpecFileMod
# `%` can be followed by a bar, or `<bar>`:{{{
#
#     source % | eval 0
#              ^
#}}}
syn match vim9SpecFile /\s%\%($\|\s*[|<]\)\@=/ms=s+1 nextgroup=vim9SpecFileMod
syn match vim9SpecFile /\s%</ms=s+1,me=e-1 nextgroup=vim9SpecFileMod
syn match vim9SpecFile /%%\d\+\|%<\|%%</ nextgroup=vim9SpecFileMod
syn match vim9SpecFileMod /\%(:[phtreS]\)\+/ contained

# Lower Priority Comments: after some vim commands... {{{1

syn region vim9CommentString start=/\%(\S\s\+\)\@<="/ end=/"/ contained oneline

# inline comments
# Warning: Do *not* use the `display` argument here.

syn match vim9Comment /^\s*#.*$/ contains=@vim9CommentGroup

# Angle-Bracket Notation {{{1

exe 'syn match vim9Notation'
    .. ' /'
    .. '\c\%(\\\|<lt>\)\='
    .. '<'
    .. '\%([scam2-4]-\)\{0,4}'
    .. '\%(right\|left\|middle\)'
    .. '\%(mouse\)\='
    .. '\%(drag\|release\)\='
    .. '>'
    .. '/'
    .. ' contains=vim9Bracket'

syn match vim9Notation
    \ /\c\%(\\\|<lt>\)\=<\%(bslash\|plug\|sid\|space\|nop\|nul\|lt\)>/
    \ contains=vim9Bracket

exe 'syn match vim9Notation'
    .. ' /'
    .. '\c\%(\\\|<lt>\)\='
    .. '<'
    .. '\%(q-\)\='
    .. '\%(line[12]\|count\|bang\|reg\|args\|mods\|f-args\|f-mods\|lt\)'
    .. '>'
    .. '/'
    .. ' contains=vim9Bracket'

syn match vim9Notation
    \ /\c\%(\\\|<lt>\)\=<\%([cas]file\|abuf\|amatch\|cword\|cWORD\|client\)>/
    \ contains=vim9Bracket

syn match vim9Bracket /[\\<>]/ contained

# Control Characters {{{1

syn match vim9CtrlChar /[\x01-\x08\x0b\x0f-\x1f]/

# Patterns matching at start of line {{{1

syn match vim9CommentLine /^[ \t]\+#.*$/ contains=@vim9CommentGroup

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
# See `:h :syn-pattern-offset`:
#}}}
syn match vim9CommentTitle /#\s*\u\%(\w\|[()]\)*\%(\s\+\u\w*\)*:/hs=s+1
    \ contained
    \ contains=@vim9CommentGroup

syn match vim9Continuation /^\s*\\/
    \ nextgroup=
    \     vim9SynContains,
    \     vim9SynContinuePattern,
    \     vim9SynMtchGrp,
    \     vim9SynNextgroup,
    \     vim9SynRegOpt,
    \     vim9SynRegStartSkipEnd
    \ skipwhite

syn match vim9SynContinuePattern =\s\+/[^/]*/= contained

syn region vim9String
    \ start=/^\s*\\\z(['"]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contains=@vim9StringGroup,vim9Continuation
    \ keepend
    \ oneline

# Backtick expansion {{{1

#     `shell command`
syn region vim9BacktickExpansion
    \ matchgroup=Special
    \ start=/`\%([^`=]\)\@=/
    \ end=/`/

#     `=Vim expr`
syn region vim9BacktickExpansionVimExpr
    \ matchgroup=Special
    \ start=/`=/
    \ end=/`/
    \ contains=@vim9Expr

# fixme/todo notices in comments {{{1

syn keyword vim9Todo FIXME TODO contained
syn cluster vim9CommentGroup contains=
    \ @Spell,
    \ vim9CommentString,
    \ vim9CommentTitle,
    \ vim9DictLiteralLegacyDeprecated,
    \ vim9Todo

# Embedded Scripts  {{{1
# Python {{{2

unlet! b:current_syntax
syn include @vim9PythonScript syntax/python.vim

syn region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/py\%[thon][3x]\=\s\+<<\s\+\z(\S\+\)$/
    \ end=/^\z1$/
    \ matchgroup=vim9Error
    \ end=/^\s\+\z1$/
    \ contains=@vim9PythonScript

syn region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/py\%[thon][3x]\=\s\+<<$/
    \ end=/\.$/
    \ contains=@vim9PythonScript

# Lua {{{2

unlet! b:current_syntax
syn include @vim9LuaScript syntax/lua.vim

syn region vim9LuaRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/lua\s\+<<\s\+\z(\S\+\)$/
    \ end=/^\z1$/
    \ matchgroup=vim9Error
    \ end=/^\s\+\z1$/
    \ contains=@vim9LuaScript

syn region vim9LuaRegion
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
#     nno <F3> <cmd>let g:myvar = 123<cr>
#
#     ✔
#     nno <F3> <cmd>call Func()<cr>
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
    syn keyword vim9LetDeprecated let contained

    # In legacy Vim script, a literal dictionary starts with `#{`.
    # This syntax is no longer valid in Vim9.
    syn match vim9DictLiteralLegacyDeprecated /#{{\@!/
endif

    # TODO: Doesn't work at the start of an indented line.
    # Update: Who cares?  It can't appear at the start of a line in legacy...
    syn match vim9LegacyVarargs /a:000/
    hi def link vim9LegacyVarargs vim9Error
    # TODO: Handle other  legacy constructs  like `a:`, `l:`,  lambdas (tricky),
    # single dots for concatenation (tricky)...
    # Also `...)` in a function's header.
    # What about eval strings?

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

    # TODO: Highlight `:call` as a useless.
    # But not after `<cmd>` nor `<bar>`.
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
    #                v---v
    #     def Func() abort
    #
    # In fact, highlight anything as an error.
    # But  do it  early, so  that  the return  type  and an  inline comment  can
    # override the highlighting.

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

# List unpack declaration {{{2

# Declaring more than one variable at a  time, using the unpack notation, is not
# supported.  See `:h E1092`.
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('list_unpack_declaration', true)

    syn region vim9ListUnpackDeclaration
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
    syn region vim9SpaceExtraAfterFuncname
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
    syn match vim9SpaceMissingBetweenArgs /,\S\@=/ contained

    #           ✘
    #           v
    #     Func(1 , 2)
    #     Func(1, 2)
    #           ^
    #           ✔
    syn match vim9SpaceExtraBetweenArgs /\s\@1<=,/ display contained

    syn cluster vim9ErrorSpaceArgs contains=
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
    syn region vim9Comment
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
    syn region vim9ListSlice
        \ matchgroup=vim9Sep
        \ start=/\[/
        \ end=/\]/
        \ contains=
        \     @vim9OperGroup,
        \     vim9ColonForVariableScope,
        \     vim9ListSlice,
        \     vim9SpaceMissingListSlice
    # If a colon is not prefixed with a space, it's an error.
    syn match vim9SpaceMissingListSlice /[^ \t[]\@1<=:/ display contained
    # If a colon is not followed with a space, it's an error.
    syn match vim9SpaceMissingListSlice /:[^ \t\]]\@=/ contained
    # Corner Case: A colon can be used in a variable name.  Ignore it.{{{
    #
    #     b:name
    #      ^
    #      ✔
    #}}}
    # Order: Out of these 3 rules, this one must come last.
    syn match vim9ColonForVariableScope /\<[bgstvw]:\w/ display contained
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
    syn match vim9Number /\%(\d'\)\@2<!\<0[0-7]\+\>/he=s+1
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
# handle.   Indeed,  it would  break  all  the  `syn  keyword` rules  for  words
# containing digits.   It would also change  the semantics of the  `\<` and `\>`
# atoms in all regexes used for `syn match` and `syn region` rules.
#}}}
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('range_missing_space', false)

    syn match vim9RangeMissingSpace /\S\@1<=\a/ display contained
endif

# Discourage usage  of an  implicit line  specifier, because  it makes  the code
# harder to read.
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('range_missing_specifier', false)
    syn match vim9RangeMissingSpecifier1 /[,;]/
        \ contained
        \ nextgroup=@vim9Range

    syn match vim9RangeMissingSpecifier2 /[,;][a-zA-Z \t]\@=/
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
    syn keyword vim9ReservedNames true false null this contained
endif
#}}}1
# Synchronize (speed) {{{1

syn sync maxlines=60
syn sync linecont /^\s\+\\/
syn sync match vim9AugroupSyncA groupthere NONE /\<aug\%[roup]\>\s\+END/
#}}}1

# Highlight Groups {{{1
# All highlight groups need to be defined with the `default` argument.{{{
#
# So that they survive after we change/reload the colorscheme.
# Indeed, a colorscheme always executes `:hi clear` to reset all highlighting to
# the  defaults.  By  default, the  user-defined HGs  do not  exist, so  for the
# latter, "reset all highlighting" means:
#
#    - removing all their attributes
#
#         $ vim --cmd 'hi WillItSurvive ctermbg=green | hi clear | hi WillItSurvive |cq'
#         WillItSurvive  xxx cleared˜
#
#    - removing the links
#
#         $ vim --cmd 'hi link WillItSurvive ErrorMsg | hi clear | hi WillItSurvive |cq'
#         WillItSurvive  xxx cleared˜
#}}}

hi def link vim9GenericCmd Statement
# Make Vim highlight user commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we  want them  to be  bold, so  that we  can't conflate  a user
# command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     hi def link vim9UserCmdExe vim9GenericCmd
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that when the syntax item for `vim9UserCmdExe` was defined earlier (with
# a `:syn`  command), Vim has automatically  created a highlight group  with the
# same name; but it's cleared:
#
#     vim9UserCmdExe      xxx cleared
#
# That's why we don't write this:
#
#     if execute('hi vim9UserCmdExe') == ''
#                                     ^---^
#                                       ✘
#}}}
if execute('hi vim9UserCmdExe') =~ '\<cleared$'
    import Derive from 'vim9syntaxUtil.vim'
    Derive('vim9UserFuncNameUser', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9UserCmdExe', 'vim9GenericCmd', 'term=bold cterm=bold gui=bold')
    Derive('vim9FuncHeader', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9CmdModifier', 'vim9GenericCmd', 'term=italic cterm=italic gui=italic')
endif

hi def link vim9Error Error

hi def link vim9AutocmdEventBadCase vim9Error
hi def link vim9CollationClassErr vim9Error
hi def link vim9DefBangError vim9Error
hi def link vim9DictLiteralLegacyDeprecated vim9Error
hi def link vim9DictMayBeLiteralKey vim9Error
hi def link vim9FTError vim9Error
hi def link vim9FuncCall vim9Error
hi def link vim9HiAttribList vim9Error
hi def link vim9HiCtermError vim9Error
hi def link vim9HiKeyError vim9Error
hi def link vim9IncrementInvalid vim9Error
hi def link vim9LambdaDictMissingParen vim9Error
hi def link vim9LetDeprecated vim9Error
hi def link vim9ListUnpackDeclaration vim9Error
hi def link vim9MapModErr vim9Error
hi def link vim9OperError vim9Error
hi def link vim9PatSepErr vim9Error
hi def link vim9RangeMissingSpace vim9Error
hi def link vim9RangeMissingSpecifier1 vim9Error
hi def link vim9RangeMissingSpecifier2 vim9Error
hi def link vim9ReservedNames vim9Error
hi def link vim9SpaceExtraBetweenArgs vim9Error
hi def link vim9SpaceMissingBetweenArgs vim9Error
hi def link vim9SpaceMissingListSlice vim9Error
hi def link vim9SubstFlagErr vim9Error
hi def link vim9SynCaseError vim9Error
hi def link vim9SynCaseError vim9Error
hi def link vim9SynError vim9Error
hi def link vim9SyncError vim9Error
hi def link vim9UserCmdAttrbError vim9Error

hi def link vim9AbbrevCmd vim9GenericCmd
hi def link vim9Augroup vim9GenericCmd
hi def link vim9AugroupNameEnd Title
hi def link vim9Autocmd vim9GenericCmd
hi def link vim9AutocmdAllEvents vim9AutocmdEventGoodCase
hi def link vim9AutocmdEventGoodCase Type
hi def link vim9AutocmdGroup vim9AugroupNameEnd
hi def link vim9AutocmdMod Special
hi def link vim9AutocmdPat vim9String
hi def link vim9BacktickExpansion vim9ShellCmd
hi def link vim9Bool Boolean
hi def link vim9Bracket Delimiter
hi def link vim9BreakContinue vim9Repeat
hi def link vim9Comment Comment
hi def link vim9CommentLine vim9Comment
hi def link vim9CommentString vim9String
hi def link vim9CommentTitle PreProc
hi def link vim9Conditional Conditional
hi def link vim9Continuation Special
hi def link vim9CtrlChar SpecialChar
hi def link vim9DataType Type
hi def link vim9DataTypeCast vim9DataType
hi def link vim9Declare Identifier
hi def link vim9DefKey Keyword
hi def link vim9DictIsLiteralKey String
hi def link vim9DoCmds vim9Repeat
hi def link vim9Doautocmd vim9GenericCmd
hi def link vim9EchoHL vim9GenericCmd
hi def link vim9EchoHLNone vim9Group
hi def link vim9EvalExpr vim9OperAssign
hi def link vim9Export vim9Import
hi def link vim9FTCmd vim9GenericCmd
hi def link vim9FTOption vim9SynType
hi def link vim9FgBgAttrib vim9HiAttrib
hi def link vim9Filter vim9GenericCmd
hi def link vim9FilterLastShellCmd Special
hi def link vim9FilterShellCmd vim9ShellCmd
hi def link vim9Finish vim9Return
hi def link vim9FuncArgs Identifier
hi def link vim9FuncEnd vim9DefKey
hi def link vim9FuncNameBuiltin Function
hi def link vim9Global vim9GenericCmd
hi def link vim9GlobalPat vim9String
hi def link vim9Group Type
hi def link vim9GroupAdd vim9SynOption
hi def link vim9GroupName vim9Group
hi def link vim9GroupRem vim9SynOption
hi def link vim9GroupSpecial Special
hi def link vim9HLGroup vim9Group
hi def link vim9HereDoc vim9String
hi def link vim9HiAttrib PreProc
hi def link vim9HiCTerm vim9HiTerm
hi def link vim9HiClear vim9Highlight
hi def link vim9HiCtermFgBg vim9HiTerm
hi def link vim9HiCtermul vim9HiTerm
hi def link vim9HiGroup vim9GroupName
hi def link vim9HiGui vim9HiTerm
hi def link vim9HiGuiFgBg vim9HiTerm
hi def link vim9HiGuiFont vim9HiTerm
hi def link vim9HiGuiRgb vim9Number
hi def link vim9HiNmbr Number
hi def link vim9HiStartStop vim9HiTerm
hi def link vim9HiTerm Type
hi def link vim9Highlight vim9GenericCmd
hi def link vim9Import Include
hi def link vim9ImportAsFrom vim9Import
hi def link vim9Increment vim9Oper
hi def link vim9IsOption PreProc
hi def link vim9IskSep Delimiter
hi def link vim9LambdaArgs vim9FuncArgs
hi def link vim9LambdaArrow vim9Sep
hi def link vim9LegacyComment vim9Comment
hi def link vim9Map vim9GenericCmd
hi def link vim9MapMod vim9Bracket
hi def link vim9MapModExpr vim9MapMod
hi def link vim9MapModKey Special
hi def link vim9MtchComment vim9Comment
hi def link vim9None Constant
hi def link vim9Norm vim9GenericCmd
hi def link vim9NormCmds String
hi def link vim9NotPatSep vim9String
hi def link vim9Notation Special
hi def link vim9Null Constant
hi def link vim9Number Number
hi def link vim9Oper Operator
hi def link vim9OperAssign Identifier
hi def link vim9OptionSigil vim9IsOption
hi def link vim9ParenSep Delimiter
hi def link vim9PatSep SpecialChar
hi def link vim9PatSepR vim9PatSep
hi def link vim9PatSepZ vim9PatSep
hi def link vim9PatSepZone vim9String
hi def link vim9RangeMark Special
hi def link vim9RangeNumber Number
hi def link vim9RangeOffset Number
hi def link vim9RangePattern String
hi def link vim9RangePatternBwdDelim Delimiter
hi def link vim9RangePatternFwdDelim Delimiter
hi def link vim9RangeSpecialSpecifier Special
hi def link vim9Repeat Repeat
hi def link vim9RepeatForIn vim9Repeat
hi def link vim9Return vim9DefKey
hi def link vim9ScriptDelim Comment
hi def link vim9Sep Delimiter
hi def link vim9Set vim9GenericCmd
hi def link vim9SetEqual vim9OperAssign
hi def link vim9SetMod vim9IsOption
hi def link vim9SetNumberValue Number
hi def link vim9SetSep Delimiter
hi def link vim9SetStringValue String
hi def link vim9ShellCmd PreProc
hi def link vim9SpecFile Identifier
hi def link vim9SpecFileMod vim9SpecFile
hi def link vim9Special Type
hi def link vim9String String
hi def link vim9StringCont vim9String
hi def link vim9StringEnd vim9String
hi def link vim9Subst vim9GenericCmd
hi def link vim9SubstDelim Delimiter
hi def link vim9SubstFlags Special
hi def link vim9SubstPat vim9String
hi def link vim9SubstRep vim9String
hi def link vim9SubstSubstr SpecialChar
hi def link vim9SubstTwoBS vim9String
hi def link vim9SynCase Type
hi def link vim9SynContains vim9SynOption
hi def link vim9SynContinuePattern String
hi def link vim9SynEqual vim9OperAssign
hi def link vim9SynEqualMtchGrp vim9OperAssign
hi def link vim9SynEqualRegion vim9OperAssign
hi def link vim9SynExeCmd vim9GenericCmd
hi def link vim9SynExeGroupName vim9GroupName
hi def link vim9SynExeType vim9SynType
hi def link vim9SynKeyContainedin vim9SynContains
hi def link vim9SynKeyOpt vim9SynOption
hi def link vim9SynMtchGrp vim9SynOption
hi def link vim9SynMtchOpt vim9SynOption
hi def link vim9SynNextgroup vim9SynOption
hi def link vim9SynNotPatRange vim9SynRegPat
hi def link vim9SynOption Special
hi def link vim9SynPatRange vim9String
hi def link vim9SynRegOpt vim9SynOption
hi def link vim9SynRegPat vim9String
hi def link vim9SynRegStartSkipEnd Type
hi def link vim9SynType vim9Special
hi def link vim9SyncC Type
hi def link vim9SyncGroup vim9GroupName
hi def link vim9SyncGroupName vim9GroupName
hi def link vim9SyncKey Type
hi def link vim9SyncNone Type
hi def link vim9Syntax vim9GenericCmd
hi def link vim9Todo Todo
hi def link vim9TryCatch Exception
hi def link vim9TryCatchPattern String
hi def link vim9TryCatchPatternDelim Delimiter
hi def link vim9Unmap vim9Map
hi def link vim9UserCmdAttrbAddress vim9String
hi def link vim9UserCmdAttrbAddress vim9String
hi def link vim9UserCmdAttrbComma vim9Sep
hi def link vim9UserCmdAttrbComplete vim9String
hi def link vim9UserCmdAttrbEqual vim9OperAssign
hi def link vim9UserCmdAttrbErrorValue vim9Error
hi def link vim9UserCmdAttrbName vim9Special
hi def link vim9UserCmdAttrbNargs vim9String
hi def link vim9UserCmdAttrbNargsNumber vim9Number
hi def link vim9UserCmdAttrbRange vim9String
hi def link vim9UserCmdDef Statement
hi def link vim9UserCmdLhs vim9UserCmdExe
hi def link vim9ValidSubType vim9DataType
hi def link vim9VimGrep vim9GenericCmd
hi def link vim9VimGrepPat vim9String
#}}}1

b:current_syntax = 'vim9'

