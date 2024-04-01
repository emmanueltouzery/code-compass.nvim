# code-compass.nvim

## Description

A set of functions to navigate code without LSP.

Code Compass leverages `tree-sitter`, `ripgrep` and [https://ast-grep.github.io/](ast-grep) (which is also tree-sitter based) to offer "go to definition" and "find references" code navigation features.

If multiple candidates are found, the list will open in `telescope.nvim` to allow you to preview them and pick one.

You can install `ast-grep` using [https://github.com/williamboman/mason.nvim](mason.nvim).

A "naive" implementation could support all languages and have results similar to tags-based implementations, but we're trying to be more ambitious.

We have language-specific support to try to get as much context as possible. Compared to a LSP, we obviously don't have a type-checker, and might give up on some advanced constructs that might be possible to discriminate against with tree-sitter. But compared to a tags-based approach, this should be much better (including support for local variables, not only global ones) and would not require re-generating tags on a regular basis.

The plugin is meant for developers working occasionally with other languages and therefore not willing to set up a LSP for them, and for languages where the LSP is complex to set up (java for instance).

The supported languages currently are:

- java

Adding a language is not trivial because we're really trying to offer as good support as possible, for instance we'll try to resolve `this` if possible, if you use `this.var` and there is a field `var` and a variable `var` we'll know to jump to the field.

References will also list and allow you to filter on the type of reference, for instance inheritance, instantiation, method reference and so on.

The performance is very good thanks to ripgrep pre-filtering the files for `ast-grep`, and then `ast-grep` being very optimised itself. I've tested this on larger codebases without performance issues.

## Installation

The plugin depends upon:

- `telescope.nvim`
- `tree-sitter` being enabled for the language
- `ast-grep` being installed on the system (`mason.nvim` can be used for that)
- `ripgrep` being installed on the system
- `nvim-treesitter`

## How to use

Two functions are exported:

- `require('code_compass').find_definition()` -- find the definition of the symbol under the cursor
- `require('code_compass').find_references()` -- find code references to the symbol under the cursor

Note that a third function, `run_tests` is also exported, meant for diagnostics and developers.
