;;; asciidoc-ts-mode.el --- Major mode for AsciiDoc markup -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Dunaevskii Maxim

;; Author: Dunaevskii M. <dunmaksim@yandex.ru>
;; Maintainer: Dunaevskii M. <dunmaksim@yandex.ru>
;; Created: October 30, 2024
;; Version: 0.0.1-alpha
;; Package-Requires: ((emacs "27.1"))
;; Keywords: files
;; URL: https://github.com/dunmaksim/asciidoc-mode/

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See the README.adoc file for details.

;;; Code:

(require 'treesit)
(require 'faces)
(require 'font-lock)
(require 'subr-x)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-end "treesit.c")
(declare-function treesit-node-type "treesit.c")

(defvar asciidoc-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\( "." table)
    (modify-syntax-entry ?\( "." table)
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table)
  "Syntax table for `asciidoc-ts-mode'.")

(defvar asciidoc-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   ;; Titles
   :language 'asciidoc
   :feature 'heading
   :override t
   '([
      ((block_macro (target) @font-lock-builtin-face))
      ((block_macro_attr) @font-lock-string-face)
      ((block_macro_name) @font-lock-constant-face)
      ((block_title (line)) @font-lock-doc-face)
      ((document_title) @font-lock-keyword-face)
      ((document_attr (attr_name)) @font-lock-builtin-face)
      ((open_block_marker) @font-lock-delimiter-face)
      ((ordered_list_marker (list_marker_dot)) @success)
      ((ordered_list_marker (list_marker_digit)) @success)
      ((unordered_list_marker (list_marker_star)) @success)
      ((unordered_list_marker (list_marker_hyphen)) @success)
      ((title1) @font-lock-keyword-face)
      ((title2) @font-lock-keyword-face)
      ((title3) @font-lock-keyword-face)
      ((title4) @font-lock-keyword-face)
      ])

   :language 'asciidoc
   :feature 'comment
   :override t
   '(((line_comment) @font-lock-comment-face)
     ((block_comment) @font-lock-comment-face))

   :language 'asciidoc-inline
   :feature 'delimiter
   '(["[" "]" "{" "}" "(" ")"] @font-lock-bracket-face)
   )
  "Tree-sitter font-lock settings for `asciidoc-ts-mode'.")

;;;###autoload
(define-derived-mode asciidoc-ts-mode text-mode "🌳 ASCIIDOC"
  "Major mode for editing AsciiDoc, powered by tree-sitter."
  :group 'asciidoc
  :syntax-table asciidoc-ts-mode--syntax-table

  (when (and
         (treesit-ready-p 'asciidoc)
         (treesit-ready-p 'asciidoc-inline))
    (progn
      (treesit-parser-create 'asciidoc-inline)
      (treesit-parser-create 'asciidoc)

      ;; Comments.
      (setq-local comment-start "// ")
      (setq-local comment-end "")

      ;; Indentation
      (setq-local indent-tabs-mode nil)

      ;; Font-lock.
      (setq-local treesit-font-lock-level 4) ;; All features
      (setq-local treesit-font-lock-settings asciidoc-ts-mode--font-lock-settings)
      (setq-local treesit-font-lock-feature-list
                  '((delimiter)
                    (comment)
                    (heading)))

      (treesit-major-mode-setup))))

(if (treesit-ready-p 'asciidoc)
    (add-to-list 'auto-mode-alist '("\\.adoc\\'" . asciidoc-ts-mode)))

(provide 'asciidoc-ts-mode)

;;; asciidoc-ts-mode.el ends here
