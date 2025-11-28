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
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    table)
  "Syntax table for `asciidoc-ts-mode'.")

(defvar h0-line-query)
(setq h0-line-query '(document_title (title_h0_marker) (line)))

(defvar asciidoc-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   ;; Titles
   :language 'asciidoc
   :feature 'title
   :override t
   '([((document_title) @success)
      ((title1) @warning)
      ((title2) @warning)
      ((title3) @warning)
      ((title4) @error)
      ((title5) @error)])

   ;; Macro
   :language 'asciidoc
   :feature 'macro
   :override t
   '([((block_macro_attr) @font-lock-string-face)
      ((block_macro_name) @font-lock-constant-face)
      ((block_title (line)) @font-lock-doc-face)
      ((document_attr (attr_name)) @font-lock-builtin-face)
      ((document_attr (line)) @font-lock-string-face)
      ((open_block_marker) @success)
      ((admonition) @success)
      ((listing_block) @fixed-pitch)])

   :language 'asciidoc
   :feature 'lists
   '(([((ordered_list_marker (list_marker_dot)))
       ((ordered_list_marker (list_marker_digit)))
       ((unordered_list_marker (list_marker_star)))
       ((unordered_list_marker (list_marker_hyphen)))
       ] @font-lock-keyword-face))

   :language 'asciidoc
   :feature 'comment
   :override t
   '([(block_comment)
      (line_comment)] @font-lock-comment-face)

   :language 'asciidoc-inline
   :feature 'macro-inline
   '(([
       ((macro_name) @font-lock-constant-face)
       ((inline_macro (attr)) @font-lock-string-face)
       ]))

   ;; Markup
   :language 'asciidoc-inline
   :feature 'markup
   :override t
   '(((emphasis ("**")) @bold)
     ((emphasis ("*")) @bold)
     ((ltalic ("_")) @italic)
     ((ltalic ("__")) @italic)
     ((monospace ("`")) @font-lock-constant-face)
     ((monospace ("``")) @font-lock-constant-face))

   :language 'asciidoc
   :feature 'error
   :override t
   '([(ERROR)
      (MISSING)] @font-lock-warning-face)
   )
  "Tree-sitter font-lock settings for `asciidoc-ts-mode'.")

(defun asciidoc-ts-imenu-node-p (node)
  "Check if NODE is a valid entry to imenu."
  (equal (treesit-node-type (treesit-node-parent node))
         "document_title"))

(defun asciidoc-ts-imenu-name-function (node)
  "Return an imenu entry if NODE is a valid header."
  (let ((name (treesit-node-text node)))
    (if (asciidoc-ts-imenu-node-p node)
        (thread-first (treesit-node-parent node)(treesit-node-text))
      name)))

;;;###autoload
(define-derived-mode asciidoc-ts-mode text-mode "AsciiDoc[TS]"
  "Major mode for editing AsciiDoc, powered by tree-sitter."
  :group 'asciidoc
  :syntax-table asciidoc-ts-mode--syntax-table

  (when (and
         (treesit-ready-p 'asciidoc-inline)
         (treesit-ready-p 'asciidoc))
    (progn
      (treesit-parser-create 'asciidoc-inline)
      (treesit-parser-create 'asciidoc)

      ;; Comments.
      (setq-local comment-start "// ")
      (setq-local comment-end "")

      ;; Indentation
      (setq-local indent-tabs-mode nil)

      ;; IMenu
      (setq-local treesit-simple-imenu-settings
                  `(("Headings" asciidoc-ts-imenu-node-p nil asciidoc-ts-imenu-name-function)))

      ;; Font-lock.
      (setq-local treesit-font-lock-level 3) ;; All features
      (setq-local treesit-font-lock-settings asciidoc-ts-mode--font-lock-settings)
      (setq-local treesit-font-lock-feature-list
                  '(;; Level 1
                    (title lists comment)
                    ;; Level 2
                    (macro paragraph-inline macro-inline markup)
                    ;; Level 3
                    ()
                    ;; Level 4
                    (error)))

      (treesit-major-mode-setup))))

(if (treesit-ready-p 'asciidoc)
    (add-to-list 'auto-mode-alist '("\\.adoc\\'" . asciidoc-ts-mode)))

(provide 'asciidoc-ts-mode)

;;; asciidoc-ts-mode.el ends here
