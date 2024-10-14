# just-ts-mode.el - Emacs mode for justfiles using Tree-Sitter

This Emacs mode does basic highlighting and indentation for justfiles, as used
by [just](https://github.com/casey/just), using a Tree-Sitter grammar from
[tree-sitter-just](https://github.com/IndianBoy42/tree-sitter-just).

# Features

This mode provides the following features for editing Justfiles:

- [x] Syntax highlighting
- [x] Basic indentation
- [x] Formatting via `just-ts-format-buffer`
- [x] Commenting
- [ ] imenu

# Installation

`just-ts-mode` requires Emacs 29.1 or newer for Tree-Sitter support. If you haven't
installed Tree-Sitter yet, please read [How to Get Started with Tree-Sitter -
Mastering
Emacs](https://www.masteringemacs.org/article/how-to-get-started-tree-sitter).

`just-ts-mode` can be installed through [MELPA](https://melpa.org/#/just-ts-mode).

## Grammar installation

This uses the justfile Tree-Sitter grammar from
[tree-sitter-just](https://github.com/IndianBoy42/tree-sitter-just).

The following Elisp code can be used to install the Justfile language parser. This requires some tools -- notably a compiler toolchain -- to be available on your machine.

``` emacs-lisp
(require 'just-ts-mode)
(just-ts-mode-install-grammar)
```

# Usage

Edit a file named `Justfile`. It will have highlighting and indentation.

# Comparison to `just-mode`

There is an existing major mode for Justfiles that does not require tree-sitter,
called [just-mode](https://stable.melpa.org/#/just-mode). It has worse syntax
highlighting, with issues like [poor highlighting of
comments](https://github.com/leon-barrett/just-mode.el/issues/11).

# License

`just-ts-mode` is licensed under the GPL3 license. Please see file `LICENSE` for
its text.
