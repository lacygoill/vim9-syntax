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
        # `syntax include @vim9Script syntax/vim.vim`)
        && !get(b:, 'force_vim9_syntax')
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
#    - `vim9LineComment`
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
execute 'syntax match vim9BracketNotation'
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
    .. ' contains=vim9BracketKey'
    .. ' nextgroup=vim9SetBracketEqual'
    .. ' display'
    #     set <Up>=^[OA
    #             ^
    syntax match vim9SetBracketEqual /=[[:cntrl:]]\@=/ contained nextgroup=vim9SetBracketKeycode
    #     set <Up>=^[OA
    #              ^--^
    syntax match vim9SetBracketKeycode /\S\+/ contained

# This could break the highlighting of a command after `<Bar>` (between `<ScriptCmd>` and `<CR>`).
syntax match vim9BracketNotation /\c<Bar>/ contains=vim9BracketKey skipwhite

# This could break the highlighting of a command in a mapping (between `<ScriptCmd>` and `<CR>`).
# Especially if `<ScriptCmd>` is preceded by some key(s).
syntax match vim9BracketNotation /\c<ScriptCmd>/hs=s+1
    \ contains=vim9BracketKey
    \ nextgroup=@vim9CanBeAtStartOfLine,@vim9Range,vim9RangeIntroducer2
    \ skipwhite
    syntax match vim9RangeIntroducer2 /:/ contained nextgroup=@vim9Range,vim9RangeMissingSpecifier1

# We only highlight `<Cmd>`; not the command which comes right after.{{{
#
# That's because this command is run in the global context, thus with the legacy
# syntax.  And handling the legacy syntax adds too much complexity.
#
# Besides, the fact  that it's not highlighted gives us  some feedback: it tells
# us  that the  command  is not  run  with  the Vim9  syntax.   Just like  after
# `:legacy`, and inside a `:function`.
#}}}
syntax match vim9BracketNotation /\c<Cmd>/hs=s+1 contains=vim9BracketKey

# let's put this here for consistency
execute 'syntax match vim9ExSpecialCharacters'
    .. ' /\c'
    .. '<'
    ..     '\%('
    ..         lang.ex_special_characters
    ..     '\)'
    .. '>'
    .. '/'
    .. ' contains=vim9BracketKey'

syntax match vim9BracketKey /[<>]/ contained

# Unbalanced paren {{{2

syntax match vim9OperError /[)\]}]/
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
syntax match vim9OperError /-\@1<!>/

# Special brackets in interpolated strings and heredocs {{{2

# This must  come *before*  the rules  matching expressions  inside interpolated
# strings and heredocs.

# String Interpolated Unbalanced Bracket
syntax match vim9SIUB /[{}]/ contained
# String Interpolated Literal Bracket
syntax match vim9SILB /{{\|}}/ contained

# :++ / :-- {{{2
# Order: Must come before `vim9AutocmdMod`, to not break `++nested` and `++once`.

# increment/decrement
# The `++` and `--` operators are implemented as Ex commands:{{{
#
#     :echo getcompletion('[-+]', 'command')
#     ['++', '--']
#
# Which makes sense.  They can only appear at the start of a line.
#}}}
syntax match vim9Increment /\%(++\|--\)\%(\h\|&\)\@=/ contained

execute 'syntax match vim9IncrementError'
    .. ' /' .. lang.increment_invalid .. '/'
    .. ' contained'
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
    # Order: Must come after `vim9RangeIntroducer`.
    syntax match vim9DisambiguatingColon /\s\=:[a-zA-Z!]\@=/
        \ contained
        \ nextgroup=@vim9CanBeAtStartOfLine

syntax cluster vim9RangeAfterSpecifier contains=
    \ @vim9CanBeAtStartOfLine,
    \ @vim9Range,
    \ vim9RangeMissingSpace

#                     v-----v v-----v
#     command MySort :<line1>,<line2> sort
syntax match vim9RangeLnumNotation /\c<line[12]>/
    \ contained
    \ contains=vim9BracketNotation,vim9UserCmdRhsEscapeSeq
    \ nextgroup=@vim9RangeAfterSpecifier
    \ skipwhite

execute 'syntax match vim9RangeMark /' .. "'" .. lang.mark_valid .. '/'
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
# So that it's removed from `lang.command_name`, and in turn from the `vim9GenericCmd` rule.
#}}}
syntax cluster vim9IsCmd contains=
    \ @vim9ControlFlow,
    \ @vim9OOP,
    \ vim9AbbrevCmd,
    \ vim9Augroup,
    \ vim9Autocmd,
    \ vim9BangCmd,
    \ vim9Cd,
    \ vim9CmdModifier,
    \ vim9CopyMove,
    \ vim9Declare,
    \ vim9DeclareError,
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
    \ vim9DeprecatedLet,
    \ vim9Map,
    \ vim9MarkCmd,
    \ vim9Norm,
    \ vim9ProfileCmd,
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

# Special Case: `:!`
syntax match vim9MayBeCmd /!\@=/ contained nextgroup=@vim9Iscmd

# Special Case: Some commands (like `:g` and `:s`) *can* be followed by a non-whitespace.
syntax match vim9MayBeCmd /\%(\<\h\w*\>\)\@=/
    \ contained
    \ nextgroup=vim9Global,vim9Subst

    # General case
    # Order: Must come after the previous rule handling the special case.
    execute 'syntax match vim9MayBeCmd'
        .. ' /\%(' .. '\<\h\w*\>' .. '!\=' .. lang.command_can_be_before .. '\)\@=/'
        .. ' contained'
        .. ' nextgroup=@vim9IsCmd'

# Now, let's build a cluster containing all groups which can appear at the start of a line.
syntax cluster vim9CanBeAtStartOfLine contains=
    \ @vim9FuncCall,
    \ vim9Block,
    \ vim9Comment,
    \ vim9DeprecatedDictLiteralLegacy,
    \ vim9DeprecatedScopes,
    \ vim9DisambiguatingColon,
    \ vim9FuncEnd,
    \ vim9FuncHeader,
    \ vim9Increment,
    \ vim9IncrementError,
    \ vim9LegacyFunction,
    \ vim9MayBeCmd,
    \ vim9RangeIntroducer,
    \ vim9This

# Let's use it in all relevant contexts.   We won't list them all here; only the
# ones which  don't have a  dedicated section (i.e. start  of line, and  after a
# bar).
syntax match vim9StartOfLine /^/
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite
    # This rule  is useful to  disallow some constructs at  the start of  a line
    # where an expression is meant to be written.
    syntax match vim9SOLExpr /^/ contained skipwhite nextgroup=@vim9Expr

syntax match vim9CmdSep /|/ skipwhite nextgroup=@vim9CanBeAtStartOfLine

# Generic {{{2

execute 'syntax keyword vim9GenericCmd' .. ' ' .. lang.command_name .. ' contained'

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
syntax match vim9AutocmdPat /[^ \t|]\S*/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine,
    \     vim9AutocmdMod,
    \     vim9BlockUserCmd,
    \     vim9ContinuationBeforeCmd
    \ skipnl
    \ skipwhite

syntax match vim9AutocmdMod /++\%(nested\|once\)/
    \ contained
    \ nextgroup=
    \     @vim9CanBeAtStartOfLine,
    \     vim9BlockUserCmd,
    \     vim9ContinuationBeforeCmd
    \ skipnl
    \ skipwhite

# Events {{{4

syntax case ignore
if get(g:, 'vim9_syntax', {})
 ->get('errors', {})
 ->get('event_wrong_case', false)
    execute 'syntax keyword vim9AutocmdEventBadCase' .. ' ' .. lang.event
        .. ' contained'
        .. ' nextgroup=vim9AutocmdPat,vim9AutocmdEndOfEventList'
        .. ' skipwhite'
    syntax case match
endif
# Order: Must come after `vim9AutocmdEventBadCase`.
execute 'syntax keyword vim9AutocmdEventGoodCase' .. ' ' .. lang.event
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
syntax keyword vim9Return return contained nextgroup=@vim9Expr skipwhite

# :break
# :continue
syntax keyword vim9BreakContinue break continue contained
# :finish
syntax keyword vim9Finish finish contained

# :if
# :elseif
syntax keyword vim9Conditional if elseif contained nextgroup=@vim9Expr skipwhite

# :else
# :endif
syntax keyword vim9Conditional else endif contained

# :for
syntax keyword vim9Repeat for
    \ contained
    \ nextgroup=vim9RepeatForDeclareName,vim9RepeatForListUnpackDeclaration
    \ skipwhite

# :for [name, ...]
#      ^---------^
# `contains=vim9DataType` to support the return type of a funcref:{{{
#
#     for [a: string, B: func(string): bool] in []
#                                      ^--^
#}}}
syntax region vim9RepeatForListUnpackDeclaration
    \ matchgroup=vim9Sep
    \ start=/\[/
    \ end=/]/
    \ contained
    \ contains=vim9RepeatForDeclareName,vim9DataType
    \ nextgroup=vim9RepeatForIn
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
syntax match vim9RepeatForDeclareName /\<\h\w*\>\%(\s*\%(:\s\|\<in\>\)\|,\|\s*\]\)\@=/
    \ contained
    \ nextgroup=@vim9DataTypeCluster,vim9RepeatForIn,vim9NoWhitespaceBeforeInit
    \ skipwhite

# for name in
#          ^^
syntax keyword vim9RepeatForIn in contained

# :while
syntax keyword vim9Repeat while contained nextgroup=@vim9Expr skipwhite

# :endfor
# :endwhile
syntax keyword vim9Repeat endfor endwhile contained

# :try
# :finally
# :endtry
syntax keyword vim9TryCatch try finally endtry contained

# :throw
syntax keyword vim9TryCatch throw contained nextgroup=@vim9Expr skipwhite

# :catch
syntax keyword vim9TryCatch catch contained nextgroup=vim9TryCatchPattern skipwhite
execute 'syntax region vim9TryCatchPattern'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' contains=vim9TryCatchPatternDelim'
    .. ' oneline'

# Declaration {{{3

# Don't rewrite this rule with `:help syn-keyword`.
# The `vim9DeclareError` rule needs to be able to override `vim9Declare`.
# But it uses a match, and thus can only win against another match/region.
syntax match vim9Declare /\<\%(const\=\|final\|unl\%[et]\|var\)\>/
    \ contained
    \ nextgroup=
    \     vim9DeclareName,
    \     vim9ListUnpackDeclaration,
    \     vim9ReservedNames
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
    syntax match vim9DeclareError /\<var\ze\s\+\%([bgstvw]:\h\|[$&@]\)/
        \ contained
    syntax match vim9DeclareError /\<\%(const\=\|final\)\ze\s\+[$&@]/
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
    syntax match vim9DeclareError /\<unlet\ze\s\+[&@]/ contained

syntax region vim9ListUnpackDeclaration
    \ contained
    \ contains=vim9DeclareName
    \ matchgroup=vim9Sep
    \ start=/\[/
    \ end=/\]/
    \ keepend
    \ oneline

syntax region vim9DeclareName
    \ contained
    \ contains=@vim9DataTypeCluster,vim9NoWhitespaceBeforeInit
    \ start=/[^ \t[]/
    \ end=/=\@=/
    \ oneline

#     var name : string = 'value'
#             ^
#             ✘
syntax match vim9NoWhitespaceBeforeInit /\s\+:\@=/
    \ contained
    \ nextgroup=@vim9DataTypeCluster
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
# Don't assign `vim9Declare` instead of `vim9DeclareHereDoc` to `matchgroup`.{{{
#
# We want the syntax  item on the text at the start/end of  a heredoc to contain
# the keyword `heredoc`.  It might be useful for other plugins; for example, for
# the Vim indent plugin.
#}}}
# Similarly, don't change the name of `vim9DeclareHereDocStop`.{{{
#
# The Vim indent plugin relies on the keyword `HereDocStop` to find the end of a
# heredoc.
#}}}
syntax region vim9HereDoc
    \ matchgroup=vim9DeclareHereDoc
    \ start=/\s\@1<==<<\s\+\%(trim\s\)\=\s*\z(\L\S*\)/
    \ matchgroup=vim9DeclareHereDocStop
    \ end=/^\s*\z1$/

syntax region vim9HereDoc
    \ matchgroup=vim9DeclareHereDoc
    \ start=/\s\@1<==<<\s\+\%(.*\<eval\>\)\@=\%(\%(trim\|eval\)\s\)\{1,2}\s*\z(\L\S*\)/
    \ matchgroup=vim9DeclareHereDocStop
    \ end=/^\s*\z1$/
    \ contains=vim9HereDocExpr,vim9SILB,vim9SIUB

syntax region vim9HereDocExpr
    \ matchgroup=PreProc
    \ start=/{{\@!/
    \ end=/}/
    \ contained
    \ contains=@vim9Expr
    \ oneline

# Modifier {{{3

execute 'syntax match vim9CmdModifier'
    .. ' /\<\%(' .. lang.command_modifier .. '\)\>/'
    .. ' contained'
    .. ' nextgroup=@vim9CanBeAtStartOfLine,vim9CmdBangModifier,vim9Line12MissingColon'
    .. ' skipwhite'

# A command modifier can be followed by a bang.
# We need to match it, otherwise, we can't match the command which comes afterward.
# The negative lookbehind is necessary because of the previous `skipwhite`.
syntax match vim9CmdBangModifier /\s\@1<!!/ contained nextgroup=@vim9CanBeAtStartOfLine skipwhite

# Highlight a legacy command (run with `:legacy`) to a minimum.{{{
#
# In particular, we don't want `:let` to be wrongly highlighted as an error:
#
#     legacy let g:name = 'value'
#            ^^^
#            not an error because valid in legacy
#}}}
execute 'syntax match vim9CmdModifier'
    .. ' /\<legacy\>/'
    .. ' contained'
    .. ' nextgroup=vim9LegacyCmd'
    .. ' skipwhite'

syntax match vim9LegacyCmd /.\{-}\%(\\\@1<!|\|$\)\@=/ contained contains=@vim9LegacyCluster

# User {{{3
# Definition {{{4
# :command {{{5

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would break the highlighting of a possible following bang.
syntax match vim9UserCmdDef /\<com\%[mand]\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttr
    \ skipwhite

syntax match vim9UserCmdDef /\<com\%[mand]\>!/he=e-1
    \ contained
    \ nextgroup=@vim9UserCmdAttr
    \ skipwhite

# error handling {{{5
# Order: should come before highlighting valid attributes.

syntax cluster vim9UserCmdAttr contains=
    \ vim9UserCmdAttrEqual,
    \ vim9UserCmdAttrError,
    \ vim9UserCmdAttrErrorValue,
    \ vim9UserCmdAttrName,
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
syntax match vim9UserCmdAttrErrorValue /\S\+/
    \ contained
    \ nextgroup=vim9UserCmdAttrName
    \ skipwhite

# an invalid attribute name is an error
syntax match vim9UserCmdAttrError /-[^ \t=]\+/
    \ contained
    \ contains=vim9UserCmdAttrName
    \ nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

# boolean attributes {{{5

syntax match vim9UserCmdAttrName /-\%(bang\|bar\|buffer\|register\)\>/
    \ contained
    \ nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

# attributes with values {{{5
# = {{{6

syntax match vim9UserCmdAttrEqual /=/ contained

# -addr {{{6

syntax match vim9UserCmdAttrName /-addr\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrAddress,vim9UserCmdAttrErrorValue

execute 'syntax match vim9UserCmdAttrAddress'
    .. ' /=\%(' .. lang.command_address_type .. '\)\>/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrEqual'
    .. ' nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd'
    .. ' skipnl'
    .. ' skipwhite'

# -complete {{{6

syntax match vim9UserCmdAttrName /-complete\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrComplete,vim9UserCmdAttrErrorValue

# -complete=arglist
# -complete=buffer
# -complete=...
execute 'syntax match vim9UserCmdAttrComplete'
    .. ' /'
    ..     '=\%(' .. lang.command_complete_type .. '\)'
    .. '/'
    .. ' contained'
    .. ' contains=vim9UserCmdAttrEqual'
    .. ' nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd'
    .. ' skipnl'
    .. ' skipwhite'

# -complete=custom,Func
# -complete=customlist,Func
syntax match vim9UserCmdAttrComplete /=custom\%(list\)\=,\%([gs]:\)\=\%(\w\|[#.]\)*/
    \ contained
    \ contains=vim9UserCmdAttrEqual,vim9UserCmdAttrComma
    \ nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vim9UserCmdAttrComma /,/ contained

# -count {{{6

syntax match vim9UserCmdAttrName /-count\>/
    \ contained
    \ nextgroup=
    \     @vim9UserCmdAttr,
    \     vim9UserCmdAttrCount,
    \     vim9UserCmdAttrErrorValue,
    \     vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vim9UserCmdAttrCount
    \ /=\d\+/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrEqual
    \ nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

# -nargs {{{6

syntax match vim9UserCmdAttrName /-nargs\>/
    \ contained
    \ nextgroup=vim9UserCmdAttrNargs,vim9UserCmdAttrErrorValue

syntax match vim9UserCmdAttrNargs
    \ /=[01*?+]/
    \ contained
    \ contains=vim9UserCmdAttrEqual,vim9UserCmdAttrNargsNumber
    \ nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vim9UserCmdAttrNargsNumber /[01]/ contained

# -range {{{6

# `-range` is a special case:
# it can accept a value, *or* be used as a boolean.
syntax match vim9UserCmdAttrName /-range\>/
    \ contained
    \ nextgroup=
    \     @vim9UserCmdAttr,
    \     vim9UserCmdAttrErrorValue,
    \     vim9UserCmdAttrRange,
    \     vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite

syntax match vim9UserCmdAttrRange /=\%(%\|-\=\d\+\)/
    \ contained
    \ contains=vim9Number,vim9UserCmdAttrEqual
    \ nextgroup=@vim9UserCmdAttr,vim9ContinuationBeforeUserCmd
    \ skipnl
    \ skipwhite
#}}}5
# LHS {{{5

syntax match vim9UserCmdLhs /\u\w*/
    \ contained
    \ nextgroup=
    \     @vim9CanBeAtStartOfLine,
    \     vim9BlockUserCmd,
    \     vim9ContinuationBeforeCmd,
    \     vim9Line12MissingColon
    \ skipnl
    \ skipwhite

#     command Cmd <line1>,<line2>yank
#                 ^
#                 ✘
#
#     command Cmd :<line1>,<line2>yank
#                 ^
#                 ✔
syntax match vim9Line12MissingColon /<line[12]>/ contained

# escape sequences in RHS {{{5

# We should limit this match to the RHS of a user command.{{{
#
# But that would add too much complexity, so we don't.
# Besides, it's unlikely we would write something like `<line1>` outside the RHS
# of a user command.
#}}}
execute 'syntax match vim9UserCmdRhsEscapeSeq'
    .. ' /'
    .. '<'
    .. '\%([fq]-\)\='
    # `:help <line1>`
    .. '\%(args\|bang\|count\|line[12]\|mods\|range\|reg\)'
    .. '>'
    .. '/'
    .. ' contains=vim9BracketKey'
    # An escape sequence might be embedded inside a string:{{{
    #
    #     command -nargs=1 Locate Wrap({source: 'locate <q-args>', options: '-m'})->Run()
    #                                                   ^------^
    #}}}
    .. ' containedin=vim9String,vim9StringInterpolated'
#}}}4
# Execution {{{4

syntax match vim9UserCmdExe /\u\w*/ contained nextgroup=vim9SpaceExtraAfterFuncname,vim9UserCmdArgs
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
syntax match vim9UserCmdArgs /\s*[^ \t|].\{-}[|\n]/ contained

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
syntax keyword vim9Set CompilerSet contained nextgroup=vim9MayBeOptionSet skipwhite
#}}}3
# :cd {{{3

syntax keyword vim9Cd cd lc[d] tc[d] chd[ir] lch[dir] tch[dir] nextgroup=vim9CdPreviousDir

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
syntax match vim9CdPreviousDir /!\=\s*-/ contained

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
    \     vim9DigraphsChars,
    \     vim9DigraphsCharsInvalid,
    \     vim9DigraphsCmdBang
    \ skipwhite

syntax match vim9DigraphsCharsInvalid /\S\+/
    \ contained
    \ nextgroup=vim9DigraphsNumber
    \ skipwhite
    syntax match vim9DigraphsCmdBang /!/ contained

# A valid `characters` argument is any sequence of 2 non-whitespace characters.
# Special Case:  a bar must  be escaped,  so that it's  not parsed as  a command
# termination.
syntax match vim9DigraphsChars /\s\@<=\%([^ \t|]\|\\|\)\{2}\_s\@=/
    \ contained
    \ nextgroup=vim9DigraphsNumber
    \ skipwhite
syntax match vim9DigraphsNumber /\d\+/
    \ contained
    \ nextgroup=vim9DigraphsChars,vim9DigraphsCharsInvalid
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
    .. ' /\<g\%[lobal]\>\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'
    .. ' skipwhite'

# with a bang
execute 'syntax match vim9Global'
    .. ' /\<g\%[lobal]\>!\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/he=e-1'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'
    .. ' skipwhite'

# vglobal/pat/cmd
execute 'syntax match vim9Global'
    .. ' /\<v\%[global]\>\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9GlobalPat'
    .. ' skipwhite'

execute 'syntax region vim9GlobalPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' nextgroup=@vim9CanBeAtStartOfLine'
    .. ' oneline'
    .. ' skipwhite'

# :highlight {{{3
# TODO: Review all the rules related to `:highlight`.
# command {{{4

syntax cluster vim9HiCluster contains=
    \ vim9HiClear,
    \ vim9HiDefault,
    \ vim9HiGroup,
    \ vim9HiLink

syntax keyword vim9Highlight hi[ghlight]
    \ contained
    \ nextgroup=@vim9HiCluster,vim9HiBang
    \ skipwhite

syntax match vim9HiBang /!/ contained nextgroup=@vim9HiCluster skipwhite

# Group name {{{4

syntax match vim9HiGroup /\w\+/
    \ contained
    \ nextgroup=
    \     vim9HiCterm,
    \     vim9HiCtermFgBg,
    \     vim9HiGroup,
    \     vim9HiGui,
    \     vim9HiGuiFgBg,
    \     vim9HiStartStop,
    \     vim9HiTerm
    \ skipwhite

# :highlight clear {{{4

syntax keyword vim9HiClear clear contained nextgroup=vim9HiGroup skipwhite

# :highlight default/link {{{4

syntax keyword vim9HiDefault def[ault] contained nextgroup=vim9HiGroup,vim9HiLink skipwhite
syntax keyword vim9HiLink link contained nextgroup=vim9HiGroup skipwhite

# :highlight group key=arg ... {{{4

syntax match vim9HiEqual /=/
    \ contained
    \ nextgroup=
    \     vim9HiAttr,
    \     vim9HiCtermColor,
    \     vim9HiFgBgAttr,
    \     vim9HiFontname,
    \     vim9HiGroup,
    \     vim9HiGuiFontname,
    \     vim9HiGuiRgb,
    \     vim9HiNumber

syntax keyword vim9HiTerm term contained nextgroup=vim9HiEqual
syntax keyword vim9HiCterm cterm contained nextgroup=vim9HiEqual
syntax keyword vim9HiCtermFgBg ctermfg ctermbg
    \ contained
    \ nextgroup=vim9HiEqual
syntax keyword vim9HiGui gui contained nextgroup=vim9HiEqual
syntax keyword vim9HiGuiFgBg guibg guifg guisp
    \ contained
    \ nextgroup=vim9HiEqual

syntax match vim9HiStartStop /\%(start\|stop\)=/he=e-1
    \ contained
    \ nextgroup=vim9HiTermcap,vim9MayBeOptionScoped

syntax match vim9HiGuiFont /font/ contained nextgroup=vim9HiEqual

syntax match vim9HiCtermul /ctermul=/he=e-1
    \ contained
    \ nextgroup=
    \     vim9HiCtermColor,
    \     vim9HiFgBgAttr,
    \     vim9HiNumber

syntax match vim9HiTermcap /\S\+/ contained contains=vim9BracketNotation
syntax match vim9HiNumber /\d\+/ contained nextgroup=vim9HiCterm,vim9HiCtermFgBg skipwhite

# attributes {{{4

syntax case ignore
syntax keyword vim9HiAttr
    \ none bold inverse italic nocombine reverse standout strikethrough
    \ underline undercurl
    \ contained
    \ nextgroup=
    \     vim9HiAttrComma,
    \     vim9HiCterm,
    \     vim9HiCtermFgBg,
    \     vim9HiGui
    \ skipwhite
syntax match vim9HiAttrComma /,/ contained nextgroup=vim9HiAttr

syntax keyword vim9HiFgBgAttr none bg background fg foreground
    \ contained
    \ nextgroup=vim9HiCterm,vim9HiGui,vim9HiGuiFgBg,vim9HiCtermFgBg
    \ skipwhite
syntax case match

syntax case ignore
syntax keyword vim9HiCtermColor contained
    \ black blue brown cyan darkblue darkcyan darkgray darkgreen darkgrey
    \ darkmagenta darkred darkyellow gray green grey lightblue lightcyan
    \ lightgray lightgreen lightgrey lightmagenta lightred magenta red white
    \ yellow
    \ nextgroup=vim9HiCterm,vim9HiCtermFgBg
    \ skipwhite
syntax case match

syntax match vim9HiFontname /[a-zA-Z\-*]\+/ contained
syntax match vim9HiGuiFontname /'[a-zA-Z\-* ]\+'/ contained
syntax match vim9HiGuiRgb /#\x\{6}/ contained nextgroup=vim9HiGuiFgBg,vim9HiGui skipwhite
#}}}3
# :import / :export {{{3

# :import
# :export
syntax keyword vim9Import imp[ort] contained nextgroup=vim9ImportedScript,vim9ImportAutoload skipwhite
syntax keyword vim9Export exp[ort] contained nextgroup=vim9Abstract,vim9Class,vim9Declare,vim9Interface skipwhite

#        v------v
# import autoload 'path/to/script.vim'
syntax keyword vim9ImportAutoload autoload
    \ contained
    \ nextgroup=vim9ImportedScript
    \ skipwhite

#        v------------v
# import 'MyScript.vim' ...
syntax match vim9ImportedScript /\(['"]\)\f\+\1/
    \ contained
    \ nextgroup=vim9ImportAs
    \ skipwhite

#                       vv
# import 'MyScript.vim' as MyAlias
syntax keyword vim9ImportAs as contained

# :inoreabbrev {{{3

syntax keyword vim9AbbrevCmd
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ contained
    \ nextgroup=vim9MapLhs,@vim9MapMod
    \ skipwhite

# :mark {{{3

syntax keyword vim9MarkCmd ma[rk]
    \ contained
    \ nextgroup=vim9MarkCmdArg,vim9MarkCmdArgInvalid
    \ skipwhite

syntax match vim9MarkCmdArgInvalid /[^ \t|]\+/ contained
# Need to allow `<` for a bracketed keycode inside a mapping (e.g. `<Bar>`).
execute 'syntax match vim9MarkCmdArg /\s\@1<=' .. lang.mark_valid .. '\%([ \t\n<]\)\@=/ contained'

# :nnoremap {{{3

syntax cluster vim9MapMod contains=vim9MapMod,vim9MapModExpr

syntax match vim9Map /\<map\>!\=\ze\s*[^(]/
    \ contained
    \ nextgroup=vim9MapLhs,vim9MapMod,vim9MapModExpr
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
    \ nextgroup=vim9MapBang,vim9MapLhs,@vim9MapMod
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

syntax match vim9MapBang /!/ contained nextgroup=vim9MapLhs,@vim9MapMod skipwhite

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
    \     vim9MapScriptCmd,
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
syntax region vim9MapScriptCmd
    \ start=/\c<ScriptCmd>/
    \ matchgroup=vim9BracketNotation
    \ end=/\c<CR>\|<Enter>\|^\s*$/
    \ contained
    \ contains=
    \     @vim9Expr,
    \     vim9BracketNotation,
    \     vim9Continuation,
    \     vim9MapCmdBar,
    \     vim9OperAssign,
    \     vim9SpecFile
    \ keepend

syntax region vim9MapInsertExpr
    \ start=/\c<C-R>=\@=/
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vim9Expr,vim9BracketNotation,vim9EvalExpr
    \ keepend
    \ oneline
syntax match vim9EvalExpr /\%(<C-R>\)\@6<==/ contained

# We don't use  `oneline` here, because it  might be convenient to  split a long
# expression on multiple lines (with explicit continuation lines).
syntax region vim9MapCmdlineExpr
    \ matchgroup=vim9BracketNotation
    \ start=/\c<C-\\>e/
    \ matchgroup=NONE
    \ end=/\c<CR>\|<Enter>/
    \ contained
    \ contains=@vim9Expr,vim9BracketNotation,vim9Continuation
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
syntax match vim9MapCmdBar /\c<Bar>/
    \ contained
    \ contains=vim9BracketNotation
    \ nextgroup=@vim9CanBeAtStartOfLine
    \ skipwhite

syntax match vim9MapRhsExtend /^\s*\\.*$/
    \ contained
    \ contains=vim9Continuation,vim9BracketNotation
    \ nextgroup=vim9MapRhsExtend
    \ skipnl
syntax match vim9MapRhsExtendExpr /^\s*\\.*$/
    \ contained
    \ contains=@vim9Expr,vim9Continuation

# :normal {{{3

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would break the highlighting of a possible following bang.
syntax match vim9Norm /\<norm\%[al]\>/ nextgroup=vim9NormCmds contained skipwhite
syntax match vim9Norm /\<norm\%[al]\>!/he=e-1 nextgroup=vim9NormCmds contained skipwhite

syntax match vim9NormCmds /.*/ contained

# :profile {{{3

syntax keyword vim9ProfileCmd prof[ile]
    \ contained
    \ nextgroup=
    \    vim9ProfileCmdBang,
    \    vim9ProfileSubCmd,
    \    vim9ProfileSubCmdInvalid
    \ skipwhite

syntax match vim9ProfileSubCmdInvalid /\S\+/
    \ contained
    \ nextgroup=vim9ProfilePat
    \ skipwhite
    syntax match vim9ProfileCmdBang /!/
        \ contained
        \ nextgroup=vim9ProfileSubCmd,vim9ProfileSubCmdInvalid
        \ skipwhite


syntax keyword vim9ProfileSubcmd continue dump file func pause start stop
    \ contained
    \ nextgroup=vim9ProfilePat
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
syntax match vim9ProfilePat '\S\+' contained

# :substitute {{{3

# TODO: Why did we include `vim9BracketNotation` here?
#
# Some  of its  effects are  really  nice in  a substitution  pattern (like  the
# highlighting of capturing groups).  But I  don't think all of its effects make
# sense here.   Consider replacing  it with  a similar  group whose  effects are
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
#     syntax clear vim9Subst
#
# Notice that everything gets broken after the substitution command.
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vim9Subst` is defined with `display`
#}}}
execute 'syntax match vim9Subst'
    .. ' /\<s\%[ubstitute]\>\s*\ze\(' .. lang.pattern_delimiter .. '\).\{-}\1.\{-}\1/'
    .. ' contained'
    .. ' nextgroup=vim9SubstPat'

execute 'syntax region vim9SubstPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
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
    .. '\%(' .. lang.collation_class .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syntax match vim9SubstSubstr /\\z\=\d/ contained
syntax match vim9SubstTwoBS /\\\\/ contained
syntax match vim9SubstFlagErr /[^< \t\r|]\+/ contained contains=vim9SubstFlags
syntax match vim9SubstFlags /[&cegiIlnpr#]\+/ contained

# :syntax {{{3
# :syntax {{{4

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
syntax match vim9Syntax /\<sy\%[ntax]\>/
    \ contained
    \ contains=vim9GenericCmd
    \ nextgroup=vim9SynType
    \ skipwhite

# Must exclude the bar for this to work:{{{
#
#     syntax clear | eval 0
#                  ^
#                  not part of a group name
#}}}
syntax match vim9GroupList /@\=[^ \t,|']\+/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep

syntax match vim9GroupList /@\=[^ \t,|']*,/
    \ contained
    \ contains=vim9GroupSpecial,vim9PatSep
    \ nextgroup=vim9GroupList

# Warning: Do not turn `:syntax match` into `:syntax keyword`.
# It would fail to match `CONTAINED`.
syntax match vim9GroupSpecial /\<\%(ALL\|ALLBUT\|CONTAINED\|TOP\)\>/ contained
syntax match vim9SynError /\i\+/ contained
syntax match vim9SynError /\i\+=/ contained nextgroup=vim9GroupList

syntax match vim9SynContains /\<contain\%(s\|edin\)/ contained nextgroup=vim9SynEqual
syntax match vim9SynEqual /=/ contained nextgroup=vim9GroupList

syntax match vim9SynKeyContainedin /\<containedin/ contained nextgroup=vim9SynEqual
syntax match vim9SynNextgroup /nextgroup/ contained nextgroup=vim9SynEqual

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

syntax cluster vim9SynMatchGroup contains=
    \ vim9BracketNotation,
    \ vim9MatchComment,
    \ vim9SynContains,
    \ vim9SynError,
    \ vim9SynMatchOpt,
    \ vim9SynNextgroup,
    \ vim9SynRegPat

syntax keyword vim9SynType match contained nextgroup=vim9SynMatchRegion skipwhite

# We need to avoid  consuming the bar in the end  pattern; otherwise, the latter
# would  be matched  with `vim9GroupName`,  which would  break the  syntax of  a
# possible subsequent command.
syntax region vim9SynMatchRegion
    \ matchgroup=vim9GroupName
    \ start=/\h\w*/
    \ end=/|\@=\|$/
    \ contained
    \ contains=@vim9SynMatchGroup
    \ keepend

execute 'syntax match vim9SynMatchOpt'
    .. ' /'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syntax match vim9SynMatchOpt /\<cchar=/ contained nextgroup=vim9SynMatchCchar
syntax match vim9SynMatchCchar /\S/ contained

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
    \ vim9SynMatchgroup,
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

syntax match vim9SynMatchgroup /matchgroup/ contained nextgroup=vim9SynEqualMatchGroup
syntax match vim9SynEqualMatchGroup /=/ contained nextgroup=vim9Group,vim9HLGroup

syntax region vim9SynRegPat
    \ start=/\z([-`~!@#$%^&*_=+;:'",./?|]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contained
    \ contains=@vim9SynRegPatGroup
    \ extend
    \ nextgroup=vim9SynPatMod,vim9SynRegStartSkipEnd
    \ skipwhite

    # Handles inline comment after a `:help :syn-match` rule.
    # Order: must come after `vim9SynRegPat`.
    syntax match vim9MatchComment contained '#[^#]\+$'

syntax match vim9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=/
    \ contained

syntax match vim9SynPatMod
    \ /\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,/
    \ contained
    \ nextgroup=vim9SynPatMod

syntax region vim9SynPatRange start=/\[/ skip=/\\\\\|\\]/ end=/]/ contained
syntax match vim9SynNotPatRange /\\\\\|\\\[/ contained

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
    .. ' /\<l\=vim\%[grep]\%(add\)\=\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/'
    .. ' nextgroup=vim9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

# with a bang
execute 'syntax match vim9VimGrep'
    .. ' /\<l\=vim\%[grep]\%(add\)\=!\ze\s*\(' .. lang.pattern_delimiter .. '\).\{-}\1/he=e-1'
    .. ' nextgroup=vim9VimGrepPat'
    .. ' contained'
    .. ' skipwhite'

execute 'syntax region vim9VimGrepPat'
    .. ' matchgroup=vim9SubstDelim'
    .. ' start=/\z(' .. lang.pattern_delimiter .. '\)/rs=s+1'
    .. ' skip=/\\\\\|\\\z1/'
    .. ' end=/\z1/'
    .. ' contained'
    .. ' contains=@vim9SubstList'
    .. ' oneline'

# :wincmd {{{3

syntax keyword vim9Wincmd winc[md]
    \ contained
    \ nextgroup=vim9WincmdArg,vim9WincmdArgInvalid
    \ skipwhite

syntax match vim9WincmdArgInvalid /\S\+/ contained
execute 'syntax match vim9WincmdArg ' .. lang.wincmd_valid .. ' contained'

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
syntax match vim9BangCmd /!/ contained nextgroup=vim9BangShellCmd
syntax match vim9BangShellCmd /.*/ contained contains=vim9BangLastShellCmd
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
syntax match vim9BangLastShellCmd /\\\@1<!!/ contained display
#}}}1
# Continuation {{{1

# We don't include `vim9Continuation` in `@vim9CanBeAtStartOfLine`.
#
# It would  somehow create an  order requirement between  `vim9Continuation` and
# `vim9ContinuationBeforeCmd`.  The former would have to be installed before the
# latter.
syntax match vim9Continuation /^\s*\\/
    \ nextgroup=
    \     vim9SynContains,
    \     vim9SynContinuePattern,
    \     vim9SynMatchgroup,
    \     vim9SynNextgroup,
    \     vim9SynRegOpt,
    \     vim9SynRegStartSkipEnd
    \ skipwhite
    # TODO: Should we use a cluster? (`@vim9SynMatchGroup`?)
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
syntax match vim9ContinuationBeforeCmd /\\/
    \ contained
    \ nextgroup=@vim9CanBeAtStartOfLine,vim9Line12MissingColon
    \ skipwhite

# Special Case:  we also  want to  be able  to break  a user  command definition
# *before* its name (not just after, which the previous rule handles).
syntax match vim9ContinuationBeforeUserCmd /\\/
    \ contained
    \ nextgroup=vim9UserCmdLhs
    \ skipwhite

# Functions {{{1
# User Definition {{{2
# Vim9 {{{3

execute 'syntax match vim9FuncHeader'
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
    .. '\)'
    .. '\ze\s*('
    .. '/'
    .. ' contains=vim9DefKey,vim9LegacyAutoloadInvalid'
    .. ' nextgroup=vim9FuncSignature,vim9SpaceAfterFuncHeader'
    syntax match vim9SpaceAfterFuncHeader /\s\+\ze(/ contained nextgroup=vim9FuncSignature

syntax keyword vim9DefKey def fu[nction]
    \ contained
    \ nextgroup=vim9DefBangError,vim9DefBang
# :def! is valid
syntax match vim9DefBang /!/ contained
# but only for global functions
syntax match vim9DefBangError /!\%(\s\+g:\)\@!/ contained

execute 'syntax match vim9LegacyAutoloadInvalid'
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
syntax region vim9FuncSignature
    \ matchgroup=vim9ParenSep
    \ start=/(/
    \ end=/)/
    \ matchgroup=NONE
    \ end=/^\s*enddef\ze\s*\%(#.*\)\=$/
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
    .. '\%(' .. '\u\%(\w\|[.]\)*' .. '\|' .. lang.legacy_autoload_invalid .. '\)'
    .. '\ze\s*('
    .. '/'
    .. ' contains=vim9DefKey,vim9LegacyAutoloadInvalid'
    .. ' nextgroup=vim9LegacyFuncBody,vim9SpaceAfterLegacyFuncHeader'
    syntax match vim9SpaceAfterLegacyFuncHeader /\s\+\ze(/ contained nextgroup=vim9LegacyFuncBody

syntax cluster vim9LegacyCluster contains=
    \ vim9LegacyComment,
    \ vim9LegacyConcatInvalid,
    \ vim9LegacyConcatValid,
    \ vim9LegacyDictMember,
    \ vim9LegacyFloat,
    #\ to support the case of a nested legacy function
    \ vim9LegacyFunction,
    \ vim9LegacyString,
    \ vim9LegacyVarArgsHeader

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
    \ start=/(/
    \ matchgroup=vim9DefKey
    \ end=/^\s*\<endf\%[unction]\ze\s*\%(".*\)\=$/
    \ contained
    \ contains=@vim9LegacyCluster
    \ nextgroup=vim9LegacyComment
    \ skipwhite

# We've borrowed these regexes from the legacy plugin.
syntax match vim9LegacyComment /^\s*".*$/ contained
# We also need to support inline comments.{{{
#
# If only  for a trailing comment  after `:endfunction`, so we  can't anchor the
# comment to the start of the line.
#}}}
syntax match vim9LegacyComment /\s\@1<="[^\-:.%#=*].*$/ contained

# We need to match strings because they can contain arbitrary text, which can break other rules.
syntax region vim9LegacyString start=/"/ skip=/\\\\\|\\"/ end=/"/ oneline keepend
syntax region vim9LegacyString start=/'/ skip=/''/ end=/'/ oneline keepend

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
syntax match vim9LegacyConcatInvalid /\.\%(\s\|\w\|['"=]\)\@=/ contained
    # A dot in the `..` concatenation operator is valid.
    syntax match vim9LegacyConcatValid /\.\./ contained
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
    syntax match vim9LegacyDictMember /\%(\h\w*\|[)})\]]\)\zs\.\ze\h\w*/ contained
    # A dot in `...` at the end of a legacy function's header is valid.{{{
    #
    # Same thing in a legacy lambda:
    #
    #     :legacy call timer_start(0, {... -> 0})
    #                                  ^^^
    #}}}
    syntax match vim9LegacyVarArgsHeader /\.\.\.\%(\s*\%()\|->\)\)\@=/ contained
    # A dot in a float is valid.
    syntax match vim9LegacyFloat /\d\+\.\d\+/ contained
#}}}2
# User Call {{{2

syntax cluster vim9FuncCall contains=vim9FuncCallBuiltin,vim9FuncCallUser

# call to user-defined function
execute 'syntax match vim9FuncCallUser'
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
    .. '(\@='
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

# Builtin Call {{{2

# Don't try to merge `vim9FuncCallBuiltin` with `vim9FuncCallUser`.{{{
#
# It would be tricky to handle this case:
#
#     repeat.func()
#
# Where `repeat` comes from an imported `repeat.vim` script.
# `repeat` would probably be wrongly highlighted as a builtin function.
#}}}
syntax match vim9FuncCallBuiltin /[:.]\@1<!\%(new\)\@!\<\l\w*(\@=/ contains=vim9FuncNameBuiltin display
#                                          ^---------^
#                                          :help vim9class /new(

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
    .. ' ' .. lang.builtin_func
    .. ' contained'

execute 'syntax match vim9FuncNameBuiltin'
    .. ' /\<\%(' .. lang.builtin_func_ambiguous .. '\)(\@=/'
    .. ' contained'

# Lambda {{{2

# This is necessary  to avoid the closing angle bracket  being highlighted as an
# error (with `vim9OperError`).
syntax match vim9LambdaName /<lambda>\d\+/
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
#     (because it could be a variable name used in the RHS of an assignment)
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
# MRE:
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
    .. ' ' .. lang.most_operators
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
syntax match vim9Oper /->\%(\_s*\%(\h\|(\)\)\@=/ skipwhite
# logical not
execute 'syntax match vim9Oper' .. ' ' .. lang.logical_not .. ' skipwhite display'

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
    \     @vim9OperGroup

# Data Types {{{1
# `vim9Expr` {{{2

syntax cluster vim9Expr contains=
    \ @vim9FuncCall,
    \ vim9Bool,
    \ vim9DataTypeCast,
    \ vim9Dict,
    \ vim9DeprecatedDictLiteralLegacy,
    \ vim9DeprecatedScopes,
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
    \ vim9String,
    \ vim9StringInterpolated

# Booleans / null / v:none {{{2

syntax match vim9Bool /\%(v:\)\=\<\%(false\|true\)\>:\@!/ display
syntax match vim9Null /\%(v:\)\=\<null\>:\@!/ display
syntax match vim9Null /\<null_\%(blob\|channel\|dict\|function\|job\|list\|partial\|string\)\>/ display

syntax match vim9None /\<v:none\>:\@!/ display

# Strings {{{2

syntax region vim9String
    \ start=/"/
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ contains=vim9EscapeSequence
    \ keepend
    \ oneline

# `:help string`
syntax match vim9EscapeSequence /\\\%(\o\{3}\|\o\{1,2}\O\@=\)/ contained
syntax match vim9EscapeSequence /\\[xX]\%(\x\{2}\|\x\X\@=\)/ contained
syntax match vim9EscapeSequence /\\u\x\{1,4}/ contained
syntax match vim9EscapeSequence /\\U\x\{1,8}/ contained
syntax match vim9EscapeSequence /\\[befnrt\\"]/ contained
highlight default link vim9EscapeSequence Special
# TODO: Should we match them in patterns too?
#
#     vim9GlobalPat
#     vim9RangePattern
#     vim9SubstPat
#     vim9SubstRep
#     vim9SynRegPat
#     vim9TryCatchPattern
#     vim9VimGrepPat
#
# Note that  in patterns, `\o`,  `\x`, `\X`, `\u`,  `\U` must include  a percent
# (`\%o`, `\%x`, ...). To avoid clashing with character classes.


# `:help interpolated-string`
syntax region vim9StringInterpolated
    \ start=/$"/
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ contains=vim9EscapeSequence,vim9StringInterpolatedExpression,vim9SILB,vim9SIUB
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
syntax region vim9StringInterpolatedExpression
    \ matchgroup=PreProc
    \ start=/{{\@!/
    \ end=/}/
    \ contained
    \ contains=@vim9Expr
    \ extend
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
    syntax region vim9StringInterpolated
        \ start=/$'/
        \ skip=/''/
        \ end=/'\d\@!/
        \ contains=vim9StringInterpolatedExpression,vim9SILB,vim9SIUB
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
    \ nextgroup=vim9Comment,vim9StrictWhitespace
    \ skipwhite
    \ display

syntax match vim9Number /-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\=\>/
    \ nextgroup=vim9Comment,vim9StrictWhitespace
    \ skipwhite
    \ display

syntax match vim9Number /\<0[xX]\x\+\>/ nextgroup=vim9Comment,vim9StrictWhitespace skipwhite display
syntax match vim9Number /\_A\zs#\x\{6}\>/ nextgroup=vim9Comment,vim9StrictWhitespace skipwhite
syntax match vim9Number /\<0[zZ][a-fA-F0-9.]\+\>/ nextgroup=vim9Comment,vim9StrictWhitespace skipwhite display
syntax match vim9Number /\<0o[0-7]\+\>/ nextgroup=vim9Comment,vim9StrictWhitespace skipwhite display
syntax match vim9Number /\<0b[01]\+\>/ nextgroup=vim9Comment,vim9StrictWhitespace skipwhite display

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
#     syntax clear vim9Number
#
# Notice that everything gets broken starting from the number.
#
# In practice, that could happen if:
#
#    - `Foo()` is folded (hence, not displayed)
#    - `vim9Number` is defined with `display`
#}}}
syntax match vim9Number /\d\@1<='\d\@=/ nextgroup=vim9Comment,vim9StrictWhitespace skipwhite

# Dictionaries {{{2

# Order: Must come before `vim9Block`.
syntax region vim9Dict
    \ matchgroup=vim9Sep
    \ start=/{/
    \ end=/}/
    \ contains=@vim9OperGroup,vim9DictExprKey,vim9DictMayBeLiteralKey

# In literal dictionary, highlight unquoted key names as strings.
execute 'syntax match vim9DictMayBeLiteralKey'
    .. ' ' .. lang.maybe_dict_literal_key
    .. ' contained'
    .. ' contains=vim9DictIsLiteralKey'
    .. ' keepend'
    .. ' display'

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
    .. ' start=/' .. lang.lambda_start .. '/'
    .. ' end=/' .. lang.lambda_end .. '/'
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

# Order: This section must come *after* the `vim9FuncCallUser` rule.{{{
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
    .. ' contained'
    .. ' display'

# support `:help type-casting` for simple types
execute 'syntax match vim9DataTypeCast'
    .. ' /<\%('
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)>'
    # TODO: Type casts *might* be used for script/function local variables too.
    # If so, you might need to remove this assertion.
    # And also allow `vim9DataTypeCastComposite` to be matched in
    # `vim9OperParen` (and other groups?), and link it to the `Type` HG.
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

execute 'syntax match vim9MayBeOptionScoped'
    .. ' /'
    ..     lang.option_can_be_after
    ..     lang.option_sigil
    ..     lang.option_valid
    .. '/'
    .. ' contains=vim9IsOption,vim9OptionSigil'
    # `vim9SetEqual` would be wrong here; we need spaces around `=`
    .. ' nextgroup=vim9OperAssign'
    .. ' display'

# Don't use `display` here.{{{
#
# It  could mess  up the  buffer  when you  set  a terminal  option whose  value
# contains an opening square bracket.  The latter could be wrongly parsed as the
# start a list.
#}}}
execute 'syntax match vim9MayBeOptionSet'
    .. ' /'
    ..     lang.option_can_be_after
    ..     lang.option_valid
    .. '/'
    .. ' contained'
    .. ' contains=vim9IsOption'
    .. ' nextgroup=vim9SetEqual,vim9SetEqualError,vim9MayBeOptionSet,vim9SetMod'
    .. ' skipwhite'
    execute 'syntax match vim9SetEqualError'
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

syntax match vim9OptionSigil /&\%([gl]:\)\=/ contained

execute 'syntax keyword vim9IsOption'
    .. ' ' .. lang.option
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'
    .. ' skipwhite'

execute 'syntax keyword vim9IsOption'
    .. ' ' .. lang.option_terminal
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

execute 'syntax match vim9IsOption'
    .. ' /\V'
    .. lang.option_terminal_special
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
execute 'syntax match vim9SetMod /' .. lang.option_modifier .. '/'
    .. ' contained'
    .. ' nextgroup=vim9MayBeOptionScoped,vim9MayBeOptionSet'
    .. ' skipwhite'
#}}}1
# Blocks {{{1

# at start of line
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

# possibly after a bar
syntax region vim9Block
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

syntax region vim9BlockUserCmd
    \ matchgroup=Statement
    \ start=/{$/
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
execute 'syntax keyword vim9HLGroup contained' .. ' ' .. lang.default_highlighting_group

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
# Make sure the file name modifiers  are accepted only after `%`, `%%`, `%%123`,
# `<cfile>`, `<sfile>`, `<afile>` and `<abuf>`.
#
# Edit: We currently match `<cfile>` (&friends) with `vim9ExSpecialCharacters`.
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
#     nnoremap x <ScriptCmd>argedit %<CR>
#                                    ^
# Pretty sure it's needed in other similar rules around here.
# Make tests.
# Try to avoid code repetition; import a regex if necessary.
#}}}
syntax match vim9SpecFile /%%\d\+\|%<\%([^ \t<>]*>\)\@!\|%%</ nextgroup=vim9SpecFileMod
syntax match vim9SpecFileMod /\%(:[phtreS]\)\+/ contained

# Lower Priority Comments: after some vim commands... {{{1

# Warning: Do *not* use the `display` argument here.

# We need  to assert  the presence  of whitespace before  the comment  leader to
# prevent matching some part of an autoload variable.
#     foo = script#autoload_variable
#                 ^----------------^
#                 that's not a comment
syntax match vim9Comment /\_s\@1<=#.*$/ contains=@vim9CommentGroup
syntax match vim9CommentContinuation /#\\ /hs=s+1 contained
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

syntax match vim9CtrlChar /[\x01-\x08\x0b\x0f-\x1f]/

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
syntax match vim9CommentTitle /#\s*\u\%(\w\|[()]\)*\%(\s\+\u\w*\)*:/hs=s+1
    \ contained
    \ contains=@vim9CommentGroup

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

syntax keyword vim9Todo FIXME NOTE TODO contained
syntax cluster vim9CommentGroup contains=
    \ @Spell,
    \ vim9CommentContinuation,
    \ vim9CommentTitle,
    \ vim9Todo

# Fenced Languages  {{{1

# NOTE: This block uses string interpolation which requires patch 8.2.4883
# Warning: Make sure not to use a variable name already used in an import.{{{
#
# For example, ATM, we already use `lang`:
#
#     import 'vim9Language.vim' as lang
#                                  ^--^
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

        syntax include @vim9{language}Script syntax/{language}.vim

        syntax match vim9{language}Cmd /\<{cmd_pat}\>/ contained nextgroup=vim9{language}CmdRegion skipwhite
        syntax region vim9{language}CmdRegion
            \ matchgroup=vim9ScriptDelim
            \ start=/<<\s*\z(\S\+\)$/
            \ end=/^\z1$/
            \ matchgroup=vim9Error
            \ end=/^\s\+\z1$/
            \ contained
            \ contains=@vim9{language}Script
            \ keepend
        syntax region vim9{language}CmdRegion
            \ matchgroup=vim9ScriptDelim
            \ start=/<<$/
            \ end=/\.$/
            \ contained
            \ contains=@vim9{language}Script
            \ keepend

        syntax match vim9{language}Do /\<{do_pat}\>/ contained nextgroup=vim9{language}DoLine skipwhite
        syntax match vim9{language}DoLine /\S.*/ contained contains=@vim9{language}Script

        syntax cluster vim9CanBeAtStartOfLine add=vim9{language}Cmd,vim9{language}Do

        highlight default link vim9{language}Cmd vim9GenericCmd
        highlight default link vim9{language}Do vim9GenericCmd
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
syntax match vim9StrictWhitespace /\s\+\ze,/ contained containedin=vim9Dict,vim9ListSlice display

#     [a, b ; c] = ...
#          ^
#          ✘
#
#     [a, b;c] = ...
#          ^
#          ✘
syntax match vim9StrictWhitespace /\s\+\ze;\|;\ze\S/ contained containedin=vim9ListSlice display

#     var l = [1,2]
#               ^
#               ✘
#
#     var d = {a: 1,b: 2}
#                  ^
#                  ✘
syntax match vim9StrictWhitespace /,\ze\S/ contained containedin=vim9Dict,vim9ListSlice display

#     var d = {'a' :1, 'b' :2}
#                 ^       ^
#                 ✘       ✘
syntax match vim9StrictWhitespace /\s\+\ze:[^ \t\]]/ contained containedin=vim9Dict display

#     var d = {a:1, b:2}
#               ^    ^
#               ✘    ✘
syntax match vim9StrictWhitespace /\S\@1<=:\S\@=/ contained containedin=vim9Dict display
    # `\S:\S` *might* be valid when it matches the start of a scoped variable.
    # Don't highlight its colon as an error then.
    # Why not just `\h`?{{{
    #
    # An explicit scope is not necessarily followed by an identifier:
    #
    #     var d = {key: g:}
    #                     ^
    #}}}
    syntax match vim9StrictWhitespaceScopedVar
        \ /\%(\<[bgstvw]\)\@1<=:\%(\h\|\_s\|[,;}\]]\)\@=/
        \ contained
        \ containedin=vim9Dict
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
syntax keyword vim9DeprecatedLet let contained

# In legacy Vim script, a literal dictionary starts with `#{`.
# This syntax is no longer valid in Vim9.
syntax match vim9DeprecatedDictLiteralLegacy /#{{\@!/ containedin=vim9ListSlice display

# the scopes `a:`, `l:` and `s:` are no longer valid
# Don't use `contained` to limit these rules to `@vim9Expr`.{{{
#
# Because then, they would fail to match this:
#
#     let a:name = ...
#         ^^
#}}}
syntax match vim9DeprecatedScopes /\<[as]:\w\@=/ display
syntax match vim9DeprecatedScopes /&\@1<!\<l:\h\@=/ display

# The `is#` operator worked in legacy, but didn't make sense.
# It's no longer supported in Vim9.
syntax match vim9DeprecatedIsOperator /\C\<\%(is\|isnot\)[#?]/ contained containedin=vim9Oper display

syntax match vim9LegacyDotEqual /\s\.\%(=\s\)\@=/hs=s+1 display

syntax match vim9LegacyVarArgs /a:000/ display

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
    syntax region vim9SpaceExtraAfterFuncname
        \ matchgroup=vim9Error
        \ start=/\s\+(/
        \ matchgroup=vim9ParenSep
        \ end=/)/
        \ contains=@vim9OperGroup
        \ contained
        \ display

    #           ✘
    #           v
    #     Func(1,2)
    #     Func(1, 2)
    #            ^
    #            ✔
    syntax match vim9SpaceMissingBetweenArgs /,\S\@=/ contained display

    #           ✘
    #           v
    #     Func(1 , 2)
    #     Func(1, 2)
    #           ^
    #           ✔
    syntax match vim9SpaceExtraBetweenArgs /\s\@1<=,/ contained display

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
    syntax match vim9SpaceMissingListSlice /[^ \t[]\@1<=:/ contained display
    # If a colon is not followed with a space, it's an error.
    syntax match vim9SpaceMissingListSlice /:[^ \t\]]\@=/ contained display
    # Corner Case: A colon can be used in a variable name.  Ignore it.{{{
    #
    #     b:name
    #      ^
    #      ✔
    #}}}
    # Order: Out of these 3 rules, this one must come last.
    execute 'syntax match vim9ColonForVariableScope'
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
    syntax match vim9NumberOctalWarn /\%(\d'\|\.\)\@2<!\<0[0-7]\+\>/he=s+1
        \ nextgroup=vim9Comment
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

    syntax match vim9RangeMissingSpace /\S\@1<=\a/ contained display
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

# Some names cannot be used for variables, because they're reserved:{{{
#
#     var true = 0
#     var null = ''
#     var this = []
#     ...
#}}}
syntax keyword vim9ReservedNames true false null this super contained
#}}}1
# Synchronize (speed) {{{1

# Need to define a pattern to sync on.{{{
#
# It doesn't need to match anything meaningful.
# It just needs to exist so that Vim searches back for something.
# This is useful – for example – when a heredoc is displayed from the middle
# (i.e. its first text line is above the first screen line).
#}}}
syntax sync match vim9Sync grouphere NONE /^dummy pattern$/
# Don't look more than 60 lines back when looking for a pattern to sync on.
syntax sync maxlines=60
#}}}1
# OOP {{{1

# Let's keep this section at the very end so that `HighlightUserTypes()` works properly.
# The latter calls `synstack()` which needs the syntax to have been fully set.

syntax cluster vim9OOP contains=
    \ vim9Abstract,
    \ vim9Class,
    \ vim9Enum,
    \ vim9Interface,
    \ vim9Public,
    \ vim9Static,
    \ vim9This,
    \ vim9UserType

# :class
# :endclass
syntax keyword vim9Class class endclass contained nextgroup=vim9ClassName skipwhite
highlight default link vim9Class Keyword

#           vvv
#     class Foo
#     endclass
syntax match vim9ClassName /\u\w*/ contained nextgroup=vim9Extends,vim9Implements,vim9Specifies skipwhite
#                          v------v           vvv
#     class Foo implements Bar, Baz specifies Qux
syntax match vim9InterfaceName /\u\w*\%(,\s\+\u\w*\)\=/
    \ contained
    \ nextgroup=vim9Extends,vim9Implements,vim9Specifies,vim9StrictWhitespace
    \ skipwhite

syntax keyword vim9Extends extends contained nextgroup=vim9ClassName skipwhite
syntax keyword vim9Implements implements contained nextgroup=vim9InterfaceName skipwhite
syntax keyword vim9Specifies specifies contained nextgroup=vim9InterfaceName skipwhite
highlight default link vim9Extends Keyword
highlight default link vim9Implements Keyword
highlight default link vim9Specifies Keyword

# :interface
# :endinterface
syntax keyword vim9Interface interface endinterface contained nextgroup=vim9InterfaceName skipwhite
highlight default link vim9Interface Keyword

# this
syntax match vim9This /\<this\.\@=/ containedin=vim9FuncSignature,vim9OperParen
highlight default link vim9This Structure

# public
# static
# public static
syntax keyword vim9Public public contained nextgroup=vim9Static skipwhite
syntax keyword vim9Static static contained
highlight default link vim9Public vim9Declare
highlight default link vim9Static vim9Declare

# abstract
syntax keyword vim9Abstract abstract contained nextgroup=vim9Class skipwhite
highlight default link vim9Abstract Special

# :enum
# :endenum
syntax region vim9Enum matchgroup=Type start=/\<enum\>\s\+\u\w*/ end=/^\s*\<endenum\>/

# :type
syntax keyword vim9UserType type contained nextgroup=vim9UserTypeName skipwhite
syntax match vim9UserTypeName /\u\w*/ contained nextgroup=@vim9DataTypeCluster skipwhite
highlight default link vim9UserType Type

if get(g:, 'vim9_syntax', {})
 ->get('user_types', false)
    HighlightUserTypes()
    autocmd_add([{
        cmd: 'HighlightUserTypes()',
        event: 'BufWritePost',
        group: 'vim9HighlightUserTypes',
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

highlight default link vim9GenericCmd Statement
# Make Vim highlight user commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we  want them  to be  bold, so  that we  can't conflate  a user
# command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     highlight default link vim9UserCmdExe vim9GenericCmd
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that when the syntax item  for `vim9UserCmdExe` was defined earlier (with
# a `:syntax` command), Vim has automatically created a highlight group with the
# same name; but it's cleared:
#
#     vim9UserCmdExe      xxx cleared
#
# That's why we need the `->get('cleared')`.
#}}}
if hlget('vim9UserCmdExe')->get(0, {})->get('cleared')
    Derive('vim9FuncCallUser', 'Function', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
    Derive('vim9UserCmdExe', 'vim9GenericCmd', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
    Derive('vim9FuncHeader', 'Function', {gui: {bold: true}, term: {bold: true}, cterm: {bold: true}})
    Derive('vim9CmdModifier', 'vim9GenericCmd', {gui: {italic: true}, term: {italic: true}, cterm: {italic: true}})
endif

highlight default link vim9Error Error

highlight default link vim9AutocmdEventBadCase vim9Error
highlight default link vim9CollationClassErr vim9Error
highlight default link vim9DeclareError vim9Error
highlight default link vim9DefBangError vim9Error
highlight default link vim9DeprecatedDictLiteralLegacy vim9Error
highlight default link vim9DeprecatedIsOperator vim9Error
highlight default link vim9DeprecatedLet vim9Error
highlight default link vim9DeprecatedScopes vim9Error
highlight default link vim9DictMayBeLiteralKey vim9Error
highlight default link vim9DigraphsCharsInvalid vim9Error
highlight default link vim9FTError vim9Error
highlight default link vim9IncrementError vim9Error
highlight default link vim9LambdaDictMissingParen vim9Error
highlight default link vim9LegacyAutoloadInvalid vim9Error
highlight default link vim9LegacyConcatInvalid vim9Error
highlight default link vim9LegacyDotEqual vim9Error
highlight default link vim9LegacyFuncArgs vim9Error
highlight default link vim9LegacyVarArgs vim9Error
highlight default link vim9MapModErr vim9Error
highlight default link vim9MarkCmdArgInvalid vim9Error
highlight default link vim9NoWhitespaceBeforeInit vim9Error
highlight default link vim9NumberOctalWarn vim9Error
highlight default link vim9OperError vim9Error
highlight default link vim9PatSepErr vim9Error
highlight default link vim9ProfileSubCmdInvalid vim9Error
highlight default link vim9RangeMissingSpace vim9Error
highlight default link vim9RangeMissingSpecifier1 vim9Error
highlight default link vim9RangeMissingSpecifier2 vim9Error
highlight default link vim9ReservedNames vim9Error
highlight default link vim9SIUB vim9Error
highlight default link vim9SetEqualError vim9Error
highlight default link vim9SpaceAfterFuncHeader vim9Error
highlight default link vim9SpaceAfterLegacyFuncHeader vim9Error
highlight default link vim9SpaceExtraBetweenArgs vim9Error
highlight default link vim9SpaceMissingBetweenArgs vim9Error
highlight default link vim9SpaceMissingListSlice vim9Error
highlight default link vim9StrictWhitespace vim9Error
highlight default link vim9SubstFlagErr vim9Error
highlight default link vim9SynCaseError vim9Error
highlight default link vim9SynCaseError vim9Error
highlight default link vim9SynError vim9Error
highlight default link vim9SyncError vim9Error
highlight default link vim9UserCmdAttrError vim9Error
highlight default link vim9WincmdArgInvalid vim9Error

highlight default link vim9AbbrevCmd vim9GenericCmd
highlight default link vim9Augroup vim9GenericCmd
highlight default link vim9AugroupNameEnd Title
highlight default link vim9Autocmd vim9GenericCmd
highlight default link vim9AutocmdAllEvents vim9AutocmdEventGoodCase
highlight default link vim9AutocmdEventGoodCase Type
highlight default link vim9AutocmdGroup vim9AugroupNameEnd
highlight default link vim9AutocmdMod Special
highlight default link vim9AutocmdPat vim9String
highlight default link vim9BacktickExpansion vim9ShellCmd
highlight default link vim9BangCmd vim9GenericCmd
highlight default link vim9BangLastShellCmd Special
highlight default link vim9BangShellCmd vim9ShellCmd
highlight default link vim9Bool Boolean
highlight default link vim9BracketKey Delimiter
highlight default link vim9BracketNotation Special
highlight default link vim9BreakContinue vim9Repeat
highlight default link vim9Cd vim9GenericCmd
highlight default link vim9Comment Comment
highlight default link vim9CommentContinuation vim9Continuation
highlight default link vim9CommentTitle PreProc
highlight default link vim9Conditional Conditional
highlight default link vim9Continuation Special
highlight default link vim9ContinuationBeforeCmd vim9Continuation
highlight default link vim9ContinuationBeforeUserCmd vim9Continuation
highlight default link vim9CopyMove vim9GenericCmd
highlight default link vim9CtrlChar SpecialChar
highlight default link vim9Declare Identifier
highlight default link vim9DeclareHereDoc vim9Declare
highlight default link vim9DeclareHereDocStop vim9Declare
highlight default link vim9DefKey Keyword
highlight default link vim9DictIsLiteralKey String
highlight default link vim9DigraphsChars vim9String
highlight default link vim9DigraphsCmd vim9GenericCmd
highlight default link vim9DigraphsNumber vim9Number
highlight default link vim9DoCmds vim9Repeat
highlight default link vim9Doautocmd vim9GenericCmd
highlight default link vim9EchoHL vim9GenericCmd
highlight default link vim9EchoHLNone vim9Group
highlight default link vim9EvalExpr vim9OperAssign
highlight default link vim9ExSpecialCharacters vim9BracketNotation
highlight default link vim9Export vim9Import
highlight default link vim9FTCmd vim9GenericCmd
highlight default link vim9FTOption vim9SynType
highlight default link vim9Finish vim9Return
highlight default link vim9FuncArgs Identifier
highlight default link vim9FuncEnd vim9DefKey
highlight default link vim9Global vim9GenericCmd
highlight default link vim9GlobalPat vim9String
highlight default link vim9Group Type
highlight default link vim9GroupAdd vim9SynOption
highlight default link vim9GroupName vim9Group
highlight default link vim9GroupRem vim9SynOption
highlight default link vim9GroupSpecial Special
highlight default link vim9HLGroup vim9Group
highlight default link vim9HereDoc vim9String
highlight default link vim9HiAttr PreProc
highlight default link vim9HiCterm vim9HiTerm
highlight default link vim9HiCtermFgBg vim9HiTerm
highlight default link vim9HiCtermul vim9HiTerm
highlight default link vim9HiEqual vim9OperAssign
highlight default link vim9HiFgBgAttr vim9HiAttr
highlight default link vim9HiGroup vim9GroupName
highlight default link vim9HiGui vim9HiTerm
highlight default link vim9HiGuiFgBg vim9HiTerm
highlight default link vim9HiGuiFont vim9HiTerm
highlight default link vim9HiGuiRgb vim9Number
highlight default link vim9HiNumber Number
highlight default link vim9HiStartStop vim9HiTerm
highlight default link vim9HiTerm Type
highlight default link vim9Highlight vim9GenericCmd
highlight default link vim9Import Include
highlight default link vim9ImportAs vim9Import
highlight default link vim9ImportedScript vim9String
highlight default link vim9Increment vim9Oper
highlight default link vim9IsOption PreProc
highlight default link vim9IskSep Delimiter
highlight default link vim9LambdaArgs vim9FuncArgs
highlight default link vim9LambdaArrow vim9Sep
highlight default link vim9LegacyComment vim9Comment
highlight default link vim9LegacyString vim9String
highlight default link vim9Line12MissingColon vim9Error
highlight default link vim9Map vim9GenericCmd
highlight default link vim9MapMod vim9BracketKey
highlight default link vim9MapModExpr vim9MapMod
highlight default link vim9MapModKey Special
highlight default link vim9MarkCmd vim9GenericCmd
highlight default link vim9MarkCmdArg Special
highlight default link vim9MatchComment vim9Comment
highlight default link vim9None Constant
highlight default link vim9Norm vim9GenericCmd
highlight default link vim9NormCmds String
highlight default link vim9NotPatSep vim9String
highlight default link vim9Null Constant
highlight default link vim9Number Number
highlight default link vim9Oper Operator
highlight default link vim9OperAssign Identifier
highlight default link vim9OptionSigil vim9IsOption
highlight default link vim9ParenSep Delimiter
highlight default link vim9PatSep SpecialChar
highlight default link vim9PatSepR vim9PatSep
highlight default link vim9PatSepZ vim9PatSep
highlight default link vim9ProfileCmd vim9GenericCmd
highlight default link vim9ProfilePat vim9String
highlight default link vim9RangeMark Special
highlight default link vim9RangeNumber Number
highlight default link vim9RangeOffset Number
highlight default link vim9RangePattern String
highlight default link vim9RangePatternBwdDelim Delimiter
highlight default link vim9RangePatternFwdDelim Delimiter
highlight default link vim9RangeSpecialSpecifier Special
highlight default link vim9Repeat Repeat
highlight default link vim9RepeatForDeclareName vim9Declare
highlight default link vim9RepeatForIn vim9Repeat
highlight default link vim9Return vim9DefKey
highlight default link vim9SILB vim9String
highlight default link vim9ScriptDelim vim9DeclareHereDoc
highlight default link vim9Sep Delimiter
highlight default link vim9Set vim9GenericCmd
highlight default link vim9SetBracketEqual vim9OperAssign
highlight default link vim9SetBracketKeycode vim9String
highlight default link vim9SetEqual vim9OperAssign
highlight default link vim9SetMod vim9IsOption
highlight default link vim9SetNumberValue Number
highlight default link vim9SetSep Delimiter
highlight default link vim9SetStringValue String
highlight default link vim9ShellCmd PreProc
highlight default link vim9SpecFile Identifier
highlight default link vim9SpecFileMod vim9SpecFile
highlight default link vim9String String
highlight default link vim9StringInterpolated vim9String
highlight default link vim9Subst vim9GenericCmd
highlight default link vim9SubstDelim Delimiter
highlight default link vim9SubstFlags Special
highlight default link vim9SubstPat vim9String
highlight default link vim9SubstRep vim9String
highlight default link vim9SubstSubstr SpecialChar
highlight default link vim9SubstTwoBS vim9String
highlight default link vim9SynCase Type
highlight default link vim9SynContains vim9SynOption
highlight default link vim9SynContinuePattern String
highlight default link vim9SynEqual vim9OperAssign
highlight default link vim9SynEqualMatchGroup vim9OperAssign
highlight default link vim9SynEqualRegion vim9OperAssign
highlight default link vim9SynExeCmd vim9GenericCmd
highlight default link vim9SynExeGroupName vim9GroupName
highlight default link vim9SynExeType vim9SynType
highlight default link vim9SynKeyContainedin vim9SynContains
highlight default link vim9SynKeyOpt vim9SynOption
highlight default link vim9SynMatchOpt vim9SynOption
highlight default link vim9SynMatchgroup vim9SynOption
highlight default link vim9SynNextgroup vim9SynOption
highlight default link vim9SynNotPatRange vim9SynRegPat
highlight default link vim9SynOption Special
highlight default link vim9SynPatRange vim9String
highlight default link vim9SynRegOpt vim9SynOption
highlight default link vim9SynRegPat vim9String
highlight default link vim9SynRegStartSkipEnd Type
highlight default link vim9SynType Type
highlight default link vim9SyncC Type
highlight default link vim9SyncGroup vim9GroupName
highlight default link vim9SyncGroupName vim9GroupName
highlight default link vim9SyncKey Type
highlight default link vim9SyncNone Type
highlight default link vim9Syntax vim9GenericCmd
highlight default link vim9Todo Todo
highlight default link vim9TryCatch Exception
highlight default link vim9TryCatchPattern String
highlight default link vim9TryCatchPatternDelim Delimiter
highlight default link vim9Unmap vim9Map
highlight default link vim9UserCmdAttrAddress vim9String
highlight default link vim9UserCmdAttrAddress vim9String
highlight default link vim9UserCmdAttrComma vim9Sep
highlight default link vim9UserCmdAttrComplete vim9String
highlight default link vim9UserCmdAttrEqual vim9OperAssign
highlight default link vim9UserCmdAttrErrorValue vim9Error
highlight default link vim9UserCmdAttrName Type
highlight default link vim9UserCmdAttrNargs vim9String
highlight default link vim9UserCmdAttrNargsNumber vim9Number
highlight default link vim9UserCmdAttrRange vim9String
highlight default link vim9UserCmdDef Statement
highlight default link vim9UserCmdLhs vim9UserCmdExe
highlight default link vim9UserCmdRhsEscapeSeq vim9BracketNotation
highlight default link vim9VimGrep vim9GenericCmd
highlight default link vim9VimGrepPat vim9String
highlight default link vim9Wincmd vim9GenericCmd
highlight default link vim9WincmdArg vim9String

if get(g:, 'vim9_syntax', {})
 ->get('builtin_functions', true)
    highlight default link vim9FuncNameBuiltin Function
endif

if get(g:, 'vim9_syntax', {})
 ->get('data_types', true)
    highlight default link vim9DataType Type
    highlight default link vim9DataTypeCast vim9DataType
    highlight default link vim9ValidSubType vim9DataType
endif
#}}}1

b:current_syntax = 'vim9'
