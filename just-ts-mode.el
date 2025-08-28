;;; just-ts-mode.el --- Justfile editing mode -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Sony Corporation of America and Leon Barrett

;; Author: Leon Barrett (leon@barrettnexus.com)
;; Maintainer: Leon Barrett (leon@barrettnexus.com)
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: files languages tools treesitter
;; URL: https://github.com/leon-barrett/just-ts-mode.el

;; This file is *NOT* part of GNU Emacs.

;; This package is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this package.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing justfiles, as defined by the tool "just"
;; (https://github.com/casey/just), powered by a tree-sitter parser provided by
;; https://github.com/IndianBoy42/tree-sitter-just .
;;
;; Install the needed tree-sitter grammar by running
;; "just-ts-mode-install-grammar".

;;; Code:



;; NOTE: This depends on Emacs 29.1 for treesitter.

(require 'prog-mode)
(require 'treesit)

;; TODO Use nested modes for rule bodies so e.g. we can have Python mode for a Python script?

(defgroup just-ts nil
  "Mode \"just-ts-mode\" is a major mode for editing just files."
  :group 'languages
  :prefix "just-ts-"
  :link '(url-link :tag "Site" "https://github.com/leon-barrett/just-ts-mode.el")
  :link '(url-link :tag "Repository" "https://github.com/leon-barrett/just-ts-mode.el"))

(defconst just-ts-builtin-functions
  ;; Built-in functions from https://github.com/casey/just/blob/9f03441eef28fd662b33a8f1961e2ee97b60f7ff/src/function.rs#L22
  '("absolute_path"
    "arch"
    "capitalize"
    "clean"
    "env_var"
    "env_var_or_default"
    "error"
    "extension"
    "file_name"
    "file_stem"
    "invocation_directory"
    "invocation_directory_native"
    "join"
    "just_executable"
    "justfile"
    "justfile_directory"
    "kebabcase"
    "lowercamelcase"
    "lowercase"
    "os"
    "os_family"
    "parent_directory"
    "path_exists"
    "quote"
    "replace"
    "replace_regex"
    "sha256"
    "sha256_file"
    "shoutykebabcase"
    "shoutysnakecase"
    "snakecase"
    "titlecase"
    "trim"
    "trim_end"
    "trim_end_match"
    "trim_end_matches"
    "trim_start"
    "trim_start_match"
    "trim_start_matches"
    "uppercamelcase"
    "uppercase"
    "uuid"
    "without_extension"))

(defconst just-ts-builtin-function-regex
  (regexp-opt just-ts-builtin-functions))

(defcustom just-ts-executable "just"
  "Location of just executable."
  :type 'file
  :group 'just
  :safe 'stringp)

(defun just-ts-format-buffer ()
  "Formats your buffer containing justfile."
  (interactive)
  (let ((exit-code (call-process just-ts-executable nil nil nil "--unstable" "--fmt")))
    (if (eq exit-code 0)
        (revert-buffer :ignore-auto :noconfirm)
        (message "Formatted")
      (message "Format failed with exit code %s" exit-code))))

(defconst just-ts-keywords
  ;; Keywords from https://github.com/casey/just/blob/4f31853835afcd8d511fccf7b2b6680f6a628446/GRAMMAR.md
  '["alias"
    "export"
    "set"
    "import"
    "mod"
    "if"
    "else"])

(defconst just-ts-settings
  ;; Settings from https://github.com/casey/just/blob/4f31853835afcd8d511fccf7b2b6680f6a628446/GRAMMAR.md
  '("allow-duplicate-recipes"
    "allow-duplicate-variables"
    "dotenv-filename"
    "dotenv-load"
    "dotenv-path"
    "dotenv-required"
    "export"
    "fallback"
    "ignore-comments"
    "positional-arguments"
    "script-interpreter"
    "quiet"
    "shell"
    "tempdir"
    "unstable"
    "windows-powershell"
    "windows-shell"
    "working-directory"))

(defconst just-ts-setting-regex
  (regexp-opt just-ts-settings))

(defvar just-ts-font-lock-rules
  `(:language just
    :feature comment
    ((comment) @font-lock-comment-face)

    :language just
    :feature keyword
    ;; ((["set" "alias" "export" "if" "else" "import" "export" "shell" "&&" "mod"] @font-lock-keyword-face))
    ((,just-ts-keywords @font-lock-keyword-face))

    :language just
    :feature builtin
    ((boolean) @font-lock-builtin-face)

    :language just
    :feature string
    ((string) @font-lock-string-face)

    :language just
    :feature string-interpolation
    ((external_command) @font-lock-preprocessor-face)

    :language just
    :feature string-interpolation
    ((interpolation) @font-lock-preprocessor-face)

    :language just
    :feature definition
    ((module name: (identifier) @font-lock-function-name-face))

    :language just
    :feature definition
    ((recipe_header "@"* @font-lock-function-name-face name: (identifier) @font-lock-function-name-face))

    :language just
    :feature variable
    ((parameter name: (identifier) @font-lock-variable-name-face))

    :language just
    :feature variable
    ((dependency name: (identifier) @font-lock-function-call-face))

    :language just
    :feature variable
    ((dependency_expression name: (identifier) @font-lock-function-call-face))

    :language just
    :feature assignment
    ((alias left: (identifier) @font-lock-function-name-face) right: (identifier) @font-lock-function-call-face)

    :language just
    :feature assignment
    ((assignment left: (identifier) @font-lock-variable-name-face))

    :language just
    :feature assignment
    ((setting "shell" @font-lock-keyword-face))

    :language just
    :feature assignment
    ((setting left: (identifier) @font-lock-keyword-face
              (:match ,just-ts-setting-regex @font-lock-keyword-face)))

    :language just
    :feature assignment
    ((setting left: (identifier) @font-lock-variable-name-face))

    :language just
    :feature variable
    ((function_call name: (identifier) @font-lock-keyword-face
                    (:match ,just-ts-builtin-function-regex @font-lock-keyword-face)))

    :language just
    :feature variable
    ((function_call name: (identifier) @font-lock-function-call-face))

    :language just
    :feature variable
    ((attribute) @font-lock-variable-name-face)

    :language just
    :feature shebang
    ((shebang) @font-lock-preprocessor-face)))

;; from https://www.emacswiki.org/emacs/BackspaceWhitespaceToTabStop
;; (which is licensed GPL 2 or later)
(defvar just-ts-indent-offset 4 "Justfile indentation offset.")
(defun just-ts-backspace-whitespace-to-tab-stop ()
  "Delete whitespace backwards to the next tab-stop, or delete one text char."
  (interactive)
  (if (or indent-tabs-mode
          (region-active-p)
          (save-excursion
            (> (point) (progn (back-to-indentation)
                              (point)))))
      (call-interactively #'backward-delete-char-untabify)
    (let ((movement (% (current-column) just-ts-indent-offset))
          (p (point)))
      (when (= movement 0) (setq movement just-ts-indent-offset))
      ;; Account for edge case near beginning of buffer
      (setq movement (min (- p 1) movement))
      (save-match-data
        (if (string-match "[^\t ]*\\([\t ]+\\)$" (buffer-substring-no-properties (- p movement) p))
            (delete-char (- (match-beginning 1) (match-end 1)))
          (call-interactively #'backward-delete-char))))))

(defun just-ts-indent-in-recipe-body (_node _parent _bol)
    "Identify if the cursor is in a recipe body.

Identify if BOL is at a recipe body start, where PARENT is the file and NODE is
nil for some reason."
    (save-excursion
      (forward-line -1)
      (let* ((prev-line-node (treesit-node-at (pos-bol)))
             (prev-line-parent (treesit-node-parent prev-line-node))
             (prev-line-gp-type (treesit-node-type (treesit-node-parent prev-line-parent)))
             (prev-line-type (treesit-node-type prev-line-parent)))
        (or
         ;; The next line after the header
         (equal prev-line-type "recipe_header")
         ;; The next line after a recipe line
         (equal prev-line-type "recipe_line")
         ;; The next line after a prefixed line e.g. starting with "@"
         (equal prev-line-gp-type "recipe_line")))))

(defvar just-ts-indent-rules
  `((just
     ;; In a recipe, indent by tab-width.
     (,#'just-ts-indent-in-recipe-body column-0 tab-width))))

(defun just-ts-setup ()
  "Set up treesit for \"just-ts-mode\"."
  (setq-local comment-start "#")
  (setq-local treesit-font-lock-feature-list
              '((comment builtin keyword string string-interpolation)
                (definition assignment shebang)
                (variable)))
  (setq-local treesit-font-lock-settings
              (apply #'treesit-font-lock-rules
                     just-ts-font-lock-rules))
  (setq-local treesit-simple-indent-rules just-ts-indent-rules)

  (treesit-major-mode-setup))

;;;###autoload
(define-derived-mode just-ts-mode prog-mode "Justfile[ts]"
  "Major mode for editing standard Justfiles using treesitter."

  (unless (treesit-ready-p 'just)
    (error "Tree-Sitter for `just' isn't available"))

  (treesit-parser-create 'just)
  (just-ts-setup))



;; Language grammar installation

(defconst just-ts-mode-treesit-language-source
  '(just "https://github.com/IndianBoy42/tree-sitter-just" "main" "src")
  "The language source entry for the associated Justfile language parser.")

(defun just-ts-mode-install-grammar ()
  "Install the language grammar for `just-ts-mode'.

The function removes existing entries for the Just language in
`treesit-language-source-alist' and adds the entry stored in
`just-ts-mode-treesit-language-source'."
  (interactive)
  ;; Remove existing entries
  (setq treesit-language-source-alist
        (assq-delete-all 'just treesit-language-source-alist))
  ;; Add the correct entry
  (add-to-list 'treesit-language-source-alist
               just-ts-mode-treesit-language-source)
  ;; Install the grammar
  (treesit-install-language-grammar 'just))



(provide 'just-ts-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("/\\(?:\\.\\)?[jJ][uU][sS][tT][fF][iI][lL][eE]\\'" . just-ts-mode))

;;; just-ts-mode.el ends here
