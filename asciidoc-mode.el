;;; asciidoc-mode.el --- Major mode for AsciiDoc markup -*- lexical-binding: t; -*-

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

(require 'text-mode)
(require 'font-lock)
(require 'faces)

(eval-when-compile
  (require 'rx))


;;; REGEXP
(defconst asciidoc--header-level-0-regexp
  (rx line-start
      (group (or "=" "#")
             (one-or-more blank)
             (one-or-more not-newline))
      line-end)
  "Regexp for headers level 0.

= Header level 0
# Header level 0")

(defconst asciidoc--header-level-1-regexp
  (rx line-start
      (group (repeat 2 (or "=" "#"))
             (one-or-more blank)
             (one-or-more not-newline)
             line-end))
  "Regexp for headers level 1.

== Header level 1
## Header level 1")

(defconst asciidoc--header-level-2-regexp
  (rx line-start
      (group (repeat 3 (or "=" "#"))
             (one-or-more blank)
             (one-or-more not-newline)
             line-end))
  "Regexp for headers level 2.

=== Header level 2
### Header level 2")

(defconst asciidoc--header-level-3-regexp
  (rx line-start
      (group (repeat 4 (or "=" "#"))
             (one-or-more blank)
             (one-or-more not-newline)
             line-end))
  "Regexp for headers level 3.

==== Header level 3
#### Header level 3")

(defconst asciidoc--header-level-4-regexp
  (rx line-start
      (group (repeat 5 (or "=" "#"))
             (one-or-more blank)
             (one-or-more not-newline)
             line-end))
  "Regexp for headers level 4.

===== Header level 4
##### Header level 4")

(defconst asciidoc--header-level-5-regexp
  (rx line-start
      (group (repeat 6 (or "=" "#"))
             (one-or-more blank)
             (one-or-more not-newline)
             line-end))
  "Regexp for headers level 5.

====== Header level 5
###### Header level 5")


(defconst asciidoc--kbd-regexp
  (rx (group "kbd")
      ":"
      "["
      (group (one-or-more (not "]")))
      "]")
  "Regexp for kbd macro.

Typical kbd:[Ctrl+Alt], and this regexp capture 2 groups:
1. kbd
2. Ctrl+Alt")


(defconst asciidoc--btn-regexp
  (rx (group "btn")
      ":"
      "["
      (group (one-or-more (not "]")))
      "]")
  "Regexp for btn macro.
Typical btn:[Open], and this regexp capture 2 groups:
1. btn
2. Open")


(defconst asciidoc--strong-unconstrained-regexp
  (rx (not "\\")
      (group (zero-or-more "["
                           (minimal-match (one-or-more any))
                           "]"))
      (group "**"
             (minimal-match (one-or-more any))
             "**"))
  "Regexp for unconstrained **strong** (bold) text.
**I am bold**
[class='data']**me too**
\**But not me**
** Not me too
VS Code AsciiDoc: (?<!\\\\\\\\)(\\[.+?\\])?((\\*\\*)(.+?)(\\*\\*))")


(defconst asciidoc--strong-constrained-regexp
  (rx (not (in "\\" ";" ":" word "*"))
      (group (zero-or-more "["
                           (minimal-match (one-or-more any))
                           "]"))
      (group "*"
             (or (not space)
                 (seq (not space)
                      (minimal-match (zero-or-more any))
                      (not space)))
             "*")
      (not word))
  "RegExp for constrained *strong* (bold) text.
*I am bold*
[class='data']*me too*
* Not me*
VS Code AsciiDoc: (?<![\\\\;:\\p{Word}\\*])(\\[.+?\\])?((\\*)(\\S|\\S.*?\\S)(\\*)(?!\\p{Word}))
")


(defconst asciidoc--emphasis-unconstrained-regexp
  (rx (not "\\")
      (group (zero-or-more "["
                           (minimal-match (not "\\"))
                           "]"))
      (group "__"
             (minimal-match (not "_")
                            (one-or-more any))
             "__"))
  "RegExp for unconstrained emphasis (italic) text.
__I am italic__
[class='data']__me too__
\__But not me__
VS Code Asciidoc: (?<!\\\\\\\\)(\\[(?:[^\\]]+?)\\])?((__)((?!_).+?)(__))")



;;; FACES
(defgroup asciidoc nil
  "Major mode for edition AsciiDoc files."
  :prefix "asciidoc-"
  :group 'languages)


(defgroup asciidoc-faces nil "Faces used in AsciiDoc Mode."
  :group 'asciidoc
  :group 'faces
  :version "30.1")


(defface asciidoc-header-level-0-face '((t :inherit success))
  "Face for headers level 0."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-header-level-0-face 'asciidoc-header-level-0-face)


(defface asciidoc-header-level-1-face '((t :inherit success))
  "Face for headers level 1."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-header-level-1-face 'asciidoc-header-level-1-face)


(defface asciidoc-header-level-2-face '((t :inherit warning))
  "Face for headers level 2."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-header-level-2-face 'asciidoc-header-level-2-face)


(defface asciidoc-header-level-3-face '((t :inherit warning))
  "Face for headers level 3."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-header-level-3-face 'asciidoc-header-level-3-face)


(defface asciidoc-header-level-4-face '((t :inherit error))
  "Face for headers level 4."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-header-level-4-face 'asciidoc-header-level-4-face)


(defface asciidoc-header-level-5-face '((t :inherit error))
  "Face for headers level 5."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-header-level-5-face 'asciidoc-header-level-5-face)


(defface asciidoc-macro-name-face '((t :inherit font-lock-keyword-face))
  "Face for macro names."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-macro-name-face 'asciidoc-macro-name-face)


(defface asciidoc-macro-attributes-face '((t :inherit font-lock-string-face))
  "Face for macro attributes."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-macro-attributes-face 'asciidoc-macro-attributes-face)


(defface asciidoc-comment-face '((t :inherit font-lock-comment-face))
  "Face for comments."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-comment-face 'asciidoc-comment-face)


;; Admonitions:
;;
;; NOTE
;; TIP
;; IMPORTANT
;; WARNING
;; CAUTION

(defface asciidoc-note-header-face '((t :inherit font-lock-constant-face))
  "Face for NOTE keyword."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-note-header-face 'asciidoc-note-header-face)


(defface asciidoc-tip-header-face '((t :inherit success))
  "Face for TIP keyword."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-tip-header-face 'asciidoc-tip-header-face)


(defface asciidoc-important-header-face '((t :inherit warning))
  "Face for IMPORTANT keyword."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-important-header-face 'asciidoc-important-header-face)


(defface asciidoc-warning-header-face '((t :inherit warning))
  "Face for WARNING keyword."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-warning-header-face 'asciidoc-warning-header-face)


(defface asciidoc-caution-header-face '((t :inherit error))
  "Face for CAUTION keyword."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-caution-header-face 'asciidoc-caution-header-face)


(defface asciidoc-strong-face '((t :inherit bold))
  "Face for bold text."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-strong-face 'asciidoc-strong-face)


(defface asciidoc-emphasis-face '((t :inherit italic))
  "Face for italic text."
  :version "30.1"
  :group 'asciidoc-faces)

(defvar asciidoc-emphasis-face 'asciidoc-emphasis-face)


;; KEYWORDS
(defvar asciidoc-mode-font-lock-keywords
  `(;; Headers
    (,asciidoc--header-level-0-regexp . asciidoc-header-level-0-face)
    (,asciidoc--header-level-1-regexp . asciidoc-header-level-1-face)
    (,asciidoc--header-level-2-regexp . asciidoc-header-level-2-face)
    (,asciidoc--header-level-3-regexp . asciidoc-header-level-3-face)
    (,asciidoc--header-level-4-regexp . asciidoc-header-level-4-face)
    (,asciidoc--header-level-5-regexp . asciidoc-header-level-5-face)
    ;; kbd
    (,asciidoc--kbd-regexp . ((1 asciidoc-macro-name-face)
                              (2 asciidoc-macro-attributes-face)))
    ;; btn
    (,asciidoc--btn-regexp . ((1 asciidoc-macro-name-face)
                              (2 asciidoc-macro-attributes-face)))
    ;; strong / bold
    (,asciidoc--strong-unconstrained-regexp . ((1 asciidoc-macro-attributes-face)
                                               (2 asciidoc-strong-face)))
    (,asciidoc--strong-constrained-regexp . ((1 asciidoc-macro-attributes-face)
                                             (2 asciidoc-strong-face)))
    ;; emphasis / italic
    (,asciidoc--emphasis-unconstrained-regexp .((1 asciidoc-macro-attributes-face)
                                                (2 asciidoc-emphasis-face)))))


;;; SYNTAX TABLE
(defvar asciidoc-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\" "."  st) ; Prevent highlighting string in quotes
    (modify-syntax-entry ?\' "."  st) ; Prevent highlighting string in quotes
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\\ "\\" st) ; Mark backslash as escape character
    st))


;;;###autoload
(define-derived-mode asciidoc-mode text-mode "ASCII"
  "Major mode for editing AsciiDoc files."

  :group "asciidoc-mode"
  :syntax-table asciidoc-mode-syntax-table

  (font-lock-mode t)

  (setq-local comment-start "//")
  (setq-local font-lock-defaults '(asciidoc-mode-font-lock-keywords))
  (setq-local font-lock-multiline nil)
  (setq-local indent-tabs-mode nil)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local require-final-newline mode-require-final-newline))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.adoc\\'" . asciidoc-mode))

(provide 'asciidoc-mode)

;;; asciidoc-mode.el ends here
