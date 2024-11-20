;;; asciidoc-mode.el --- Major mode for AsciiDoc files -*- lexical-binding: t; -*-

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


(defconst asciidoc--regexp-header-1
  ;; = Header 1
  (rx line-start
      "="
      space
      (one-or-more any)
      line-end)
  "Regexp for headers level 1.")

(defconst asciidoc--regexp-header-2
  ;; == Header 2
  (rx line-start
      "=="
      space
      (one-or-more any)
      line-end)
  "Regexp for headers level 2.")


(defconst asciidoc--regexp-header-3
  ;; === Header 3
  (rx line-start
      "==="
      space
      (one-or-more any)
      line-end)
  "Regexp for headers level 3.")


(defconst asciidoc--regexp-header-4
  ;; ==== Header 4
  (rx line-start
      "===="
      space
      (one-or-more any)
      line-end)
  "Regexp for headers level 4.")


(defconst asciidoc--regexp-header-5
  ;; ===== Header 5
  (rx line-start
      "====="
      space
      (one-or-more any)
      line-end)
  "Regexp for headers level 5.")


(defconst asciidoc--regexp-header-6
  ;; ===== Header 6
  (rx line-start
      "======"
      space
      (one-or-more any)
      line-end)
  "Regexp for headers level 6.")


(defconst asciidoc--regexp-bold
  ;; *bold text*
  (rx "*"
      (minimal-match (one-or-more any))
      "*")
  "Regexp for bold text.")


(defconst asciidoc--regexp-emphasis
  ;; _emphasis_
  (rx "_"
      (one-or-more any)
      "_")
  "Regexp for emphasis text.")


(defconst asciidoc--regexp-inline-code
  ;; Text `code` text
  (rx "`"
      (minimal-match (one-or-more any))
      "`")
  "Regexp for inline code block.")


(defconst asciidoc--regexp-footnote
  ;; Textfootnote:[Footnote text.]
  (rx (group "footnote")
      (group ":")
      (group "[")
      (group (one-or-more any))
      (group "]"))
  "Regexp for footnote.")

(defconst asciidoc--regexp-kbd
  ;; kbd:[C-c C-v]
  (rx (group "kbd")
      (group ":")
      (group "[")
      (group (one-or-more any))
      (group "]"))
  "Regexp for kbd macros.")


(defconst asciidoc--regexp-note-one-line
  ;; NOTE: Text
  (rx line-start
      (group "NOTE")
      (group ":")
      (one-or-more any)
      line-end)
  "Regexp for one line note.")

(defconst asciidoc--regexp-note-multi-line
  ;; [NOTE]
  ;; ====
  ;; Text
  ;; ====
  (rx
   (group line-start "[NOTE]" line-end)
   (group line-start "====" line-end)
   (group zero-or-more any line-end)
   (group line-start "====" line-end))
  "Regexp for multi line note.")


(defconst asciidoc--regexp-id
  ;; [#id]
  (rx line-start
      "["
      (one-or-more any)
      "]"
      line-end)
  "Regexp for identifiers.")

(defconst asciidoc--regexp-comment-block
  ;; ////
  ;; Commentary
  ;; ////
  (rx line-start
      (repeat 4 "/")
      line-end

      line-start
      any
      line-end

      line-start
      (repeat 4 "/")
      line-end)
  "Regexp for block comment.")


;; Keywords and syntax highlightning
(defvar asciidoc--font-lock-keywords
  `((,asciidoc--regexp-header-1 . asciidoc-face-header-1)
    (,asciidoc--regexp-header-2 . asciidoc-face-header-2)
    (,asciidoc--regexp-header-3 . asciidoc-face-header-3)
    (,asciidoc--regexp-header-4 . asciidoc-face-header-4)
    (,asciidoc--regexp-header-5 . asciidoc-face-header-5)
    (,asciidoc--regexp-header-6 . asciidoc-face-header-6)

    ;; Text styles
    (,asciidoc--regexp-bold . asciidoc-face-bold)
    (,asciidoc--regexp-emphasis . asciidoc-face-emphasis)
    (,asciidoc--regexp-inline-code . asciidoc-face-inline-code)

    ;; Footnote
    (,asciidoc--regexp-footnote
     (1 'asciidoc-face-footnote)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-bracket)
     (4 'asciidoc-face-footnote-text)
     (5 'asciidoc-face-bracket))

    ;; kbd:[Text]
    ;;  │ ││ │  └─ 5
    ;;  │ ││ └──── 4
    ;;  │ │└────── 3
    ;;  │ └─────── 2
    ;;  └───────── 1
    (,asciidoc--regexp-kbd
     (1 'asciidoc-face-kbd)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-bracket)
     (4 'asciidoc-face-kbd-text)
     (5 'asciidoc-face-bracket))

    ;; One line note
    ;; NOTE: Text
    ;; │   └──── 2
    ;; └──────── 1
    (,asciidoc--regexp-note-one-line
     (1 'asciidoc-face-note)
     (2 'asciidoc-face-punctuation))

    ;; Multiline note
    ;; [NOTE] ── 1
    ;; ==== ──── 2
    ;; Text
    ;; ==== ──── 3
    (,asciidoc--regexp-note-multi-line
     (1 'asciidoc-face-note)
     (2 'asciidoc-face-punctuation)
     (3 'asciidoc-face-punctuation))

    (,asciidoc--regexp-id . asciidoc-face-id)
    (,asciidoc--regexp-comment-block . asciidoc-face-comment)

    ) "Default font lock for keywords.")

(defun asciidoc-font-lock-mark-block-function ()
  "Function for marking inline code blocks."
  ;; TODO: взято из `adoc-mode.el'.
  ;; Надо понять, что тут вообще происходит.
  (mark-paragraph 2)
  (forward-paragraph -1))


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
  (setq-local font-lock-defaults
              '(asciidoc--font-lock-keywords
                nil
                nil
                nil
                nil
                (font-lock-mark-block-function . asciidoc-font-lock-mark-block-function))))


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.adoc\\'" . asciidoc-mode))


(provide 'asciidoc-mode)

;;; asciidoc-mode.el ends here
