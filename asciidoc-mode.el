;;; asciidoc-mode.el --- Major mode for AsciiDoc files -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Dunaevskii Maxim

;; Author: Dunaevskii M. <dunmaksim@yandex.ru>
;; Maintainer: Dunaevskii M. <dunmaksim@yandex.ru>
;; Created: October 30, 2024
;; Version: 0.0.1-alpha
;; Package-Requires: ((emacs "27.1"))
;; Keywords: AsciiDoc
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

;; See the README.md file for details.

;;; Code:

(require 'faces)
(require 'font-lock)
(require 'rx)
(require 'asciidoc-faces)

(defconst asciidoc-package-version "0.0.1-alpha")

(defun asciidoc-version ()
  "Return a package `asciidoc-mode.el' version."
  (interactive)
  (message (format "asciidoc-mode version: %s" asciidoc-package-version)))


(defgroup asciidoc nil "Support for AsciiDoc documents."
  :group 'text
  :version asciidoc-package-version
  :link '(url-link "https://docs.asciidoctor.org/"))


(defcustom asciidoc-mode-hook nil
  "Hook run when `asciddoc-mode' is turned on.
The hook for `text-mode' is run before this one."
  :group 'asciidoc
  :type '(hook))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SYNTAX TABLE
(defvar asciidoc-mode-syntax-table
  (let ((st (copy-syntax-table text-mode-syntax-table)))
    (modify-syntax-entry ?$ "." st)
    (modify-syntax-entry ?% "." st)
    (modify-syntax-entry ?& "." st)
    (modify-syntax-entry ?' "." st)
    (modify-syntax-entry ?` "\"`  " st)
    (modify-syntax-entry ?* "\"*  " st)
    (modify-syntax-entry ?+ "." st)
    (modify-syntax-entry ?- "." st)
    (modify-syntax-entry ?/ "." st)
    (modify-syntax-entry ?< "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?> "." st)
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?_ "." st)
    (modify-syntax-entry ?| "." st)
    (modify-syntax-entry ?« "." st)
    (modify-syntax-entry ?» "." st)
    (modify-syntax-entry ?‘ "." st)
    (modify-syntax-entry ?’ "." st)
    (modify-syntax-entry ?“ "." st)
    (modify-syntax-entry ?” "." st)
    st)
  "Syntax table used while in `asciidoc-mode'.")

(defvar asciidoc--font-lock-keywords
  '(("^= .+$" . asciidoc-face-header-1)
    ("^== .+$" . asciidoc-face-header-2)
    ("^=== .+$" . asciidoc-face-header-3)
    ("^==== .+$" . asciidoc-face-header-4)
    ("^===== .+$" . asciidoc-face-header-5)
    ("^====== .+$" . asciidoc-face-header-6)
    ("\\*.+\\*" . asciidoc-face-bold)
    ("_.+_" . asciidoc-face-emphasis)
    ("`.+`" . asciidoc-face-inline-code)

    ;; footnote:[Text]
    ;; 1 - footnote
    ;; 2 - :
    ;; 3 - [
    ;; 4 - Text
    ;; 5 - ]
    ("\\(footnote\\)\\(:\\)\\(\\[\\)\\(.+\\)\\(\\]\\)"
     (1 'asciidoc-face-footnote)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-bracket)
     (4 'asciidoc-face-footnote-text)
     (5 'asciidoc-face-bracket))

    ;; NOTE: Text
    ;; 1 - NOTE
    ;; 2 - :
    ("^\\(NOTE\\)\\(:\\) .+$"
     (1 'asciidoc-face-note)
     (2 'asciidoc-face-punctuation))

    ;; [NOTE]
    ;; 1 - [
    ;; 2 - NOTE
    ;; 3 - ]
    ("^\\(\\[\\)\\(NOTE\\)\\(\\]\\)$"
     (1 'asciidoc-face-bracket)
     (2 'asciidoc-face-note)
     (3 'asciidoc-face-bracket))

    ;; TIP: Text
    ;; 1 - TIP
    ;; 2 - :
    ;; 3 -  Text
    ("^\\(TIP\\)\\(:\\)\\( .+\\)$"
     (1 'asciidoc-face-tip)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-default))

    ;; [TIP]
    ;; 1 - [
    ;; 2 - TIP
    ;; 3 - ]
    ("^\\(\\[\\)\\(TIP\\)\\(\\]\\)$"
     (1 'asciidoc-face-bracket)
     (2 'asciidoc-face-tip)
     (3 'asciidoc-face-bracket))

    ;; IMPORTANT: Text
    ;; 1 - IMPORTANT
    ;; 2 - :
    ;; 3 -  Text
    ("^\\(IMPORTANT\\)\\(:\\)\\( .+\\)$"
     (1 'asciidoc-face-important)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-default))

    ;; [IMPORTANT]
    ;; 1 - [
    ;; 2 - IMPORTANT
    ;; 3 -]
    ("^\\(\\[\\)\\(IMPORTANT\\)\\(\\]\\)$"
     (1 'asciidoc-face-bracket)
     (2 'asciidoc-face-important)
     (3 'asciidoc-face-bracket))

    ;; CAUTION: Text
    ;; 1 - CAUTION
    ;; 2 - :
    ;; 3 - Text
    ("^\\(CAUTION\\)\\(:\\)\\( .+\\)$"
     (1 'asciidoc-face-caution)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-default))

    ;; [CAUTION]
    ;; 1 - [
    ;; 2 - CAUTION
    ;; 3 -]
    ("^\\(\\[\\)\\(CAUTION\\)\\(\\]\\)$"
     (1 'asciidoc-face-bracket)
     (2 'asciidoc-face-caution)
     (3 'asciidoc-face-bracket))

    ;; WARNING: Text
    ;; 1 - WARNING
    ;; 2 - :
    ;; 3 -  Text
    ("^\\(WARNING\\)\\(:\\)\\( .+\\)$"
     (1 'asciidoc-face-warning)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-default))

    ;; [WARNING]
    ;; 1 - [
    ;; 2 - WARNING
    ;; 3 -]
    ("^\\(\\[\\)\\(WARNING\\)\\(\\]\\)$"
     (1 'asciidoc-face-bracket)
     (2 'asciidoc-face-warning)
     (3 'asciidoc-face-bracket))

    ;; kbd:[C-x C-c]
    ;; 1 - kbd
    ;; 2 - :
    ;; 3 - [
    ;; 4 - C-x C-c
    ;; 5 - ]
    ("\\(kbd\\)\\(:\\)\\(\\[\\)\\(.+\\)\\(\\]\\)"
     (1 'asciidoc-face-kbd)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-bracket)
     (4 'asciidoc-face-kbd-text)
     (5 'asciidoc-face-bracket))

    ;; Block macro
    ;; name::value[text]
    ;; 1 - name
    ;; 2 - ::
    ;; 3 - value
    ;; 4 - [
    ;; 5 - text
    ;; 6 - ]
    ("^\\(.+\\)\\(::\\)\\(.+\\)\\(\\[\\)\\(.*\\)\\(\\]\\)"
     (1 'asciidoc-face-macro-name)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-text)
     (4 'asciidoc-face-bracket)
     (5 'asciidoc-face-macro-value)
     (6 'asciidoc-face-bracket))

    ;; Block comment:
    ;; 1. //// - comment delimiter
    ;; 2. Commentary - commentary
    ;; 3. //// - comment delimiter
    ("^\\(////\n\\)\\(.+\n\\)\\(////\\)$"
     (1 'asciidoc-face-comment-delimiter)
     (2 'asciidoc-face-comment)
     (3 'asciidoc-face-comment-delimiter))

    ;; One line commentary
    ;; // Commentary
    ("^//.*$" asciidoc-face-comment)

    ;; ID:
    ;; [#id]
    ;; 1 - [
    ;; 2 - #id
    ;; 3 - ]
    ("^\\(\\[\\)\\(#.+\\)\\(\\]\\)"
     (1 'asciidoc-face-bracket)
     (2 'asciidoc-face-id)
     (3 'asciidoc-face-bracket))

    ;; Unordered list items
    ;; * List item
    ;; ** List item (level 2)
    ;;
    ;; 1 - *
    ;; 2 -  List item
    ("^\\(\\*+\\)\\( .+\\)"
     (1 'asciidoc-face-punctuation)
     (2 'asciidoc-face-default))

    ;; Ordered list items
    ;; . List item
    ;; 1 - .
    ;; 2 -  List item
    ("^\\(\\.+\\)\\( .+\\)"
     (1 'asciidoc-face-punctuation)
     (2 'asciidoc-face-default))

    ;; Description
    ;; Text::
    ;; 1 - Text
    ;; 2 - :: (2 or more colon)
    ("^\\(.+\\)\\(:::*\\)$"
     (1 'asciidoc-face-description)
     (2 'asciidoc-face-punctuation))
    )
  "Default `font-lock-keywords' for `asciidoc-mode'.")

;;;###autoload
  (define-derived-mode asciidoc-mode text-mode "AsciiDoc"
    "Major mode for editing AsciiDoc documents.

Turning on `asciidoc-mode' calls the normal hooks `text-mode-hook'
and `asciidoc-mode-hook'.  This mode also support font-lock
highlighting."
    :syntax-table asciidoc-mode-syntax-table
    :group 'asciidoc
    (setq-local comment-start "//")
    (setq-local indent-tabs-mode nil)

    ;; Font lock.
    (setq-local font-lock-defaults '(asciidoc--font-lock-keywords t nil nil nil)))


;;;###autoload
  (add-to-list 'auto-mode-alist '("\\.adoc\\'" . asciidoc-mode))


  (provide 'asciidoc-mode)

;;; asciidoc-mode.el ends here
