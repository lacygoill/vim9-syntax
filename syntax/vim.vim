vim9script noclear

# Credits: Charles E. Campbell <NcampObell@SdrPchip.AorgM-NOSPAM>
# Author of syntax plugin for Vim script legacy.

if (exists('b:current_syntax')
        # bail out for a file written in legacy Vim script
        || "\n" .. getline(1, 10)->join("\n") !~ '\nvim9\%[script]\>'
        # Bail out if we're included from another filetype (e.g. `markdown`).{{{
        #
        # Rationale: If we're  included, we don't  know which type of  syntax does
        # the codeblock  use.  Legacy or  Vim9?  In  doubt, let the  legacy plugin
        # win, to respect the principle of least astonishment.
        #}}}
        || &filetype != 'vim'
        # provide  an ad-hoc  mechanism to  let the  user disable  the plugin  on a
        # per-buffer basis
        || get(b:, 'force_legacy_syntax'))
        # provide   an  ad-hoc   mechanism   to  let   the   user  force   the
        # plugin   on  a   per-buffer   basis  (useful   for  something   like
        # `syntax include @vi9Script syntax/vim.vim`)
        && !get(b:, 'force_vim9_syntax')
    finish
endif

# Requirement: Any syntax group should be prefixed with `vi9`; not `vim`.{{{
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
#}}}
# Known limitation: The plugin does not highlight legacy functions.{{{
#
# Only the `function` and `endfunction` keywords, as well as legacy comments inside.
# We could support more; we would  need to allow `vi9StartOfLine` to start from
# the `vi9LegacyFuncBody` region:
#
#     syntax region vi9LegacyFuncBody
#         \ start=/\ze\s*(/
#         \ matchgroup=vi9DefKey
#         \ end=/^\s*\<endf\%[unction]/
#         \ contained
#         \ contains=vi9LegacyComment,vi9StartOfLine
#                                     ^------------^
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
#     vi9FuncNameBuiltin
#     vi9IsOption
#     vi9MapModKey
#
# Make sure to update `HelpTopic()` in:
#
#     ~/.vim/pack/mine/opt/doc/autoload/doc/mapping.vim
#}}}

# TODO: Try to extract as many complex regexes into importable items.
# Look for the pattern `^\s*exe\%[cute]`.

# TODO: Try to remove as many `Order:` requirements as possible.
#
# If such a requirement  involves 2 rules in the same  section, that should be
# fine.  But not if it involves 2 rules in different sections; because in that
# case, you  might one day  re-order the  sections, and unknowingly  break the
# requirement.
#
# To remove such a requirement, try to improve some of your regexes.

# TODO: The following  command will give  you the list  of all groups  for which
# there is at least one item matching at the top level:
#
#     $ vim +'set filetype=vim' \
#         +'unlet! b:current_syntax' +'call setline(1, "vim9script")' \
#         +'syntax include @Foo syntax/vim.vim | syntax list @Foo'
#
# Check whether  those items  should be contained  to avoid  spurious matches.
# For  example, right  now, we  match backtick  expansions at  the top  level.
# That's wrong; this syntax is only  valid where a command expects a filename.
# In  the future,  make  sure  it's contained.   You'll  first  need to  match
# commands expecting file arguments, then those arguments.

# TODO: Some commands accept a `++option` argument.
# Highlight it properly.  Example:
#
#                    as an assignment operator
#                    v
#     edit ++encoding=cp437
#          ^--------^
#          as a Vim option?
#
# Same thing with `+cmd`.
#
#     :helpgrep ^:.*\[+cmd\]
#     :helpgrep ^:.*\[++opt\]

# TODO:
#
#     nnoremap <expr> <F3> true ? '<C-A>' : '<C-B>'
#                                  ^---^
#                                  should be highlighted as a translated keycode?

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
# Remove  any  cluster  or  syntax  group   which  is  useless.   Try  to  use
# intermediate clusters to group related syntax groups, and use them to reduce
# the verbosity of some `contains=`.

# TODO: Whenever we've  used `syntax case ignore`,  should we have  enforced a
# specific case?  Similar to what we did for the names of autocmds events.


# Imports {{{1

import 'vim9Language.vim' as lang

import 'vim9SyntaxUtil.vim' as util
const Derive: func = util.Derive
const HighlightUserTypes: func = util.HighlightUserTypes
#}}}1

# Early {{{1
# These rules need to be sourced early.
# Angle-Bracket Notation {{{2

# This could break the highlighting of an expression in a mapping between `<C-\>e` and `<CR>`.
execute 'syntax match vi9BracketNotation'
    .. ' /\c'
    # opening angle bracket
    .. '<'
    # possible modifiers; for `2-4`, see `:help <2-LeftMouse>`
    .. '\%([scmad2-4]-\)\{,3}'
    # key name
    .. '\%(' .. lang.key_name .. '\)'
    # closing angle bracket
    .. '>'
    .. '/'
    .. ' contains=vi9BracketKey'
    .. ' nextgroup=vi9SetBracketEqual'
    .. ' display'
    #     set <Up>=^[OA
    #             ^
    syntax match vi9SetBracketEqual /=[[:cntrl:]]\@=/ contained nextgroup=vi9SetBracketKeycode
    #     set <Up>=^[OA
    #              ^--^
    syntax match vi9SetBracketKeycode /\S\+/ contained

# This could break the highlighting of a command after `<Bar>` (between `<ScriptCmd>` and `<CR>`).
syntax match vi9BracketNotation /\c<Bar>/ contains=vi9BracketKey skipwhite

# This could break the highlighting of a command in a mapping (between `<ScriptCmd>` and `<CR>`).
# Especially if `<ScriptCmd>` is preceded by some key(s).
syntax match vi9BracketNotation /\c<ScriptCmd>/hs=s+1
    \ contains=vi9BracketKey
    \ nextgroup=@vi9CanBeAtStartOfLine,@vi9Range,vi9RangeIntroducer2
    \ skipwhite
    syntax match vi9RangeIntroducer2 /:/ contained nextgroup=@vi9Range,vi9RangeMissingSpecifier1

# We only highlight `<Cmd>`; not the command which comes right after.{{{
#
# That's because this command is run in the global context, thus with the legacy
# syntax.  And handling the legacy syntax adds too much complexity.
#
# Besides, the fact  that it's not highlighted gives us  some feedback: it tells
# us  that the  command  is not  run  with  the Vim9  syntax.   Just like  after
# `:legacy`, and inside a `:function`.
#}}}
syntax match vi9BracketNotation /\c<Cmd>/hs=s+1 contains=vi9BracketKey

# let's put this here for consistency
execute 'syntax match vi9ExSpecialCharacters'
    .. ' /\c'
    .. '<'
    ..     '\%('
    ..         lang.ex_special_characters
    ..     '\)'
    .. '>'
    .. '/'
    .. ' contains=vi9BracketKey'

syntax match vi9BracketKey /[<>]/ contained

# Unbalanced paren {{{2

syntax match vi9OperError /[)\]}]/
# This needs to be installed early because it could break `>` when used as a comparison operator.
# We also want to disallow a hyphen before.{{{
#
# To  prevent a  distracting highlighting  while  we're typing  a method  call
# (which is quite frequent), and we haven't typed yet the name of the function
# afterward.
#
# Besides, the highlighting would be applied inconsistently.
# That's because, if  the next non-whitespace character is a  head of word (even
# on a different line),  then `->` is parsed as a method call  (even if it's not
# the correct one).
#}}}
syntax match vi9OperError /-\@1<!>/

# Special brackets in interpolated strings and heredocs {{{2

# This must  come *before*  the rules  matching expressions  inside interpolated
# strings and heredocs.

# String Interpolated Unbalanced Bracket
syntax match vi9SIUB /[{}]/ contained
# String Interpolated Literal Bracket
syntax match vi9SILB /{{\|}}/ contained

# :++ / :-- {{{2
# Order: Must come before `vi9AutocmdMod`, to not break `++nested` and `++once`.

# increment/decrement
# The `++` and `--` operators are implemented as Ex commands:{{{
#
#     :echo getcompletion('[-+]', 'command')
#     ['++', '--']
#
# Which makes sense.  They can only appear at the start of a line.
#}}}
syntax match vi9Increment /\%(++\|--\)\%(\h\|&\)\@=/ contained

execute 'syntax match vi9IncrementError'
    .. ' /' .. lang.increment_invalid .. '/'
    .. ' contained'
#}}}1

# Range {{{1

syntax cluster vi9Range contains=
    \ vi9RangeDelimiter,
    \ vi9RangeLnumNotation,
    \ vi9RangeMark,
    \ vi9RangeMissingSpecifier2,
    \ vi9RangeNumber,
    \ vi9RangeOffset,
    \ vi9RangePattern,
    \ vi9RangeSpecialSpecifier

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
syntax match vi9RangeIntroducer /\%(^\|\s\):\S\@=/
    \ contained
    \ nextgroup=@vi9Range,vi9RangeMissingSpecifier1

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
    # misinterpreted as something else than an Ex command:
    #
    #     :!shellCmd
    #     ^
    #
    # Here, `:` asserts that `!` is an Ex command, and not the logical operator NOT.
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
    # Order: Must come after `vi9RangeIntroducer`.
    syntax match vi9DisambiguatingColon /\s\=:[a-zA-Z!]\@=/
        \ contained
        \ nextgroup=@vi9CanBeAtStartOfLine

syntax cluster vi9RangeAfterSpecifier contains=
    \ @vi9CanBeAtStartOfLine,
    \ @vi9Range,
    \ vi9RangeMissingSpace

#                     v-----v v-----v
#     command MySort :<line1>,<line2> sort
syntax match vi9RangeLnumNotation /\c<line[12]>/
    \ contained
    \ contains=vi9BracketNotation,vi9UserCmdRhsEscapeSeq
    \ nextgroup=@vi9RangeAfterSpecifier
    \ skipwhite

execute 'syntax match vi9RangeMark /' .. "'" .. lang.mark_valid .. '/'
    .. ' contained'
    .. ' nextgroup=@vi9RangeAfterSpecifier'
    .. ' skipwhite'

syntax match vi9RangeNumber /\d\+/
    \ contained
    \ nextgroup=@vi9RangeAfterSpecifier
    \ skipwhite

syntax match vi9RangeOffset /[-+]\+\d*/
    \ contained
    \ nextgroup=@vi9RangeAfterSpecifier
    \ skipwhite

syntax match vi9RangePattern +/[^/]*/+
    \ contained
    \ contains=vi9RangePatternFwdDelim
    \ nextgroup=@vi9RangeAfterSpecifier
    \ skipwhite
syntax match vi9RangePatternFwdDelim +/+ contained

syntax match vi9RangePattern +?[^?]*?+
    \ contained
    \ contains=vi9RangePatternBwdDelim
    \ nextgroup=@vi9RangeAfterSpecifier
    \ skipwhite
syntax match vi9RangePatternBwdDelim /?/ contained

syntax match vi9RangeSpecialSpecifier /[.$%*]/
    \ contained
    \ nextgroup=@vi9RangeAfterSpecifier
    \ skipwhite

syntax match vi9RangeDelimiter /[,;]/
    \ contained
    \ nextgroup=@vi9RangeAfterSpecifier

# Ex commands {{{1
# Assert where Ex commands can match {{{2

# `vi9GenericCmd` handles most Ex commands.
# But some of them are special.{{{
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
# Second, make sure it's listed in `SPECIAL_CMDS` in `./tools/GenerateImport.vim`.
# So that it's removed from `lang.command_name`, and in turn from the `vi9GenericCmd` rule.
#}}}
syntax cluster vi9IsCmd contains=
    \ @vi9ControlFlow,
    \ @vi9OOP,
    \ vi9AbbrevCmd,
    \ vi9Augroup,
    \ vi9Autocmd,
    \ vi9BangCmd,
    \ vi9Cd,
    \ vi9CmdModifier,
    \ vi9CopyMove,
    \ vi9Declare,
    \ vi9DeclareError,
    \ vi9DigraphsCmd,
    \ vi9DoCmds,
    \ vi9Doautocmd,
    \ vi9EchoHL,
    \ vi9Export,
    \ vi9Filetype,
    \ vi9GenericCmd,
    \ vi9Global,
    \ vi9Highlight,
    \ vi9Import,
    \ vi9DeprecatedLet,
    \ vi9Map,
    \ vi9MarkCmd,
    \ vi9Norm,
    \ vi9ProfileCmd,
    \ vi9Set,
    \ vi9Subst,
    \ vi9Syntax,
    \ vi9Unmap,
    \ vi9UserCmdDef,
    \ vi9UserCmdExe,
    \ vi9VimGrep,
    \ vi9Wincmd

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

# Special Case: `:!`
syntax match vi9MayBeCmd /!\@=/ contained nextgroup=@vi9Iscmd

# Special Case: Some commands (like `:g` and `:s`) *can* be followed by a non-whitespace.
syntax match vi9MayBeCmd /\%(\<\h\w*\>\)\@=/
    \ contained
    \ nextgroup=vi9Global,vi9Subst

    # General case
    # Order: Must come after the previous rule handling the special case.
    execute 'syntax match vi9MayBeCmd'
        .. ' /\%(' .. '\<\h\w*\>' .. '!\=' .. lang.command_can_be_before .. '\)\@=/'
        .. ' contained'
        .. ' nextgroup=@vi9IsCmd'

# Now, let's build a cluster containing all groups which can appear at the start of a line.
syntax cluster vi9CanBeAtStartOfLine contains=
    \ @vi9FuncCall,
    \ vi9Block,
    \ vi9Comment,
    \ vi9DeprecatedDictLiteralLegacy,
    \ vi9DeprecatedScopes,
    \ vi9DisambiguatingColon,
    \ vi9FuncEnd,
    \ vi9FuncHeader,
    \ vi9Increment,
    \ vi9IncrementError,
    \ vi9LegacyFunction,
    \ vi9MayBeCmd,
    \ vi9RangeIntroducer,
    \ vi9This

# Let's use it in all relevant contexts.   We won't list them all here; only the
# ones which  don't have a  dedicated section (i.e. start  of line, and  after a
# bar).
syntax match vi9StartOfLine /^/
    \ nextgroup=@vi9CanBeAtStartOfLine
    \ skipwhite
    # This rule  is useful to  disallow some constructs at  the start of  a line
    # where an expression is meant to be written.
    syntax match vi9SOLExpr /^/ contained skipwhite nextgroup=@vi9Expr

syntax match vi9CmdSep /|/ skipwhite nextgroup=@vi9CanBeAtStartOfLine

# Generic {{{2

execute 'syntax keyword vi9GenericCmd' .. ' ' .. lang.command_name .. ' contained'

syntax match vi9GenericCmd /\<z[-+^.=]\=\>/ contained

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
#     augroup Name
#        autocmd!
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

syntax match vi9Augroup
    \ /\<aug\%[roup]\ze!\=\s\+\h\%(\w\|-\)*/
    \ contained
    \ nextgroup=vi9AugroupNameEnd
    \ skipwhite

#          v--v
# :augroup Name
# :augroup END
#          ^^^
syntax match vi9AugroupNameEnd /\h\%(\w\|-\)*/ contained

# `:autocmd` {{{4

# :au[tocmd] [group] {event} {pat} [++once] [++nested] {cmd}
syntax match vi9Autocmd /\<au\%[tocmd]\>/
    \ contained
    \ nextgroup=
    \     vi9AutocmdAllEvents,
    \     vi9AutocmdEventBadCase,
    \     vi9AutocmdEventGoodCase,
    \     vi9AutocmdGroup,
    \     vi9AutocmdMod
    \ skipwhite

#           v
# :au[tocmd]! ...
syntax match vi9Autocmd /\<au\%[tocmd]\>!/he=e-1
    \ contained
    \ nextgroup=
    \     vi9AutocmdAllEvents,
    \     vi9AutocmdEventBadCase,
    \     vi9AutocmdEventGoodCase,
    \     vi9AutocmdGroup
    \ skipwhite

# The trailing whitespace is useful to prevent a correct but still noisy/useless
# match when we simply clear an augroup.
syntax match vi9AutocmdGroup /\S\+\s\@=/
    \ contained
    \ nextgroup=
    \     vi9AutocmdAllEvents,
    \     vi9AutocmdEventBadCase,
    \     vi9AutocmdEventGoodCase
    \ skipwhite

# Special Case: A wildcard can be used for all events.{{{
#
#     autocmd! * <buffer>
#              ^
#
# This is *not* the same syntax token as the pattern which follows an event.
#}}}
syntax match vi9AutocmdAllEvents /\*\_s\@=/
    \ contained
    \ nextgroup=vi9AutocmdPat
    \ skipwhite

# An autocmd pattern cannot start with a bar.{{{
#
#     autocmd BufWinEnter |pat echomsg '...'
#                         ^
#                         this is not the start of a pattern
#
#     if exists('#BufEnter') | doautocmd BufEnter | endif
#                                                 ^
#                                                 this is not a pattern
#}}}
syntax match vi9AutocmdPat /[^[:blank:]|]\S*/
    \ contained
    \ nextgroup=@vi9CanBeAtStartOfLine,
    \     vi9AutocmdMod,
    \     vi9BlockUserCmd,
    \     vi9ContinuationBeforeCmd
    \ skipnl
    \ skipwhite

syntax match vi9AutocmdMod /++\%(nested\|once\)/
    \ contained
    \ nextgroup=
    \     @vi9CanBeAtStartOfLine,
    \     vi9BlockUserCmd,
    \     vi9ContinuationBeforeCmd
    \ skipnl
    \ skipwhite

# Events {{{4

syntax case ignore
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('event_wrong_case', false)
    execute 'syntax keyword vi9AutocmdEventBadCase' .. ' ' .. lang.event
        .. ' contained'
        .. ' nextgroup=vi9AutocmdPat,vi9AutocmdEndOfEventList'
        .. ' skipwhite'
    syntax case match
endif
# Order: Must come after `vi9AutocmdEventBadCase`.
execute 'syntax keyword vi9AutocmdEventGoodCase' .. ' ' .. lang.event
    .. ' contained'
    .. ' nextgroup=vi9AutocmdPat,vi9AutocmdEndOfEventList'
    .. ' skipwhite'
syntax case match

syntax match vi9AutocmdEndOfEventList /,\%(\a\+,\)*\a\+/
    \ contained
    \ contains=vi9AutocmdEventBadCase,vi9AutocmdEventGoodCase
    \ nextgroup=vi9AutocmdPat
    \ skipwhite

# `:doautocmd`, `:doautoall` {{{4

# :do[autocmd] [<nomodeline>] [group] {event} [fname]
# :doautoa[ll] [<nomodeline>] [group] {event} [fname]
syntax keyword vi9Doautocmd do[autocmd] doautoa[ll]
    \ contained
    \ nextgroup=
    \     vi9AutocmdEventBadCase,
    \     vi9AutocmdEventGoodCase,
    \     vi9AutocmdGroup,
    \     vi9AutocmdMod
    \ skipwhite

syntax match vi9AutocmdMod /<nomodeline>/
    \ contained
    \ nextgroup=
    \     vi9AutocmdEventBadCase,
    \     vi9AutocmdEventGoodCase,
    \     vi9AutocmdGroup
    \ skipwhite
#}}}3
# Control Flow {{{3

syntax cluster vi9ControlFlow contains=
    \ vi9BreakContinue,
    \ vi9Conditional,
    \ vi9Finish,
    \ vi9Repeat,
    \ vi9Return,
    \ vi9TryCatch

# :return
syntax keyword vi9Return return contained nextgroup=@vi9Expr skipwhite

# :break
# :continue
syntax keyword vi9BreakContinue break continue contained
# :finish
syntax keyword vi9Finish finish contained

# :if
# :elseif
syntax keyword vi9Conditional if elseif contained nextgroup=@vi9Expr skipwhite

# :else
# :endif
syntax keyword vi9Conditional else endif contained

# :for
syntax keyword vi9Repeat for
    \ contained
    \ nextgroup=vi9RepeatForDeclareName,vi9RepeatForListUnpackDeclaration
    \ skipwhite

# :for [name, ...]
#      ^---------^
# `contains=vi9DataType` to support the return type of a funcref:{{{
#
#     for [a: string, B: func(string): bool] in []
#                                      ^--^
#}}}
syntax region vi9RepeatForListUnpackDeclaration
    \ matchgroup=vi9Sep
    \ start=/[[(]/
    \ end=/[])]/
    \ contained
    \ contains=vi9RepeatForDeclareName,vi9DataType
    \ nextgroup=vi9RepeatForIn
    \ oneline
    \ skipwhite
    \ skipnl

# :for name
#      ^--^
# In the positive lookahead, we need to allow whitespace in front of the colon.{{{
#
# Even though it's wrong.
#
#             we want this highlighted as an error
#             v
#     for name : string in []
#         ^--^
#         we want this highlighted as an iteration variable
#
# This is even more necessary when iterating over a list.
#}}}
#   And we need to match a whitespace afterward.{{{
#
# To highlight `a:`, `l:` and `s:` as errors.
#
#         this is a scope which is only valid in legacy
#         vv
#     for l:legacy_var in ...
#         ^
#         this is NOT an iteration variable
#}}}
# We also match  a possible comma or  closing bracket in case we  iterate over a
# list of lists.
syntax match vi9RepeatForDeclareName /\<\h\w*\>\%(\s*\%(:\s\|\<in\>\)\|,\|\s*[)\]]\)\@=/
    \ contained
    \ nextgroup=@vi9DataTypeCluster,vi9RepeatForIn,vi9NoWhitespaceBeforeInit
    \ skipwhite

# for name in
#          ^^
syntax keyword vi9RepeatForIn in contained

# :while
syntax keyword vi9Repeat while contained nextgroup=@vi9Expr skipwhite

# :endfor
# :endwhile
syntax keyword vi9Repeat endfor endwhile contained

# :try
# :finally
# :endtry
syntax keyword vi9TryCatch try finally endtry contained

# :throw
syntax keyword vi9TryCatch throw contained nextgroup=@vi9Expr skipwhite

# :catch
syntax keyword vi9TryCatch catch contained nextgroup=vi9TryCatchPattern skipwhite
execute 'syntax region vi9TryCatchPattern'
    .. ' matchgroup=vi9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vi9SubstList'
    .. ' contains=vi9TryCatchPatternDelim'
    .. ' oneline'

# Declaration {{{3

# Don't rewrite this rule with `:help syn-keyword`.
# The `vi9DeclareError` rule needs to be able to override `vi9Declare`.
# But it uses a match, and thus can only win against another match/region.
syntax match vi9Declare /\<\%(const\=\|final\|unl\%[et]\|var\)\>/
    \ contained
    \ nextgroup=
    \     vi9DeclareName,
    \     vi9ListUnpackDeclaration,
    \     vi9ReservedNames
    \ skipwhite
    # “Public” variables cannot be declared:{{{
    #
    #      ✘
    #     vvv
    #     var b:name = ...
    #     var g:name = ...
    #     var t:name = ...
    #     var v:name = ...
    #     var w:name = ...
    #     ^^^
    #      ✘
    #
    # Same thing for environment variables, Vim options, and Vim registers:
    #
    #      ✘
    #     vvv
    #     var $ENV = ...
    #     var &g:name = ...
    #     var &l:name = ...
    #     var &name = ...
    #     var @r = ...
    #     ^^^
    #      ✘
    #}}}
    syntax match vi9DeclareError /\<var\ze\s\+\%([bgstvw]:\h\|[$&@]\)/
        \ contained
    syntax match vi9DeclareError /\<\%(const\=\|final\)\ze\s\+[$&@]/
        \ contained
    # `:unlet` cannot delete a Vim option/register:{{{
    #
    #     unlet &shiftwidth
    #     ^---^
    #       ✘
    #
    #     unlet @r
    #     ^---^
    #       ✘
    #}}}
    syntax match vi9DeclareError /\<unlet\ze\s\+[&@]/ contained

syntax region vi9ListUnpackDeclaration
    \ contained
    \ contains=vi9DeclareName
    \ matchgroup=vi9Sep
    \ start=/\[/
    \ end=/\]/
    \ keepend
    \ oneline

syntax region vi9DeclareName
    \ contained
    \ contains=@vi9DataTypeCluster,vi9NoWhitespaceBeforeInit
    \ start=/[^[:blank:][]/
    \ end=/=\@=/
    \ oneline

#     var name : string = 'value'
#             ^
#             ✘
syntax match vi9NoWhitespaceBeforeInit /\s\+:\@=/
    \ contained
    \ nextgroup=@vi9DataTypeCluster
    # Necessary if we want a broken type specification to be still highlighted.{{{
    #
    #     for [name : string] in []
    #                 ^----^
    #                 even though it's broken by the space before the colon,
    #                 we still want this to be recognized as a type
    #}}}

# In the legacy syntax plugin, `vimLetHereDoc` contains `vimComment` and `vim9Comment`.  That's wrong.{{{
#
# It causes  any text  following a double  quote at  the start of  a line  to be
# highlighted as a Vim comment.  But that's  not a comment; that's a part of the
# heredoc; i.e. a string.
#
# Besides, we apply various styles inside comments, such as bold or italics.
# It would be unexpected and distracting to see those styles in a heredoc.
#}}}
# Don't assign `vi9Declare` instead of `vi9DeclareHereDoc` to `matchgroup`.{{{
#
# We want the syntax  item on the text at the start/end of  a heredoc to contain
# the keyword `heredoc`.  It might be useful for other plugins; for example, for
# the Vim indent plugin.
#}}}
# Similarly, don't change the name of `vi9DeclareHereDocStop`.{{{
#
# The Vim indent plugin relies on the keyword `HereDocStop` to find the end of a
# heredoc.
#}}}
syntax region vi9HereDoc
    \ matchgroup=vi9DeclareHereDoc
    \ start=/\s\@1<==<<\s\+\%(trim\s\)\=\s*\z(\L\S*\)/
    \ matchgroup=vi9DeclareHereDocStop
    \ end=/^\s*\z1$/

syntax region vi9HereDoc
    \ matchgroup=vi9DeclareHereDoc
    \ start=/\s\@1<==<<\s\+\%(.*\<eval\>\)\@=\%(\%(trim\|eval\)\s\)\{1,2}\s*\z(\L\S*\)/
    \ matchgroup=vi9DeclareHereDocStop
    \ end=/^\s*\z1$/
    \ contains=vi9HereDocExpr,vi9SILB,vi9SIUB

syntax region vi9HereDocExpr
    \ matchgroup=PreProc
    \ start=/{{\@!/
    \ end=/}/
    \ contained
    \ contains=@vi9Expr
    \ oneline

# Modifier {{{3

execute 'syntax match vi9CmdModifier'
    .. ' /\<\%(' .. lang.command_modifier .. '\)\>/'
    .. ' contained'
    .. ' nextgroup=@vi9CanBeAtStartOfLine,vi9CmdBangModifier,vi9Line12MissingColon'
    .. ' skipwhite'

# A command modifier can be followed by a bang.
# We need to match it, otherwise, we can't match the command which comes afterward.
# The negative lookbehind is necessary because of the previous `skipwhite`.
syntax match vi9CmdBangModifier /\s\@1<!!/ contained nextgroup=@vi9CanBeAtStartOfLine skipwhite

# Highlight a legacy command (run with `:legacy`) to a minimum.{{{
#
# In particular, we don't want `:let` to be wrongly highlighted as an error:
#
#     legacy let g:name = 'value'
#            ^^^
#            not an error because valid in legacy
#}}}
execute 'syntax match vi9CmdModifier'
    .. ' /\<legacy\>/'
    .. ' contained'
    .. ' nextgroup=vi9LegacyCmd'
    .. ' skipwhite'

syntax match vi9LegacyCmd /.\{-}\%(\\\@1<!|\|$\)\@=/ contained contains=@vi9LegacyCluster

# User {{{3
# Definition {{{4
# :command {{{5

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would break the highlighting of a possible following bang.
syntax match vi9UserCmdDef /\<com\%[mand]\>/
    \ contained
    \ nextgroup=@vi9UserCmdAttr
    \ skipwhite

syntax match vi9UserCmdDef /\<com\%[mand]\>!/he=e-1
    \ contained
    \ nextgroup=@vi9UserCmdAttr
    \ skipwhite

# error handling {{{5
# Order: should come before highlighting valid attributes.

syntax cluster vi9UserCmdAttr contains=
    \ vi9UserCmdAttrEqual,
    \ vi9UserCmdAttrError,
    \ vi9UserCmdAttrErrorValue,
    \ vi9UserCmdAttrName,
    \ vi9UserCmdLhs

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
syntax match vi9UserCmdAttrErrorValue /\S\+/
    \ contained
    \ nextgroup=vi9UserCmdAttrName
    \ skipwhite

# an invalid attribute name is an error
syntax match vi9UserCmdAttrError /-[^[:blank:]=]\+/
    \ contained
    \ contains=vi9UserCmdAttrName
    \ nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

# boolean attributes {{{5

syntax match vi9UserCmdAttrName /-\%(bang\|bar\|buffer\|register\)\>/
    \ contained
    \ nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

# attributes with values {{{5
# = {{{6

syntax match vi9UserCmdAttrEqual /=/ contained

# -addr {{{6

syntax match vi9UserCmdAttrName /-addr\>/
    \ contained
    \ nextgroup=vi9UserCmdAttrAddress,vi9UserCmdAttrErrorValue

execute 'syntax match vi9UserCmdAttrAddress'
    .. ' /=\%(' .. lang.command_address_type .. '\)\>/'
    .. ' contained'
    .. ' contains=vi9UserCmdAttrEqual'
    .. ' nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd'
    .. ' skipnl'
    .. ' skipwhite'

# -complete {{{6

syntax match vi9UserCmdAttrName /-complete\>/
    \ contained
    \ nextgroup=vi9UserCmdAttrComplete,vi9UserCmdAttrErrorValue

# -complete=arglist
# -complete=buffer
# -complete=...
execute 'syntax match vi9UserCmdAttrComplete'
    .. ' /'
    ..     '=\%(' .. lang.command_complete_type .. '\)'
    .. '/'
    .. ' contained'
    .. ' contains=vi9UserCmdAttrEqual'
    .. ' nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd'
    .. ' skipnl'
    .. ' skipwhite'

# -complete=custom,Func
# -complete=customlist,Func
syntax match vi9UserCmdAttrComplete /=custom\%(list\)\=,\%([gs]:\)\=\%(\w\|[#.]\)*/
    \ contained
    \ contains=vi9UserCmdAttrEqual,vi9UserCmdAttrComma
    \ nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vi9UserCmdAttrComma /,/ contained

# -count {{{6

syntax match vi9UserCmdAttrName /-count\>/
    \ contained
    \ nextgroup=
    \     @vi9UserCmdAttr,
    \     vi9UserCmdAttrCount,
    \     vi9UserCmdAttrErrorValue,
    \     vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vi9UserCmdAttrCount
    \ /=\d\+/
    \ contained
    \ contains=vi9Number,vi9UserCmdAttrEqual
    \ nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

# -nargs {{{6

syntax match vi9UserCmdAttrName /-nargs\>/
    \ contained
    \ nextgroup=vi9UserCmdAttrNargs,vi9UserCmdAttrErrorValue

syntax match vi9UserCmdAttrNargs
    \ /=[01*?+]/
    \ contained
    \ contains=vi9UserCmdAttrEqual,vi9UserCmdAttrNargsNumber
    \ nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vi9UserCmdAttrNargsNumber /[01]/ contained

# -range {{{6

# `-range` is a special case:
# it can accept a value, *or* be used as a boolean.
syntax match vi9UserCmdAttrName /-range\>/
    \ contained
    \ nextgroup=
    \     @vi9UserCmdAttr,
    \     vi9UserCmdAttrErrorValue,
    \     vi9UserCmdAttrRange,
    \     vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vi9UserCmdAttrRange /=\%(%\|-\=\d\+\)/
    \ contained
    \ contains=vi9Number,vi9UserCmdAttrEqual
    \ nextgroup=@vi9UserCmdAttr,vi9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite
#}}}5
# LHS {{{5

syntax match vi9UserCmdLhs /\u\w*/
    \ contained
    \ nextgroup=
    \     @vi9CanBeAtStartOfLine,
    \     vi9BlockUserCmd,
    \     vi9ContinuationBeforeCmd,
    \     vi9Line12MissingColon
    \ skipnl
    \ skipwhite

#     command Cmd <line1>,<line2>yank
#                 ^
#                 ✘
#
#     command Cmd :<line1>,<line2>yank
#                 ^
#                 ✔
syntax match vi9Line12MissingColon /<line[12]>/ contained

# escape sequences in RHS {{{5

# We should limit this match to the RHS of a user command.{{{
#
# But that would add too much complexity, so we don't.
# Besides, it's unlikely we would write something like `<line1>` outside the RHS
# of a user command.
#}}}
execute 'syntax match vi9UserCmdRhsEscapeSeq'
    .. ' /'
    .. '<'
    .. '\%([fq]-\)\='
    # `:help <line1>`
    .. '\%(args\|bang\|count\|line[12]\|mods\|range\|reg\)'
    .. '>'
    .. '/'
    .. ' contains=vi9BracketKey'
    # An escape sequence might be embedded inside a string:{{{
    #
    #     command -nargs=1 Locate Wrap({source: 'locate <q-args>', options: '-m'})->Run()
    #                                                   ^------^
    #}}}
    .. ' containedin=vi9String,vi9StringInterpolated'
#}}}4
# Execution {{{4

syntax match vi9UserCmdExe /\u\w*/ contained nextgroup=vi9SpaceExtraAfterFuncname,vi9UserCmdArgs
# Don't highlight the arguments of a user-defined command.{{{
#
# We don't know their semantics, so assuming anything might lead to mistakes.
# For example:
#
#             those are not dictionary delimiters
#             v       v
#     Abolish {hte,teh} the
#                 ^
#                 there is no error here;
#                 no missing whitespace after a comma between items in a dictionary
#}}}
syntax match vi9UserCmdArgs /\s*[^[:blank:]|].\{-}[|\n]/ contained

# This lets Vim highlight the name of an option and its value, when we set it with `:CompilerSet`.{{{
#
#     CompilerSet mp=pandoc
#                 ^-------^
#
# See: `:help :CompilerSet`
#}}}
# But it breaks the highlighting of `:CompilerSet`.  It should be highlighted as a *user* command!{{{
#
# No,  it  should not.   The  fact  that its  name  starts  with an  uppercase
# character does not mean it's a user command.  It's definitely not one:
#
#     :command CompilerSet
#     No user-defined commands found
#}}}
syntax keyword vi9Set CompilerSet contained nextgroup=vi9MayBeOptionSet skipwhite
#}}}3
# :cd {{{3

syntax keyword vi9Cd cd lc[d] tc[d] chd[ir] lch[dir] tch[dir] nextgroup=vi9CdPreviousDir

# For `:cd`, `-` stands for the previous working directory.
# Let's make sure it's not matched as an arithmetic operator.{{{
#
#     if getcwd() != cwd
#       cd -
#          ^
#          this should not be highlighted as an operator
#     endif
#     # --^
#     # otherwise, this would no longer be matched as a command
#}}}
syntax match vi9CdPreviousDir /!\=\s*-/ contained

# :copy / :move {{{3
# These commands need a special treatment because of the address they receive as argument.{{{
#
#     move '>+1
#           ^
#           if we highlight unbalanced brackets as error, this one should be ignored;
#           it's not an error;
#           it's a valid mark
#}}}

syntax keyword vi9CopyMove m[ove] co[py] contained nextgroup=@vi9Range skipwhite

# `:digraphs` {{{3

syntax keyword vi9DigraphsCmd dig[raphs]
    \ contained
    \ nextgroup=
    \     vi9DigraphsChars,
    \     vi9DigraphsCharsInvalid,
    \     vi9DigraphsCmdBang
    \ skipwhite

syntax match vi9DigraphsCharsInvalid /\S\+/
    \ contained
    \ nextgroup=vi9DigraphsNumber
    \ skipwhite
    syntax match vi9DigraphsCmdBang /!/ contained

# A valid `characters` argument is any sequence of 2 non-whitespace characters.
# Special Case:  a bar must  be escaped,  so that it's  not parsed as  a command
# termination.
syntax match vi9DigraphsChars /\s\@<=\%([^[:blank:]|]\|\\|\)\{2}\_s\@=/
    \ contained
    \ nextgroup=vi9DigraphsNumber
    \ skipwhite
syntax match vi9DigraphsNumber /\d\+/
    \ contained
    \ nextgroup=vi9DigraphsChars,vi9DigraphsCharsInvalid
    \ skipwhite

# `:*do` {{{3

syntax keyword vi9DoCmds argdo bufdo cdo cfdo ld[o] lfdo tabd[o] windo
    \ contained
    \ nextgroup=@vi9CanBeAtStartOfLine
    \ skipwhite

# :echohl {{{3

syntax keyword vi9EchoHL echoh[l]
    \ contained
    \ nextgroup=vi9EchoHLNone,vi9Group,vi9HLGroup
    \ skipwhite

syntax case ignore
syntax keyword vi9EchoHLNone none contained
syntax case match

# :filetype {{{3

syntax match vi9Filetype /\<filet\%[ype]\%(\s\+\I\i*\)*/
    \ contained
    \ contains=vi9FTCmd,vi9FTError,vi9FTOption
    \ skipwhite

syntax match vi9FTError /\I\i*/ contained
syntax keyword vi9FTCmd filet[ype] contained
syntax keyword vi9FTOption detect indent off on plugin contained

# :global {{{3

# without a bang
execute 'syntax match vi9Global'
    .. ' /\<g\%[lobal]\>\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vi9GlobalPat'
    .. ' skipwhite'

# with a bang
execute 'syntax match vi9Global'
    .. ' /\<g\%[lobal]\>!\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/he=e-1'
    .. ' contained'
    .. ' nextgroup=vi9GlobalPat'
    .. ' skipwhite'

# vglobal/pat/cmd
execute 'syntax match vi9Global'
    .. ' /\<v\%[global]\>\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vi9GlobalPat'
    .. ' skipwhite'

execute 'syntax region vi9GlobalPat'
    .. ' matchgroup=vi9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vi9SubstList'
    .. ' nextgroup=@vi9CanBeAtStartOfLine'
    .. ' oneline'
    .. ' skipwhite'

# :highlight {{{3
# TODO: Review all the rules related to `:highlight`.
# command {{{4

syntax cluster vi9HiCluster contains=
    \ vi9HiClear,
    \ vi9HiDefault,
    \ vi9HiGroup,
    \ vi9HiLink

syntax keyword vi9Highlight hi[ghlight]
    \ contained
    \ nextgroup=@vi9HiCluster,vi9HiBang
    \ skipwhite

syntax match vi9HiBang /!/ contained nextgroup=@vi9HiCluster skipwhite

# Group name {{{4

syntax match vi9HiGroup /\w\+/
    \ contained
    \ nextgroup=
    \     vi9HiCterm,
    \     vi9HiCtermFgBg,
    \     vi9HiGroup,
    \     vi9HiGui,
    \     vi9HiGuiFgBg,
    \     vi9HiStartStop,
    \     vi9HiTerm
    \ skipwhite

# :highlight clear {{{4

syntax keyword vi9HiClear clear contained nextgroup=vi9HiGroup skipwhite

# :highlight default/link {{{4

syntax keyword vi9HiDefault def[ault] contained nextgroup=vi9HiGroup,vi9HiLink skipwhite
syntax keyword vi9HiLink link contained nextgroup=vi9HiGroup skipwhite

# :highlight group key=arg ... {{{4

syntax match vi9HiEqual /=/
    \ contained
    \ nextgroup=
    \     vi9HiAttr,
    \     vi9HiCtermColor,
    \     vi9HiFgBgAttr,
    \     vi9HiFontname,
    \     vi9HiGroup,
    \     vi9HiGuiFontname,
    \     vi9HiGuiRgb,
    \     vi9HiNumber

syntax keyword vi9HiTerm term contained nextgroup=vi9HiEqual
syntax keyword vi9HiCterm cterm contained nextgroup=vi9HiEqual
syntax keyword vi9HiCtermFgBg ctermfg ctermbg
    \ contained
    \ nextgroup=vi9HiEqual
syntax keyword vi9HiGui gui contained nextgroup=vi9HiEqual
syntax keyword vi9HiGuiFgBg guibg guifg guisp
    \ contained
    \ nextgroup=vi9HiEqual

syntax match vi9HiStartStop /\%(start\|stop\)=/he=e-1
    \ contained
    \ nextgroup=vi9HiTermcap,vi9MayBeOptionScoped

syntax match vi9HiGuiFont /font/ contained nextgroup=vi9HiEqual

syntax match vi9HiCtermul /ctermul=/he=e-1
    \ contained
    \ nextgroup=
    \     vi9HiCtermColor,
    \     vi9HiFgBgAttr,
    \     vi9HiNumber

syntax match vi9HiTermcap /\S\+/ contained contains=vi9BracketNotation
syntax match vi9HiNumber /\d\+/ contained nextgroup=vi9HiCterm,vi9HiCtermFgBg skipwhite

# attributes {{{4

syntax case ignore
syntax keyword vi9HiAttr
    \ none bold inverse italic nocombine reverse standout strikethrough
    \ underline undercurl
    \ contained
    \ nextgroup=
    \     vi9HiAttrComma,
    \     vi9HiCterm,
    \     vi9HiCtermFgBg,
    \     vi9HiGui
    \ skipwhite
syntax match vi9HiAttrComma /,/ contained nextgroup=vi9HiAttr

syntax keyword vi9HiFgBgAttr none bg background fg foreground
    \ contained
    \ nextgroup=vi9HiCterm,vi9HiGui,vi9HiGuiFgBg,vi9HiCtermFgBg
    \ skipwhite
syntax case match

syntax case ignore
syntax keyword vi9HiCtermColor contained
    \ black blue brown cyan darkblue darkcyan darkgray darkgreen darkgrey
    \ darkmagenta darkred darkyellow gray green grey lightblue lightcyan
    \ lightgray lightgreen lightgrey lightmagenta lightred magenta red white
    \ yellow
    \ nextgroup=vi9HiCterm,vi9HiCtermFgBg
    \ skipwhite
syntax case match

syntax match vi9HiFontname /[a-zA-Z\-*]\+/ contained
syntax match vi9HiGuiFontname /'[a-zA-Z\-* ]\+'/ contained
syntax match vi9HiGuiRgb /#\x\{6}/ contained nextgroup=vi9HiGuiFgBg,vi9HiGui skipwhite
#}}}3
# :import / :export {{{3

# :import
# :export
syntax keyword vi9Import imp[ort] contained nextgroup=vi9ImportedScript,vi9ImportAutoload skipwhite
syntax keyword vi9Export exp[ort] contained nextgroup=vi9Abstract,vi9Class,vi9Declare,vi9Interface skipwhite

#        v------v
# import autoload 'path/to/script.vim'
syntax keyword vi9ImportAutoload autoload
    \ contained
    \ nextgroup=vi9ImportedScript
    \ skipwhite

#        v------------v
# import 'MyScript.vim' ...
syntax match vi9ImportedScript /\(['"]\)\f\+\1/
    \ contained
    \ nextgroup=vi9ImportAs
    \ skipwhite

#                       vv
# import 'MyScript.vim' as MyAlias
syntax keyword vi9ImportAs as contained

# :inoreabbrev {{{3

syntax keyword vi9AbbrevCmd
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ contained
    \ nextgroup=vi9MapLhs,@vi9MapMod
    \ skipwhite

# :mark {{{3

syntax keyword vi9MarkCmd ma[rk]
    \ contained
    \ nextgroup=vi9MarkCmdArg,vi9MarkCmdArgInvalid
    \ skipwhite

syntax match vi9MarkCmdArgInvalid /[^[:blank:]|]\+/ contained
# Need to allow `<` for a bracketed keycode inside a mapping (e.g. `<Bar>`).
execute 'syntax match vi9MarkCmdArg /\s\@1<=' .. lang.mark_valid .. '\%([[:blank:]\n<]\)\@=/ contained'

# :nnoremap {{{3

syntax cluster vi9MapMod contains=vi9MapMod,vi9MapModExpr

syntax match vi9Map /\<map\>!\=\ze\s*[^(]/
    \ contained
    \ nextgroup=vi9MapLhs,vi9MapMod,vi9MapModExpr
    \ skipwhite

# Do *not* include `vi9MapLhsExpr` in the `nextgroup` argument.{{{
#
# `vi9MapLhsExpr`  is  only  possible  after  `<expr>`,  which  is  matched  by
# `vi9MapModExpr` which is included in `@vi9MapMod`.
#}}}
syntax keyword vi9Map
    \ cm[ap] cno[remap] im[ap] ino[remap] lm[ap] ln[oremap] nm[ap] nn[oremap]
    \ no[remap] om[ap] ono[remap] smap snor[emap] tno[remap] tm[ap] vm[ap]
    \ vn[oremap] xm[ap] xn[oremap]
    \ contained
    \ nextgroup=vi9MapBang,vi9MapLhs,@vi9MapMod
    \ skipwhite

syntax keyword vi9Map
    \ mapc[lear] smapc[lear] cmapc[lear] imapc[lear] lmapc[lear]
    \ nmapc[lear] omapc[lear] tmapc[lear] vmapc[lear] xmapc[lear]
    \ contained

syntax keyword vi9Unmap
    \ cu[nmap] iu[nmap] lu[nmap] nun[map] ou[nmap] sunm[ap]
    \ tunma[p] unm[ap] unm[ap] vu[nmap] xu[nmap]
    \ contained
    \ nextgroup=vi9MapBang,vi9MapLhs,@vi9MapMod
    \ skipwhite

syntax match vi9MapLhs /\S\+/
    \ contained
    \ contains=vi9BracketNotation,vi9CtrlChar
    \ nextgroup=vi9MapRhs
    \ skipwhite

syntax match vi9MapLhsExpr /\S\+/
    \ contained
    \ contains=vi9BracketNotation,vi9CtrlChar
    \ nextgroup=vi9MapRhsExpr
    \ skipwhite

syntax match vi9MapBang /!/ contained nextgroup=vi9MapLhs,@vi9MapMod skipwhite

execute 'syntax match vi9MapMod'
    .. ' /'
    .. '\c'
    .. '\%(<\%('
    ..         'buffer\|\%(local\)\=leader\|nowait'
    .. '\|' .. 'plug\|script\|sid\|unique\|silent'
    .. '\)>\s*\)\+'
    .. '/'
    .. ' contained'
    .. ' contains=vi9MapModErr,vi9MapModKey'
    .. ' nextgroup=vi9MapLhs'
    .. ' skipwhite'

execute 'syntax match vi9MapModExpr'
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
    .. ' contains=vi9MapModErr,vi9MapModKey'
    .. ' nextgroup=vi9MapLhsExpr'
    .. ' skipwhite'

syntax case ignore
syntax keyword vi9MapModKey contained
    \ buffer expr leader localleader nowait plug script sid silent unique
syntax case match

syntax match vi9MapRhs /.*/
    \ contained
    \ contains=
    \     vi9BracketNotation,
    \     vi9CtrlChar,
    \     vi9MapScriptCmd,
    \     vi9MapCmdlineExpr,
    \     vi9MapInsertExpr
    \ nextgroup=vi9MapRhsExtend
    \ skipnl

syntax match vi9MapRhsExpr /.*/
    \ contained
    \ contains=@vi9Expr,vi9BracketNotation,vi9CtrlChar
    \ nextgroup=vi9MapRhsExtendExpr
    \ skipnl

# `matchgroup=vi9BracketNotation` is necessary to prevent `<CR>` from being consumed by a contained item.{{{
#
# Example:
#
#                                      v--v
#     nnoremap x <ScriptCmd>normal! abc<CR>
#     nnoremap x <ScriptCmd>doautocmd WinEnter<CR>
#                                             ^--^
#
# In the first command, `<CR>` should not be matched normal commands.
# In the second one, `<CR>` should not be matched as a file pattern in an autocmd.
#}}}
# TODO: Are there other regions where we should make sure to prevent a contained
# match in its start/end?
#
# TODO: Try to highlight bracket keys even inside strings:
#
#     nnoremap <F3> <ScriptCmd>execute 'normal! <C-\><C-N>'<CR>
#                                               ^--------^
# We don't add `oneline` because it's convenient to break a RHS on multiple lines.{{{
#
#     nnoremap <key> <ScriptCmd>Foo(
#       \ arg1,
#       \ arg2,
#       \ arg3,
#       \ )
#}}}
syntax region vi9MapScriptCmd
    \ start=/\c<ScriptCmd>/
    \ matchgroup=vi9BracketNotation
    \ end=/\c<CR>\|<Enter>\|^\s*$/
    \ contained
    \ contains=
    \     @vi9Expr,
    \     vi9BracketNotation,
    \     vi9Continuation,
    \     vi9MapCmdBar,
    \     vi9OperAssign,
    \     vi9SpecFile
    \ keepend

syntax region vi9MapInsertExpr
    \ start=/\c<C-R>=\@=/
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vi9Expr,vi9BracketNotation,vi9EvalExpr
    \ keepend
    \ oneline
syntax match vi9EvalExpr /\%(<C-R>\)\@5<==/ contained

# We don't use  `oneline` here, because it  might be convenient to  split a long
# expression on multiple lines (with explicit continuation lines).
syntax region vi9MapCmdlineExpr
    \ matchgroup=vi9BracketNotation
    \ start=/\c<C-\\>e/
    \ matchgroup=NONE
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vi9Expr,vi9BracketNotation,vi9Continuation
    \ keepend

# Highlight what comes after `<Bar>` as a command:{{{
#
#     nnoremap xxx <ScriptCmd>FuncA() <Bar> eval 1 + 2<CR>
#                                           ^--^
#
# But only if it's between `<ScriptCmd>` and `<CR>`.
# Anywhere else, we have no guarantee that we're inside an Ex command.
# Actually, we  do between `<Cmd>`  and `<CR>`, but  we don't want  to highlight
# anything  in there;  it's processed  in the  global context  where the  legacy
# syntax must be used; we're only interested in highlighting the Vim9 syntax.
#}}}
syntax match vi9MapCmdBar /\c<Bar>/
    \ contained
    \ contains=vi9BracketNotation
    \ nextgroup=@vi9CanBeAtStartOfLine
    \ skipwhite

syntax match vi9MapRhsExtend /^\s*\\.*$/
    \ contained
    \ contains=vi9Continuation,vi9BracketNotation
    \ nextgroup=vi9MapRhsExtend
    \ skipnl
syntax match vi9MapRhsExtendExpr /^\s*\\.*$/
    \ contained
    \ contains=@vi9Expr,vi9Continuation

# :normal {{{3

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would break the highlighting of a possible following bang.
syntax match vi9Norm /\<norm\%[al]\>/ nextgroup=vi9NormCmds contained skipwhite
syntax match vi9Norm /\<norm\%[al]\>!/he=e-1 nextgroup=vi9NormCmds contained skipwhite

syntax match vi9NormCmds /.*/ contained

# :profile {{{3

syntax keyword vi9ProfileCmd prof[ile]
    \ contained
    \ nextgroup=
    \    vi9ProfileCmdBang,
    \    vi9ProfileSubCmd,
    \    vi9ProfileSubCmdInvalid
    \ skipwhite

syntax match vi9ProfileSubCmdInvalid /\S\+/
    \ contained
    \ nextgroup=vi9ProfilePat
    \ skipwhite
    syntax match vi9ProfileCmdBang /!/
        \ contained
        \ nextgroup=vi9ProfileSubCmd,vi9ProfileSubCmdInvalid
        \ skipwhite


syntax keyword vi9ProfileSubcmd continue dump file func pause start stop
    \ contained
    \ nextgroup=vi9ProfilePat
    \ skipwhite

# It's important to match the pattern because it could be a wildcard.{{{
#
# And a wildcard could break the syntax of the next token:
#
#                  v
#     profile func *
#
#     broken if the previous "*" is matched as an arithmetic operator
#     vvv
#     def Func()
#        ...
#}}}
syntax match vi9ProfilePat '\S\+' contained

# :substitute {{{3

# TODO: Why did we include `vi9BracketNotation` here?
#
# Some  of its  effects are  really  nice in  a substitution  pattern (like  the
# highlighting of capturing groups).  But I  don't think all of its effects make
# sense here.   Consider replacing  it with  a similar  group whose  effects are
# limited to the ones which make sense.
#
# Also, make sure to include it in  any pattern supplied to a command (`:catch`,
# `:global`, `:vimgrep`)...
syntax cluster vi9SubstList contains=
    \ vi9BracketNotation,
    \ vi9Collection,
    \ vi9PatRegion,
    \ vi9PatSep,
    \ vi9PatSepErr,
    \ vi9SubstTwoBS

        syntax match vi9NotPatSep /\\\\/ contained
        syntax match vi9PatSep /\\|/ contained
        syntax match vi9PatSepErr /\\)/ contained
        syntax region vi9PatRegion
            \ matchgroup=vi9PatSepR
            \ start=/\\[z%]\=(/
            \ end=/\\)/
            \ contained
            \ contains=@vi9SubstList
            \ oneline
            \ transparent

syntax cluster vi9SubstRepList contains=
    \ vi9BracketNotation,
    \ vi9SubstSubstr,
    \ vi9SubstTwoBS

# Warning: Do *not* use `display` here.{{{
#
# It could break some subsequent highlighting.
#
# MRE:
#
#     # test script
#     def Foo()
#         substitute/(")"//
#     enddef
#     def Bar()
#     enddef
#
#     # command to execute:
#     syntax clear vi9Subst
#
# Notice that everything gets broken after the substitution command.
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vi9Subst` is defined with `display`
#}}}
execute 'syntax match vi9Subst'
    .. ' /\<s\%[ubstitute]\>\s*\ze\(' .. lang.pattern_delimiter .. '\).\{-}\1.\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vi9SubstPat'

execute 'syntax region vi9SubstPat'
    .. ' matchgroup=vi9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/re=e-1,me=e-1'
    .. ' contained'
    .. ' contains=@vi9SubstList'
    .. ' nextgroup=vi9SubstRep,vi9SubstRepExpr'
    .. ' oneline'

syntax region vi9SubstRep
    \ matchgroup=vi9SubstDelim
    \ start=/\z(.\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vi9BracketNotation
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vi9SubstRepList
    \ nextgroup=vi9SubstFlagErr
    \ oneline

syntax region vi9SubstRepExpr
    \ matchgroup=vi9SubstDelim
    \ start=/\z(.\)\%(\\=\)\@=/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ matchgroup=vi9BracketNotation
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vi9Expr,vi9EvalExpr
    \ nextgroup=vi9SubstFlagErr
    \ oneline
syntax match vi9EvalExpr /\\=/ contained

syntax region vi9Collection
    \ start=/\\\@1<!\[/
    \ skip=/\\\[/
    \ end=/\]/
    \ contained
    \ contains=vi9CollationClass
    \ transparent

syntax match vi9CollationClassErr /\[:.\{-\}:\]/ contained

execute 'syntax match vi9CollationClass'
    .. ' /\[:'
    .. '\%(' .. lang.collation_class .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syntax match vi9SubstSubstr /\\z\=\d/ contained
syntax match vi9SubstTwoBS /\\\\/ contained
syntax match vi9SubstFlagErr /[^<[:blank:]\r|]\+/ contained contains=vi9SubstFlags
syntax match vi9SubstFlags /[&cegiIlnpr#]\+/ contained

# :syntax {{{3
# :syntax {{{4

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
syntax match vi9Syntax /\<sy\%[ntax]\>/
    \ contained
    \ contains=vi9GenericCmd
    \ nextgroup=vi9SynType
    \ skipwhite

# Must exclude the bar for this to work:{{{
#
#     syntax clear | eval 0
#                  ^
#                  not part of a group name
#}}}
syntax match vi9GroupList /@\=[^[:blank:],|']\+/
    \ contained
    \ contains=vi9GroupSpecial,vi9PatSep

syntax match vi9GroupList /@\=[^[:blank:],|']*,/
    \ contained
    \ contains=vi9GroupSpecial,vi9PatSep
    \ nextgroup=vi9GroupList

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would fail to match `CONTAINED`.
syntax match vi9GroupSpecial /\<\%(ALL\|ALLBUT\|CONTAINED\|TOP\)\>/ contained
syntax match vi9SynError /\i\+/ contained
syntax match vi9SynError /\i\+=/ contained nextgroup=vi9GroupList

syntax match vi9SynContains /\<contain\%(s\|edin\)/ contained nextgroup=vi9SynEqual
syntax match vi9SynEqual /=/ contained nextgroup=vi9GroupList

syntax match vi9SynKeyContainedin /\<containedin/ contained nextgroup=vi9SynEqual
syntax match vi9SynNextgroup /nextgroup/ contained nextgroup=vi9SynEqual

# :syntax case {{{4

syntax keyword vi9SynType contained
    \ case skipwhite
    \ nextgroup=vi9SynCase,vi9SynCaseError

syntax match vi9SynCaseError /\i\+/ contained
syntax keyword vi9SynCase ignore match contained

# :syntax clear {{{4

# `vi9HiGroup` needs  to be in the  `nextgroup` argument, so that  `{group}` is
# highlighted in `syntax clear {group}`.
syntax keyword vi9SynType clear
    \ contained
    \ nextgroup=vi9GroupList,vi9HiGroup
    \ skipwhite

# :syntax cluster {{{4

syntax keyword vi9SynType cluster contained nextgroup=vi9ClusterName skipwhite

syntax region vi9ClusterName
    \ matchgroup=vi9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ matchgroup=vi9Sep
    \ end=/$\||/
    \ contained
    \ contains=vi9GroupAdd,vi9GroupRem,vi9SynContains,vi9SynError

syntax match vi9GroupAdd /add=/ contained nextgroup=vi9GroupList
syntax match vi9GroupRem /remove=/ contained nextgroup=vi9GroupList

# :syntax iskeyword {{{4

syntax keyword vi9SynType iskeyword contained nextgroup=vi9IskList skipwhite
syntax match vi9IskList /\S\+/ contained contains=vi9IskSep
syntax match vi9IskSep /,/ contained

# :syntax include {{{4

syntax keyword vi9SynType include contained nextgroup=vi9GroupList skipwhite

# :syntax keyword {{{4

syntax cluster vi9SynKeyGroup contains=
    \ vi9SynKeyContainedin,
    \ vi9SynKeyOpt,
    \ vi9SynNextgroup

syntax keyword vi9SynType keyword contained nextgroup=vi9SynKeyRegion skipwhite

syntax region vi9SynKeyRegion
    \ matchgroup=vi9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ matchgroup=vi9Sep
    \ end=/|\|$/
    \ contained
    \ contains=@vi9SynKeyGroup
    \ keepend
    \ oneline

syntax match vi9SynKeyOpt
    \ /\<\%(conceal\|contained\|transparent\|skipempty\|skipwhite\|skipnl\)\>/
    \ contained

# :syntax match {{{4

syntax cluster vi9SynMatchGroup contains=
    \ vi9BracketNotation,
    \ vi9MatchComment,
    \ vi9SynContains,
    \ vi9SynError,
    \ vi9SynMatchOpt,
    \ vi9SynNextgroup,
    \ vi9SynRegPat

syntax keyword vi9SynType match contained nextgroup=vi9SynMatchRegion skipwhite

# We need to avoid  consuming the bar in the end  pattern; otherwise, the latter
# would  be matched  with `vi9GroupName`,  which would  break the  syntax of  a
# possible subsequent command.
syntax region vi9SynMatchRegion
    \ matchgroup=vi9GroupName
    \ start=/\h\w*/
    \ end=/|\@=\|$/
    \ contained
    \ contains=@vi9SynMatchGroup
    \ keepend

execute 'syntax match vi9SynMatchOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syntax match vi9SynMatchOpt /\<cchar=/ contained nextgroup=vi9SynMatchCchar
syntax match vi9SynMatchCchar /\S/ contained

# :syntax [on|off] {{{4

syntax keyword vi9SynType enable list manual off on reset contained

# :syntax region {{{4

syntax cluster vi9SynRegPatGroup contains=
    \ vi9BracketNotation,
    \ vi9NotPatSep,
    \ vi9PatRegion,
    \ vi9PatSep,
    \ vi9PatSepErr,
    \ vi9SubstSubstr,
    \ vi9SynNotPatRange,
    \ vi9SynPatRange

syntax cluster vi9SynRegGroup contains=
    \ vi9SynContains,
    \ vi9SynMatchgroup,
    \ vi9SynNextgroup,
    \ vi9SynRegOpt,
    \ vi9SynRegStartSkipEnd

syntax keyword vi9SynType region contained nextgroup=vi9SynRegion skipwhite

syntax region vi9SynRegion
    \ matchgroup=vi9GroupName
    \ start=/\h\w*/
    \ skip=/\\\\\|\\|/
    \ end=/|\|$/
    \ contained
    \ contains=@vi9SynRegGroup
    \ keepend

execute 'syntax match vi9SynRegOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\%(ends\)\=\|transparent\|contained\|excludenl'
    .. '\|' .. 'skipempty\|skipwhite\|display\|keepend\|oneline\|extend\|skipnl'
    .. '\|' .. 'fold'
    .. '\)\>\_s\@='
    .. '/'
    .. ' contained'

syntax match vi9SynRegStartSkipEnd /\%(start\|skip\|end\)=\@=/
    \ contained
    \ nextgroup=vi9SynEqualRegion
syntax match vi9SynEqualRegion /=/ contained nextgroup=vi9SynRegPat

syntax match vi9SynMatchgroup /matchgroup/ contained nextgroup=vi9SynEqualMatchGroup
syntax match vi9SynEqualMatchGroup /=/ contained nextgroup=vi9Group,vi9HLGroup

syntax region vi9SynRegPat
    \ start=/\z([-`~!@#$%^&*_=+;:'",./?|]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contained
    \ contains=@vi9SynRegPatGroup
    \ extend
    \ nextgroup=vi9SynPatMod,vi9SynRegStartSkipEnd
    \ skipwhite

    # Handles inline comment after a `:help :syn-match` rule.
    # Order: must come after `vi9SynRegPat`.
    syntax match vi9MatchComment contained '#[^#]\+$'

syntax match vi9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=/
    \ contained

syntax match vi9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,/
    \ contained
    \ nextgroup=vi9SynPatMod

syntax region vi9SynPatRange start=/\[/ skip=/\\\\\|\\]/ end=/]/ contained
syntax match vi9SynNotPatRange /\\\\\|\\\[/ contained

# :syntax sync {{{4

syntax keyword vi9SynType sync
    \ contained
    \ nextgroup=
    \     vi9SyncC,
    \     vi9SyncError,
    \     vi9SyncLinebreak,
    \     vi9SyncLinecont,
    \     vi9SyncLines,
    \     vi9SyncMatch,
    \     vi9SyncRegion
    \ skipwhite

syntax match vi9SyncError /\i\+/ contained
syntax keyword vi9SyncC ccomment clear fromstart contained
syntax keyword vi9SyncMatch match contained nextgroup=vi9SyncGroupName skipwhite
syntax keyword vi9SyncRegion region contained nextgroup=vi9SynRegStartSkipEnd skipwhite

syntax match vi9SyncLinebreak /\<linebreaks=/
    \ contained
    \ nextgroup=vi9Number
    \ skipwhite

syntax keyword vi9SyncLinecont linecont contained nextgroup=vi9SynRegPat skipwhite
syntax match vi9SyncLines /\%(min\|max\)\=lines=/ contained nextgroup=vi9Number
syntax match vi9SyncGroupName /\h\w*/ contained nextgroup=vi9SyncKey skipwhite

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
syntax match vi9SyncKey /\<\%(groupthere\|grouphere\)\>/
    \ contained
    \ nextgroup=vi9SyncGroup
    \ skipwhite

syntax match vi9SyncGroup /\h\w*/
    \ contained
    \ nextgroup=vi9SynRegPat,vi9SyncNone
    \ skipwhite

syntax keyword vi9SyncNone NONE contained
#}}}3
# :vimgrep {{{3

# without a bang
execute 'syntax match vi9VimGrep'
    .. ' /\<l\=vim\%[grep]\%(add\)\=\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/'
    .. ' nextgroup=vi9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

# with a bang
execute 'syntax match vi9VimGrep'
    .. ' /\<l\=vim\%[grep]\%(add\)\=!\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/he=e-1'
    .. ' nextgroup=vi9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

execute 'syntax region vi9VimGrepPat'
    .. ' matchgroup=vi9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vi9SubstList'
    .. ' oneline'

# :wincmd {{{3

syntax keyword vi9Wincmd winc[md]
    \ contained
    \ nextgroup=vi9WincmdArg,vi9WincmdArgInvalid
    \ skipwhite

syntax match vi9WincmdArgInvalid /\S\+/ contained
execute 'syntax match vi9WincmdArg ' .. lang.wincmd_valid .. ' contained'

# :! {{{3

# We need to match a filter command to avoid breaking the highlighting of the next line.{{{
#
# Indeed, a  shell command might  end with `-`  (stdin), which our  plugin could
# conflate with an arithmetic operator; this could break the highlighting of the
# first keyword on the next line (e.g. `:enddef`).
#}}}
# We do not support `:!` without a colon.{{{
#
# First, it would be too tricky to distinguish it from the logical NOT operator.
#
# Second, it's easy to add a colon to clearly lift the ambiguity.
#
# Third, `:terminal`  is a better  command; it's  more readable, and  provides a
# regular buffer in which you can leverage all of your usual commands.
#
# ---
#
# Note that we do support `!`, if it's after a command modifier like `:silent`.
#}}}
syntax match vi9BangCmd /!/ contained nextgroup=vi9BangShellCmd
syntax match vi9BangShellCmd /.*/ contained contains=vi9BangLastShellCmd
# TODO: Support special filenames like `%:p`, `%%`, ...

# Inside a bang command, an unescaped `!` has a special meaning:{{{
#
# From `:help :!`:
#
#    > Any '!' in {cmd} is replaced with the previous
#    > external command (see also 'cpoptions').  But not when
#    > there is a backslash before the '!', then that
#    > backslash is removed.
#}}}
syntax match vi9BangLastShellCmd /\\\@1<!!/ contained display
#}}}1
# Continuation {{{1

# We don't include `vi9Continuation` in `@vi9CanBeAtStartOfLine`.
#
# It would  somehow create an  order requirement between  `vi9Continuation` and
# `vi9ContinuationBeforeCmd`.  The former would have to be installed before the
# latter.
syntax match vi9Continuation /^\s*\\/
    \ nextgroup=
    \     vi9SynContains,
    \     vi9SynContinuePattern,
    \     vi9SynMatchgroup,
    \     vi9SynNextgroup,
    \     vi9SynRegOpt,
    \     vi9SynRegStartSkipEnd
    \ skipwhite
    # TODO: Should we use a cluster? (`@vi9SynMatchGroup`?)
    # TODO: `nextgroup` should be limited to a continuation after a `:syntax` command.
    # IOW, we need an extra rule.

# When we break a too-long command on multiple lines, we want to be able to preserve the highlighting.{{{
#
# We can do so by allowing a command  to start after a backslash at the start of
# a line, but only  in some positions where it's convenient  to break a too-long
# command.
#
#     command -bar -nargs=? -range=% -complete=custom,SomeFunc
#         \ SomeCmd AnotherFunc(<line1>, <line2>, <q-args>)
#         ^
#         the next rule can be used to match this continuation line
#}}}
syntax match vi9ContinuationBeforeCmd /\\/
    \ contained
    \ nextgroup=@vi9CanBeAtStartOfLine,vi9Line12MissingColon
    \ skipwhite

# Special Case:  we also  want to  be able  to break  a user  command definition
# *before* its name (not just after, which the previous rule handles).
syntax match vi9ContinuationBeforeUserCmd /\\/
    \ contained
    \ nextgroup=vi9UserCmdLhs
    \ skipwhite

# Functions {{{1
# User Definition {{{2
# Vim9 {{{3

execute 'syntax match vi9FuncHeader'
    .. ' /'
    .. '\<def!\=\s\+'
    .. '\%('
    # Global or script-local function.
    # The possible underscore is for private methods:{{{
    #
    #    > If you want object methods to be accessible only from other methods of the
    #    > same class and not used from outside the class, then you can make them
    #    > private.  This is done by prefixing the method name with an underscore:
    #
    # Source: `:help E1366`
    #}}}
    .. '\%(g:\)\=_\=\u\w*'
    # *invalid* autoload function name{{{
    #
    # In  a Vim9  autoload script,  when  declaring an  autoload function,  we
    # cannot write `path#to#script#Func()`; `:export` must be used instead:
    #
    #     ✘
    #     def path#to#script#Func()
    #
    #     ✔
    #     export def Func()
    #
    # Let's highlight the old way as an error.
    #
    # ---
    #
    # Note that  we use  the `*` quantifier  at the end,  and not  `+`. That's
    # because in  legacy, it is  allowed for an  autoload function name  to be
    # empty:
    #
    #     def path#to#script#()
    #                       ^
    #
    # We want to catch the error no matter what.
    #}}}
    .. '\|' .. lang.legacy_autoload_invalid
    # `:help object`
    # `:help vim9class /Multiple constructors`
    .. '\|' .. 'new\w*'
    # `:help E1412`
    .. '\|' .. '\%(empty\|len\|string\)'
    .. '\)'
    .. '\ze\s*[(<]'
    .. '/'
    .. ' contains=vi9DefKey,vi9LegacyAutoloadInvalid'
    .. ' nextgroup=vi9FuncSignature,vi9GenericFunction,vi9SpaceAfterFuncHeader'
    syntax match vi9SpaceAfterFuncHeader /\s\+\ze[(<]/ contained nextgroup=vi9FuncSignature,vi9GenericFunction

syntax keyword vi9DefKey def fu[nction]
    \ contained
    \ nextgroup=vi9DefBangError,vi9DefBang
# :def! is valid
syntax match vi9DefBang /!/ contained
# but only for global functions
syntax match vi9DefBangError /!\%(\s\+g:\)\@!/ contained

execute 'syntax match vi9LegacyAutoloadInvalid'
    .. ' /'
    # When `:function` is prefixed by `:legacy`, `path#to#script#func` is valid.
    #
    #     v----v          v-----------------v
    #     legacy function path#to#script#func()
    #     endfunction
    #
    # We should not  highlight the function name as an  error then; hence this
    # negative lookbehind.
    .. '\%(\<leg\%[acy]\s\+fu\%[nction]\s\+\)\@16<!'
    .. '\<' .. lang.legacy_autoload_invalid
    .. '/'
    .. ' contained'

# Ending the  signature at `enddef`  prevents a temporary unbalanced  paren from
# causing havoc beyond the end of the function.
syntax region vi9FuncSignature
    \ matchgroup=vi9ParenSep
    \ start=/(/
    \ end=/)/
    \ matchgroup=NONE
    \ end=/^\s*enddef\ze\s*\%(#.*\)\=$/
    \ contained
    \ contains=
    \     @vi9DataTypeCluster,
    \     @vi9ErrorSpaceArgs,
    \     @vi9Expr,
    \     vi9Comment,
    \     vi9FuncArgs,
    \     vi9OperAssign
    \ skipwhite

    syntax match vi9LegacyFuncArgs /\%(:\s*\)\=\%(abort\|closure\|dict<\@!\|range\)/
        \ contained
        \ nextgroup=vi9LegacyFuncArgs
        \ skipwhite

execute 'syntax match vi9FuncArgs'
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

syntax match vi9FuncEnd /^\s*enddef\ze\s*\%(#.*\)\=$/

syntax region vi9GenericFunction
    \ matchgroup=vi9ParenSep
    \ start=/</
    \ end=/>/
    \ contained
    \ contains=@vi9ErrorSpaceArgs,vi9GenericTypes
    \ nextgroup=vi9FuncSignature
    \ skipwhite

syntax match vi9GenericTypes /\u\w*/ contained

# Legacy {{{3

execute 'syntax match vi9LegacyFunction'
    .. ' /'
    .. '\<fu\%[nction]!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(' .. '\u\%(\w\|[.]\)*' .. '\|' .. lang.legacy_autoload_invalid .. '\)'
    .. '\ze\s*('
    .. '/'
    .. ' contains=vi9DefKey,vi9LegacyAutoloadInvalid'
    .. ' nextgroup=vi9LegacyFuncBody,vi9SpaceAfterLegacyFuncHeader'
    syntax match vi9SpaceAfterLegacyFuncHeader /\s\+\ze(/ contained nextgroup=vi9LegacyFuncBody

syntax cluster vi9LegacyCluster contains=
    \ vi9LegacyComment,
    \ vi9LegacyConcatInvalid,
    \ vi9LegacyConcatValid,
    \ vi9LegacyDictMember,
    \ vi9LegacyFloat,
    #\ to support the case of a nested legacy function
    \ vi9LegacyFunction,
    \ vi9LegacyString,
    \ vi9LegacyVarArgsHeader

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
syntax region vi9LegacyFuncBody
    \ start=/(/
    \ matchgroup=vi9DefKey
    \ end=/^\s*\<endf\%[unction]\ze\s*\%(".*\)\=$/
    \ contained
    \ contains=@vi9LegacyCluster
    \ nextgroup=vi9LegacyComment
    \ skipwhite

# We've borrowed these regexes from the legacy plugin.
syntax match vi9LegacyComment /^\s*".*$/ contained
# We also need to support inline comments.{{{
#
# If only  for a trailing comment  after `:endfunction`, so we  can't anchor the
# comment to the start of the line.
#}}}
syntax match vi9LegacyComment /\s\@1<="[^\-:.%#=*].*$/ contained

# We need to match strings because they can contain arbitrary text, which can break other rules.
syntax region vi9LegacyString start=/"/ skip=/\\\\\|\\"/ end=/"/ oneline keepend
syntax region vi9LegacyString start=/'/ skip=/''/ end=/'/ oneline keepend

# In a Vim9 script, `.` cannot be used for a concatenation (nor `.=`).  Only `..` is valid.
# *Even* in a legacy function.{{{
#
# From `:help Vim9-script`:
#
#    > When using `:function` in a Vim9 script file the legacy syntax is used, with
#    > the highest |scriptversion|.
#
# From `:help scriptversion-2`:
#
#    > String concatenation with "." is not supported, use ".." instead.
#}}}
# The positive lookahead is necessary to avoid a spurious match when dot is used in a non-quoted regex.{{{
#
#     syn match Rule /aaa .* bbb/
#                         ^
#                         this is NOT a concatenation operator;
#                         this is a regex atom
#}}}
# TODO: Highlight these errors everywhere; not just in legacy functions.
syntax match vi9LegacyConcatInvalid /\.\%(\s\|\w\|['"=]\)\@=/ contained
    # A dot in the `..` concatenation operator is valid.
    syntax match vi9LegacyConcatValid /\.\./ contained
    # A dot to access a dictionary member is valid.{{{
    #
    # Note that this regex is too broad, but we can't make it better.
    # For example:
    #
    #     d.key
    #     d['a'].key
    #     {a: 0}.key
    #     Func().key
    #
    # This is correct only if what precedes `.key` evaluates to a dictionary.
    # Unfortunately, we can't know that with a  simple regex; so we accept it no
    # matter what it is.
    #}}}
    syntax match vi9LegacyDictMember /\%(\h\w*\|[)})\]]\)\zs\.\ze\h\w*/ contained
    # A dot in `...` at the end of a legacy function's header is valid.{{{
    #
    # Same thing in a legacy lambda:
    #
    #     :legacy call timer_start(0, {... -> 0})
    #                                  ^^^
    #}}}
    syntax match vi9LegacyVarArgsHeader /\.\.\.\%(\s*\%()\|->\)\)\@=/ contained
    # A dot in a float is valid.
    syntax match vi9LegacyFloat /\d\+\.\d\+/ contained
#}}}2
# User Call {{{2

syntax cluster vi9FuncCall contains=vi9FuncCallBuiltin,vi9FuncCallUser

# call to user-defined function
execute 'syntax match vi9FuncCallUser'
    .. ' /\<'
    .. '\%('
    # function with global scope
    ..     'g:\u\w*'
    .. '\|'
    # function with implicit scope: its name must start with an uppercase
    ..     '\u\w*'
    .. '\|'
    # autoload function
    # (even in a Vim9 script, we might need to call an autoload function with its legacy name)
    ..     '\%(\w\|#\)\+'
    .. '\|'
    # dict function: its name must contain a `.`
    # Why do you disallow `:`?{{{
    #
    # We don't want to highlight `dict` here:
    #
    #     b:dict.func()
    #       ^--^
    #
    # If we did, to be consistent we would need to do the same here:
    #
    #     b:dict[expr].func()
    #       ^--^
    #
    # But what about `[expr]`?
    # If we leave it alone, the middle of our function would not be highlighted.
    # So, we would need to highlight it as well.
    # But that would be:
    #
    #    - weird if `expr` is a string (e.g. `'key'`)
    #    - impossible to match since `expr` could be an arbitrarily complex expression
    #
    # In any case, the function is really `func()`, not whatever comes before.
    #}}}
    ..     ':\@1<!\w\+\.\%(\w\|\.\)\+'
    .. '\|'
    ..     'new\w*'
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
    .. '[(<]\@='
    .. '\|'
    # Special Case:{{{
    #
    #     Foo().bar()
    #           ^^^
    #
    #     b:dict.func()
    #            ^--^
    #
    # A function might  be saved in a  dictionary which is assigned  to a public
    # variable (e.g. `b:dict`), or given as the output of an arbitrarily complex
    # expression (e.g. `Foo()`).
    # The previous regex matching dict functions can't handle this, in part
    # because of the `\<` assertion.
    #}}}
    ..     '\.\w\+(\@='
    .. '/ display'
    .. ' nextgroup=vi9GenericFunctionCall'

syntax region vi9GenericFunctionCall
    \ matchgroup=vi9ParenSep
    \ start=/</
    \ end=/>/
    \ contained
    \ contains=@vi9ErrorSpaceArgs,vi9DataTypeListDict,vi9GenericFunctionCallDataType,vi9GenericTypes
    \ skipwhite

syntax match vi9GenericFunctionCallDataType
    \ /\<\%(any\|blob\|bool\|channel\|float\|func\|job\|number\|string\)\>/
    \ contained

# Builtin Call {{{2

# Don't try to merge `vi9FuncCallBuiltin` with `vi9FuncCallUser`.{{{
#
# It would be tricky to handle this case:
#
#     repeat.func()
#
# Where `repeat` comes from an imported `repeat.vim` script.
# `repeat` would probably be wrongly highlighted as a builtin function.
#}}}
syntax match vi9FuncCallBuiltin /[:.]\@1<!\%(new\)\@!\<\l\w*(\@=/ contains=vi9FuncNameBuiltin display
#                                         ^---------^
#                                         :help vim9class /new(

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
execute 'syntax keyword vi9FuncNameBuiltin'
    .. ' ' .. lang.builtin_func
    .. ' contained'

execute 'syntax match vi9FuncNameBuiltin'
    .. ' /\<\%(' .. lang.builtin_func_ambiguous .. '\)(\@=/'
    .. ' contained'

# Lambda {{{2

# This is necessary  to avoid the closing angle bracket  being highlighted as an
# error (with `vi9OperError`).
syntax match vi9LambdaName /<lambda>\d\+/
#}}}1
# Operators {{{1

# Warning: Don't include `vi9DictMayBeLiteralKey`.{{{
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
# Don't include `vi9FuncArgs` either for similar reasons.
syntax cluster vi9OperGroup contains=
    \ @vi9Expr,
    \ vi9BracketNotation,
    \ vi9Comment,
    \ vi9Continuation,
    \ vi9Oper,
    \ vi9OperAssign,
    \ vi9OperParen,
    \ vi9UserCmdRhsEscapeSeq

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
#     nextgroup=vi9Dict
#
# But it would create an inconsistent highlighting:
#
#     # no indentation
#     var name =
#     yank
#     ^--^
#     not matched by anything
#     (because it could be a variable name used in the RHS of an assignment)
#
#     # the lines are indented
#         var name =
#         yank
#         ^--^
#         matched as an Ex command
#
# By  using `vi9SOLExpr`,  we prevent  the `yank`  token to  be matched  in the
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
# Here, it's not satisfied, because of `vi9SOLExpr`.
#
# ---
#
# In practice, it would sometimes cause spurious highlights.
#
# MRE:
#
#     # test script
#     (x ==# 0)
#     def Func()
#     enddef
#
#     # command to execute:
#     syntax clear vi9Oper
#
# Notice that everything gets broken after `(x ==# 0)`.
# In practice, that could happen if:
#
#    - `Func()` is folded (hence, not displayed)
#    - `vi9Oper` is defined with `display`
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
execute 'syntax match vi9Oper'
    .. ' ' .. lang.most_operators
    .. ' nextgroup=vi9SOLExpr'
    .. ' skipnl'
    .. ' skipwhite'

#   =
#  -=
#  +=
#  *=
#  /=
#  %=
# ..=
syntax match vi9OperAssign #\s\@1<=\%([-+*/%]\|\.\.\)\==\_s\@=#
    \ nextgroup=vi9SOLExpr
    \ skipnl
    \ skipwhite

# methods
syntax match vi9Oper /->\%(\_s*\%(\h\|(\)\)\@=/ skipwhite
# logical not
execute 'syntax match vi9Oper' .. ' ' .. lang.logical_not .. ' skipwhite display'

# support `:` when used inside conditional `?:` operator
syntax match vi9Oper /\_s\@1<=:\_s\@=/
    \ nextgroup=vi9SOLExpr
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
execute 'syntax match vi9ListSliceDelimiter'
    .. ' /'
    # try to ignore a colon part of a ternary operator (used in a slice)
    .. '\%(?[^()?:]*\)\@<!'
    # the colon must be surrounded with whitespace
    .. '\s\@1<=:\s\@='
    .. '/'
    .. ' contained'
    .. ' containedin=vi9ListSlice'

# contains `@vi9ErrorSpaceArgs` to handle errors in function calls
syntax region vi9OperParen
    \ matchgroup=vi9ParenSep
    \ start=/(/
    \ end=/)/
    \ contains=
    \     @vi9ErrorSpaceArgs,
    \     @vi9OperGroup

# Data Types {{{1
# `vi9Expr` {{{2

syntax cluster vi9Expr contains=
    \ @vi9FuncCall,
    \ vi9Bool,
    \ vi9DataTypeCast,
    \ vi9Dict,
    \ vi9DeprecatedDictLiteralLegacy,
    \ vi9DeprecatedScopes,
    \ vi9Lambda,
    \ vi9LambdaArrow,
    \ vi9ListSlice,
    \ vi9MayBeOptionScoped,
    \ vi9None,
    \ vi9Null,
    \ vi9Number,
    \ vi9Oper,
    \ vi9OperParen,
    \ vi9Registers,
    \ vi9String,
    \ vi9StringInterpolated

# Booleans / null / v:none {{{2

syntax match vi9Bool /\%(v:\)\=\<\%(false\|true\)\>:\@!/ display
syntax match vi9Null /\%(v:\)\=\<null\>:\@!/ display
syntax match vi9Null /\<null_\%(blob\|channel\|dict\|function\|job\|list\|partial\|string\|tuple\)\>/ display

syntax match vi9None /\<v:none\>:\@!/ display

# Strings {{{2

syntax region vi9String
    \ start=/"/
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ contains=vi9EscapeSequence
    \ keepend
    \ oneline

# `:help string`
syntax match vi9EscapeSequence /\\\%(\o\{3}\|\o\{1,2}\O\@=\)/ contained
syntax match vi9EscapeSequence /\\[xX]\%(\x\{2}\|\x\X\@=\)/ contained
syntax match vi9EscapeSequence /\\u\x\{1,4}/ contained
syntax match vi9EscapeSequence /\\U\x\{1,8}/ contained
syntax match vi9EscapeSequence /\\[befnrt\\"]/ contained
highlight default link vi9EscapeSequence Special
# TODO: Should we match them in patterns too?
#
#     vi9GlobalPat
#     vi9RangePattern
#     vi9SubstPat
#     vi9SubstRep
#     vi9SynRegPat
#     vi9TryCatchPattern
#     vi9VimGrepPat
#
# Note that  in patterns, `\o`,  `\x`, `\X`, `\u`,  `\U` must include  a percent
# (`\%o`, `\%x`, ...). To avoid clashing with character classes.


# `:help interpolated-string`
syntax region vi9StringInterpolated
    \ start=/$"/
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ contains=vi9EscapeSequence,vi9StringInterpolatedExpression,vi9SILB,vi9SIUB
    \ keepend
    \ oneline

# `extend` is necessary in case the expression contains strings:{{{
#
#     echo $"{"foo"}" .. $'{'bar'}'
#              ^^^           ^^^
#              should be highlighted as strings
#
#     echo $"me{"\x7b"}\x7dme"
#                ^--^
#}}}
syntax region vi9StringInterpolatedExpression
    \ matchgroup=PreProc
    \ start=/{{\@!/
    \ end=/}/
    \ contained
    \ contains=@vi9Expr
    \ extend
    \ oneline

# In a  syntax file, we  often build  syntax rules with  strings concatenations,
# which we then `:execute`.  Highlight the tokens inside the strings.
if expand('%:p:h:t') == 'syntax'
    syntax region vi9String
        \ start=/'/
        \ skip=/''/
        \ end=/'/
        \ contains=@vi9SynRegGroup,vi9SynExeCmd
        \ keepend
        \ oneline
    syntax match vi9SynExeCmd /\<sy\%[ntax]\>/  contained nextgroup=vi9SynExeType skipwhite
    syntax keyword vi9SynExeType keyword match region contained nextgroup=vi9SynExeGroupName skipwhite
    syntax match vi9SynExeGroupName /[^'[:blank:]]\+/ contained
else
    # Order: Must come before `vi9Number`.
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
    syntax region vi9String
        \ start=/'/
        \ skip=/''/
        \ end=/'\d\@!/
        \ keepend
        \ oneline
    syntax region vi9StringInterpolated
        \ start=/$'/
        \ skip=/''/
        \ end=/'\d\@!/
        \ contains=vi9StringInterpolatedExpression,vi9SILB,vi9SIUB
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
syntax match vi9Registers /@[-"0-9a-z+.:%#/=]/

# Numbers {{{2

syntax match vi9Number /\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vi9Comment,vi9StrictWhitespace
    \ skipwhite
    \ display

syntax match vi9Number /-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vi9Comment,vi9StrictWhitespace
    \ skipwhite
    \ display

syntax match vi9Number /\<0[xX]\x\+\>/ nextgroup=vi9Comment,vi9StrictWhitespace skipwhite display
syntax match vi9Number /\_A\zs#\x\{6}\>/ nextgroup=vi9Comment,vi9StrictWhitespace skipwhite
syntax match vi9Number /\<0[zZ][a-fA-F0-9.]\+\>/ nextgroup=vi9Comment,vi9StrictWhitespace skipwhite display
syntax match vi9Number /\<0o[0-7]\+\>/ nextgroup=vi9Comment,vi9StrictWhitespace skipwhite display
syntax match vi9Number /\<0b[01]\+\>/ nextgroup=vi9Comment,vi9StrictWhitespace skipwhite display

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
# MRE:
#
#     # test script
#     def Foo()
#         (1'2) .. ''
#     enddef
#     def Bar()
#     enddef
#
#     # command to execute:
#     syntax clear vi9Number
#
# Notice that everything gets broken starting from the number.
#
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vi9Number` is defined with `display`
#}}}
syntax match vi9Number /\d\@1<='\d\@=/ nextgroup=vi9Comment,vi9StrictWhitespace skipwhite

# Dictionaries {{{2

# Order: Must come before `vi9Block`.
syntax region vi9Dict
    \ matchgroup=vi9Sep
    \ start=/{/
    \ end=/}/
    \ contains=@vi9OperGroup,vi9DictExprKey,vi9DictMayBeLiteralKey

# In literal dictionary, highlight unquoted key names as strings.
execute 'syntax match vi9DictMayBeLiteralKey'
    .. ' ' .. lang.maybe_dict_literal_key
    .. ' contained'
    .. ' contains=vi9DictIsLiteralKey'
    .. ' keepend'
    .. ' display'

# check the validity of the key
syntax match vi9DictIsLiteralKey /\%(\w\|-\)\+/ contained

# support expressions as keys (`[expr]`).
syntax match vi9DictExprKey /\[.\{-}]\%(:\s\)\@=/
    \ contained
    \ contains=@vi9Expr
    \ keepend

# Lambdas {{{2

# Warning: Don't add `keepend` here; it would break this:
#
#     return (F_: func(U): func(V): W) => (Y_: V) => (X_: U) => F_(X_)(Y_)
execute 'syntax region vi9Lambda'
    .. ' matchgroup=vi9ParenSep'
    .. ' start=/' .. lang.lambda_start .. '/'
    .. ' end=/' .. lang.lambda_end .. '/'
    .. ' contains=@vi9DataTypeCluster,@vi9ErrorSpaceArgs,vi9LambdaArgs'
    .. ' nextgroup=@vi9DataTypeCluster'
    .. ' oneline'

syntax match vi9LambdaArgs /\.\.\.\h[a-zA-Z0-9_]*/ contained
syntax match vi9LambdaArgs /\%(:\s\)\@2<!\<\h[a-zA-Z0-9_]*/ contained

syntax match vi9LambdaArrow /\s\@1<==>\_s\@=/
    \ nextgroup=vi9LambdaDictMissingParen,vi9Block
    \ skipwhite

# Type checking {{{2

# Order: This section must come *after* the `vi9FuncCallUser` rule.{{{
#
# Otherwise, a funcref return type in a function's header would sometimes not be
# highlighted in its entirety:
#
#     def Func(): func(): number
#                 ^-----^
#                 not highlighted
#     enddef
#}}}
syntax cluster vi9DataTypeCluster contains=
    \ vi9DataType,
    \ vi9DataTypeCast,
    \ vi9DataTypeCastComposite,
    \ vi9DataTypeCompositeLeadingColon,
    \ vi9DataTypeFuncref,
    \ vi9DataTypeListDict

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
execute 'syntax match vi9DataType'
    .. ' /'
    .. '\%(' .. '[:,]\s\+' .. '\)'
    .. '\%('
               # match simple types
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
               # match generic types
    ..         '\|\u\w*'
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
    .. ' nextgroup=vi9RepeatForIn'
    .. ' skipwhite'

# Composite data types need to be handled separately.
# First, let's deal with their leading colon.
syntax match vi9DataTypeCompositeLeadingColon /:\s\+\%(\%(list\|dict\|tuple\)<\|func(\)\@=/
    \ nextgroup=vi9DataTypeListDict,vi9DataTypeFuncref

# Now, we can deal with the rest.
# But a list/dict/funcref type can contain  itself; this is too tricky to handle
# with a  match and a  single regex.   It's much simpler  to let Vim  handle the
# possible recursion with a region which can contain itself.
syntax region vi9DataTypeListDict
    \ matchgroup=vi9ValidSubType
    \ start=/\<\%(list\|dict\|tuple\)</
    \ end=/>/
    \ contained
    \ contains=vi9DataTypeFuncref,vi9DataTypeListDict,vi9ValidSubType
    \ nextgroup=vi9RepeatForIn
    \ oneline
    \ skipwhite

syntax region vi9DataTypeFuncref
    \ matchgroup=vi9ValidSubType
    \ start=/\<func(/
    \ end=/)/
    \ contained
    \ contains=vi9DataTypeFuncref,vi9DataTypeListDict,vi9ValidSubType
    \ oneline

# validate subtypes
execute 'syntax match vi9ValidSubType'
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
    # generic type
    .. '\|\u\w*'
    .. '\)\>'
    # the lookbehinds are  necessary to avoid breaking the nesting  of the outer
    # region;  which would  prevent some  trailing `>`  or `)`  to be  correctly
    # highlighted
    .. '\|'
    .. '?\=\<\%('
    ..         'd\@1<=ict<'
    .. '\|' .. 'l\@1<=ist<'
    .. '\|' .. 't\@1<=uple<'
    .. '\|' .. 'f\@1<=unc(\|)'
    .. '\)'
    .. '\|'
    # support triple dot in `func(...list<type>)`
    .. '\.\.\.\%(\%(list\|tuple\)<\)\@='
    # support comma in `func(type1, type2)`
    .. '\|' .. ','
    .. '/'
    .. ' contained'
    .. ' display'

# support `:help type-casting` for simple types
execute 'syntax match vi9DataTypeCast'
    .. ' /<\%('
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)>'
    # TODO: Type casts *might* be used for script/function local variables too.
    # If so, you might need to remove this assertion.
    # And also allow `vi9DataTypeCastComposite` to be matched in
    # `vi9OperParen` (and other groups?), and link it to the `Type` HG.
    .. '\%([bgtw]:\)\@='
    .. '/'

# support `:help type-casting` for composite types
syntax region vi9DataTypeCastComposite
    \ matchgroup=vi9ValidSubType
    \ start=/<\%(list\|dict\|tuple\)</
    \ end=/>>/
    \ contains=vi9DataTypeFuncref,vi9DataTypeListDict,vi9ValidSubType
    \ oneline

syntax region vi9DataTypeCastComposite
    \ matchgroup=vi9ValidSubType
    \ start=/<func(/
    \ end=/)>/
    \ contains=vi9DataTypeFuncref,vi9DataTypeListDict,vi9ValidSubType
    \ oneline
#}}}1
# Options {{{1
# Assignment commands {{{2

syntax keyword vi9Set setl[ocal] setg[lobal] se[t]
    \ contained
    \ nextgroup=vi9MayBeOptionSet
    \ skipwhite

# Names {{{2

execute 'syntax match vi9MayBeOptionScoped'
    .. ' /'
    ..     lang.option_can_be_after
    ..     lang.option_sigil
    ..     lang.option_valid
    .. '/'
    .. ' contains=vi9IsOption,vi9OptionSigil'
    # `vi9SetEqual` would be wrong here; we need spaces around `=`
    .. ' nextgroup=vi9OperAssign'
    .. ' display'

# Don't use `display` here.{{{
#
# It  could mess  up the  buffer  when you  set  a terminal  option whose  value
# contains an opening square bracket.  The latter could be wrongly parsed as the
# start a list.
#}}}
execute 'syntax match vi9MayBeOptionSet'
    .. ' /'
    ..     lang.option_can_be_after
    ..     lang.option_valid
    .. '/'
    .. ' contained'
    .. ' contains=vi9IsOption'
    .. ' nextgroup=vi9SetEqual,vi9SetEqualError,vi9MayBeOptionSet,vi9SetMod'
    .. ' skipwhite'
    execute 'syntax match vi9SetEqualError'
        .. ' /'
        ..    '\s\+'
        ..    '\%('
        # White space is disallowed around the assignment operator:{{{
        #
        #                        ✘
        #                        vv
        #     setlocal foldmethod = 'expr'
        #     setlocal foldmethod=expr
        #                        ^
        #                        ✔
        #}}}
        ..        '[-+^]\=='
        ..    '\|'
        # It's also disallowed before a modifier:{{{
        #
        #                 ✘
        #                 v
        #     set hlsearch &
        #     set hlsearch !
        #                 ^
        #                 ✘
        #}}}
        ..        lang.option_modifier
        ..    '\)\@='
        .. '/'
        .. ' contained'

syntax match vi9OptionSigil /&\%([gl]:\)\=/ contained

execute 'syntax keyword vi9IsOption'
    .. ' ' .. lang.option
    .. ' contained'
    .. ' nextgroup=vi9MayBeOptionScoped,vi9SetEqual'
    .. ' skipwhite'

execute 'syntax keyword vi9IsOption'
    .. ' ' .. lang.option_terminal
    .. ' contained'
    .. ' nextgroup=vi9MayBeOptionScoped,vi9SetEqual'

execute 'syntax match vi9IsOption'
    .. ' /\V'
    .. lang.option_terminal_special
    .. '/'
    .. ' contained'
    .. ' nextgroup=vi9MayBeOptionScoped,vi9SetEqual'

# Assignment operators {{{2

syntax match vi9SetEqual /[-+^]\==/
    \ contained
    \ nextgroup=vi9SetNumberValue,vi9SetStringValue

# Values + separators (`[,:]`) {{{2

execute 'syntax match vi9SetStringValue'
    .. ' /'
    .. '\%('
               # match characters with no special meaning
    ..         '[^\\[:blank:]]'
               # match whitespace escaped with an odd number of backslashes
    .. '\|' .. '\%(\\\\\)*\\\s'
               # match backslash escaping sth else than a whitespace
    .. '\|' .. '\\\S'
    .. '\)*'
    .. '/'
    .. ' contained'
    .. ' contains=vi9SetSep'
    # necessary to support the case where a single `:set` command sets several options
    .. ' nextgroup=vi9MayBeOptionScoped,vi9MayBeOptionSet'
    .. ' oneline'
    .. ' skipwhite'

syntax match vi9SetSep /[,:]/ contained

# Order: Must come after `vi9SetStringValue`.
syntax match vi9SetNumberValue /\d\+\_s\@=/
    \ contained
    \ nextgroup=vi9MayBeOptionScoped,vi9MayBeOptionSet
    \ skipwhite

# Modifiers (e.g. `&vim`) {{{2

# Modifiers which can be appended to an option name.{{{
#
# < = set local value to global one; or remove local value (for global-local options)
# ? = show value
# ! = invert value
#}}}
execute 'syntax match vi9SetMod /' .. lang.option_modifier .. '/'
    .. ' contained'
    .. ' nextgroup=vi9MayBeOptionScoped,vi9MayBeOptionSet'
    .. ' skipwhite'
#}}}1
# Blocks {{{1

# at start of line
syntax region vi9Block
    \ matchgroup=Statement
    \ start=/^\s*{$/
    \ end=/^\s*}/
    \ contains=TOP
# `contains=TOP` is really necessary.{{{
#
# You can't get away with just:
#
#     \ contains=vi9StartOfLine
#
# That would not match things like strings, which are not contained in anything:
#
#     execute 'cmd ' .. name
#             ^----^
#}}}

# possibly after a bar
syntax region vi9Block
    \ matchgroup=Statement
    \ start=/\s*{$/
    \ end=/^\s*}/
    \ contains=TOP
    \ contained

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
# Order: must come before the next `vi9Block` rule.
syntax match vi9LambdaDictMissingParen /{/ contained

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
syntax region vi9Block
    \ matchgroup=Statement
    \ start=/\%(=>\s\+\)\@<={$/
    \ end=/^\s*}/
    \ contained
    \ contains=TOP

syntax region vi9BlockUserCmd
    \ matchgroup=Statement
    \ start=/{$/
    \ end=/^\s*}/
    \ contained
    \ contains=TOP

# Highlight commonly used Groupnames {{{1

syntax case ignore
syntax keyword vi9Group contained
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
execute 'syntax keyword vi9HLGroup contained' .. ' ' .. lang.default_highlighting_group

# Warning: Do *not* turn this `match` into  a `keyword` rule; `conceal` would be
# wrongly interpreted as an argument to `:syntax`.
syntax match vi9HLGroup /\<conceal\>/ contained
syntax case match

# Special Filenames, Modifiers, Extension Removal {{{1

syntax match vi9SpecFile /<\%([acs]file\|abuf\)>/ nextgroup=vi9SpecFileMod

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
# Make sure the file name modifiers  are accepted only after `%`, `%%`, `%%123`,
# `<cfile>`, `<sfile>`, `<afile>` and `<abuf>`.
#
# Edit: We currently match `<cfile>` (&friends) with `vi9ExSpecialCharacters`.
# Is that wrong?  Should we match them with `vi9SpecFile`?
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
syntax match vi9SpecFile /\s%:/ms=s+1,me=e-1 nextgroup=vi9SpecFileMod
# `%` can be followed by a bar, or `<Bar>`:{{{
#
#     source % | eval 0
#              ^
#}}}
syntax match vi9SpecFile /\s%\%($\|\s*[|<]\)\@=/ms=s+1 nextgroup=vi9SpecFileMod
syntax match vi9SpecFile /\s%<\%([^[:blank:]<>]*>\)\@!/ms=s+1,me=e-1 nextgroup=vi9SpecFileMod
# TODO: The negative lookahead is necessary to prevent a match in a mapping:{{{
#
#     nnoremap x <ScriptCmd>argedit %<CR>
#                                    ^
# Pretty sure it's needed in other similar rules around here.
# Make tests.
# Try to avoid code repetition; import a regex if necessary.
#}}}
syntax match vi9SpecFile /%%\d\+\|%<\%([^[:blank:]<>]*>\)\@!\|%%</ nextgroup=vi9SpecFileMod
syntax match vi9SpecFileMod /\%(:[phtreS]\)\+/ contained

# Lower Priority Comments: after some vim commands... {{{1

# Warning: Do *not* use the `display` argument here.

# We need  to assert  the presence  of whitespace before  the comment  leader to
# prevent matching some part of an autoload variable.
#     foo = script#autoload_variable
#                 ^----------------^
#                 that's not a comment
syntax match vi9Comment /\_s\@1<=#.*$/ contains=@vi9CommentGroup
syntax match vi9CommentContinuation /#\\ /hs=s+1 contained
# If you want to highlight a missing backslash in a line continuation comment, try this regex:{{{
#
#     #\%(\\ \)\@!\%(.*\n\s*\%(\\\|||\@!\|#\\ \)\)\@=
#
# Broken down:
#
#     #
#     a comment leader
#
#     \%(\\ \)\@!
#     not followed by a backslash
#
#     \%(.*\n\s*\%(\\\|||\@!\|#\\ \)\)\@=
#     but the next line is a continuation line
#
# Remember that a continuation line can start with:
#
#    - a backslash
#    - a bar (but not 2; that would be the logical operator OR)
#    - a commented backslash (followed by a space)
#
# It would  be useful to  highlight this  as an error,  but we don't  because it
# seems a little too costly for a syntax which is very rarely used.
#}}}

# Control Characters {{{1

syntax match vi9CtrlChar /[\x01-\x08\x0b\x0f-\x1f]/

# Patterns matching at start of line {{{1

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
syntax match vi9CommentTitle /#\s*\u\%(\w\|[()]\)*\%(\s\+\u\w*\)*:/hs=s+1
    \ contained
    \ contains=@vi9CommentGroup

syntax match vi9SynContinuePattern =\s\+/[^/]*/= contained

# Backtick expansion {{{1

#     `shell command`
syntax region vi9BacktickExpansion
    \ matchgroup=Special
    \ start=/`\%([^`=]\)\@=/
    \ end=/`/
    \ oneline

#     `=Vim expr`
syntax region vi9BacktickExpansionVimExpr
    \ matchgroup=Special
    \ start=/`=/
    \ end=/`/
    \ contains=@vi9Expr
    \ oneline

# fixme/todo notices in comments {{{1

syntax keyword vi9Todo FIXME NOTE TODO contained
syntax cluster vi9CommentGroup contains=
    \ @Spell,
    \ vi9CommentContinuation,
    \ vi9CommentTitle,
    \ vi9Todo

# Fenced Languages  {{{1

# NOTE: This block uses string interpolation which requires patch 8.2.4883
# Warning: Make sure not to use a variable name already used in an import.{{{
#
# For example, ATM, we already use `lang`:
#
#     import 'vi9Language.vim' as lang
#                                 ^--^
#
# So, don't write:
#
#     for lang: string in ...
#         ^--^
#          ✘
#}}}
for language: string in get(g:, 'vim9_syntax', {})->get('fenced_languages', [])
    var cmd_pat: string = {
        lua: 'lua',
        ruby: 'rub\%[y]',
        perl: 'pe\%[rl]',
        python: 'py\%[thon][3x]\=',
        tcl: 'tcl',
    }->get(language, '')

    if cmd_pat == ''
        continue
    endif

    var do_pat: string = {
        lua: 'luado\=',
        ruby: 'rubydo\=',
        perl: 'perldo\=',
        python: 'py[3x]\=do\=',
        tcl: 'tcldo\=',
    }->get(language, '')

    var code: list<string> =<< trim eval END
        unlet! b:current_syntax

        syntax include @vi9{language}Script syntax/{language}.vim

        syntax match vi9{language}Cmd /\<{cmd_pat}\>/ contained nextgroup=vi9{language}CmdRegion skipwhite
        syntax region vi9{language}CmdRegion
            \ matchgroup=vi9ScriptDelim
            \ start=/<<\s*\z(\S\+\)$/
            \ end=/^\z1$/
            \ matchgroup=vi9Error
            \ end=/^\s\+\z1$/
            \ contained
            \ contains=@vi9{language}Script
            \ keepend
        syntax region vi9{language}CmdRegion
            \ matchgroup=vi9ScriptDelim
            \ start=/<<$/
            \ end=/\.$/
            \ contained
            \ contains=@vi9{language}Script
            \ keepend

        syntax match vi9{language}Do /\<{do_pat}\>/ contained nextgroup=vi9{language}DoLine skipwhite
        syntax match vi9{language}DoLine /\S.*/ contained contains=@vi9{language}Script

        syntax cluster vi9CanBeAtStartOfLine add=vi9{language}Cmd,vi9{language}Do

        highlight default link vi9{language}Cmd vi9GenericCmd
        highlight default link vi9{language}Do vi9GenericCmd
    END

    code->join("\n")
        ->substitute('\n\s*\\', ' ', 'g')
        ->split('\n')
        ->execute()
endfor
#}}}1
# Errors {{{1
# Strict whitespace usage {{{2

#                ✘
#                v
#     var l = [1  , 2]
#     var l = ['' , '']
#     var l = [[] , []]
#     var l = [{} , {}]
#                ^
#                ✘
#
#                   ✘
#                   v
#     var d = {a: 1  , b: 2}
#     var d = {a: '' , b: ''}
#     var d = {a: [] , b: []}
#     var d = {a: {} , b: {}}
#                   ^
#                   ✘
syntax match vi9StrictWhitespace /\s\+\ze,/ contained containedin=vi9Dict,vi9ListSlice display

#     [a, b ; c] = ...
#          ^
#          ✘
#
#     [a, b;c] = ...
#          ^
#          ✘
syntax match vi9StrictWhitespace /\s\+\ze;\|;\ze\S/ contained containedin=vi9ListSlice display

#     var l = [1,2]
#               ^
#               ✘
#
#     var d = {a: 1,b: 2}
#                  ^
#                  ✘
syntax match vi9StrictWhitespace /,\ze\S/ contained containedin=vi9Dict,vi9ListSlice display

#     var d = {'a' :1, 'b' :2}
#                 ^       ^
#                 ✘       ✘
syntax match vi9StrictWhitespace /\s\+\ze:[^[:blank:]\]]/ contained containedin=vi9Dict display

#     var d = {a:1, b:2}
#               ^    ^
#               ✘    ✘
syntax match vi9StrictWhitespace /\S\@1<=:\S\@=/ contained containedin=vi9Dict display
    # `\S:\S` *might* be valid when it matches the start of a scoped variable.
    # Don't highlight its colon as an error then.
    # Why not just `\h`?{{{
    #
    # An explicit scope is not necessarily followed by an identifier:
    #
    #     var d = {key: g:}
    #                     ^
    #}}}
    syntax match vi9StrictWhitespaceScopedVar
        \ /\%(\<[bgstvw]\)\@1<=:\%(\h\|\_s\|[,;}\]]\)\@=/
        \ contained
        \ containedin=vi9Dict
        \ display

# TODO: Try to highlight missing whitespace around most binary operators as an error.
# That's going to be tricky.
# For example, a filename could be `abc+def`; and `+` is not an operator.

# TODO: Highlight these as errors:
#
#            ✘
#            v
#     &option=value
#     &option-=value
#     &option+=value
#            ^^
#            ✘

# Deprecated syntaxes {{{2

# Where can a legacy syntax be used in a Vim9 script?{{{
#
#    - inside a `:function`
#    - after `:legacy`
#    - in the RHS of a mapping (except if it uses `<expr>` or `<ScriptCmd>`)
#}}}
#   Can't the next rules sometimes highlight a valid legacy syntax as an error?{{{
#
# No, they can't.
# We install syntax rules to match the previous contexts, and we don't allow the
# next rules to nest inside.
#}}}
# `:let` is deprecated.
syntax keyword vi9DeprecatedLet let contained

# In legacy Vim script, a literal dictionary starts with `#{`.
# This syntax is no longer valid in Vim9.
syntax match vi9DeprecatedDictLiteralLegacy /#{{\@!/ containedin=vi9ListSlice display

# the scopes `a:`, `l:` and `s:` are no longer valid
# Don't use `contained` to limit these rules to `@vi9Expr`.{{{
#
# Because then, they would fail to match this:
#
#     let a:name = ...
#         ^^
#}}}
syntax match vi9DeprecatedScopes /\<[as]:\w\@=/ display
syntax match vi9DeprecatedScopes /&\@1<!\<l:\h\@=/ display

# The `is#` operator worked in legacy, but didn't make sense.
# It's no longer supported in Vim9.
syntax match vi9DeprecatedIsOperator /\C\<\%(is\|isnot\)[#?]/ contained containedin=vi9Oper display

syntax match vi9LegacyDotEqual /\s\.\%(=\s\)\@=/hs=s+1 display

syntax match vi9LegacyVarArgs /a:000/ display

# TODO: Handle other legacy constructs like:
#
#    - `...)` in a function's header
#    - eval string
#    - lambda (tricky)
#    - single dot for concatenation (tricky)

# TODO: Highlight legacy comment leaders as an error.  Optional.

# TODO: Highlight missing types in function header as errors:
#
#     def Func(foo, bar)
#
# Exceptions: `_` and `..._`.

# TODO: Highlight `:call` as useless.
#
# ---
#
# Same thing for `v:` in `v:true`, `v:false`, `v:null`.
#
# ---
#
# Same thing for `#` in `==#`, `!=#`, `=~#`, `!~#`.

# TODO: Highlight this as an error:
#
#     def Func(...name: job)

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
 ->get('strict_whitespace', true)

    #         ✘
    #         v
    #     Func (arg)
    syntax region vi9SpaceExtraAfterFuncname
        \ matchgroup=vi9Error
        \ start=/\s\+(/
        \ matchgroup=vi9ParenSep
        \ end=/)/
        \ contains=@vi9OperGroup
        \ contained
        \ display

    #           ✘
    #           v
    #     Func(1,2)
    #     Func(1, 2)
    #            ^
    #            ✔
    syntax match vi9SpaceMissingBetweenArgs /,\S\@=/ contained display

    #           ✘
    #           v
    #     Func(1 , 2)
    #     Func(1, 2)
    #           ^
    #           ✔
    syntax match vi9SpaceExtraBetweenArgs /\s\@1<=,/ contained display

    syntax cluster vi9ErrorSpaceArgs contains=
        \ vi9SpaceExtraBetweenArgs,
        \ vi9SpaceMissingBetweenArgs

    #                   need a space before
    #                   v
    #     var name = 123# Error!
    # We need to match a whitespace to avoid reporting spurious errors:{{{
    #
    #     start=/[^[:blank:]]\@1<=#\s/
    #                              ^^
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
    syntax region vi9Comment
        \ matchgroup=vi9Error
        \ start=/[^[:blank:]@]\@1<=#\s\@=/
        \ end=/$/
        \ contains=@vi9CommentGroup
        \ excludenl
        \ oneline
        \ display

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
    syntax region vi9ListSlice
        \ matchgroup=vi9Sep
        \ start=/\[/
        \ end=/\]/
        \ contains=
        \     @vi9OperGroup,
        \     vi9ColonForVariableScope,
        \     vi9ListSlice,
        \     vi9ListSliceDelimiter,
        \     vi9SpaceMissingListSlice
    # If a colon is not prefixed with a space, it's an error.
    syntax match vi9SpaceMissingListSlice /[^[:blank:][]\@1<=:/ contained display
    # If a colon is not followed with a space, it's an error.
    syntax match vi9SpaceMissingListSlice /:[^[:blank:]\]]\@=/ contained display
    # Corner Case: A colon can be used in a variable name.  Ignore it.{{{
    #
    #     b:name
    #      ^
    #      ✔
    #}}}
    # Order: Out of these 3 rules, this one must come last.
    execute 'syntax match vi9ColonForVariableScope'
        .. ' /'
        .. '\<[bgtvw]:'
        .. '\%('
        ..    '\w'
        .. '\|'
               # `b:` is a dictionary expression, thus might be followed by `->`
        ..     '->'
        .. '\)\@='
        .. '/'
        .. ' contained'
        .. ' display'
endif

# Octal numbers {{{2

# Warn about missing `o` in `0o` prefix in octal number.{{{
#
#    > Numbers starting with zero are not considered to be octal, only numbers
#    > starting with "0o" are octal: "0o744". |scriptversion-4|
#
#          ✘
#          v
#     echo 0765
#     echo 0o765
#          ^^
#          ✔
#}}}
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('octal_missing_o_prefix', false)

    # The  negative lookbehind  is necessary  to  ignore big  numbers which  are{{{
    # written with quotes to be more readable:
    #
    #     1'076
    #       ^^^
    #
    # Here, `076` is not a badly written octal number.
    # There is no reason to stop the highlighting at `0`.
    #
    # ---
    #
    # Also, it's necessary to ignore a number used as a key in a dictionary:
    #
    #     d.0123
    #       ^--^
    #       this is not an octal number;
    #       this is a key to retrieve some value from a dictionary
    #}}}
    syntax match vi9NumberOctalWarn /\%(\d'\|\.\)\@2<!\<0[0-7]\+\>/he=s+1
        \ nextgroup=vi9Comment
        \ skipwhite
        \ display
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

    syntax match vi9RangeMissingSpace /\S\@1<=\a/ contained display
endif

# Discourage usage  of an  implicit line  specifier, because  it makes  the code
# harder to read.
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('range_missing_specifier', false)
    syntax match vi9RangeMissingSpecifier1 /[,;]/
        \ contained
        \ nextgroup=@vi9Range

    syntax match vi9RangeMissingSpecifier2 /[,;][a-zA-Z[:blank:]]\@=/
        \ contained
        \ nextgroup=@vi9CanBeAtStartOfLine
        \ skipwhite
endif

# Reserved names {{{2

# Some names cannot be used for variables, because they're reserved:{{{
#
#     var true = 0
#     var null = ''
#     var this = []
#     ...
#}}}
syntax keyword vi9ReservedNames true false null this super contained
#}}}1
# Synchronize (speed) {{{1

# Need to define a pattern to sync on.{{{
#
# It doesn't need to match anything meaningful.
# It just needs to exist so that Vim searches back for something.
# This is useful – for example – when a heredoc is displayed from the middle
# (i.e. its first text line is above the first screen line).
#}}}
syntax sync match vi9Sync grouphere NONE /^dummy pattern$/
# Don't look more than 60 lines back when looking for a pattern to sync on.
syntax sync maxlines=60
#}}}1
# OOP {{{1

# Let's keep this section at the very end so that `HighlightUserTypes()` works properly.
# The latter calls `synstack()` which needs the syntax to have been fully set.

syntax cluster vi9OOP contains=
    \ vi9Abstract,
    \ vi9Class,
    \ vi9Enum,
    \ vi9Interface,
    \ vi9Public,
    \ vi9Static,
    \ vi9This,
    \ vi9UserType

# :class
# :endclass
syntax keyword vi9Class class endclass contained nextgroup=vi9ClassName skipwhite
highlight default link vi9Class Keyword

#           vvv
#     class Foo
#     endclass
syntax match vi9ClassName /\u\w*/ contained nextgroup=vi9Extends,vi9Implements,vi9Specifies skipwhite
#                          v------v           vvv
#     class Foo implements Bar, Baz specifies Qux
syntax match vi9InterfaceName /\u\w*\%(,\s\+\u\w*\)\=/
    \ contained
    \ nextgroup=vi9Extends,vi9Implements,vi9Specifies,vi9StrictWhitespace
    \ skipwhite

syntax keyword vi9Extends extends contained nextgroup=vi9ClassName skipwhite
syntax keyword vi9Implements implements contained nextgroup=vi9InterfaceName skipwhite
syntax keyword vi9Specifies specifies contained nextgroup=vi9InterfaceName skipwhite
highlight default link vi9Extends Keyword
highlight default link vi9Implements Keyword
highlight default link vi9Specifies Keyword

# :interface
# :endinterface
syntax keyword vi9Interface interface endinterface contained nextgroup=vi9InterfaceName skipwhite
highlight default link vi9Interface Keyword

# this
syntax match vi9This /\<this\>/ containedin=vi9FuncSignature,vi9OperParen
highlight default link vi9This Structure

# public
# static
# public static
syntax keyword vi9Public public contained nextgroup=vi9Static,vi9Declare skipwhite
syntax keyword vi9Static static contained nextgroup=vi9Declare skipwhite
highlight default link vi9Public vi9Declare
highlight default link vi9Static vi9Declare

# abstract
syntax keyword vi9Abstract abstract contained nextgroup=vi9Class skipwhite
highlight default link vi9Abstract Special

# :enum
# :endenum
syntax region vi9Enum
    \ matchgroup=Type
    \ start=/\<enum\>\s\+\u\w*/
    \ end=/^\s*\<endenum\>/
    \ contains=
    \ vi9DataType,
    \ vi9Declare,
    \ vi9FuncCallUser,
    \ vi9FuncEnd,
    \ vi9FuncHeader,
    \ vi9Implements,
    \ vi9OperParen,
    \ vi9Return,
    \ vi9This

# :type
syntax keyword vi9UserType type contained nextgroup=vi9UserTypeName skipwhite
syntax match vi9UserTypeName /\u\w*/ contained nextgroup=@vi9DataTypeCluster skipwhite
highlight default link vi9UserType Type

if get(g:, 'vim9_syntax', {})
 ->get('user_types', false)
    HighlightUserTypes()
    autocmd_add([{
        cmd: 'HighlightUserTypes()',
        event: 'BufWritePost',
        group: 'vi9HighlightUserTypes',
        pattern: '<buffer>',
        replace: true,
    }])
endif
# }}}1

# Highlight Groups {{{1
# All highlight groups need to be defined with the `default` argument.{{{
#
# So that they survive after we change/reload the colorscheme.
# Indeed,  a  colorscheme  always  executes  `:highlight  clear`  to  reset  all
# highlighting to the defaults.  By default,  the user-defined HGs do not exist,
# so for the latter, “reset all highlighting” means:
#
#    - removing all their attributes
#
#         $ vim --cmd 'highlight WillItSurvive ctermbg=green | highlight clear | highlight WillItSurvive | quit'
#         WillItSurvive  xxx cleared
#
#    - removing the links
#
#         $ vim --cmd 'highlight link WillItSurvive ErrorMsg | highlight clear | highlight WillItSurvive | quit'
#         WillItSurvive  xxx cleared
#}}}

highlight default link vi9GenericCmd Statement
# Make Vim highlight user commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we  want them  to be  bold, so  that we  can't conflate  a user
# command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     highlight default link vi9UserCmdExe vi9GenericCmd
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that when the syntax item  for `vi9UserCmdExe` was defined earlier (with
# a `:syntax` command), Vim has automatically created a highlight group with the
# same name; but it's cleared:
#
#     vi9UserCmdExe      xxx cleared
#
# That's why we need the `->get('cleared')`.
#}}}
if hlget('vi9UserCmdExe')->get(0, {})->get('cleared')
    Derive('vi9FuncCallUser', 'Function', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
    Derive('vi9UserCmdExe', 'vi9GenericCmd', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
    Derive('vi9FuncHeader', 'Function', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
    Derive('vi9CmdModifier', 'vi9GenericCmd', {gui: {italic: true}, term: {italic: true}, cterm: {italic: true}})
endif

highlight default link vi9Error Error

highlight default link vi9AutocmdEventBadCase vi9Error
highlight default link vi9CollationClassErr vi9Error
highlight default link vi9DeclareError vi9Error
highlight default link vi9DefBangError vi9Error
highlight default link vi9DeprecatedDictLiteralLegacy vi9Error
highlight default link vi9DeprecatedIsOperator vi9Error
highlight default link vi9DeprecatedLet vi9Error
highlight default link vi9DeprecatedScopes vi9Error
highlight default link vi9DictMayBeLiteralKey vi9Error
highlight default link vi9DigraphsCharsInvalid vi9Error
highlight default link vi9FTError vi9Error
highlight default link vi9IncrementError vi9Error
highlight default link vi9LambdaDictMissingParen vi9Error
highlight default link vi9LegacyAutoloadInvalid vi9Error
highlight default link vi9LegacyConcatInvalid vi9Error
highlight default link vi9LegacyDotEqual vi9Error
highlight default link vi9LegacyFuncArgs vi9Error
highlight default link vi9LegacyVarArgs vi9Error
highlight default link vi9MapModErr vi9Error
highlight default link vi9MarkCmdArgInvalid vi9Error
highlight default link vi9NoWhitespaceBeforeInit vi9Error
highlight default link vi9NumberOctalWarn vi9Error
highlight default link vi9OperError vi9Error
highlight default link vi9PatSepErr vi9Error
highlight default link vi9ProfileSubCmdInvalid vi9Error
highlight default link vi9RangeMissingSpace vi9Error
highlight default link vi9RangeMissingSpecifier1 vi9Error
highlight default link vi9RangeMissingSpecifier2 vi9Error
highlight default link vi9ReservedNames vi9Error
highlight default link vi9SIUB vi9Error
highlight default link vi9SetEqualError vi9Error
highlight default link vi9SpaceAfterFuncHeader vi9Error
highlight default link vi9SpaceAfterLegacyFuncHeader vi9Error
highlight default link vi9SpaceExtraBetweenArgs vi9Error
highlight default link vi9SpaceMissingBetweenArgs vi9Error
highlight default link vi9SpaceMissingListSlice vi9Error
highlight default link vi9StrictWhitespace vi9Error
highlight default link vi9SubstFlagErr vi9Error
highlight default link vi9SynCaseError vi9Error
highlight default link vi9SynCaseError vi9Error
highlight default link vi9SynError vi9Error
highlight default link vi9SyncError vi9Error
highlight default link vi9UserCmdAttrError vi9Error
highlight default link vi9WincmdArgInvalid vi9Error

highlight default link vi9AbbrevCmd vi9GenericCmd
highlight default link vi9Augroup vi9GenericCmd
highlight default link vi9AugroupNameEnd Title
highlight default link vi9Autocmd vi9GenericCmd
highlight default link vi9AutocmdAllEvents vi9AutocmdEventGoodCase
highlight default link vi9AutocmdEventGoodCase Type
highlight default link vi9AutocmdGroup vi9AugroupNameEnd
highlight default link vi9AutocmdMod Special
highlight default link vi9AutocmdPat vi9String
highlight default link vi9BacktickExpansion vi9ShellCmd
highlight default link vi9BangCmd vi9GenericCmd
highlight default link vi9BangLastShellCmd Special
highlight default link vi9BangShellCmd vi9ShellCmd
highlight default link vi9Bool Boolean
highlight default link vi9BracketKey Delimiter
highlight default link vi9BracketNotation Special
highlight default link vi9BreakContinue vi9Repeat
highlight default link vi9Cd vi9GenericCmd
highlight default link vi9Comment Comment
highlight default link vi9CommentContinuation vi9Continuation
highlight default link vi9CommentTitle PreProc
highlight default link vi9Conditional Conditional
highlight default link vi9Continuation Special
highlight default link vi9ContinuationBeforeCmd vi9Continuation
highlight default link vi9ContinuationBeforeUserCmd vi9Continuation
highlight default link vi9CopyMove vi9GenericCmd
highlight default link vi9CtrlChar SpecialChar
highlight default link vi9Declare Identifier
highlight default link vi9DeclareHereDoc vi9Declare
highlight default link vi9DeclareHereDocStop vi9Declare
highlight default link vi9DefKey Keyword
highlight default link vi9DictIsLiteralKey String
highlight default link vi9DigraphsChars vi9String
highlight default link vi9DigraphsCmd vi9GenericCmd
highlight default link vi9DigraphsNumber vi9Number
highlight default link vi9DoCmds vi9Repeat
highlight default link vi9Doautocmd vi9GenericCmd
highlight default link vi9EchoHL vi9GenericCmd
highlight default link vi9EchoHLNone vi9Group
highlight default link vi9EvalExpr vi9OperAssign
highlight default link vi9ExSpecialCharacters vi9BracketNotation
highlight default link vi9Export vi9Import
highlight default link vi9FTCmd vi9GenericCmd
highlight default link vi9FTOption vi9SynType
highlight default link vi9Finish vi9Return
highlight default link vi9FuncArgs Identifier
highlight default link vi9FuncEnd vi9DefKey
highlight default link vi9GenericFunctionCallDataType Type
highlight default link vi9GenericTypes Type
highlight default link vi9Global vi9GenericCmd
highlight default link vi9GlobalPat vi9String
highlight default link vi9Group Type
highlight default link vi9GroupAdd vi9SynOption
highlight default link vi9GroupName vi9Group
highlight default link vi9GroupRem vi9SynOption
highlight default link vi9GroupSpecial Special
highlight default link vi9HLGroup vi9Group
highlight default link vi9HereDoc vi9String
highlight default link vi9HiAttr PreProc
highlight default link vi9HiCterm vi9HiTerm
highlight default link vi9HiCtermFgBg vi9HiTerm
highlight default link vi9HiCtermul vi9HiTerm
highlight default link vi9HiEqual vi9OperAssign
highlight default link vi9HiFgBgAttr vi9HiAttr
highlight default link vi9HiGroup vi9GroupName
highlight default link vi9HiGui vi9HiTerm
highlight default link vi9HiGuiFgBg vi9HiTerm
highlight default link vi9HiGuiFont vi9HiTerm
highlight default link vi9HiGuiRgb vi9Number
highlight default link vi9HiNumber Number
highlight default link vi9HiStartStop vi9HiTerm
highlight default link vi9HiTerm Type
highlight default link vi9Highlight vi9GenericCmd
highlight default link vi9Import Include
highlight default link vi9ImportAs vi9Import
highlight default link vi9ImportedScript vi9String
highlight default link vi9Increment vi9Oper
highlight default link vi9IsOption PreProc
highlight default link vi9IskSep Delimiter
highlight default link vi9LambdaArgs vi9FuncArgs
highlight default link vi9LambdaArrow vi9Sep
highlight default link vi9LegacyComment vi9Comment
highlight default link vi9LegacyString vi9String
highlight default link vi9Line12MissingColon vi9Error
highlight default link vi9Map vi9GenericCmd
highlight default link vi9MapMod vi9BracketKey
highlight default link vi9MapModExpr vi9MapMod
highlight default link vi9MapModKey Special
highlight default link vi9MarkCmd vi9GenericCmd
highlight default link vi9MarkCmdArg Special
highlight default link vi9MatchComment vi9Comment
highlight default link vi9None Constant
highlight default link vi9Norm vi9GenericCmd
highlight default link vi9NormCmds String
highlight default link vi9NotPatSep vi9String
highlight default link vi9Null Constant
highlight default link vi9Number Number
highlight default link vi9Oper Operator
highlight default link vi9OperAssign Identifier
highlight default link vi9OptionSigil vi9IsOption
highlight default link vi9ParenSep Delimiter
highlight default link vi9PatSep SpecialChar
highlight default link vi9PatSepR vi9PatSep
highlight default link vi9PatSepZ vi9PatSep
highlight default link vi9ProfileCmd vi9GenericCmd
highlight default link vi9ProfilePat vi9String
highlight default link vi9RangeMark Special
highlight default link vi9RangeNumber Number
highlight default link vi9RangeOffset Number
highlight default link vi9RangePattern String
highlight default link vi9RangePatternBwdDelim Delimiter
highlight default link vi9RangePatternFwdDelim Delimiter
highlight default link vi9RangeSpecialSpecifier Special
highlight default link vi9Repeat Repeat
highlight default link vi9RepeatForDeclareName vi9Declare
highlight default link vi9RepeatForIn vi9Repeat
highlight default link vi9Return vi9DefKey
highlight default link vi9SILB vi9String
highlight default link vi9ScriptDelim vi9DeclareHereDoc
highlight default link vi9Sep Delimiter
highlight default link vi9Set vi9GenericCmd
highlight default link vi9SetBracketEqual vi9OperAssign
highlight default link vi9SetBracketKeycode vi9String
highlight default link vi9SetEqual vi9OperAssign
highlight default link vi9SetMod vi9IsOption
highlight default link vi9SetNumberValue Number
highlight default link vi9SetSep Delimiter
highlight default link vi9SetStringValue String
highlight default link vi9ShellCmd PreProc
highlight default link vi9SpecFile Identifier
highlight default link vi9SpecFileMod vi9SpecFile
highlight default link vi9String String
highlight default link vi9StringInterpolated vi9String
highlight default link vi9Subst vi9GenericCmd
highlight default link vi9SubstDelim Delimiter
highlight default link vi9SubstFlags Special
highlight default link vi9SubstPat vi9String
highlight default link vi9SubstRep vi9String
highlight default link vi9SubstSubstr SpecialChar
highlight default link vi9SubstTwoBS vi9String
highlight default link vi9SynCase Type
highlight default link vi9SynContains vi9SynOption
highlight default link vi9SynContinuePattern String
highlight default link vi9SynEqual vi9OperAssign
highlight default link vi9SynEqualMatchGroup vi9OperAssign
highlight default link vi9SynEqualRegion vi9OperAssign
highlight default link vi9SynExeCmd vi9GenericCmd
highlight default link vi9SynExeGroupName vi9GroupName
highlight default link vi9SynExeType vi9SynType
highlight default link vi9SynKeyContainedin vi9SynContains
highlight default link vi9SynKeyOpt vi9SynOption
highlight default link vi9SynMatchOpt vi9SynOption
highlight default link vi9SynMatchgroup vi9SynOption
highlight default link vi9SynNextgroup vi9SynOption
highlight default link vi9SynNotPatRange vi9SynRegPat
highlight default link vi9SynOption Special
highlight default link vi9SynPatRange vi9String
highlight default link vi9SynRegOpt vi9SynOption
highlight default link vi9SynRegPat vi9String
highlight default link vi9SynRegStartSkipEnd Type
highlight default link vi9SynType Type
highlight default link vi9SyncC Type
highlight default link vi9SyncGroup vi9GroupName
highlight default link vi9SyncGroupName vi9GroupName
highlight default link vi9SyncKey Type
highlight default link vi9SyncNone Type
highlight default link vi9Syntax vi9GenericCmd
highlight default link vi9Todo Todo
highlight default link vi9TryCatch Exception
highlight default link vi9TryCatchPattern String
highlight default link vi9TryCatchPatternDelim Delimiter
highlight default link vi9Unmap vi9Map
highlight default link vi9UserCmdAttrAddress vi9String
highlight default link vi9UserCmdAttrAddress vi9String
highlight default link vi9UserCmdAttrComma vi9Sep
highlight default link vi9UserCmdAttrComplete vi9String
highlight default link vi9UserCmdAttrEqual vi9OperAssign
highlight default link vi9UserCmdAttrErrorValue vi9Error
highlight default link vi9UserCmdAttrName Type
highlight default link vi9UserCmdAttrNargs vi9String
highlight default link vi9UserCmdAttrNargsNumber vi9Number
highlight default link vi9UserCmdAttrRange vi9String
highlight default link vi9UserCmdDef Statement
highlight default link vi9UserCmdLhs vi9UserCmdExe
highlight default link vi9UserCmdRhsEscapeSeq vi9BracketNotation
highlight default link vi9VimGrep vi9GenericCmd
highlight default link vi9VimGrepPat vi9String
highlight default link vi9Wincmd vi9GenericCmd
highlight default link vi9WincmdArg vi9String

if get(g:, 'vim9_syntax', {})
 ->get('builtin_functions', true)
    highlight default link vi9FuncNameBuiltin Function
endif

if get(g:, 'vim9_syntax', {})
 ->get('data_types', true)
    highlight default link vi9DataType Type
    highlight default link vi9DataTypeCast vi9DataType
    highlight default link vi9ValidSubType vi9DataType
endif
#}}}1

b:current_syntax = 'vim9'
