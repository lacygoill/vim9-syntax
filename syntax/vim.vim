vim9script

if exists('b:current_syntax')
    # bail out for a file written in legacy Vim script
    || "\n" .. getline(1, 10)->join("\n") !~ '\n\s*vim9\%[script]\>'
    # bail out if we're included from another filetype (e.g. `markdown`)
    || &filetype != 'vim'
    finish
endif

# Requirement: Any syntax group should be prefixed with `vim9`; not `vim`.{{{
#
# To avoid any  interference from the default  syntax plugin, in case  we load a
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
#    - `vim9LineComment`
#
# There is no good  reason to want different colors between a  Vim9 comment in a
# Vim9 script and a Vim9 comment in a legacy script.  That would be confusing.
#}}}
# Known limitation: The plugin does not highlight legacy functions.{{{
#
# Only the `fu` and `endfu` keywords, as well as legacy comments inside.
# We  could  support  more; we  would  need  to  allow  all the  groups  in  the
# `@vim9FuncBodyContains` cluster to start from the `vim9LegacyFuncBody` region:
#
#     syn region vim9LegacyFuncBody
#         \ start=/\ze\s*(/
#         \ matchgroup=vim9GenericCmd
#         \ end=/\<endf\%[unction]/
#         \ contained
#         \ contains=@vim9FuncBodyContains
#           ^----------------------------^
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
# But not if  it involves 2 rules  in different sections; because  in that case,
# you might one day re-order the section, and unknowingly break the requirement
#
# To remove such a requirement, try to improve some of your regexes.

# TODO:
#
#     edit ++encoding=cp437
#          ^^        ^
#          ✘         ✘

# TODO:
#             ✔
#         v-------v
#     set mp=pandoc
#     CompilerSet mp=pandoc
#                 ^-------^
#                     ✘

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

# TODO: Find the commands which expect a pattern as argument.
# Highlight it as a string.
#
#     :global
#     :substitute
#     :vglobal
#     :vimgrep
#     :vimgrepadd
#     :lvimgrep
#     :lvimgrepadd
#
#     :2match
#     :3match
#     :argdelete
#     :fu /
#     :helpgrep
#     :lhelpgrep
#     :match
#     :prof[ile] func {pattern}
#     :prof[ile][!] file {pattern}
#     :sort
#     :syntax
#     :tag

# TODO: Find the commands which expect another command as argument.
# Handle them specially and consistently.

# TODO: Try to  nest all function names,  event names, ... inside  a match.  Use
# the match to assert some lookarounds and fix some spurious highlightings.  For
# example, try  to assert  that a  function name  must always  be followed  by a
# paren.

# TODO: Try to simplify the values of all the `contains=` arguments.
# Remove what any cluster or syntax group which is useless.
# Try to use intermediate clusters to  group related syntax groups, and use them
# to reduce the verbosity of some `contains=`.

# TODO: Whenever we've used `syn case ignore`, should we have enforced a specific case?
# Similar to what we did for the names of autocmds events.

# Imports {{{1

import command_can_be_before from 'vim9syntax.vim'
import option_can_be_after from 'vim9syntax.vim'
import option_sigil from 'vim9syntax.vim'
import option_valid from 'vim9syntax.vim'

import builtin_func from 'vim9syntax.vim'
import builtin_func_ambiguous from 'vim9syntax.vim'
import collation_class from 'vim9syntax.vim'
import command_address_type from 'vim9syntax.vim'
import command_complete_type from 'vim9syntax.vim'
import command_modifier from 'vim9syntax.vim'
import command_name from 'vim9syntax.vim'
import default_highlighting_group from 'vim9syntax.vim'
import event from 'vim9syntax.vim'
import option from 'vim9syntax.vim'
import option_terminal from 'vim9syntax.vim'
import option_terminal_special from 'vim9syntax.vim'

# Assert where builtin Ex commands can match. {{{1

# TODO: Whenever you  use this cluster, make  sure it does not  contain too many
# syntax  groups in  the  current  context.  If  necessary,  create (a)  smaller
# cluster(s).

# TODO: Add more groups  in this "mega" cluster.  It should  contain all special
# commands which can't  be matched by the generic `syn  keyword` rule.  That is,
# all  commands that  expect  special  arguments which  need  to be  highlighted
# themselves  (e.g. `:map`);  or  commands which  need to  be  highlighted in  a
# different way (e.g. `try`).
# Also, make  sure to  remove the  names of  these commands  from `command_name`
# (include them in the `special` heredoc).
#
# ---
#
# Also, make sure  to remove the syntax groups/subclusters of  this mega cluster
# out of `@vim9FuncBodyContains`.
# Warning: Don't remove a  group blindly.  Only if the text  it matches can only
# appear in a limited set of positions.  For example, in the past, we've wrongly
# removed `vim9FuncCall`.  We shouldn't have, because a function call can appear
# in many places, including in the middle of an expression.
syn cluster vim9IsCmd contains=
    \ @vim9ControlFlow,
    \ vim9AbbrevCmd,
    \ vim9Augroup,
    \ vim9Autocmd,
    \ vim9CmdModifier,
    \ vim9CmdTakesExpr,
    \ vim9Declare,
    \ vim9DoCmds,
    \ vim9Doautocmd,
    \ vim9EchoHL,
    \ vim9Export,
    \ vim9Filetype,
    \ vim9GenericCmd,
    \ vim9Highlight,
    \ vim9Import,
    \ vim9LetDeprecated,
    \ vim9Map,
    \ vim9Norm,
    \ vim9RangeIntroducer,
    \ vim9Set,
    \ vim9Syntax,
    \ vim9Unmap,
    \ vim9UserCmd,
    \ vim9UserCmdDef

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

# Special Case: We need different assertions regarding the end of `:g` and `:s`.{{{
#
# For  example, for  most commands,  the next  character must  be a  whitespace,
# but  not for  `:g`  and `:s`;  for  those,  the next  character  is usually  a
# non-whitespace like a slash.
#}}}
# Order: Must come before the next rule with the lookahead.
syn match vim9MayBeCmd /\%(\<\h\w*\>\)\@=/
    \ contained
    \ nextgroup=vim9Global,vim9Subst
# General case
exe 'syn match vim9MayBeCmd /\%(\<\h\w*\>' .. command_can_be_before .. '\)\@=/'
    .. ' contained'
    .. ' nextgroup=@vim9IsCmd'

# Now  that  we  have  a  syntax group  validating  possible  Ex  command  names
# (`vim9MayBeCmd`), let's use  it in relevant contexts.  We won't  list them all
# here; only the ones which don't have  a dedicated section (i.e. start of line,
# and after a bar).

# An Ex command might be at the start of a line.
syn match vim9StartOfLine /^/
    \ skipwhite
    \ nextgroup=
    \     vim9FuncHeader,
    \     vim9LegacyFunction,
    \     vim9MayBeCmd,
    \     vim9RangeIntroducer,
    \     vim9UselessColon

# Or in the middle of a line, after a bar.
syn match vim9CmdSep /|/ skipwhite nextgroup=vim9MayBeCmd

# Builtin Ex commands {{{1
# Generic ones {{{2

exe 'syn keyword vim9GenericCmd ' .. command_name .. ' contained'

syn match vim9GenericCmd /\<z[-+^.=]\=\>/ contained

# Special ones {{{2
# A command is special iff it needs a special highlighting.{{{
#
# For example, `:for` – as a  control flow statement – should be highlighted
# differently than `:delete`.   Same thing for `:autocmd`; not  because it needs
# to be  highlighted differently, but because  some of its arguments  need to be
# highlighted.
#}}}

# Modifier commands {{{3

exe 'syn match vim9CmdModifier /'
    ..     '\<\%(' .. command_modifier .. '\)\>'
    .. '/'
    .. ' contained'
    .. ' nextgroup=vim9CmdBang,vim9MayBeCmd,vim9RangeIntroducer'
    .. ' skipwhite'

syn match vim9CmdBang /!/ contained nextgroup=vim9MayBeCmd skipwhite

# Commands taking expression as argument {{{3

exe 'syn region vim9CmdTakesExpr'
    .. ' excludenl'
    .. ' matchgroup=vim9GenericCmd'
    .. ' start='
    ..     '/\<\%('
    ..             '[cl]\%(add\|get\)\=expr'
    ..     '\|' .. 'echo'
    ..     '\|' .. 'echoc\%[onsole]'
    ..     '\|' .. 'echoerr'
    ..     '\|' .. 'echom\%[sg]'
    ..     '\|' .. 'echon'
    ..     '\|' .. 'eval'
    ..     '\|' .. 'exe\%[cute]'
    ..     '\)\>'
    .. '/'
    .. ' skip=/\%(\\\\\)*\\|/'
    .. ' matchgroup=vim9CmdSep'
    # Make sure the end pattern does not consume a bar termination character.
    # It could be needed by other rules.
    .. ' end=/$\|.|\@=\|\s#\@=/'
    # special case: `:exe` in the rhs of a mapping
    .. ' matchgroup=vim9Notation'
    # do *not* consume the bar; it might be needed by other rules
    .. ' end=/\%(<bar>\)\@=\|<cr>/'
    .. ' contained'
    .. ' contains=@vim9ExprContains'
    .. ' oneline'

# Import/Export {{{3

syn match vim9Export /\<export\>/
    \ contained
    \ nextgroup=vim9Declare
    \ skipwhite

syn match vim9Import /\<\%(import\|from\|as\)\>/
    \ contained
    \ nextgroup=vim9ImportedItems
    \ skipwhite

syn region vim9ImportedItems matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contained
    \ nextgroup=vim9Import
    \ skipwhite

syn match vim9ImportedItems /\h[a-zA-Z0-9_]*/
    \ contained
    \ nextgroup=vim9Import
    \ skipwhite

syn match vim9ImportedItems /\*/ contained nextgroup=vim9Import skipwhite

# `:echohl` arguments {{{3

syn match vim9EchoHL /\<echohl\>/
    \ contained
    \ nextgroup=vim9EchoHLNone,vim9Group,vim9HLGroup
    \ skipwhite

syn case ignore
syn keyword vim9EchoHLNone none contained
syn case match
#}}}1
# Range {{{1

syn cluster vim9RangeContains contains=
    \ vim9RangeDelimiter,
    \ vim9RangeLnumNotation,
    \ vim9RangeMark,
    \ vim9RangeMissingSpecifier2,
    \ vim9RangeNumber,
    \ vim9RangeOffset,
    \ vim9RangePattern,
    \ vim9RangeSpecialChar

# Make sure there is nothing before, to avoid a wrong match in sth like:
#     g:name = 'value'
#      ^
syn match vim9RangeIntroducer /\%(^\|\s\):\S\@=/
    \ nextgroup=@vim9RangeContains,vim9RangeMissingSpecifier1
    \ contained

# Sometimes, we might want to add a colon in front of an Ex command, even if it's not necessary.{{{
#
# Maybe for the sake of consistency:
#
#     :1,2 s/.../.../
#     :3,4 s/.../.../
#     : s/.../.../
#     ^
#     to get a column of colons
#}}}
# Order: Must come after `vim9RangeIntroducer`.
syn match vim9UselessColon /\s\=:/ contained nextgroup=vim9MayBeCmd skipwhite

syn cluster vim9RangeAfterSpecifier contains=
    \ @vim9RangeContains,
    \ vim9Filter,
    \ vim9MayBeCmd,
    \ vim9RangeMissingSpace

#                 v-----v v-----v
#     com MySort :<line1>,<line2> sort
syn match vim9RangeLnumNotation /<line[12]>/
    \ contained
    \ contains=vim9Notation
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangeMark /'[a-zA-Z0-9<>()[\]{}]/
    \ contained
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

syn match vim9RangeNumber /\d\+/
    \ nextgroup=@vim9RangeAfterSpecifier
    \ contained
    \ skipwhite

syn match vim9RangeOffset /[-+]\+\d*/
    \ nextgroup=@vim9RangeAfterSpecifier
    \ contained
    \ skipwhite

syn match vim9RangePattern +/[^/]*/+
    \ nextgroup=@vim9RangeAfterSpecifier
    \ contained
    \ contains=vim9RangePatternFwdDelim
    \ skipwhite
syn match vim9RangePatternFwdDelim +/+ contained

syn match vim9RangePattern +?[^?]*?+
    \ nextgroup=@vim9RangeAfterSpecifier
    \ contained
    \ contains=vim9RangePatternBwdDelim
    \ skipwhite
syn match vim9RangePatternBwdDelim /?/ contained

syn match vim9RangeSpecialChar /[.$%*]/
    \ nextgroup=@vim9RangeAfterSpecifier
    \ contained
    \ skipwhite

syn match vim9RangeDelimiter /[,;]/
    \ nextgroup=@vim9RangeAfterSpecifier
    \ contained

# Options {{{1
# TODO: Check whether all options are correctly highlighted.
#
#     \<\%(setl\%[ocal]\|setg\%[lobal]\|se\%[t]\)\>\s\|&\%([gl]:\)\=[a-z]\{2,\}\|&t_..
# Assignment commands {{{2

syn match vim9Set /\<\%(setl\%[ocal]\|setg\%[lobal]\|se\%[t]\)\s/
    \ contained
    \ nextgroup=vim9MayBeOptionSet
    \ skipwhite

# Option names {{{2

# Note that an option value can be written right at the start of the line.{{{
#
#     &guioptions = 'M'
#     ^---------^
#}}}
exe 'syn match vim9MayBeOptionScoped '
    .. '/'
    ..     option_can_be_after
    ..     option_sigil
    ..     option_valid
    .. '/'
    .. ' display'
    .. ' contains=vim9IsOption,vim9OptionSigil'
    # `vim9SetEqual` would be wrong here; we need spaces around `=`
    .. ' nextgroup=vim9OperAssign'

exe 'syn match vim9MayBeOptionSet '
    .. '/'
    ..     option_can_be_after
    ..     option_valid
    .. '/'
    .. ' display'
    .. ' contained'
    .. ' contains=vim9IsOption'
    .. ' nextgroup=vim9SetEqual,vim9MayBeOptionSet,vim9SetMod'
    .. ' skipwhite'

syn match vim9OptionSigil /&\%([gl]:\)\=/ contained

exe 'syn keyword vim9IsOption '
    .. option
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'
    .. ' skipwhite'

exe 'syn keyword vim9IsOption '
    .. option_terminal
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

exe 'syn match vim9IsOption '
    .. '/\V'
    .. option_terminal_special
    .. '/'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

# Modifiers (e.g. `&vim`) {{{2

# Modifiers which can be appended to an option name.{{{
#
# < = set local value to global one; or remove local value (for global-local options)
# ? = show value
# ! = invert value
#}}}
syn match vim9SetMod /&\%(vim\)\=\|[<?!]/
    \ contained
    \ nextgroup=vim9MayBeOptionScoped,vim9MayBeOptionSet
    \ skipwhite

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
#}}}1
# Autocmds {{{1
# `:augroup` {{{2

# The default syntax plugin wraps all the contents of an augroup inside a region.{{{
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
# But the default syntax plugin wrongly handles such a situation:
#
#     augroup Name | au!
#         def Func()
#         ^^^
#         wrongly highlighted as an option (:def is confused with 'def')
#         enddef
#     augroup END
#
# That's because the region doesn't include the right syntax group(s).
# Finding and writing the right ones is cumbersome is brittle.
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

# `:autocmd` {{{2

# :au[tocmd] [group] {event} {pat} [++once] [++nested] {cmd}
syn match vim9Autocmd /\<au\%[tocmd]\>\%(\s*\w\)\@=/
    \ contained
    \ skipwhite
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup,
    \     vim9AutocmdMod
# The positive  lookahead prevents  a variable named  `auto` from  being wrongly
# highlighted as a command in an assignment or a computation.

#           v
# :au[tocmd]! ...
syn match vim9Autocmd /\<au\%[tocmd]\>!/he=e-1
    \ contained
    \ skipwhite
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup

# The trailing whitespace is useful to prevent a correct but still noisy/useless
# match when we simply clear an augroup.
syn match vim9AutocmdGroup /\S\+\s\@=/
    \ contained
    \ skipwhite
    \ nextgroup=
    \     vim9AutocmdAllEvents,
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase

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
    \ nextgroup=vim9AutocmdMod,vim9MayBeCmd
    \ skipwhite

syn match vim9AutocmdMod /++\%(nested\|once\)/
    \ nextgroup=vim9MayBeCmd
    \ skipwhite

# Events {{{2

# TODO: Hide the bad case error behind an option.
syn case ignore
exe 'syn keyword vim9AutocmdEventBadCase ' .. event
    .. ' contained'
    .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
    .. ' skipwhite'
syn case match

# Order: Must come after `vim9AutocmdEventBadCase`.
exe 'syn keyword vim9AutocmdEventGoodCase ' .. event
    .. ' contained'
    .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
    .. ' skipwhite'

syn match vim9AutocmdEndOfEventList /,\%(\a\+,\)*\a\+/
    \ contained
    \ contains=vim9AutocmdEventBadCase,vim9AutocmdEventGoodCase
    \ nextgroup=vim9AutocmdPat
    \ skipwhite

# `:doautocmd`, `:doautoall` {{{2

# :do[autocmd] [<nomodeline>] [group] {event} [fname]
# :doautoa[ll] [<nomodeline>] [group] {event} [fname]
syn match vim9Doautocmd /\<\%(do\%[autocmd]\|doautoa\%[ll]\)\>/
    \ contained
    \ skipwhite
    \ nextgroup=
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup,
    \     vim9AutocmdMod

syn match vim9AutocmdMod /<nomodeline>/
    \ skipwhite
    \ nextgroup=
    \     vim9AutocmdEventBadCase,
    \     vim9AutocmdEventGoodCase,
    \     vim9AutocmdGroup
#}}}1
# vim9Todo: contains common special-notices for comments {{{1
# Use the `vim9CommentGroup` cluster to add your own.

syn keyword vim9Todo FIXME TODO contained
syn cluster vim9CommentGroup contains=
    \ @Spell,
    \ vim9CommentString,
    \ vim9CommentTitle,
    \ vim9DictLiteralLegacyDeprecated,
    \ vim9Todo

# Declarations {{{1

syn keyword vim9Declare cons[t] final unl[et] var
    \ contained
    \ skipwhite
    \ nextgroup=vim9ListUnpackDeclaration,vim9ReservedNames

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

# Booleans / null / v:none {{{1

# Even though `v:` is useless in Vim9, we  still need it in a mapping; because a
# mapping is run in the legacy context, even when installed from a Vim9 script.
syn match vim9Bool /\%(v:\)\=\<\%(false\|true\)\>:\@!/
syn match vim9Null /\%(v:\)\=\<null\>:\@!/

syn match vim9None /\<v:none\>:\@!/

# Highlight commonly used Groupnames {{{1

syn case ignore
syn keyword vim9Group contained
    \ Comment
    \ Constant
    \ String
    \ Character
    \ Number
    \ Boolean
    \ Float
    \ Identifier
    \ Function
    \ Statement
    \ Conditional
    \ Repeat
    \ Label
    \ Operator
    \ Keyword
    \ Exception
    \ PreProc
    \ Include
    \ Define
    \ Macro
    \ PreCondit
    \ Type
    \ StorageClass
    \ Structure
    \ Typedef
    \ Special
    \ SpecialChar
    \ Tag
    \ Delimiter
    \ SpecialComment
    \ Debug
    \ Underlined
    \ Ignore
    \ Error
    \ Todo
syn case match

# Default highlighting groups {{{1

syn case ignore
exe 'syn keyword vim9HLGroup contained ' .. default_highlighting_group

# Do *not* turn  this `match` into a `keyword` rule;  `conceal` would be wrongly
# interpreted as an argument to `:syntax`.
syn match vim9HLGroup /\<conceal\>/ contained
syn case match

# Function Names {{{1

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
exe 'syn keyword vim9FuncNameBuiltin '
    .. builtin_func
    .. ' contained'

exe 'syn match vim9FuncNameBuiltin '
    .. '/\<\%(' .. builtin_func_ambiguous .. '\)'
    .. '(\@='
    .. '/'
    .. ' contained'

# Filetypes {{{1

syn match vim9Filetype /\<filet\%[ype]\%(\s\+\I\i*\)*/
    \ contained
    \ contains=vim9FTCmd,vim9FTError,vim9FTOption
    \ skipwhite

syn match vim9FTError /\I\i*/ contained
syn keyword vim9FTCmd filet[ype] contained
syn keyword vim9FTOption detect indent off on plugin contained

# Operators {{{1

syn cluster vim9ExprContains contains=
    \ vim9Bool,
    \ vim9DataTypeCast,
    \ vim9Dict,
    \ vim9EnvVar,
    \ vim9FuncCall,
    \ vim9LambdaArrow,
    \ vim9List,
    \ vim9ListSlice,
    \ vim9MayBeOptionScoped,
    \ vim9None,
    \ vim9Null,
    \ vim9Number,
    \ vim9Oper,
    \ vim9OperParen,
    \ vim9String

# `vim9LineComment` needs to be in `@vim9OperGroup`.{{{
#
# So that the comment leader is highlighted  on an empty commented line inside a
# dictionary inside a function.
#}}}
syn cluster vim9OperGroup contains=
    \ @vim9ExprContains,
    \ vim9Comment,
    \ vim9Continue,
    \ vim9DataType,
    \ vim9DataTypeCast,
    \ vim9DataTypeCastComposite,
    \ vim9DataTypeCompositeLeadingColon,
    \ vim9LineComment,
    \ vim9Notation,
    \ vim9Oper,
    \ vim9OperAssign,
    \ vim9OperParen

syn match vim9Oper "\s\@1<=\%([-+*/%!]\|\.\.\|==\|!=\|>=\|<=\|=\~\|!\~\|>\|<\)[?#]\=\_s\@="
    \ display
    \ nextgroup=vim9Bool,vim9SpecFile,vim9String
    \ skipwhite

syn match vim9OperAssign #\s\@1<=\%([-+*/%]\|\.\.\)\==\_s\@=#
    \ display
    \ skipwhite

syn match vim9Oper /\s\@1<=\%(is\|isnot\)\s\@=/
    \ display
    \ nextgroup=vim9SpecFile,vim9String
    \ skipwhite

# We want to assert the presence of surrounding whitespace.{{{
#
# To avoid spurious highglights in legacy Vim script.
#
# Example:
#
#     /pattern/delete
#     ^       ^
#     these should not be highlighted as arithmetic operators
#
# This  does  mean that  sometimes,  an  arithmetic  operator is  not  correctly
# highlighted:
#
#     eval 1+2
#           ^
#
# But we don't care because:
#
#    - the issue is limited to legacy which we almost never read/write anymore
#
#    - `1+2` is ugly:
#      it would be more readable as `1 + 2`, where `+` is correctly highlighted
#
# ---
#
# Also, in Vim9,  arithmetic operators *must* be surrounded  with whitespace; so
# it makes sense to enforce them in the syntax highlighting too.
#
# ---
#
# Also, this fixes  an issue where the tilde character  would not be highlighted
# in an `!~` operator.
#}}}
syn match vim9Oper /\s\@1<=\%(||\|&&\|??\=\)\_s\@=/
    \ display
    \ nextgroup=vim9SpecFile,vim9String
    \ skipwhite

# methods and increment/decrement operators
syn match vim9Oper /->\|++\|--/
    \ nextgroup=vim9SpecFile,vim9String
    \ skipwhite

# logical not{{{
#
# The negative  lookbehind is necessary to  not highlight `!` when  used after a
# command name:
#
#     packadd!
#            ^
#
# Note that we still want to highlight `!` when preceded by a paren:
#
#     echo 'aaa' .. (!empty(...) ? ... : ...)
#                   ^^
#
# ---
#
# The  negative lookahead  is necessary  to not  break the  highlighting of  `~`
# inside the operator `!~`.
#
# ---
#
# The `!*` quantifier  is necessary to support  a double not (`!!`),  which is a
# syntax we sometimes use to turn any type of expression into a boolean.
#}}}
syn match vim9Oper /\w\@1<!![~=]\@!!*/
    \ display
    \ nextgroup=vim9SpecFile,vim9String
    \ skipwhite

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
syn match vim9Oper /\%(?[^[]*\s\|^\s\+\)\@<=:\s\@=/
    \ display
    \ nextgroup=vim9SpecFile,vim9String
    \ skipwhite

# Don't  include   `vim9Args`  inside  `@vim9OperGroup`;  it   would  break  the
# highlighting of a dictionary.
syn region vim9OperParen
    \ matchgroup=vim9ParenSep
    \ start=/(/
    \ end=/)/
    \ contains=
    \     @vim9OperGroup,
    \     @vim9ExprContains,
    \     vim9Args,
    \     vim9Block,
    \     vim9SpaceExtraBetweenArgs,
    \     vim9SpaceMissingBetweenArgs

syn match vim9OperError /)/

# Dictionaries {{{1

# Order: Must come before `vim9Block`.
# Warning: Don't include `vim9DictMayBeLiteralKey` in `@vim9OperGroup`:{{{
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
syn region vim9Dict
    \ matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contains=@vim9OperGroup,vim9DictExprKey,vim9DictMayBeLiteralKey

# in literal dictionary, highlight keys as strings
syn match vim9DictMayBeLiteralKey /\%(^\|[ \t{]\)\@1<=[^ {(]\+\ze\%(:\s\)\@=/
    \ display
    \ contained
    \ contains=vim9DictIsLiteralKey
    \ keepend

# check the validity of the key
syn match vim9DictIsLiteralKey /\%(\w\|-\)\+/ contained

# support expressions as keys (`[expr]`).
syn match vim9DictExprKey /\[.\{-}]\%(:\s\)\@=/
    \ contained
    \ contains=@vim9ExprContains
    \ keepend
#}}}1
# Functions {{{1

syn cluster vim9FuncList contains=vim9DefKey

# `vim9LineComment` needs to be in `@vim9FuncBodyContains`.{{{
#
# So that the comment leader is highlighted  on an empty commented line inside a
# function.
#}}}
# The legacy script includes `vimSynType` inside `@vimFuncBodyList`.  Don't do the same.{{{
#
#     ✘
#     syn cluster vim9FuncBodyContains add=vim9SynType
#
# Otherwise a  list type (like  `list<any>`) would not be  correctly highlighted
# when used as the return type of a `:def` function.
# That's because the `vim9FuncBody`  region contains the `@vim9FuncBodyContains`
# cluster.
#
# Besides, it's just wrong.  There is no reason nor need for this.
# Indeed, the `vim9Syntax` group  definition specifies that `vim9SynType` should
# be tried  for a match right  after any `:syntax` command,  via the `nextgroup`
# argument:
#
#     syn match vim9Syntax /\<sy\%[ntax]\>/
#         \ ...
#         \ nextgroup=vim9SynType,...
#            ^------------------^
#         \ ...
#
# ---
#
# BTW, in case you wonder what `vim9SynType` is, it's the list of valid keywords
# which can appear after `:syntax` (e.g. `match`, `cluster`, `include`, ...).
#}}}
syn cluster vim9FuncBodyContains contains=
    \ vim9BacktickExpansion,
    \ vim9BacktickExpansionVimExpr,
    \ vim9Block,
    \ vim9Bool,
    \ vim9CmdSep,
    \ vim9Comment,
    \ vim9Continue,
    \ vim9CtrlChar,
    \ vim9DataType,
    \ vim9DataTypeCast,
    \ vim9DataTypeCastComposite,
    \ vim9DataTypeCompositeLeadingColon,
    \ vim9Dict,
    \ vim9EnvVar,
    \ vim9FuncCall,
    \ vim9FuncHeader,
    \ vim9GroupAdd,
    \ vim9GroupRem,
    \ vim9HereDoc,
    \ vim9HiLink,
    \ vim9LambdaArrow,
    \ vim9LegacyFunction,
    \ vim9LineComment,
    \ vim9ListSlice,
    \ vim9LuaRegion,
    \ vim9MayBeOptionScoped,
    \ vim9Notation,
    \ vim9Null,
    \ vim9Number,
    \ vim9Oper,
    \ vim9OperAssign,
    \ vim9OperParen,
    \ vim9PythonRegion,
    \ vim9Region,
    \ vim9SpecFile,
    \ vim9StartOfLine,
    \ vim9String,
    \ vim9SynLine,
    \ vim9SynMtchGroup

exe 'syn match vim9FuncHeader'
    .. ' /'
    .. '\<def!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(\i\|[#.]\)*'
    .. '\ze('
    .. '/'
    .. ' contains=@vim9FuncList'
    .. ' nextgroup=vim9FuncBody'

# Do not use `keepend`.{{{
#
# If there is a  heredoc in your function, and it contains  an `enddef` line, it
# would wrongly end there.  If you need  `keepend`, then, try to use `extend` in
# the rule handling the heredocs.
#}}}
syn region vim9FuncBody
    \ start=/(/
    \ matchgroup=vim9DefKey
    \ end=/^\s*enddef$/
    \ contains=@vim9FuncBodyContains
    \ contained

syn match vim9Args /\<\h[a-zA-Z0-9#_]*\%(:\s\|\s\+=\s\)\@=/ contained
# special case: variable arguments
syn match vim9Args /\.\.\.\h[a-zA-Z0-9_]*\%(:\s\|\s\+=\s\)\@=/ contained

exe 'syn match vim9LegacyFunction'
    .. ' /'
    .. '\<fu\%[nction]!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(\i\|[#.]\)*'
    .. '\ze('
    .. '/'
    .. ' contains=@vim9FuncList'
    .. ' nextgroup=vim9LegacyFuncBody'

syn region vim9LegacyFuncBody
    \ start=/\ze\s*(/
    \ matchgroup=vim9DefKey
    \ end=/^\s*\<endf\%[unction]/
    \ contained

syn keyword vim9DefKey def fu[nction]
    \ contained
    \ nextgroup=vim9DefBangError,vim9DefBang
# :def! is valid
syn match vim9DefBang /!/ contained
# but only for global functions
syn match vim9DefBangError /!\%(\s\+g:\)\@!/ contained

syn keyword vim9Pattern start skip end contained

syn match vim9LambdaArrow /\s\@1<==>\_s\@=/
    \ nextgroup=vim9LambdaDictMissingParen
    \ skipwhite

# block at script-level, function-level, or inside lambda
syn region vim9Block
    \ matchgroup=Statement
    \ start=/^\s*{$\|\s\+=>\s\+{$/
    \ end=/^\s*}/
    \ contains=@vim9FuncBodyContains

# Special Filenames, Modifiers, Extension Removal {{{1

syn match vim9SpecFile /<c\%(word\|WORD\)>/ nextgroup=vim9SpecFileMod

syn match vim9SpecFile /<\%([acs]file\|amatch\|abuf\)>/
    \ nextgroup=vim9SpecFileMod

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
syn match vim9SpecFile /\s%$/ms=s+1 nextgroup=vim9SpecFileMod
syn match vim9SpecFile /\s%</ms=s+1,me=e-1 nextgroup=vim9SpecFileMod
syn match vim9SpecFile /#\d\+\|[#%]<\>/ nextgroup=vim9SpecFileMod
syn match vim9SpecFileMod /\%(:[phtreS]\)\+/ contained

# User Commands {{{1
# :command {{{2

syn match vim9UserCmdDef /\<com\%[mand]\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttrbContains,vim9UserCmdBang
    \ skipwhite

syn match vim9UserCmdDef /\<com\%[mand]\>!/he=e-1
    \ contained
    \ nextgroup=@vim9UserCmdAttrbContains,vim9UserCmdBang
    \ skipwhite

# error handling {{{2
# Order: should come before highlighting valid attributes.

syn cluster vim9UserCmdAttrbContains contains=
    \ vim9UserCmdAttrb,
    \ vim9UserCmdAttrbEqual,
    \ vim9UserCmdAttrbError,
    \ vim9UserCmdAttrbErrorValue,
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
    \ nextgroup=vim9UserCmdAttrb
    \ skipwhite

# an invalid attribute name is an error
syn match vim9UserCmdAttrbError /-[^ \t=]\+/
    \ contained
    \ contains=vim9UserCmdAttrb
    \ nextgroup=@vim9UserCmdAttrbContains
    \ skipwhite

# boolean attributes {{{2

syn match vim9UserCmdAttrb /-\%(bang\|bar\|buffer\|register\)\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttrbContains
    \ skipwhite

# attributes with values {{{2
# = {{{3

syn match vim9UserCmdAttrbEqual /=/ contained

# -addr {{{3

syn match vim9UserCmdAttrb /-addr\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbAddress,vim9UserCmdAttrbErrorValue

exe 'syn match vim9UserCmdAttrbAddress '
    .. '/'
    .. '=\%(' .. command_address_type .. '\)\>'
    .. '/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrbEqual'
    .. ' nextgroup=@vim9UserCmdAttrbContains'
    .. ' skipwhite'

# -complete {{{3

syn match vim9UserCmdAttrb /-complete\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbComplete,vim9UserCmdAttrbErrorValue

# -complete=arglist
# -complete=buffer
# -complete=...
exe 'syn match vim9UserCmdAttrbComplete '
    .. '/'
    ..     '=\%(' .. command_complete_type .. '\)'
    .. '/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrbEqual'
    .. ' nextgroup=@vim9UserCmdAttrbContains'
    .. ' skipwhite'

# -complete=custom,Func
# -complete=customlist,Func
syn match vim9UserCmdAttrbComplete /=custom\%(list\)\=,\%([gs]:\)\=\%(\i\|[#.]\)*/
    \ contained
    \ contains=vim9UserCmdAttrbEqual,vim9UserCmdAttrbComma
    \ nextgroup=@vim9UserCmdAttrbContains
    \ skipwhite

syn match vim9UserCmdAttrbComma /,/ contained

# -count {{{3

syn match vim9UserCmdAttrb /-count\>/
    \ contained
    \ skipwhite
    \ nextgroup=
    \     @vim9UserCmdAttrbContains,
    \     vim9UserCmdAttrbCount,
    \     vim9UserCmdAttrbErrorValue

syn match vim9UserCmdAttrbCount
    \ /=\d\+/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrbEqual
    \ nextgroup=@vim9UserCmdAttrbContains
    \ skipwhite

# -nargs {{{3

syn match vim9UserCmdAttrb /-nargs\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrbNargs,vim9UserCmdAttrbErrorValue

syn match vim9UserCmdAttrbNargs
    \ /=[01*?+]/
    \ contained
    \ contains=vim9UserCmdAttrbEqual,vim9UserCmdAttrbNargsNumber
    \ nextgroup=@vim9UserCmdAttrbContains
    \ skipwhite

syn match vim9UserCmdAttrbNargsNumber /[01]/ contained

# -range {{{3

# `-range` is a special case:
# it can accept a value, *or* be used as a boolean.
syn match vim9UserCmdAttrb /-range\>/
    \ contained
    \ skipwhite
    \ nextgroup=
    \     @vim9UserCmdAttrbContains,
    \     vim9UserCmdAttrbErrorValue,
    \     vim9UserCmdAttrbRange

syn match vim9UserCmdAttrbRange /=\%(%\|-\=\d\+\)/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrbEqual
    \ nextgroup=@vim9UserCmdAttrbContains
    \ skipwhite
#}}}2
# lhs / rhs {{{2

syn match vim9UserCmdLhs /\u\w*/
    \ contained
    \ nextgroup=vim9MayBeCmd
    \ skipwhite
#}}}1
# Lower Priority Comments: after some vim commands... {{{1

syn region vim9CommentString start=/\%(\S\s\+\)\@<="/ end=/"/ contained oneline

# inline comments
# Warning: Do *not* use the `display` argument here.
syn match vim9Comment /\s\@1<=#.*$/ contains=@vim9CommentGroup excludenl

syn match vim9Comment /^\s*#.*$/ contains=@vim9CommentGroup

# Strings {{{1

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
syn region vim9String start=/[^a-zA-Z>!\\@]\@1<='/ end=/'\d\@!/ keepend oneline

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

# Numbers {{{1

syn match vim9Number /\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /\<0[xX]\x\+\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\%(^\|\A\)\zs#\x\{6}\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\<0[zZ][a-zA-Z0-9.]\+\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\<0o[0-7]\+\>/ nextgroup=vim9Comment skipwhite
syn match vim9Number /\<0b[01]\+\>/ nextgroup=vim9Comment skipwhite

# It is possible to use single quotes inside numbers to make them easier to read:{{{
#
#     echo 1'000'000
#
# Highlight them as part of a number.
#}}}
syn match vim9Number /\d\@1<='\d\@=/ display nextgroup=vim9Comment skipwhite

# :substitute {{{1

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

# `:h pattern-delimiter`

# In Vim9, `"` is still not a valid delimiter:{{{
#
#     vim9script
#     ['aba bab']->repeat(3)->setline(1)
#     sil! s/nowhere//
#     :% s"b"B"g
#     E486: Pattern not found: nowhere˜
#
# `#` seems to work,  but let's be consistent; if in  legacy, the comment leader
# doesn't work, that should remain true in Vim9.
#}}}
syn match vim9Subst
    \ /\<s\%[ubstitute]\>\ze\([^[:alnum:] \t\"#|]\@=.\).\{-}\1.\{-}\1/
    \ contained
    \ display
    \ nextgroup=vim9SubstPat

syn region vim9SubstPat
    \ matchgroup=vim9SubstDelim
    \ start=/\z([^[:alnum:] \t\"#|]\@=.\)/rs=s+1
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/re=e-1,me=e-1
    \ contained
    \ contains=@vim9SubstList
    \ nextgroup=vim9SubstRep
    \ oneline

syn region vim9SubstRep
    \ matchgroup=vim9SubstDelim
    \ start=/\z(.\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vim9Notation
    \ end=/<[cC][rR]>/
    \ contained
    \ contains=@vim9SubstRepList
    \ nextgroup=vim9SubstFlagErr
    \ oneline

syn region vim9Collection
    \ start=/\\\@1<!\[/
    \ skip=/\\\[/
    \ end=/\]/
    \ contained
    \ contains=vim9CollationClass
    \ transparent

syn match vim9CollationClassErr /\[:.\{-\}:\]/ contained

exe 'syn match vim9CollationClass '
    .. ' /\%#=1\[:'
    .. '\%(' .. collation_class .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syn match vim9SubstSubstr /\\z\=\d/ contained
syn match vim9SubstTwoBS /\\\\/ contained
syn match vim9SubstFlagErr /[^< \t\r|]\+/ contained contains=vim9SubstFlags
syn match vim9SubstFlags /[&cegiIlnpr#]\+/ contained

# :global {{{1

syn match vim9Global
    \ /\<v\=g\%[lobal]\>!\=\ze\([^[:alnum:] \t\"#|]\@=.\).\{-}\1/
    \ nextgroup=vim9GlobalPat
    \ contained

syn region vim9GlobalPat
    \ matchgroup=vim9SubstDelim
    \ start=/\z([^[:alnum:] \t\"#|]\@=.\)/rs=s+1
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contained
    \ contains=@vim9SubstList
    \ nextgroup=vim9MayBeCmd
    \ oneline

# :{range}!{filter} {{{1
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

# Abbreviations {{{1

syn keyword vim9AbbrevCmd
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ contained
    \ nextgroup=@vim9MapLhs,@vim9MapMod
    \ skipwhite

# Angle-Bracket Notation {{{1

syn case ignore
exe 'syn match vim9Notation'
    .. ' /'
    .. '\%#=1\%(\\\|<lt>\)\='
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

syn match vim9Notation /<cmd>/
    \ contains=vim9Bracket
    \ nextgroup=@vim9RangeContains,vim9MayBeCmd

exe 'syn match vim9Notation '
    .. '/'
    .. '\%#=1\%(\\\|<lt>\)\='
    .. '<'
    .. '\%([scam2-4]-\)\{0,4}'
    .. '\%(right\|left\|middle\)'
    .. '\%(mouse\)\='
    .. '\%(drag\|release\)\='
    .. '>'
    .. '/'
    .. ' contains=vim9Bracket'

syn match vim9Notation
    \ /\%#=1\%(\\\|<lt>\)\=<\%(bslash\|plug\|sid\|space\|nop\|nul\|lt\)>/
    \ contains=vim9Bracket

syn match vim9Notation /<bar>/ contains=vim9Bracket skipwhite

syn match vim9Notation /\%(\\\|<lt>\)\=<C-R>[0-9a-z"%#:.\-=]/he=e-1
    \ contains=vim9Bracket

exe 'syn match vim9Notation '
    .. '/'
    .. '\%#=1\%(\\\|<lt>\)\='
    .. '<'
    .. '\%(q-\)\='
    .. '\%(line[12]\|count\|bang\|reg\|args\|mods\|f-args\|f-mods\|lt\)'
    .. '>'
    .. '/'
    .. ' contains=vim9Bracket'

syn match vim9Notation
    \ /\%#=1\%(\\\|<lt>\)\=<\%([cas]file\|abuf\|amatch\|cword\|cWORD\|client\)>/
    \ contains=vim9Bracket

syn match vim9Bracket /[\\<>]/ contained
syn case match

# Maps {{{1

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

exe 'syn match vim9MapMod '
    .. '/'
    .. '\%#=1\c'
    .. '\%(<\%('
    ..         'buffer\|\%(local\)\=leader\|nowait'
    .. '\|' .. 'plug\|script\|sid\|unique\|silent'
    .. '\)>\s*\)\+'
    .. '/'
    .. ' contained'
    .. ' contains=vim9MapModErr,vim9MapModKey'
    .. ' nextgroup=vim9MapLhs'
    .. ' skipwhite'

exe 'syn match vim9MapModExpr '
    .. '/'
    .. '\%#=1\c'
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
    \ nextgroup=vim9MapRhsExtend
    \ skipnl
    \ contains=
    \     vim9CtrlChar,
    \     vim9MapCmd,
    \     vim9MapCmdlineExpr,
    \     vim9MapInsertExpr,
    \     vim9Notation

syn match vim9MapRhsExpr /.*/
    \ contained
    \ contains=@vim9ExprContains,vim9CtrlChar,vim9Notation
    \ nextgroup=vim9MapRhsExtendExpr
    \ skipnl

# `\s*` is necessary in the `start` pattern to allow a nested match on `<cmd>`, `<c-r>`, `<c-\>`.
syn region vim9MapCmd
    \ start=/\s*\c<cmd>/
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9ExprContains,vim9Notation,vim9MapCmdBar
    \ keepend
    \ oneline
syn region vim9MapInsertExpr
    \ start=/\s*\c<c-r>=/
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9ExprContains,vim9Notation
    \ keepend
    \ oneline
syn region vim9MapCmdlineExpr
    \ start=/\s*\c<c-\\>e/
    \ end=/\c<cr>/
    \ contained
    \ contains=@vim9ExprContains,vim9Notation
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
# Order: Must come after the `vim9Notation` rule handling a `<bar>` in any location.
syn match vim9MapCmdBar /<bar>/
    \ contained
    \ contains=vim9Notation
    \ nextgroup=vim9MayBeCmd
    \ skipwhite

syn match vim9MapRhsExtend /^\s*\\.*$/ contained contains=vim9Continue
syn match vim9MapRhsExtendExpr /^\s*\\.*$/
    \ contained
    \ contains=@vim9ExprContains,vim9Continue

# User Function Call {{{1

# call to any kind of function (builtin + custom)
exe 'syn match vim9FuncCall '
    .. '/\<'
    .. '\%('
    # with an explicit scope, the name can start with and contain any word character
    ..     '[gs]:\w\+'
    .. '\|'
    # otherwise, it must start with a head of word (i.e. word character except digit);
    # afterward, it can contain any word character and `#` (for autoload functions)
    ..     '\h\%(\w\|#\)*'
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
    .. ' contains=vim9FuncNameBuiltin,vim9UserFuncNameCustom'

# name of custom function in function call
exe 'syn match vim9UserFuncNameCustom '
    .. '/\<'
    .. '\%('
    ..     '[gs]:\w\+'
    .. '\|'
    # without an explicit scope, the name of the function must not start with a lowercase
    # (that's reserved to builtin functions)
    ..     '[A-Z_]\w*'
    .. '\|'
    # unless it's an autoload function
    ..     '\h\w*#\%(\w\|#\)*'
    .. '\)'
    .. '\ze('
    .. '/'
    .. ' contained'
    .. ' contains=vim9Notation'

# User Command Call {{{1

exe 'syn match vim9UserCmd '
    .. '"\u\%(\w*\)\@>'
    .. '\%('
    # Don't highlight a custom Vim function invoked without ":call".{{{
    #
    #     Func()
    #     ^--^
    #}}}
    # Don't highlight a capitalized autoload function name, in a function call:{{{
    #
    #     Script#func()
    #     ^----^
    #}}}
    # Don't highlight the member of a list/dictionary:{{{
    #
    #     var NAME: list<number> = [1]
    #     NAME[0] = 2
    #     ^--^
    #}}}
    ..     '[(#[]'
    .. '\|'
    # Don't highlight a capitalized variable name, in an assignment without declaration:{{{
    #
    #     var MYCONSTANT: number
    #     MYCONSTANT = 12
    #     MYCONSTANT += 34
    #     MYCONSTANT *= 56
    #     ...
    #}}}
    ..     '\s\+\%([-+*/%]\=\|\.\.\)='
    .. '\|'
    .. '\%('
    # Don't highlight a funcref expression at the start of a line.{{{
    #
    #     def Foo(): string
    #         return 'some text'
    #     enddef
    #
    #     def Bar(F: func): string
    #         return F()
    #     enddef
    #
    #     # should NOT be highlighted as an Ex command
    #     vvv
    #     Foo->Bar()
    #        ->setline(1)
    #}}}
    ..     '\_s*->'
    # Nor a key in a literal dictionary.{{{
    #
    #     var d = {
    #         Key: 123,
    #         ^^^
    #         # should NOT be highlighted as an Ex command
    #     }
    #
    # Actually,  in this  simple example,  there is  no issue,  probably because
    # `Key`  is in  `vim9OperParen`.   But if  the start  of  the dictionary  is
    # far  away,  then  the  syntax  *might*  fail  to  parse  `Key`  as  inside
    # `vim9OperParen`, which can cause `Key` to be parsed as `vim9UserCmd`.
    # To reproduce, we  need – approximately – twice the  number assigned to
    # `:syn sync maxlines`:
    #
    #     syn sync maxlines=60
    #                       ^^
    #                       60 * 2 = 120
    #
    # But depending on  how you've scrolled vertically in the  buffer, the issue
    # might not be reproducible or disappear.
    #}}}
    ..     '\|' .. '\s*:'
    # Nor an expression followed by an operator on the next line.{{{
    #
    #     var name =
    #           Foo
    #         + Bar
    #}}}
    ..     '\|' .. '\_s*\%([-+*/%?]\|\.\.\)'
    .. '\)'
    .. '\)\@!"'
    .. ' contained'
    .. ' nextgroup=vim9SpaceExtraAfterFuncname'

# Data Types {{{1

# Order: This section must come *after* the `vim9FuncCall` and `vim9UserFuncNameCustom` rules.{{{
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
exe 'syn match vim9DataType /'
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
    .. ' /'
    .. 'any\|blob\|bool\|channel'
    .. '\|float\|func(\@!\|job\|number\|string\|void'
    # the lookbehinds are  necessary to avoid breaking the nesting  of the outer
    # region;  which would  prevent some  trailing `>`  or `)`  to be  correctly
    # highlighted
    .. '\|d\@1<=ict<\|f\@1<=unc(\|)\|l\@1<=ist<'
    .. '/'
    .. ' display contained'

# support `:h type-casting` for simple types
exe 'syn match vim9DataTypeCast /'
    .. '<\%('
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

# Control Flow {{{1

syn cluster vim9ControlFlow contains=
    \ vim9Conditional,
    \ vim9Repeat,
    \ vim9Return,
    \ vim9TryCatch

# :return
syn match vim9Return
    \ /\<return\>/
    \ contained
    \ nextgroup=@vim9ExprContains
    \ skipwhite

# :if
# :elseif
syn match vim9Conditional
    \ /\<\%(if\|el\%[seif]\)\>/
    \ contained
    \ nextgroup=@vim9ExprContains
    \ skipwhite

# :endif
syn match vim9Conditional /\<en\%[dif]\>/ contained skipwhite

# :for
syn match vim9Repeat
    \ /\<for\=\>/
    \ contained
    \ skipwhite
    \ nextgroup=vim9RepeatForVar
    \ skipwhite

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
syn match vim9RepeatForIn /\<in\>/ contained

# :while
syn match vim9Repeat
    \ /\<wh\%[ile]\>/
    \ contained
    \ skipwhite
    \ nextgroup=@vim9ExprContains

# :endfor
# :endwhile
syn match vim9Repeat /\<\%(endfor\=\|endw\%[hile]\)\>/ contained skipwhite

# :try
# :catch
# :throw
# :finally
# :endtry
syn match vim9TryCatch /\<\%(try\|endtry\|finally\)\>/ contained
syn match vim9TryCatch /\<throw\>/ contained nextgroup=@vim9ExprContains skipwhite
syn match vim9TryCatch -\<catch\>\%(\s\+/[^/]*/\)\=- contained contains=vim9TryCatchPattern

# Problem: A pattern can contain any text; in particular, an unbalanced paren is
# possible.  But this breaks all the subsequent syntax highlighting.
#
# Solution: Make sure all patterns are highlighted as strings.
# Let's start with a `:catch` pattern.
#
# NOTE: We  could  achieve  the  desired  result  with  a  single  rule,  and  a
# lookbehind.  But it would be more expensive.
syn match vim9TryCatchPattern +/.*/+ contained contains=vim9TryCatchPatternDelim
syn match vim9TryCatchPatternDelim +/+ contained

# `:*do` {{{1

syn match vim9DoCmds
    \ /\<\%(arg\|buf\|cf\=\|lf\=\|tab\|win\)do\>/
    \ contained
    \ skipwhite
    \ nextgroup=vim9MayBeCmd
    \ skipwhite

# Norm {{{1

syn match vim9Norm /\<norm\%[al]\>/ nextgroup=vim9NormCmds contained skipwhite
syn match vim9Norm /\<norm\%[al]\>!/he=e-1 nextgroup=vim9NormCmds contained skipwhite

# in a mapping, stop before the `<cr>` which executes `:norm`
syn region vim9NormCmds start=/./ end=/$\|\ze<cr>/ contained oneline

# Syntax {{{1

# Order: Must come *before* the rule setting `vim9HiGroup`.{{{
#
# Otherwise, the name of a highlight group would not be highlighted here:
#
#     syn clear Foobar
#               ^----^
#}}}
syn match vim9GroupList /@\=[^ \t,]\+/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep

syn match vim9GroupList /@\=[^ \t,]*,/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep
    \ nextgroup=vim9GroupList

syn keyword vim9GroupSpecial ALL ALLBUT CONTAINED TOP contained
syn match vim9SynError /\i\+/ contained
syn match vim9SynError /\i\+=/ contained nextgroup=vim9GroupList

syn match vim9SynContains /\<contain\%(s\|edin\)=/
    \ contained
    \ nextgroup=vim9GroupList

syn match vim9SynKeyContainedin /\<containedin=/ contained nextgroup=vim9GroupList
syn match vim9SynNextgroup /nextgroup=/ contained nextgroup=vim9GroupList

syn match vim9Syntax /\<sy\%[ntax]\>/
    \ contained
    \ contains=vim9GenericCmd
    \ nextgroup=vim9Comment,vim9SynType
    \ skipwhite

# Syntax: case {{{1

syn keyword vim9SynType contained
    \ case skipwhite
    \ nextgroup=vim9SynCase,vim9SynCaseError

syn match vim9SynCaseError /\i\+/ contained
syn keyword vim9SynCase ignore match contained

# Syntax: clear {{{1

# `vim9HiGroup` needs  to be in the  `nextgroup` argument, so that  `{group}` is
# highlighted in `syn clear {group}`.
syn keyword vim9SynType clear
    \ contained
    \ nextgroup=vim9GroupList,vim9HiGroup
    \ skipwhite

# Syntax: cluster {{{1

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

# Syntax: iskeyword {{{1

syn keyword vim9SynType iskeyword contained nextgroup=vim9IskList skipwhite
syn match vim9IskList /\S\+/ contained contains=vim9IskSep
syn match vim9IskSep /,/ contained

# Syntax: include {{{1

syn keyword vim9SynType include contained nextgroup=vim9GroupList skipwhite

# Syntax: keyword {{{1

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
    \ /\%#=1\<\%(conceal\|contained\|transparent\|skipempty\|skipwhite\|skipnl\)\>/
    \ contained

# Syntax: match {{{1

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

exe 'syn match vim9SynMtchOpt '
    .. '/'
    .. '\%#=1'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syn match vim9SynMtchOpt /\<cchar=/ contained nextgroup=vim9SynMtchCchar
syn match vim9SynMtchCchar /\S/ contained

# Syntax: off and on {{{1

syn keyword vim9SynType enable list manual off on reset contained

# Syntax: region {{{1

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
    \ vim9SynReg,
    \ vim9SynRegOpt

syn keyword vim9SynType region contained nextgroup=vim9SynRegion skipwhite

syn region vim9SynRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ end=/|\|$/
    \ contained
    \ contains=@vim9SynRegGroup
    \ keepend

exe 'syn match vim9SynRegOpt '
    .. '/'
    .. '\%#=1'
    .. '\<\%('
    ..         'conceal\%(ends\)\=\|transparent\|contained\|excludenl'
    .. '\|' .. 'skipempty\|skipwhite\|display\|keepend\|oneline\|extend\|skipnl'
    .. '\|' .. 'fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syn match vim9SynReg /\%(start\|skip\|end\)=/he=e-1
    \ contained
    \ nextgroup=vim9SynRegPat

syn match vim9SynMtchGrp /matchgroup=/ contained nextgroup=vim9Group,vim9HLGroup

syn region vim9SynRegPat
    \ start=/\z([-`~!@#$%^&*_=+;:'",./?|]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contained
    \ contains=@vim9SynRegPatGroup
    \ extend
    \ nextgroup=vim9SynPatMod,vim9SynReg
    \ skipwhite

syn match vim9SynPatMod
    \ /\%#=1\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=/
    \ contained

syn match vim9SynPatMod
    \ /\%#=1\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,/
    \ contained
    \ nextgroup=vim9SynPatMod

syn region vim9SynPatRange start=/\[/ skip=/\\\\\|\\]/ end=/]/ contained
syn match vim9SynNotPatRange /\\\\\|\\\[/ contained
syn match vim9MtchComment /#[^#]\+$/ contained

# Syntax: sync {{{1

syn keyword vim9SynType sync
    \ contained
    \ skipwhite
    \ nextgroup=
    \     vim9SyncC,
    \     vim9SyncError,
    \     vim9SyncLinebreak,
    \     vim9SyncLinecont,
    \     vim9SyncLines,
    \     vim9SyncMatch,
    \     vim9SyncRegion

syn match vim9SyncError /\i\+/ contained
syn keyword vim9SyncC ccomment clear fromstart contained
syn keyword vim9SyncMatch match contained nextgroup=vim9SyncGroupName skipwhite
syn keyword vim9SyncRegion region contained nextgroup=vim9SynReg skipwhite

syn match vim9SyncLinebreak /\<linebreaks=/
    \ contained
    \ nextgroup=vim9Number
    \ skipwhite

syn keyword vim9SyncLinecont linecont contained nextgroup=vim9SynRegPat skipwhite
syn match vim9SyncLines /\%(min\|max\)\=lines=/ contained nextgroup=vim9Number
syn match vim9SyncGroupName /\h\w*/ contained nextgroup=vim9SyncKey skipwhite

syn match vim9SyncKey /\<groupthere\|grouphere\>/
    \ contained
    \ nextgroup=vim9SyncGroup
    \ skipwhite

syn match vim9SyncGroup /\h\w*/
    \ contained
    \ nextgroup=vim9SynRegPat,vim9SyncNone
    \ skipwhite

syn keyword vim9SyncNone NONE contained

# Highlighting {{{1

syn cluster vim9HighlightCluster contains=
    \ vim9Comment,
    \ vim9HiClear,
    \ vim9HiKeyList,
    \ vim9HiLink

syn match vim9HiCtermError /\D\i*/ contained

syn match vim9Highlight /\<hi\%[ghlight]\>/
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
syn match vim9HiCtermColor /\<color\d\{1,3}\>/ contained
syn case match

syn match vim9HiFontname /[a-zA-Z\-*]\+/ contained
syn match vim9HiGuiFontname /'[a-zA-Z\-* ]\+'/ contained
syn match vim9HiGuiRgb /#\x\{6}/ contained

# Highlighting: hi group key=arg ... {{{1

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
syn match vim9HiTerm /\cterm=/he=e-1 contained nextgroup=vim9HiAttribList

syn match vim9HiStartStop /\c\%(start\|stop\)=/he=e-1
    \ contained
    \ nextgroup=vim9HiTermcap,vim9MayBeOptionScoped

syn match vim9HiCTerm /\ccterm=/he=e-1 contained nextgroup=vim9HiAttribList

syn match vim9HiCtermFgBg /\ccterm[fb]g=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiCtermColor,
    \     vim9HiCtermError,
    \     vim9HiNmbr

syn match vim9HiCtermul /\cctermul=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiCtermColor,
    \     vim9HiCtermError,
    \     vim9HiNmbr

syn match vim9HiGui /\cgui=/he=e-1 contained nextgroup=vim9HiAttribList
syn match vim9HiGuiFont /\cfont=/he=e-1 contained nextgroup=vim9HiFontname

syn match vim9HiGuiFgBg /\cgui\%([fb]g\|sp\)=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9FgBgAttrib,
    \     vim9HiGroup,
    \     vim9HiGuiFontname,
    \     vim9HiGuiRgb

syn match vim9HiTermcap /\S\+/ contained contains=vim9Notation
syn match vim9HiNmbr /\d\+/ contained

# Highlight: clear {{{1

# `skipwhite` is necessary for `{group}` to be highlighted in `hi clear {group}`.
syn keyword vim9HiClear clear contained nextgroup=vim9HiGroup skipwhite

# Highlight: link {{{1

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

# Control Characters {{{1

syn match vim9CtrlChar /[\x01-\x08\x0b\x0f-\x1f]/

# Beginners - Patterns that involve ^ {{{1

syn match vim9LineComment /^[ \t]\+#.*$/ contains=@vim9CommentGroup

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

syn match vim9Continue /^\s*\\/
    \ skipwhite
    \ nextgroup=
    \     vim9SynContains,
    \     vim9SynContinuePattern,
    \     vim9SynMtchGrp,
    \     vim9SynNextgroup,
    \     vim9SynReg,
    \     vim9SynRegOpt

syn match vim9SynContinuePattern =\s\+/[^/]*/= contained

syn region vim9String
    \ start=/^\s*\\\z(['"]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contains=@vim9StringGroup,vim9Continue
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
    \ contains=@vim9ExprContains

# Embedded Scripts  {{{1

unlet! b:current_syntax
syn include @vim9PythonScript syntax/python.vim

syn region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/py\%[thon][3x]\=\s*<<\s*\z(\S*\)\ze\%(\s*#.*\)\=$/
    \ end=/^\z1\ze\%(\s*".*\)\=$/
    \ contains=@vim9PythonScript

syn region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/py\%[thon][3x]\=\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vim9PythonScript

syn region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/Py\%[thon]2or3\s*<<\s*\z(\S*\)\ze\%(\s*#.*\)\=$/
    \ end=/^\z1\ze\%(\s*".*\)\=$/
    \ contains=@vim9PythonScript

syn region vim9PythonRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/Py\%[thon]2or3\=\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vim9PythonScript

unlet! b:current_syntax
syn include @vim9LuaScript syntax/lua.vim

syn region vim9LuaRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/lua\s*<<\s*\z(.*\)$/
    \ end=/^\z1$/
    \ contains=@vim9LuaScript

syn region vim9LuaRegion
    \ matchgroup=vim9ScriptDelim
    \ start=/lua\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vim9LuaScript

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
        \ start=/[^ \t@]\@1<=#\s/
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
    syn match vim9ColonForVariableScope /\<[bgstvw]\@1<=:\w\@=/ display contained
endif

# Missing parens around dictionary in lambda {{{2

if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('lambda_dict_missing_paren', true)

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
    syn match vim9LambdaDictMissingParen /{/ contained
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
        \ nextgroup=@vim9RangeContains

    syn match vim9RangeMissingSpecifier2 /[,;][a-zA-Z \t]\@=/
        \ contained
        \ nextgroup=vim9MayBeCmd
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
# Make Vim highlight custom commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we want  them to be  bold, so that  we can't conflate  a custom
# command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     hi def link vim9UserCmd vim9GenericCmd
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that when  the syntax item for `vim9UserCmd` was  defined earlier (with a
# `:syn` command), Vim has automatically created a highlight group with the same
# name; but it's cleared:
#
#     vim9UserCmd      xxx cleared
#
# That's why we don't write this:
#
#     if execute('hi vim9UserCmd') == ''
#                                  ^---^
#                                    ✘
#}}}
if execute('hi vim9UserCmd') =~ '\<cleared$'
    import Derive from 'Vim9SyntaxUtil.vim'
    Derive('vim9UserFuncNameCustom', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9UserCmd', 'vim9GenericCmd', 'term=bold cterm=bold gui=bold')
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
hi def link vim9Args Identifier
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
hi def link vim9Comment Comment
hi def link vim9CommentString vim9String
hi def link vim9CommentTitle PreProc
hi def link vim9Conditional Conditional
hi def link vim9Continue Special
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
hi def link vim9Export vim9Import
hi def link vim9FTCmd vim9GenericCmd
hi def link vim9FTOption vim9SynType
hi def link vim9FgBgAttrib vim9HiAttrib
hi def link vim9Filter vim9GenericCmd
hi def link vim9FilterLastShellCmd Special
hi def link vim9FilterShellCmd vim9ShellCmd
hi def link vim9FuncNameBuiltin Function
hi def link vim9Global vim9GenericCmd
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
hi def link vim9IsOption PreProc
hi def link vim9IskSep Delimiter
hi def link vim9LambdaArrow vim9Sep
hi def link vim9LineComment vim9Comment
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
hi def link vim9Pattern Type
hi def link vim9RangeMark Special
hi def link vim9RangeNumber Number
hi def link vim9RangeOffset Number
hi def link vim9RangePattern String
hi def link vim9RangePatternBwdDelim Delimiter
hi def link vim9RangePatternFwdDelim Delimiter
hi def link vim9RangeSpecialChar Special
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
hi def link vim9SubstSubstr SpecialChar
hi def link vim9SubstTwoBS vim9String
hi def link vim9SynCase Type
hi def link vim9SynContains vim9SynOption
hi def link vim9SynContinuePattern String
hi def link vim9SynKeyContainedin vim9SynContains
hi def link vim9SynKeyOpt vim9SynOption
hi def link vim9SynMtchGrp vim9SynOption
hi def link vim9SynMtchOpt vim9SynOption
hi def link vim9SynNextgroup vim9SynOption
hi def link vim9SynNotPatRange vim9SynRegPat
hi def link vim9SynOption Special
hi def link vim9SynPatRange vim9String
hi def link vim9SynReg Type
hi def link vim9SynRegOpt vim9SynOption
hi def link vim9SynRegPat vim9String
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
hi def link vim9UserCmdAttrb vim9Special
hi def link vim9UserCmdAttrbAddress vim9String
hi def link vim9UserCmdAttrbAddress vim9String
hi def link vim9UserCmdAttrbComma vim9Sep
hi def link vim9UserCmdAttrbComplete vim9String
hi def link vim9UserCmdAttrbEqual vim9OperAssign
hi def link vim9UserCmdAttrbErrorValue vim9Error
hi def link vim9UserCmdAttrbNargs vim9String
hi def link vim9UserCmdAttrbNargsNumber vim9Number
hi def link vim9UserCmdAttrbRange vim9String
hi def link vim9UserCmdDef Statement
hi def link vim9UserCmdLhs vim9UserCmd
hi def link vim9ValidSubType vim9DataType
#}}}1

b:current_syntax = 'vim9'
