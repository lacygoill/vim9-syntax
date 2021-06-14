vim9script

if exists('b:current_syntax')
    # bail out for a file written in legacy Vim script
    || "\n" .. getline(1, 10)->join("\n") !~ '\n\s*vim9\%[script]\>'
    # bail out if we're included from another filetype (e.g. `markdown`)
    || &filetype != 'vim'
    finish
endif

var lookahead: string
var lookbehind: string

# Requirement: Any syntax group should be prefixed with `vim9`; not `vim`.{{{
#
# To avoid any  interference from the default  syntax plugin, in case  we load a
# legacy script at some point.
#
# In particular,  we don't want  the color choices we  make for Vim9  scripts to
# affect legacy Vim scripts.
# That could happen if  we use a syntax group name which is  already used in the
# default Vim syntax plugin,  and we load a Vim9 script file  after a legacy Vim
# script file.
#
# Remember that the name  you choose for a syntax group  affects the name you'll
# have to use in a `:hi link` command.  And while syntax items are buffer-local,
# highlight groups are *global*.
#
# ---
#
# Q: But what if the default syntax plugin also uses the `vim9` prefix?
#
# A: That should not be an issue.
#
# If we and the default plugin install the same `vim9Foo` rule, we most probably
# also want the same colors.
#
# For example, right now, the default syntax plugin installs these groups:
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
#         \ matchgroup=vim9IsCommand
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
#     vim9BuiltinFuncName
#     vim9IsOption
#     vim9MapModKey
#     vim9UserAttrbKey
#
# Make sure to update `HelpTopic()` in:
#
#     ~/.vim/pack/mine/opt/doc/autoload/doc/mapping.vim
#}}}

# TODO: We  should  highlight obvious  errors  (e.g.  missing whitespace  around
# binary operators; look for "error" at  `:h vim9`).  Usage of `:let` instead of
# `:var` to declare a variable.
# Also, highlight ` = ` as an error inside an expression.
# And, highlight ` == ` as an error when used in an assignment.

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

# All `vim9IsCommand` are contained by `vim9MayBeCommand`. {{{1

# TODO: Whenever you  use this cluster, make  sure it does not  contain too many
# syntax  groups in  the  current  context.  If  necessary,  create (a)  smaller
# cluster(s).
# TODO: Add more groups  in this "mega" cluster.  It should  contain all special
# commands which can't  be matched by the generic `syn  keyword` rule.  That is,
# all  commands that  expect  special  arguments which  need  to be  highlighted
# themselves  (e.g. `:map`);  or  commands which  need to  be  highlighted in  a
# different way (e.g. `try`).
# Also, make  sure to  remove the  names of  these commands  from the  output of
# `vim9syntax#getCommandNames()` (include them in the `special` heredoc).
#
# ---
#
# Also, make sure  to remove the syntax groups/subclusters of  this mega cluster
# out of `@vim9FuncBodyContains`.
# Warning: Don't remove a  group blindly.  Only if the text  it matches can only
# appear in a limited set of positions.  For example, in the past, we've wrongly
# removed `vim9CallFuncName`.   We shouldn't have,  because a function  call can
# appear in many places, including in the middle of an expression.
syn cluster vim9CmdAllowedHere contains=
    \@vim9ControlFlow,vim9Autocmd,vim9CallFuncName,vim9CmdModifier
    \,vim9CmdTakesExpr,vim9Declare,vim9Doautocmd,vim9EchoHL,vim9Global
    \,vim9Highlight,vim9Map,vim9MayBeAbbrevCmd,vim9MayBeCommand,vim9Norm,vim9Set
    \,vim9Subst,vim9Syntax,vim9Unmap,vim9UserCmdCall,vim9UserCmdDef

syn match vim9CmdSep /|/
    \ skipwhite
    \ nextgroup=@vim9CmdAllowedHere,vim9Address

# This lookahead is necessary to prevent spurious highlightings.{{{
#
# Example:
#
#     syn region xFoo
#         \ ...
#         \ start=/pattern/
#           ^---^
#           we don't want that to be highlighted as a command
#         \ ...
#}}}
lookahead =
    # after a command, we know there must be a bang, a whitespace or a newline
       '[! \t\n]\@='
    # but there must *not* be a binary operator
    .. '\%(\s*\%([-+*/%]\==\|\.\.=\)\|\_s*->\)\@!'

# Order: `vim9MayBeCommand` must come before `vim9Augroup`, `vim9Import`, `vim9Set`.
exe 'syn match vim9MayBeCommand /\<\h\w*\>' .. lookahead .. '/'
    .. ' contained'
    .. ' contains=vim9IsCommand'

# Special Case: An Ex command in the rhs of a mapping, right after a `<cmd>` or `<bar>`.
syn match vim9MayBeCommand /\<\h\w*\ze\%(<bar>\|<cr>\)/
    \ contained
    \ contains=vim9IsCommand

# An Ex command might be at the start of a line.
syn match vim9StartOfLine /^/
    \ skipwhite
    \ nextgroup=@vim9CmdAllowedHere,vim9FuncHeader,vim9Import,vim9Export,vim9RangeIntroducer

# Builtin Ex commands {{{1
# Generic ones {{{2

exe 'syn keyword vim9IsCommand ' .. vim9syntax#getCommandNames() .. ' contained'

syn match vim9IsCommand /\<z[-+^.=]\=\>/ contained

# Special ones {{{2
# Modifier commands {{{3

exe 'syn match vim9CmdModifier /\<\%('
    ..         'bel\%[owright]'
    .. '\|' .. 'bo\%[tright]'
    .. '\|' .. 'bro\%[wse]'
    .. '\|' .. 'hid\%[e]'
    .. '\|' .. 'keepalt'
    .. '\|' .. 'keep\%[jumps]'
    .. '\|' .. 'kee\%[pmarks]'
    .. '\|' .. 'keepp\%[atterns]'
    .. '\|' .. 'lefta\%[bove]'
    .. '\|' .. 'leg\%[acy]'
    .. '\|' .. 'loc\%[kmarks]'
    .. '\|' .. 'noa\%[utocmd]'
    .. '\|' .. 'nos\%[wapfile]'
    .. '\|' .. 'rightb\%[elow]'
    .. '\|' .. 'san\%[dbox]'
    .. '\|' .. 'sil\%[ent]'
    .. '\|' .. 'tab'
    .. '\|' .. 'to\%[pleft]'
    .. '\|' .. 'uns\%[ilent]'
    .. '\|' .. 'verb\%[ose]'
    .. '\|' .. 'vert\%[ical]'
    .. '\|' .. 'vim9\%[cmd]'
    .. '\)\>/'
    .. ' contained'
    .. ' nextgroup=@vim9CmdAllowedHere,vim9CmdBang,vim9RangeIntroducer'
    .. ' skipwhite'

syn match vim9CmdBang /!/ contained nextgroup=@vim9CmdAllowedHere skipwhite

# Commands taking expression as argument {{{3

exe 'syn region vim9CmdTakesExpr'
    .. ' excludenl'
    .. ' matchgroup=vim9IsCommand'
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
    # Do not highlight a poorly-named variable as a command.{{{
    #
    #     var execute: string
    #     execute = 'text'
    #     ^-----^
    #     this should NOT be highlighted as a command
    #
    # ---
    #
    # If you need to be even more restrictive, try this instead:
    #
    #     .. '\%(' .. '\s\+[-+!"''\x28\x5b{&$@_a-zA-Z]' .. '\)\@='
    #
    # This  leverages the  fact that  when `execute`  (& friends)  is used  as a
    # command, it must  be followed by an expression; and  only a few characters
    # can appear at the start of an expression.
    #}}}
    .. '\%(\s*\%(=\|->\)\)\@!'
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

syn match vim9Export /\<export\>/ contained

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
syn keyword vim9EchoHLNone none
syn case match
#}}}1
# Range {{{1

syn cluster vim9RangeContains contains=
    \vim9RangeDelimiter,vim9RangeMark,vim9RangeMissingSpecifier2,vim9RangeNumber
    \,vim9RangeOffset,vim9RangePattern,vim9RangeSpecialChar

# Make sure there is nothing before, to avoid a wrong match in sth like:
#     g:name = 'value'
#      ^
syn match vim9RangeIntroducer /\%(^\|\s\):\S\@=/
    \ nextgroup=@vim9RangeContains,vim9RangeMissingSpecifier1
    \ contained

syn cluster vim9RangeAfterSpecifier
    \ contains=@vim9CmdAllowedHere,@vim9RangeContains,vim9Filter,vim9RangeMissingSpace

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
    \ nextgroup=vim9MayBeOptionSet
    \ skipwhite

# Option names {{{2

# We  include  `-` and  `+`  in  the lookbehind  to  support  the increment  and
# decrement operators (`--` and `++`).  Example:
#
#     ++&l:foldlevel
#     ^^
lookbehind = '\%(^\|[-+ \t!([]\)\@1<='

# sigil to refer to option value
var sigil: string = '&\%([gl]:\)\='

var option_name: string = '\%('
            # name of regular option
    ..     '[a-z]\{2,}\>'
    .. '\|'
            # name of terminal option
    ..     't_[a-zA-Z0-9#%*:@_]\{2}'
    .. '\)'

# Note that an option value can be written right at the start of the line.{{{
#
#     &guioptions = 'M'
#     ^---------^
#}}}
exe 'syn match vim9MayBeOptionScoped '
    .. '/'
    ..     lookbehind
    ..     sigil
    ..     option_name
    .. '/'
    .. ' contains=vim9IsOption,vim9OptionSigil'
    .. ' nextgroup=vim9SetEqual'

exe 'syn match vim9MayBeOptionSet '
    .. '/'
    ..     lookbehind
    ..     option_name
    .. '/'
    .. ' contained'
    .. ' contains=vim9IsOption'
    .. ' nextgroup=vim9SetEqual,vim9MayBeOptionSet,vim9SetMod'
    .. ' skipwhite'

syn match vim9OptionSigil /&\%([gl]:\)\=/ contained

exe 'syn keyword vim9IsOption '
    .. vim9syntax#getOptionNames()
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'
    .. ' skipwhite'

# terminal options are tricky
vim9syntax#installTerminalOptionsRules()

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

syn cluster vim9AugroupList contains=
    \@vim9DataTypeCluster,vim9Address,vim9Augroup,vim9BacktickExpansion
    \,vim9BacktickExpansionVimExpr,vim9Block,vim9Bool,vim9CallFuncName
    \,vim9CmdModifier,vim9CmdSep,vim9Comment,vim9ComplexRepeat,vim9Conditional
    \,vim9Continue,vim9CtrlChar,vim9Declare,vim9Dict,vim9EnvVar,vim9FuncHeader
    \,vim9HereDoc,vim9LegacyFunction,vim9Map,vim9MayBeOptionScoped,vim9Notation
    \,vim9Number,vim9Oper,vim9OperAssign,vim9OperParen,vim9Region,vim9Repeat
    \,vim9Return,vim9Set,vim9SpecFile,vim9StartOfLine,vim9String,vim9Subst
    \,vim9SynLine,vim9UserCmdDef

# Actually, the case of `END` does not matter.{{{
#
# Also, the name of an augroup can contain any keyword character.
# But in both cases, I prefer to enforce widely adopted conventions.
#}}}
# `keepend` is necessary to prevent `vim9MayBeCommand` from consuming `END`.{{{
#
# This would force Vim to wrongly extend  the augroup/region to find a new match
# for the region's end.
#}}}
# The  `end`  pattern needs  `^\s*`  to  prevent a  wrong  match  on a  possible
# commented augroup inside the current augroup.
syn region vim9Augroup
    \ start=/\<aug\%[roup]\s\+\%(END\)\@!\h\%(\w\|-\)*/
    \ matchgroup=vim9AugroupEnd
    \ end=/^\s*aug\%[roup]\s\+\zsEND\>/
    \ contains=@vim9AugroupList
    \ keepend

# `:autocmd` {{{2

# :au[tocmd] [group] {event} {pat} [++once] [++nested] {cmd}
syn match vim9Autocmd /\<au\%[tocmd]\>\%(\s*\w\)\@=/
    \ contained
    \ nextgroup=vim9AutocmdAllEvents,vim9AutocmdEventBadCase
    \,vim9AutocmdEventGoodCase,vim9AutocmdGroup,vim9AutocmdMod
    \ skipwhite
# The positive  lookahead prevents  a variable named  `auto` from  being wrongly
# highlighted as a command in an assignment or a computation.

#           v
# :au[tocmd]! ...
syn match vim9Autocmd /\<au\%[tocmd]\>!/he=e-1
    \ contained
    \ nextgroup=vim9AutocmdAllEvents,vim9AutocmdEventBadCase
    \,vim9AutocmdEventGoodCase,vim9AutocmdGroup
    \ skipwhite

# The trailing whitespace is useful to prevent a correct but still noisy/useless
# match when we simply clear an augroup.
syn match vim9AutocmdGroup /\S\+\s\@=/
    \ contained
    \ nextgroup=vim9AutocmdAllEvents,vim9AutocmdEventBadCase,vim9AutocmdEventGoodCase
    \ skipwhite

# Special Case: A wildcard can be used for all events.{{{
#
#     au! * <buffer>
#         ^
#
# This is *not* the same syntax token as the pattern which follows an event.
#}}}
syn match vim9AutocmdAllEvents /\*\_s\@=/ contained nextgroup=vim9AutocmdPat skipwhite

syn match vim9AutocmdPat /\S\+/
    \ contained
    \ nextgroup=@vim9CmdAllowedHere,vim9AutocmdMod
    \ skipwhite

syn match vim9AutocmdMod /++\%(nested\|once\)/
    \ nextgroup=@vim9CmdAllowedHere
    \ skipwhite

# Events {{{2

# TODO: Hide the bad case error behind an option.
var events: string = vim9syntax#getEventNames()
syn case ignore
exe 'syn keyword vim9AutocmdEventBadCase ' .. events
    .. ' contained'
    .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
    .. ' skipwhite'
syn case match

exe 'syn keyword vim9AutocmdEventGoodCase ' .. events
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
    \ nextgroup=vim9AutocmdEventBadCase,vim9AutocmdEventGoodCase
    \,vim9AutocmdGroup,vim9AutocmdMod

syn match vim9AutocmdMod /<nomodeline>/
    \ nextgroup=vim9AutocmdEventBadCase,vim9AutocmdEventGoodCase,vim9AutocmdGroup
    \ skipwhite
#}}}1
# vim9Todo: contains common special-notices for comments {{{1
# Use the `vim9CommentGroup` cluster to add your own.

syn keyword vim9Todo FIXME TODO contained
syn cluster vim9CommentGroup contains=
    \@Spell,vim9CommentString,vim9CommentTitle,vim9DictLiteralLegacyError,vim9Todo

# Variables {{{1

syn keyword vim9Declare cons[t] final unl[et] var contained skipwhite nextgroup=vim9DeclareReserved
syn keyword vim9DeclareReserved true false null this contained

# NOTE: In the default syntax plugin, `vimLetHereDoc` contains `vimComment` and `vim9Comment`.{{{
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
    \ start=/=<<\s\+\%(trim\>\)\=\s*\z(\L\S*\)/
    \ end=/^\s*\z1$/

syn match vim9EnvVar /\$[A-Z_][A-Z0-9_]*/

# Even though `v:` is useless in Vim9, we  still need it in a mapping; because a
# mapping is run in the legacy context, even when installed from a Vim9 script.
syn match vim9Bool /\%(v:\)\=\<\%(false\|true\)\>:\@!/
syn match vim9Null /\%(v:\)\=\<null\>:\@!/

# Highlight commonly used Groupnames {{{1

syn case ignore
syn keyword vim9Group contained
    \ Comment Constant String Character Number Boolean Float Identifier Function
    \ Statement Conditional Repeat Label Operator Keyword Exception PreProc
    \ Include Define Macro PreCondit Type StorageClass Structure Typedef Special
    \ SpecialChar Tag Delimiter SpecialComment Debug Underlined Ignore Error Todo
syn case match

# Default highlighting groups {{{1

syn case ignore
syn keyword vim9HLGroup contained
    \ ColorColumn Cursor CursorColumn CursorIM CursorLine CursorLineNr
    \ DiffAdd DiffChange DiffDelete DiffText Directory EndOfBuffer ErrorMsg
    \ FoldColumn Folded IncSearch LineNr LineNrAbove LineNrBelow MatchParen Menu
    \ ModeMsg MoreMsg NonText Normal Pmenu PmenuSbar PmenuSel PmenuThumb Question
    \ QuickFixLine Scrollbar Search SignColumn SpecialKey SpellBad SpellCap
    \ SpellLocal SpellRare StatusLine StatusLineNC StatusLineTerm TabLine
    \ TabLineFill TabLineSel Terminal Title Tooltip VertSplit Visual VisualNOS
    \ WarningMsg WildMenu
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
exe 'syn keyword vim9BuiltinFuncName '
    .. vim9syntax#getBuiltinFunctionNames()
    .. ' contained'

exe 'syn match vim9BuiltinFuncName '
    .. '/\<\%('
    ..     vim9syntax#getBuiltinFunctionNames(true)
    .. '\)'
    .. '(\@='
    .. '/'
    .. ' contained'

# Filetypes {{{1

syn match vim9Filetype /\<filet\%[ype]\%(\s\+\I\i*\)*/
    \ contains=vim9FTCmd,vim9FTError,vim9FTOption
    \ skipwhite

syn match vim9FTError /\I\i*/ contained
syn keyword vim9FTCmd filet[ype] contained
syn keyword vim9FTOption detect indent off on plugin contained

# Operators {{{1

syn cluster vim9ExprContains contains=
    \vim9Bool,vim9CallFuncName,vim9DataTypeCast,vim9Dict,vim9EnvVar,vim9List
    \,vim9MayBeOptionScoped,vim9Null,vim9Number,vim9Oper,vim9OperParen
    \,vim9String

# `vim9LineComment` needs to be in `@vim9OperGroup`.{{{
#
# So that the comment leader is highlighted  on an empty commented line inside a
# dictionary inside a function.
#}}}
syn cluster vim9OperGroup contains=
    \@vim9ExprContains,vim9Comment,vim9Continue,vim9DataType,vim9DataTypeCast
    \,vim9DataTypeCastComposite,vim9DataTypeCompositeLeadingColon
    \,vim9LineComment,vim9Oper,vim9OperAssign,vim9OperParen

syn match vim9Oper "\s\@1<=\%([-+*/%!]\|\.\.\|==\|!=\|>=\|<=\|=\~\|!\~\|>\|<\)[?#]\{0,2}\_s\@="
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
    \ contains=@vim9OperGroup,vim9Args,vim9Block,vim9LambdaArrow
    \,vim9MayBeOptionScoped

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
    \ contains=
    \@vim9OperGroup,vim9DictExprKey,vim9DictMayBeLiteralKey,vim9LambdaArrow
    \,vim9MayBeOptionScoped

# in literal dictionary, highlight keys as strings
syn match vim9DictMayBeLiteralKey /\%(^\|[ \t{]\)\@1<=[^ {(]\+\ze\%(:\s\)\@=/
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

syn cluster vim9FuncList contains=vim9DefKey,vim9FuncScope

# `vim9LineComment` needs to be in `@vim9FuncBodyContains`.{{{
#
# So that the comment leader is highlighted  on an empty commented line inside a
# function.
#}}}
# The default script includes `vimSynType` inside `@vimFuncBodyList`.  Don't do the same.{{{
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
    \vim9Address,vim9Augroup,vim9BacktickExpansion,vim9BacktickExpansionVimExpr
    \,vim9Block,vim9Bool,vim9CallFuncName,vim9CmdSep,vim9Comment
    \,vim9ComplexRepeat,vim9Continue,vim9CtrlChar,vim9DataType,vim9DataTypeCast
    \,vim9DataTypeCastComposite,vim9DataTypeCompositeLeadingColon,vim9Dict
    \,vim9EnvVar,vim9FuncHeader,vim9GroupAdd,vim9GroupRem,vim9HereDoc,vim9HiLink
    \,vim9LambdaArrow,vim9LegacyFunction,vim9LineComment,vim9LuaRegion
    \,vim9MayBeOptionScoped,vim9Notation,vim9Null,vim9Number,vim9Oper
    \,vim9OperAssign,vim9OperParen,vim9PythonRegion,vim9RangeIntroducer
    \,vim9Region,vim9SpecFile,vim9StartOfLine,vim9String,vim9SynLine
    \,vim9SynMtchGroup
# TODO: Make sure no special command/keyword is wrongly highlighted when used as
# a variable name.  If necessary, remove some syntax groups from this cluster.

exe 'syn match vim9FuncHeader'
    .. ' /'
    .. '\<def!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(\i\|[#.]\)*'
    .. '\ze('
    .. '/'
    .. ' contains=@vim9FuncList'
    .. ' nextgroup=vim9FuncBody'

syn region vim9FuncBody
    \ start=/(/
    \ matchgroup=vim9DefKey
    \ end=/^\s*enddef$/
    \ contains=@vim9FuncBodyContains
    \ contained
    \ keepend

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
    \ matchgroup=vim9IsCommand
    \ end=/\<endf\%[unction]/
    \ contained

syn match vim9FuncScope /\<[gs]:/ contained
syn keyword vim9DefKey def fu[nction] contained
syn match vim9FuncBlank /\s\+/ contained

syn keyword vim9Pattern start skip end contained

syn match vim9LambdaArrow /\s\@1<==>\_s\@=/

# block at script-level, function-level, or inside lambda
syn region vim9Block
    \ matchgroup=Statement
    \ start=/^\s*{$\|\s\+=>\s\+{$/
    \ end=/^\s*}/
    \ contains=@vim9FuncBodyContains

# Special Filenames, Modifiers, Extension Removal {{{1

syn match vim9SpecFile /<c\%(word\|WORD\)>/ nextgroup=vim9SpecFileMod,vim9Subst

syn match vim9SpecFile /<\%([acs]file\|amatch\|abuf\)>/
    \ nextgroup=vim9SpecFileMod,vim9Subst

# Do *not* add allow a space to match after `%`.{{{
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
syn match vim9SpecFile /\s%:/ms=s+1,me=e-1 nextgroup=vim9SpecFileMod,vim9Subst
syn match vim9SpecFile /\s%$/ms=s+1 nextgroup=vim9SpecFileMod,vim9Subst
syn match vim9SpecFile /\s%</ms=s+1,me=e-1 nextgroup=vim9SpecFileMod,vim9Subst
syn match vim9SpecFile /#\d\+\|[#%]<\>/ nextgroup=vim9SpecFileMod,vim9Subst
syn match vim9SpecFileMod /\%(:[phtreS]\)\+/ contained

# User-Specified Commands {{{1

syn cluster vim9UserCmdList contains=
    \vim9Address,vim9Autocmd,vim9BuiltinFuncName,vim9CallFuncName,vim9Comment
    \,vim9ComplexRepeat,vim9CtrlChar,vim9Declare,vim9EscapeBrace,vim9FuncHeader
    \,vim9Highlight,vim9LegacyFunction,vim9Notation,vim9Number,vim9Oper
    \,vim9Region,vim9Set,vim9SpecFile,vim9String,vim9Subst,vim9SubstRange
    \,vim9SubstRep,vim9SynLine,vim9Syntax

syn match vim9UserCmdDef /\<com\%[mand]\>.*$/
    \ contains=@vim9UserCmdList,vim9ComFilter,vim9UserAttrb,vim9UserAttrbError
    \ contained

syn match vim9UserAttrbError /-\a\+\ze\s/ contained

syn match vim9UserAttrb /-nargs=[01*?+]/
    \ contained
    \ contains=vim9Oper,vim9UserAttrbKey

syn match vim9UserAttrb /-complete=/
    \ contained
    \ contains=vim9Oper,vim9UserAttrbKey
    \ nextgroup=vim9UserAttrbCmplt,vim9UserCmdError

syn match vim9UserAttrb
    \ /-range\%(=%\|=\d\+\)\=/
    \ contained
    \ contains=vim9Number,vim9Oper,vim9UserAttrbKey

syn match vim9UserAttrb
    \ /-count\%(=\d\+\)\=/
    \ contained
    \ contains=vim9Number,vim9Oper,vim9UserAttrbKey

syn match vim9UserAttrb /-bang\>/ contained contains=vim9Oper,vim9UserAttrbKey
syn match vim9UserAttrb /-bar\>/ contained contains=vim9Oper,vim9UserAttrbKey
syn match vim9UserAttrb /-buffer\>/ contained contains=vim9Oper,vim9UserAttrbKey
syn match vim9UserAttrb /-register\>/ contained contains=vim9Oper,vim9UserAttrbKey
syn match vim9UserCmdError /\S\+\>/ contained

syn case ignore
syn keyword vim9UserAttrbKey contained
    \ bar ban[g] cou[nt] ra[nge] com[plete] n[args] re[gister]

syn keyword vim9UserAttrbCmplt contained
    \ augroup
    \ buffer behave color command compiler cscope dir environment event

syn keyword vim9UserAttrbCmplt contained
    \ expression file file_in_path function help locale mapping packadd shellcmd
    \ sign syntax syntime tag tag_listfiles user
    \ filetype
    \ highlight
    \ history
    \ menu
    \ option
    \ var

syn keyword vim9UserAttrbCmplt contained
    \ custom customlist
    \ nextgroup=vim9UserAttrbCmpltFunc,vim9UserCmdError
syn case match

syn match vim9UserAttrbCmpltFunc
    \ /,\%(s:\)\=\%(\h\w*\%(#\h\w*\)\+\|\h\w*\)/hs=s+1
    \ contained
    \ nextgroup=vim9UserCmdError

syn match vim9UserAttrbCmplt /custom,\u\w*/ contained

# Lower Priority Comments: after some vim commands... {{{1

syn region vim9CommentString start=/\%(\S\s\+\)\@<="/ end=/"/ contained oneline

# inline comments
# Warning: Do *not* use the `display` argument here.
syn match vim9Comment /\s\@1<=#.*$/ contains=@vim9CommentGroup excludenl

syn match vim9Comment /^\s*#.*$/ contains=@vim9CommentGroup

# In legacy Vim script, a literal dictionary starts with `#{`.
# This syntax is no longer valid in Vim9.
# Highlight it as an error.
syn match vim9DictLiteralLegacyError /#{{\@!/

# In-String Specials {{{1

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
    \@Spell,vim9EscapeBrace,vim9NotPatSep,vim9PatSep,vim9PatSepErr,vim9PatSepZone

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

syn match vim9Number /\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /\<0[xX]\x\+/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /\%(^\|\A\)\zs#\x\{6}/
    \ nextgroup=vim9Comment
    \ skipwhite

syn match vim9Number /\<0[zZ][a-zA-Z0-9.]\+/
    \ nextgroup=vim9Comment
    \ skipwhite

# TODO: Why no `\<`?
syn match vim9Number /0o[0-7]\+/
    \ nextgroup=vim9Comment
    \ skipwhite

# TODO: Why no `\<`?
syn match vim9Number /0b[01]\+/
    \ nextgroup=vim9Comment
    \ skipwhite

# It is possible to use single quotes inside numbers to make them easier to read:{{{
#
#     echo 1'000'000
#
# Highlight them as part of a number.
#}}}
syn match vim9Number /\d\@1<='\d\@=/
    \ nextgroup=vim9Comment
    \ skipwhite

# Substitutions {{{1

syn cluster vim9SubstList contains=
    \vim9Collection,vim9Notation,vim9PatRegion,vim9PatSep,vim9PatSepErr
    \,vim9SubstRange,vim9SubstTwoBS

syn cluster vim9SubstRepList contains=
    \vim9Notation,vim9SubstSubstr,vim9SubstTwoBS

exe 'syn match vim9Subst'
    .. ' /'
    ..     '\%(:\+\s*\|^\s*\||\s*\)'
    ..     '\<\%(\<s\%[ubstitute]\>\|\<sm\%[agic]\>\|\<sno\%[magic]\>\)'
    ..     '[:#[:alpha:]]\@!'
    .. '/'
    .. ' nextgroup=vim9SubstPat'

# We don't recognize `(` as a delimiter.{{{
#
# That's because  – sometimes  – it  would cause `s`  or `substitute`  to be
# wrongly highlighted as an Ex command.
#
# Example:
#
#     def A()
#         B(s)
#     enddef
#
# Also, when used as a method:
#
#     fu A()
#         eval substitute('aaa', 'b', 'c', '')->B()
#     endfu
#
#     fu A()
#         call substitute('aaa', 'b', 'c', '')->B()
#     endfu
#
#     fu A()
#         return histget(':')->execute()->substitute('\n', '', '')
#     endfu
#
# Besides, using `(` as a delimiter is a bad idea.
# It makes the code more ambiguous and harder to read:
#
#     :substitute(pattern(replacement(flags
#                ^       ^           ^
#                ✘       ✘           ✘
#
# It's easy to choose a different and less problematic delimiter:
#
#     :substitute@pattern@replacement@flags
#                ^       ^           ^
#                ✔       ✔           ✔
#}}}
syn match vim9Subst /\%(^\|[^\\"'(]\)\@1<=\<\%(s\%[ubstitut]\|substitute(\@!\)\>[:#[:alpha:]"']\@!/
    \ contained
    \ nextgroup=vim9SubstPat

syn match vim9Subst +/\zs\<s\%[ubstitute]\>\ze/+ nextgroup=vim9SubstPat
syn match vim9Subst /\%(:\+\s*\|^\s*\)s\ze#.\{-}#.\{-}#/ nextgroup=vim9SubstPat

syn region vim9SubstPat
    \ matchgroup=vim9SubstDelim
    \ start=/\z([^a-zA-Z( \t[\]&]\)/rs=s+1
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/re=e-1,me=e-1
    \ contained
    \ contains=@vim9SubstList
    \ nextgroup=vim9SubstRep4
    \ oneline

syn region vim9SubstRep4
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
    \ contains=vim9CollClass
    \ transparent

syn match vim9CollClassErr /\[:.\{-\}:\]/ contained

exe 'syn match vim9CollClass '
    .. ' /\%#=1\[:'
    .. '\%('
    ..         'alnum\|alpha\|blank\|cntrl\|digit\|graph\|lower\|print\|punct'
    .. '\|' .. 'space\|upper\|xdigit\|return\|tab\|escape\|backspace'
    .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syn match vim9SubstSubstr /\\z\=\d/ contained
syn match vim9SubstTwoBS /\\\\/ contained
syn match vim9SubstFlagErr /[^< \t\r|]\+/ contained contains=vim9SubstFlags
syn match vim9SubstFlags /[&cegiIlnpr#]\+/ contained

# 'String' {{{1

syn match vim9String /[^(,]'[^']\{-}\zs'/

# Filters {{{1

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
syn region vim9Filter
    \ matchgroup=vim9IsCommand
    \ start=/!/
    \ matchgroup=vim9ShellCmd
    \ end=/.*/
    \ contained
    \ oneline

# Abbreviations {{{1

exe 'syn match vim9MayBeAbbrevCmd'
    .. ' /'
    .. '\<\%('
    ..             'inorea\%[bbrev]'
    ..     '\|' .. 'cnorea\%[bbrev]'
    ..     '\|' .. 'norea\%[bbrev]'
    ..     '\|' .. 'ia\%[bbrev]'
    ..     '\|' .. 'ca\%[bbrev]'
    ..     '\|' .. 'ab\%[breviate]'
    .. '\)\s'
    .. '/'
    .. ' contained'
    .. ' contains=vim9IsAbbrevCmd'
    .. ' nextgroup=@vim9MapLhs,@vim9MapMod'

syn keyword vim9IsAbbrevCmd
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ contained
    \ skipwhite

# Angle-Bracket Notation {{{1

syn case ignore
exe 'syn match vim9Notation'
    .. ' /'
    .. '\%#=1\%(\\\|<lt>\)\='
    .. '<' .. '\%([scamd]-\)\{0,4}x\='
    .. '\%('
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
    \ nextgroup=@vim9CmdAllowedHere,@vim9RangeContains

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
    \ contains=vim9CtrlChar,vim9MapCmd,vim9MapCommandLineExpr,vim9MapInsertExpr
    \,vim9Notation
    \ nextgroup=vim9MapRhsExtend
    \ skipnl

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
syn region vim9MapCommandLineExpr
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
    \ nextgroup=@vim9CmdAllowedHere
    \ skipwhite

syn match vim9MapRhsExtend /^\s*\\.*$/ contained contains=vim9Continue
syn match vim9MapRhsExtendExpr /^\s*\\.*$/
    \ contained
    \ contains=@vim9ExprContains,vim9Continue

# User Function Highlighting {{{1

# call to any kind of function (builtin + custom)
exe 'syn match vim9CallFuncName '
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
    .. ' contains=vim9BuiltinFuncName,vim9UserCallFuncName'

# call to custom function
exe 'syn match vim9UserCallFuncName '
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

# User Command Highlighting {{{1

exe 'syn match vim9UserCmdCall '
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
    # Don't highlight a funcref expression at the start of a line; nor a key in a literal dictionary.{{{
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
    #
    # ---
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
    # `vim9OperParen`, which can cause `Key` to be parsed as `vim9UserCmdCall`.
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
    .. '\|' .. '\%(\s*->\|:\)'
    .. '\)\@!"'
    .. ' contained'

# Data Types {{{1

# Order: This section must come *after* the `vim9CallFuncName` and `vim9UserCallFuncName` rules.{{{
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
    \vim9DataType,vim9DataTypeCast,vim9DataTypeCastComposite
    \,vim9DataTypeCompositeLeadingColon,vim9DataTypeFuncref,vim9DataTypeListDict

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

# sanitize subtypes
exe 'syn match vim9ValidSubType'
    .. ' /'
    .. 'any\|blob\|bool\|channel'
    .. '\|float\|func(\@!\|job\|number\|string\|void'
    # the lookbehinds are  necessary to avoid breaking the nesting  of the outer
    # region;  which would  prevent some  trailing `>`  or `)`  to be  correctly
    # highlighted
    .. '\|d\@1<=ict<\|f\@1<=unc(\|)\|l\@1<=ist<'
    .. '/'
    .. ' contained'

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

# Control Flow + Return {{{1

syn cluster vim9ControlFlow contains=
    \vim9Conditional,vim9Repeat,vim9Return,vim9TryCatch

syn match vim9Return
    \ /\<return\>/
    \ contained
    \ nextgroup=@vim9ExprContains
    \ skipwhite

syn match vim9Conditional
    \ /\<\%(if\|el\%[seif]\)\>/
    \ contained
    \ nextgroup=@vim9ExprContains
    \ skipwhite

syn match vim9Conditional /\<en\%[dif]\>/ contained skipwhite

syn match vim9Repeat
    \ /\<\%(for\=\|wh\%[ile]\)\>/
    \ contained
    \ skipwhite
    \ nextgroup=@vim9ExprContains

syn match vim9Repeat /\<\%(endfor\=\|endw\%[hile]\)\>/ contained skipwhite

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
# lookbehind.  But it would be more costly.
syn match vim9TryCatchPattern +/.*/+ contained contains=vim9TryCatchPatternDelim
syn match vim9TryCatchPatternDelim +/+ contained

# Norm {{{1

syn match vim9Norm /\<norm\%[al]\>/ nextgroup=vim9NormCmds skipwhite
syn match vim9Norm /\<norm\%[al]\>!/he=e-1 nextgroup=vim9NormCmds skipwhite
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
    \ contains=vim9IsCommand
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

syn cluster vim9SynKeyGroup
    \ contains=vim9SynKeyContainedin,vim9SynKeyOpt,vim9SynNextgroup

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
    \vim9Comment,vim9MtchComment,vim9Notation,vim9SynContains,vim9SynError
    \,vim9SynMtchOpt,vim9SynNextgroup,vim9SynRegPat

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
    \vim9NotPatSep,vim9Notation,vim9PatRegion,vim9PatSep,vim9PatSepErr
    \,vim9SubstSubstr,vim9SynNotPatRange,vim9SynPatRange

syn cluster vim9SynRegGroup contains=
    \vim9SynContains,vim9SynMtchGrp,vim9SynNextgroup,vim9SynReg,vim9SynRegOpt

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
    \ nextgroup=vim9SyncC,vim9SyncError,vim9SyncLinebreak,vim9SyncLinecont
    \,vim9SyncLines,vim9SyncMatch,vim9SyncRegion

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

syn cluster vim9HighlightCluster
    \ contains=vim9Comment,vim9HiClear,vim9HiKeyList,vim9HiLink

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
    \vim9Group,vim9HiCTerm,vim9HiCtermFgBg,vim9HiCtermul,vim9HiGroup,vim9HiGui
    \,vim9HiGuiFgBg,vim9HiGuiFont,vim9HiKeyError,vim9HiStartStop,vim9HiTerm
    \,vim9Notation

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
    \ nextgroup=vim9FgBgAttrib,vim9HiCtermColor,vim9HiCtermError,vim9HiNmbr

syn match vim9HiCtermul /\cctermul=/he=e-1
    \ contained
    \ nextgroup=vim9FgBgAttrib,vim9HiCtermColor,vim9HiCtermError,vim9HiNmbr

syn match vim9HiGui /\cgui=/he=e-1 contained nextgroup=vim9HiAttribList
syn match vim9HiGuiFont /\cfont=/he=e-1 contained nextgroup=vim9HiFontname

syn match vim9HiGuiFgBg /\cgui\%([fb]g\|sp\)=/he=e-1
    \ contained
    \ nextgroup=vim9FgBgAttrib,vim9HiGroup,vim9HiGuiFontname,vim9HiGuiRgb

syn match vim9HiTermcap /\S\+/ contained contains=vim9Notation
syn match vim9HiNmbr /\d\+/ contained

# Highlight: clear {{{1

# `skipwhite` is necessary for `{group}` to be highlighted in `hi clear {group}`.
syn keyword vim9HiClear clear contained nextgroup=vim9HiGroup skipwhite

# Highlight: link {{{1

exe 'syn region vim9HiLink'
    .. ' matchgroup=vim9IsCommand'
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

syn match vim9LineComment /^[ \t:]\+#.*$/ contains=@vim9CommentGroup

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

# `@vim9CmdAllowedHere` is useful for autocmds broken down on multiple lines:{{{
#
#     au BufEnter *
#         \ execute 'ls'
#           ^-----^
#           we want this to be highlighted as a command
#}}}
syn match vim9Continue /^\s*\\/
    \ skipwhite
    \ nextgroup=@vim9CmdAllowedHere,vim9SynContains,vim9SynMtchGrp,vim9SynNextgroup,vim9SynReg
    \,vim9SynContinuePattern,vim9SynRegOpt

syn match vim9SynContinuePattern =\s\+/[^/]*/= contained

syn region vim9String
    \ start=/^\s*\\\z(['"]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contains=@vim9StringGroup,vim9Continue
    \ keepend
    \ oneline

# Searches And Globals {{{1

syn region vim9Global
    \ matchgroup=Statement
    \ start=+\<g\%[lobal]!\=/+
    \ skip=/\\./
    \ end=+/+
    \ nextgroup=vim9Subst
    \ contained
    \ oneline
    \ skipwhite

syn region vim9Global
    \ matchgroup=Statement
    \ start=+\<v\%[global]!\=/+
    \ skip=/\\./
    \ end=+/+
    \ nextgroup=vim9Subst
    \ contained
    \ oneline
    \ skipwhite

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

# Discourage usage  of an  implicit line  specifier, because  it makes  the code
# harder to read.
if get(g:, 'vim9_syntax', {})->get('range-missing-specifier')
    syn match vim9RangeMissingSpecifier1 /[,;]/
        \ contained
        \ nextgroup=@vim9RangeContains

    syn match vim9RangeMissingSpecifier2 /[,;][a-zA-Z \t]\@=/
        \ contained
        \ nextgroup=@vim9CmdAllowedHere
        \ skipwhite
endif

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
# Note that this issue also affects the legacy script.
# We could try to fix it by removing all digits from the *syntax* option 'iskeyword':
#
#     :syntax iskeyword @,_
#
# But that would cause  other issues which would require too  much extra code to
# handle.   Indeed,  it would  break  all  the  `syn  keyword` rules  for  words
# containing digits.   It would also change  the semantics of the  `\<` and `\>`
# atoms in all regexes used for `syn match` and `syn region` rules.
#}}}
if get(g:, 'vim9_syntax', {})->get('range-missing-space')
    syn match vim9RangeMissingSpace /\S\@1<=\a/ contained
endif

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

hi def link vim9IsCommand Statement
# Make Vim highlight custom commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we want  them to be  bold, so that  we can't conflate  a custom
# command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     hi def link vim9UserCmdCall vim9IsCommand
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that when  the syntax item for `vim9UserCmdCall`  was defined earlier
# (with a `:syn` command), Vim has  automatically created a highlight group with
# the same name; but it's cleared:
#
#     vim9UserCmdCall      xxx cleared
#
# That's why we don't write this:
#
#     if execute('hi vim9UserCmdCall') == ''
#                                      ^---^
#                                        ✘
#}}}
if execute('hi vim9UserCmdCall') =~ '\<cleared$'
    import Derive from 'vim9syntax.vim'
    Derive('vim9UserCallFuncName', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9UserCmdCall', 'vim9IsCommand', 'term=bold cterm=bold gui=bold')
    Derive('vim9FuncHeader', 'Function', 'term=bold cterm=bold gui=bold')
    Derive('vim9CmdModifier', 'vim9IsCommand', 'term=italic cterm=italic gui=italic')
endif

hi def link vim9AutocmdEventBadCase vim9Error
hi def link vim9CallFuncName vim9Error
hi def link vim9CollClassErr vim9Error
hi def link vim9FTError vim9Error
hi def link vim9HiAttribList vim9Error
hi def link vim9HiCtermError vim9Error
hi def link vim9HiKeyError vim9Error
hi def link vim9MapModErr vim9Error
hi def link vim9SubstFlagErr vim9Error
hi def link vim9SynCaseError vim9Error

hi def link vim9Args Identifier
hi def link vim9AugroupEnd Special
hi def link vim9AugroupError vim9Error
hi def link vim9Autocmd vim9IsCommand
hi def link vim9AutocmdAllEvents vim9AutocmdEventGoodCase
hi def link vim9AutocmdEventGoodCase Type
hi def link vim9AutocmdGroup Title
hi def link vim9AutocmdMod Special
hi def link vim9AutocmdPat vim9String
hi def link vim9BacktickExpansion vim9ShellCmd
hi def link vim9Bool Boolean
hi def link vim9Bracket Delimiter
hi def link vim9BuiltinFuncName Function
hi def link vim9Comment Comment
hi def link vim9CommentString vim9String
hi def link vim9CommentTitle PreProc
hi def link vim9ComplexRepeat SpecialChar
hi def link vim9Conditional Conditional
hi def link vim9Continue Special
hi def link vim9CtrlChar SpecialChar
hi def link vim9DataType Type
hi def link vim9DataTypeCast vim9DataType
hi def link vim9Declare Identifier
hi def link vim9DeclareReserved Error
hi def link vim9DefKey Keyword
hi def link vim9DictIsLiteralKey String
hi def link vim9DictKey String
hi def link vim9DictLiteralLegacyError Error
hi def link vim9DictMayBeLiteralKey Error
hi def link vim9Doautocmd vim9IsCommand
hi def link vim9EchoHL vim9IsCommand
hi def link vim9EchoHLNone vim9Group
hi def link vim9Error Error
hi def link vim9Export vim9Import
hi def link vim9FTCmd vim9IsCommand
hi def link vim9FTOption vim9SynType
hi def link vim9FgBgAttrib vim9HiAttrib
hi def link vim9FuncScope Special
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
hi def link vim9Highlight vim9IsCommand
hi def link vim9Import Include
hi def link vim9IsAbbrevCmd vim9IsCommand
hi def link vim9IsOption PreProc
hi def link vim9IskSep Delimiter
hi def link vim9LambdaArrow Type
# NOTE: I think it's important to highlight the declaration commands differently
# than other regular Ex commands.  They are more important/special in Vim9.
hi def link vim9LineComment vim9Comment
hi def link vim9Map vim9IsCommand
hi def link vim9MapBang vim9IsCommand
hi def link vim9MapMod vim9Bracket
hi def link vim9MapModExpr vim9MapMod
hi def link vim9MapModKey vim9FuncScope
hi def link vim9MtchComment vim9Comment
hi def link vim9Norm vim9IsCommand
hi def link vim9NormCmds String
hi def link vim9NotPatSep vim9String
hi def link vim9Notation Special
hi def link vim9Null Constant
hi def link vim9Number Number
hi def link vim9Oper Operator
hi def link vim9OperAssign Identifier
hi def link vim9OperError Error
hi def link vim9OptionSigil vim9IsOption
hi def link vim9ParenSep Delimiter
hi def link vim9PatSep SpecialChar
hi def link vim9PatSepErr vim9Error
hi def link vim9PatSepR vim9PatSep
hi def link vim9PatSepZ vim9PatSep
hi def link vim9PatSepZone vim9String
hi def link vim9Pattern Type
hi def link vim9RangeMark Special
hi def link vim9RangeMissingSpace vim9Error
hi def link vim9RangeMissingSpecifier1 vim9Error
hi def link vim9RangeMissingSpecifier2 vim9Error
hi def link vim9RangeNumber Number
hi def link vim9RangeOffset Number
hi def link vim9RangePattern String
hi def link vim9RangePatternBwdDelim Delimiter
hi def link vim9RangePatternFwdDelim Delimiter
hi def link vim9RangeSpecialChar Special
hi def link vim9Repeat Repeat
hi def link vim9Return vim9IsCommand
hi def link vim9ScriptDelim Comment
hi def link vim9Sep Delimiter
hi def link vim9Set vim9IsCommand
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
hi def link vim9Subst vim9IsCommand
hi def link vim9SubstDelim Delimiter
hi def link vim9SubstFlags Special
hi def link vim9SubstSubstr SpecialChar
hi def link vim9SubstTwoBS vim9String
hi def link vim9SynCase Type
hi def link vim9SynCaseError Error
hi def link vim9SynContains vim9SynOption
hi def link vim9SynContinuePattern String
hi def link vim9SynError Error
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
hi def link vim9SyncError Error
hi def link vim9SyncGroup vim9GroupName
hi def link vim9SyncGroupName vim9GroupName
hi def link vim9SyncKey Type
hi def link vim9SyncNone Type
hi def link vim9Syntax vim9IsCommand
hi def link vim9Todo Todo
hi def link vim9TryCatch Exception
hi def link vim9TryCatchPattern String
hi def link vim9TryCatchPatternDelim Delimiter
hi def link vim9Unmap vim9Map
hi def link vim9UserAttrb vim9Special
hi def link vim9UserAttrbCmplt vim9Special
hi def link vim9UserAttrbCmpltFunc Special
hi def link vim9UserAttrbError Error
hi def link vim9UserAttrbKey vim9IsOption
hi def link vim9UserCmdDef vim9IsCommand
hi def link vim9UserCmdError Error
hi def link vim9ValidSubType vim9DataType
hi def link vim9Warn WarningMsg
#}}}1

b:current_syntax = 'vim9'
