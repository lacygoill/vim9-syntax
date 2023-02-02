Syntax plugin for Vim9.  Work in progress.

---

The highlighting can be controlled via keys in the dictionary `g:vim9_syntax`:

   - `builtin_functions` controls whether builtin functions are highlighted (`true` by default)
   - `data_types` controls whether Vim9 data types in declarations are highlighted (`true` by default)
   - `user_types` controls whether user types are highlighted (`:help :type`; `false` by default)
   - `errors` controls whether some possible mistakes are highlighted
   - `fenced_languages` is a list of languages which should be highlighted with their own syntax when included inside fenced codeblocks (empty list by default)

`g:vim9_syntax.errors` is a nested dictionary containing these keys:

   - `event_wrong_case` controls whether names of events in autocmds are highlighted as errors, if they don't have the same case as in the help (`false` by default)
   - `octal_missing_o_prefix` controls whether an octal number prefixed with `0` instead of `0o` is highlighted as an error (`false` by default)
   - `range_missing_space` controls whether no space between a line specifier and a command is highlighted as an error (`false` by default)
   - `range_missing_specifier` controls whether an implicit line specifier is highlighted as an error (`false` by default)
   - `strict_whitespace` controls whether missing/superfluous whitespace is highlighted as an error (`true` by default)

Example of configuration:

    g:vim9_syntax = {
       builtin_functions: true,
       data_types: false,
       user_types: false,
       fenced_languages: ['lua', 'python'],
       errors: {
           event_wrong_case: false,
           octal_missing_o_prefix: false,
           range_missing_space: false,
           range_missing_specifier: false,
           strict_whitespace: true,
       }
    }
