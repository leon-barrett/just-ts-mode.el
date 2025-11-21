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
     ;; In a recipe, indent by just-ts-indent-offset.
     (,#'just-ts-indent-in-recipe-body column-0 just-ts-indent-offset))))

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
  (just-ts-setup)

  ;; Imenu
  (setq-local imenu-generic-expression
              '(("setting" "^set +\\([A-Z_a-z][0-9A-Z_a-z-]*\\)\\(?:\\'\\|$\\| \\|:=\\)" 1)
                ("variable" "^\\(?:export +\\)?\\([A-Z_a-z][0-9A-Z_a-z-]*\\) *:=" 1)
                ("task" "^\\(?:alias +\\)?@?\\([A-Z_a-z][0-9A-Z_a-z-]*\\).*:[^=]" 1)))

  (local-set-key (kbd "C-c '") #'just-src-edit))



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

;;; Task body editing

(defvar just-src-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-s") #'just-src-edit-save)
    (define-key map (kbd "C-c '") #'just-src-edit-sync-and-exit)
    (define-key map (kbd "C-c C-k") #'just-src-edit-abort)
    map)
  "Keymap for `just-src-edit-mode'.")

(define-minor-mode just-src-edit-mode
  "Minor mode for editing Just task bodies."
  :init-value nil
  :lighter " Just-Edit"
  :keymap just-src-edit-mode-map)

(defvar-local just-src-edit--original-buffer nil)
(put 'just-src-edit--original-buffer 'permanent-local t)

(defvar-local just-src-edit--beg-marker nil)
(put 'just-src-edit--beg-marker 'permanent-local t)

(defvar-local just-src-edit--end-marker nil)
(put 'just-src-edit--end-marker 'permanent-local t)

(defvar-local just-src-edit--indentation nil)
(put 'just-src-edit--indentation 'permanent-local t)

(defvar-local just-src-edit--task-name nil)
(put 'just-src-edit--task-name 'permanent-local t)

(defun just-src-edit--find-task-bounds ()
  "Find the bounds of the task at point.
Returns (task-name body-start body-end) or nil if not in a task."
  (save-excursion
    (let ((start-pos (point))
          (task-regexp "^@?\\([A-Z_a-z][0-9A-Z_a-z-]*\\).*:[^=]")
          task-name body-start body-end)

      ;; Find the task we're currently in using the same regex as imenu
      ;; Go back to find a task line
      (while (and (not (bobp))
                  (not (looking-at task-regexp)))
        (forward-line -1))

      ;; Task line found
      (when (looking-at task-regexp)
        (setq task-name (match-string 1))
        (setq body-start (line-beginning-position 2))

        ;; Find the next line with no indentation (column 0)
        (forward-line 1)
        (while (and (not (eobp))
                    (not (and (not (looking-at "^\\s-*$")) ; not empty line
                              (looking-at "^[^ \t\n]"))))  ; starts at column 0
          (forward-line 1))

        ;; Go back to find the last non-empty line before the unindented line
        (forward-line -1)
        (while (and (> (point) body-start)
                    (looking-at "^\\s-*$"))
          (forward-line -1))
        (setq body-end (line-end-position))

        ;; Ensure body-end is at least at body-start
        (when (<= body-end body-start)
          (setq body-end (save-excursion
                           (goto-char body-start)
                           (line-end-position))))

        ;; Check if original point was within the task body
        (when (and (>= start-pos body-start)
                   (<= start-pos body-end))
          (list task-name body-start body-end))))))

(defun just-src-edit--calculate-indentation (start end)
  "Calculate the common indentation for task body between START and END."
  (save-excursion
    (goto-char start)
    (let ((min-indent most-positive-fixnum))
      (while (< (point) end)
        (when (not (looking-at "^\\s-*$"))  ; skip empty lines
          (setq min-indent (min min-indent (current-indentation))))
        (forward-line 1))
      (if (= min-indent most-positive-fixnum) 0 min-indent))))

(defun just-src-edit--remove-indentation (content indentation)
  "Remove INDENTATION spaces from each line of CONTENT."
  (let ((lines (split-string content "\n")))
    (mapconcat
     (lambda (line)
       (if (string-match-p "^\\s-*$" line)
           line
         (if (and (>= (length line) indentation)
                  (string-prefix-p (make-string indentation ?\s) line))
             (substring line indentation)
           line)))
     lines
     "\n")))

(defun just-src-edit--add-indentation (content indentation)
  "Add INDENTATION spaces to each line of CONTENT."
  (let ((lines (split-string content "\n"))
        (indent-str (make-string indentation ?\s)))
    (mapconcat
     (lambda (line)
       (if (string-match-p "^\\s-*$" line)
           line
         (concat indent-str line)))
     lines
     "\n")))

(defun just-src-edit ()
  "Edit the task body at point in a dedicated buffer."
  (interactive)
  (let ((task-info (just-src-edit--find-task-bounds)))
    (unless task-info
      (user-error "Not in a task body"))

    (let* ((task-name (nth 0 task-info))
           (body-start (nth 1 task-info))
           (body-end (nth 2 task-info))
           (original-buffer (current-buffer))
           (indentation (just-src-edit--calculate-indentation body-start body-end))
           (content (buffer-substring-no-properties body-start body-end))
           (clean-content (just-src-edit--remove-indentation content indentation))
           (edit-buffer (generate-new-buffer (format "*Just Task: %s*" task-name))))

      ;; Switch to edit buffer
      (pop-to-buffer edit-buffer)

      ;; Insert content and set up buffer
      (insert clean-content)
      (goto-char (point-min))

      ;; Ensure buffer ends with newline
      (goto-char (point-max))
      (unless (and (> (point-max) (point-min))
                   (= (char-before) ?\n))
        (insert "\n"))
      (goto-char (point-min))

      ;; Detect and set appropriate mode
      (if (string-match "^#!" clean-content)
          (normal-mode)
        (sh-mode))

      ;; Set up buffer-local variables
      (setq just-src-edit--original-buffer original-buffer)
      (setq just-src-edit--beg-marker (with-current-buffer original-buffer
                                        (copy-marker body-start)))
      (setq just-src-edit--end-marker (with-current-buffer original-buffer
                                        (copy-marker body-end t)))
      (setq just-src-edit--indentation indentation)
      (setq just-src-edit--task-name task-name)

      ;; Enable the minor mode for keybindings
      (just-src-edit-mode 1)

      ;; Show helpful message
      (message "Edit task '%s'. %s" task-name (just-src-edit--describe-bindings)))))

(defun just-src-edit--describe-bindings ()
  "Return a string describing the current key bindings for just-src-edit-mode."
  (let ((sync-key (substitute-command-keys "\\[just-src-edit-sync-and-exit]"))
        (save-key (substitute-command-keys "\\[just-src-edit-save]"))
        (abort-key (substitute-command-keys "\\[just-src-edit-abort]")))
    (format "%s to sync and exit, %s to save, %s to abort"
            sync-key save-key abort-key)))

(defun just-src-edit-save ()
  "Save the edited task back to the original buffer and file."
  (interactive)
  (just-src-edit--sync-to-original t))

(defun just-src-edit-sync-and-exit ()
  "Sync changes to original buffer and exit edit buffer."
  (interactive)
  (just-src-edit--sync-to-original nil)
  (quit-window t)
  (message "Synced changes to original buffer"))

(defun just-src-edit-abort ()
  "Abort editing without saving changes."
  (interactive)
  (quit-window t))

(defun just-src-edit--sync-to-original (save-file)
  "Sync the edited content back to the original buffer.
If SAVE-FILE is non-nil, also save the original buffer."
  (unless (and just-src-edit--original-buffer
               (buffer-live-p just-src-edit--original-buffer))
    (error "Original buffer no longer exists"))

  (let ((content (string-trim-right (buffer-string) "\n+"))
        (original-buf just-src-edit--original-buffer)
        (beg just-src-edit--beg-marker)
        (end just-src-edit--end-marker)
        (indent just-src-edit--indentation))

    (with-current-buffer original-buf
      (save-excursion
        (let ((indented-content (just-src-edit--add-indentation content indent)))
          (goto-char beg)
          (delete-region beg end)
          (insert indented-content)
          (set-marker end (point))))

      (when save-file
        (save-buffer)))

    (set-buffer-modified-p nil)))


(provide 'just-ts-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("/\\(?:\\.\\)?[jJ][uU][sS][tT][fF][iI][lL][eE]\\'" . just-ts-mode))

;;; just-ts-mode.el ends here
