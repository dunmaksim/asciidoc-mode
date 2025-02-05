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
    ;; Escape char is "\"
    (modify-syntax-entry ?\ "\\" st)
    ;; Space chars
    (modify-syntax-entry ?\s " " st) ;; SPACE
    (modify-syntax-entry ?\t " " st) ;; TAB
    (modify-syntax-entry ?  " " st)  ;; NON-BREACKABLE SPACE
    ;; Punctuation char
    (modify-syntax-entry ?! "." st)
    (modify-syntax-entry ?$ "." st)
    (modify-syntax-entry ?% "." st)
    (modify-syntax-entry ?& "." st)
    (modify-syntax-entry ?' "." st)
    (modify-syntax-entry ?+ "." st)
    (modify-syntax-entry ?, "." st)
    (modify-syntax-entry ?- "." st)
    (modify-syntax-entry ?. "." st)
    (modify-syntax-entry ?< "." st)
    (modify-syntax-entry ?= "." st)
    (modify-syntax-entry ?> "." st)
    (modify-syntax-entry ?? "." st)
    (modify-syntax-entry ?` "." st)
    (modify-syntax-entry ?« "." st)
    (modify-syntax-entry ?» "." st)

    ;; Words and symbols delimiters
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?– "_" st) ;; EN DASH
    (modify-syntax-entry ?— "_" st) ;; EM DASH

    ;; Paired delimiters
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")]" st)
    (modify-syntax-entry ?\{ "(}" st)
    (modify-syntax-entry ?\} "){" st)

    st)
  "Syntax table used while in `asciidoc-mode'.")


(defconst asciidoc--regexp-attribute-entry
  ;; TODO
  ;; Original regexp from AsciiDoctor.json
  ;; ^(:)(!?\\w.*?)(:)(\\p{Blank}+.+\\p{Blank}(?:\\+|\\\\))$
  (rx line-start
      line-end)
  "Regexp for attribute entry.")


(defconst asciidoc--regexp-attribute-value
  ;; TODO
  ;; Original regexp from AsciiDoctor.json
  ;; ^\\p{Blank}+.+$(?<!\\+|\\\\)|^\\p{Blank}*$
  (rx line-start line-end)
  "Regexp for attribute value.")


(defconst asciidoc--regexp-attribute-entry-definition
  ;; TODO
  ;; Original regexp from AsciiDoctor.json
  ;; ^(:)(!?\\w.*?)(:)(\\p{Blank}+(.*))?$
  (rx line-start
      line-end)
  "Regexp for attribute entry definition.")


(defconst asciidoc--regexp-block-attribute-heading
  ;; ^\\[(|\\p{Blank}*[\\p{Word}\\{,.#\"'%].*)\\]$
  (rx line-start                                       ;; ^
      "["                                              ;; \\[
      (group "|"                                       ;; |
             (zero-or-more blank)                      ;; \\p{Blank}*
             (any word "{" "," "." "#" """" "\\'" "%") ;; [\\p{Word}\\{,.#\"'%]
             (zero-or-more any))                       ;; .*
      "]"                                              ;; \\]
      line-end)                                        ;; $
  "Regexp for block attribute headers.")


(defconst asciidoc--regexp-heading-0
  ;; = Header 0
  ;; # Header 0
  ;; Original regexp from plugin for VS Code:
  ;; ^((?:=|#){1})([\\p{Blank}]+)(?=\\S+)
  ;;   │          │              └─ 3
  ;;   │          └─ 2
  ;;   └─ 1
  (rx line-start
      (group (seq (repeat 1 (or "=" "#"))
                  (one-or-more blank)
                  (zero-or-more (not space))
                  (zero-or-more any))))
  "Regexp for headers level 0.")


(defconst asciidoc--regexp-heading-1
  ;; == Header 1
  ;; ## Header 1
  ;; Original regexp from plugin for VS Code:
  ;; ^((?:=|#){2})([\\p{Blank}]+)(?=\\S+)
  ;;   │          │
  ;;   │          └─ 2
  ;;   └─ 1
  (rx line-start
      (group (seq (repeat 2 (or "=" "#"))
                  (one-or-more blank)
                  (zero-or-more (not space))
                  (zero-or-more any))))
  "Regexp for headers level 1.")


(defconst asciidoc--regexp-heading-2
  ;; === Header 2
  ;; ### Header 2
  ;; Original regexp from plugin for VS Code:
  ;; ^((?:=|#){3})([\\p{Blank}]+)(?=\\S+)
  ;;   │          │
  ;;   │          └─ 2
  ;;   └─ 1
  (rx line-start
      (group (seq (repeat 3 (or "=" "#"))
                  (one-or-more blank)
                  (zero-or-more (not space))
                  (zero-or-more any))))
  "Regexp for headers level 2.")


(defconst asciidoc--regexp-heading-3
  ;; ==== Header 3
  ;; #### Header 3
  ;; Original regexp from plugin for VS Code:
  ;; ^((?:=|#){4})([\\p{Blank}]+)(?=\\S+)
  ;;   │          │
  ;;   │          └─ 2
  ;;   └─ 1
  (rx line-start
      (group (seq (repeat 4 (or "=" "#"))
                  (one-or-more blank)
                  (zero-or-more (not space))
                  (zero-or-more any))))
  "Regexp for headers level 3.")


(defconst asciidoc--regexp-heading-4
  ;; ===== Header 4
  ;; ####= Header 4
  ;; Original regexp from plugin for VS Code:
  ;; ^((?:=|#){5})([\\p{Blank}]+)(?=\\S+)
  ;;   │          │
  ;;   │          └─ 2
  ;;   └─ 1
  (rx line-start
      (group (seq (repeat 5 (or "=" "#"))
                  (one-or-more blank)
                  (zero-or-more (not space))
                  (zero-or-more any))))
  "Regexp for headers level 4.")


(defconst asciidoc--regexp-heading-5
  ;; ====== Header 5
  ;; ###### Header 5
  ;; Original regexp from plugin for VS Code:
  ;; ^((?:=|#){6})([\\p{Blank}]+)(?=\\S+)
  ;;   │          │
  ;;   │          └─ 2
  ;;   └─ 1
  (rx line-start
      (group (seq (repeat 6 (or "=" "#"))
                  (one-or-more blank)
                  (zero-or-more (not space))
                  (zero-or-more any))))
  "Regexp for headers level 5.")


(defconst asciidoc--regexp-block-title
  ;; .Block title
  ;;
  ;; Original regexp from AsciiDoctor.json:
  ;; ^\\.([^\\p{Blank}.].*)
  (rx
   line-start ;; ^
   "."        ;; \\.
   (group
    (not (in "." blank)) ;; [^\\p{Blank}.]
    (zero-or-more any)) ;; .*
   line-end)
  "Regexp for block title.")


(defconst asciidoc--regexp-callout
  ;; <20> Callout
  ;;
  ;; Original regexp from AsciiDoctor.json:
  ;; ^(<)(\\d+)(>)\\p{Blank}+(.*)$
  (rx line-start
      (group "<") ;; (<)
      (group (one-or-more digit)) ;; (\\d+)
      (group ">") ;; (>)
      (one-or-more blank) ;; \\p{Blank}+
      (group (zero-or-more any))
      line-end)
  "Regexp for callout.")


(defconst asciidoc--regexp-strong-unconstrained
  ;; [optional properties list]**bold text**
  ;; Original regexp from AsciiDoctor.json:
  ;; (?<!\\\\\\\\)(\\[.+?\\])?((\\*\\*)(.+?)(\\*\\*))
  ;; TODO: CHECK!!!
  (rx (repeat 0 "\\\\")                          ;;  (?<!\\\\\\\\)
      (group (zero-or-more (seq "[" (one-or-more any) "]"))) ;; (\\[.+?\\])?
      (group "**")                                           ;; \\*\\*
      (group (one-or-more any)) ;; (.+?)
      (group "**"))             ;; (\\*\\*)
  "Regexp for unconstrained bold text.")


(defconst asciidoc--regexp-strong-constrained
  ;; Original regexp from AsciiDoctor.json:
  ;; (?<![\\\\;:\\p{Word}\\*])(\\[.+?\\])?((\\*)(\\S|\\S.*?\\S)(\\*)(?!\\p{Word}))
  ;; TODO
  (rx (repeat 0 (in "\\" ";" ":" word "*")) ;; (?<![\\\\;:\\p{Word}\\*])
      (group  ;; (\\[.+?\\])?
       (zero-or-more
        (seq
         "["
         (one-or-more any)
         "]")))
      (group "*") ;; (\\*)
      (group (or ;;
              (not space)
              (seq (not space)
                   (zero-or-more any)
                   (not space))))
      (group "*")
      (repeat 0 word))
  "Regexp for constrained bold text.")


(defconst asciidoc--regexp-subscript
  ;; H~2~O
  ;; Original regexp from VS Code plugin:
  ;; (?<!\\\\)(\\[.+?\\])?((~)(\\S+?)(~))
  ;;          │            │  │      └─ 4
  ;;          │            │  └─ 3
  ;;          │            └─ 2
  ;;          └─ 1
  (rx (not "\\")          ;; (?<!\\\\)
      (group              ;; [.+?]
       (zero-or-more
        (seq "["
             (one-or-more any)
             "]")))
      (group "~")
      (group (one-or-more (not space)))
      (group "~"))
  "Regexp for subscript text.")


(defconst asciidoc--regexp-superscript
  ;; E = mc^2^
  ;; Original regexp from VS Code plugin
  ;; (?<!\\\\)(\\[.+?\\])?((\\^)(\\S+?)(\\^))
  ;;          │            │    │      └─ 4
  ;;          │            │    └─ 3
  ;;          │            └─ 2
  ;;          └─ 1
  (rx (not "\\")
      (group
       (zero-or-more
        (seq "["
             (one-or-more any)
             "]")))
      (group "^")
      (group (one-or-more (not space)))
      (group "^"))
  "Regexp for superscript text.")


(defconst asciidoc--regexp-xref-reference-1
  ;; <<xref name>>
  ;; Original regexp from AsciiDoctor.json:
  ;; (?<!\\\\)(?:(<<)([\\p{Word}\":./]+,)?(.*?)(>>))
  ;; TODO: check
  (rx (repeat 0 "\\")
      (group "<<")
      (group (one-or-more (in word """" ":" "." "/")))
      (group (zero-or-more any))
      (group ">>"))
  "Regexp for <<xref>> macro.")


(defconst asciidoc--regexp-xref-reference-2
  ;; xref:[xref name]
  ;; Original regexp from AsciiDoctor.json:
  ;; (?<!\\\\)(xref:)([\\p{Word}\":.\\/].*?)(\\[) content "\\]|^$"
  ;; TODO: check
  (rx (repeat 0 "\\")
      (group "xref:")
      (group (seq (one-or-more (in word """" "." "\\" "/"))
                  (zero-or-more any)))
      (group "[") ;; (\\[)
      (group (one-or-more any)) ;; content
      (group (or "]" (seq line-start line-end)))
      )
  "Regexp for xref:[macro].")



(defconst asciidoc--regexp-emphasis
  ;; _emphasis_
  (rx
   (group "_")
   (group (one-or-more any))
   (group "_"))
  "Regexp for emphasis text.")


(defconst asciidoc--regexp-emphasis-inline
  ;; Text with emp__has__is part of word
  (rx
   (group "__")
   (group (one-or-more any))
   (group "__"))
  "Regexp for emphasis word part.")


(defconst asciidoc--regexp-monospace-unconstrained
  ;; Text ``code`` text
  ;; Regexp from AsciiDoctor.json:
  ;; (?<!\\\\)(\\[.+?\\])?((``)(.+?)(``))
  ;; TODO: check regexp
  (rx (repeat 0 "\\\\")
      (group (zero-or-more (seq "["
                                (one-or-more any)
                                "]")))
      (group (repeat 2 ?`))
      (group (one-or-more any))
      (group (repeat 2 ?`)))
  "Regexp for unconstrained inline code block.")


(defconst asciidoc--regexp-monospace-constrained
  ;; Text `code`'text
  ;; Regexp from AsciiDoctor.json:
  ;; (?<![\\\\;:\\p{Word}\"'`])(\\[.+?\\])?((`)(\\S|\\S.*?\\S)(`))(?![\\p{Word}\"'`])
  ;; TODO: check regexp
  (rx (repeat 0 (in ?\\
                    ";"
                    ":"
                    word
                    ?\"
                    "'"
                    "`"))
      (group (zero-or-more (seq "]"
                                (one-or-more any)
                                "]")))
      (group ?`)
      (group (or (not space)
                 (seq (not space)
                      (zero-or-more any)
                      (not space))))
      (group ?`)
      (repeat 0 (in word
                    ?\"
                    ?'
                    ?`)))
  "Regexp for constrained inline code block.")


;; ;; Footnotes
;; ;; Regexp from AsciiDoctor.json:
;; ;; (?<!\\\\)footnote(?:(ref):|:([\\w-]+)?)\\[(?:|(.*?[^\\\\]))\\]
;; ;;
;; ;; Syntax from AsciiDoctor Docs:
;; ;; Footnote with text without ID: footnote:[text]
;; ;; Footnote with text with ID: footnote:id[text]
;; ;; Footnote without text with ID: footnote:id[]
;; ;; TODO: FIX!
;; (defconst asciidoc--regexp-footnote
;;   ;; footnote:(ref):
;;   (rx (repeat 0 "\\")
;;       "footnote"
;;       (or
;;        ;; footnote:id[]
;;        (seq (one-or-more (in word ?-)) "[]")
;;        ;; footnote:[Text]
;;        ;; footnote:id[Text]
;;        ))
;;   "Regexp for footnote with reference.")


(defconst asciidoc--regexp-kbd
  ;; kbd:[C-c C-v]
  (rx (group "kbd")
      (group ?:)
      (group "[")
      (group (one-or-more any))
      (group "]"))
  "Regexp for kbd macros.")


(defconst asciidoc--regexp-menu-macro
  ;; menu:File[]
  ;; menu:File[Save > Save as])
  ;; Original regexp from VS Code plugin
  ;; (?<!\\\\)(menu):(\\p{Word}|\\p{Word}.*?\\S)\\[\\p{Blank}*(.+?)?\\]
  ;;          │     ││                            ││                  └─ 6
  ;;          │     ││                            │└─ 5
  ;;          │     ││                            └─ 4
  ;;          │     │└─ 3
  ;;          │     └─ 2
  ;;          └─ 1
  ;; TODO: Fix regexp
  (rx (repeat 0 "\\")   ;; ?<!\\\\
      (group "menu")    ;; (menu)
      (group ":")       ;; :
      (group (or word   ;; (\\p{Word}|\\p{Word}.*?\\S)
                 (seq word (zero-or-more any) (not space))))
      (group "[")       ;; \\[
      (group (seq (zero-or-more blank)(one-or-more any))) ;; \\p{Blank}*(.+?)
      (group "]"))      ;; ?\\]
  "Regexp for menu macro.")


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
   (group (zero-or-more any) line-end)
   (group line-start "====" line-end))
  "Regexp for multiline note.")


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


(defconst asciidoc--regexp-comment
  ;; // Commentary
  (rx line-start "//" any line-end)
  "Regexp for one line comment.")


(defconst asciidoc--regexp-include-directive
  ;; include::filename.adoc[]
  ;; Original regexp from Asciidoctor.json:
  ;; ^(include)(::)([^\\[]+)(\\[)(.*?)(\\])$
  (rx line-start                      ;; ^
      (group "include")               ;; include
      (group "::")                    ;; ::
      (group (one-or-more (not "["))) ;; ([^\\[]+)
      (group "[")                     ;; (\\[)
      (group (zero-or-more any))      ;; (.*?)
      (group "]")                     ;; (\\])
      line-end)
  "Regexp for include directive.")


(defconst asciidoc--regexp-todo-markup
  ;; * [ ] To do
  ;; * [*] To do
  ;; * [x] To do
  ;; - [ ] To do
  ;; - [*] To do
  ;; - [x] To do
  ;;
  ;; Original regexp from AsciiDoctor.json:
  ;; ^\\s*(-)\\p{Blank}(\\[[\\p{Blank}\\*x]\\])(?=\\p{Blank})
  (rx line-start
      (zero-or-more space)
      (group "-")
      blank
      (group
       "["
       (in blank "*" "x")
       "]")
      blank)
  "Regexp for todo list items.")


(defconst asciidoc--regexp-list-unordered
  ;; * item
  ;; - item
  ;; • item
  ;; Original regexp from Asciidoctor.json:
  ;; ^\\p{Blank}*(-|\\*{1,5}|\\u2022{1,5})(?=\\p{Blank})
  (rx line-start
      (zero-or-more blank)
      (group (or ?-
                 (repeat 1 5 ?*)
                 (repeat 1 5 ?•)))
      (group (not space)))
  "Regexp for unordered list.")


(defconst asciidoc--regexp-list-ordered
  ;; . Item
  ;; .. Item
  ;; a. Item
  ;; I. Item
  ;;
  ;; Original regexp from AsciiDoctor.json:
  ;; ^\\p{Blank}*(\\.{1,5}|\\d+\\.|[a-zA-Z]\\.|[IVXivx]+\\))(?=\\p{Blank})
  (rx line-start
      (zero-or-more blank)
      (or (repeat 1 5 ?.)
          (seq (one-or-more digit) ?.)
          (seq (in "a-zA-Z") ?.)
          (seq (one-or-more (in "IVXivx"))
               ?\) ))
      blank)
  "Regexp for ordered list.")


;; Keywords and syntax highlightning
(defvar asciidoc--font-lock-keywords

  `(;; TODO
    ;; (,asciidoc--regexp-attribute-entry)

    ;; TODO
    ;; (,asciidoc--regexp-attribute-value)

    ;; TODO
    ;; (,asciidoc--regexp-attribute-entry-definition)

    (,asciidoc--regexp-block-attribute-heading . asciidoc-face-block-attribute-heading)

    (,asciidoc--regexp-block-title . asciidoc-face-block-title)

    (,asciidoc--regexp-callout
     (1 'asciidoc-face-symbol-other-constant)
     (2 'asciidoc-face-numeric-constant)
     (3 'asciidoc-face-symbol-other-constant)
     (4 'asciidoc-face-inline))

    ;; - [ ] Todo
    ;; * [ ] Todo
    ;; - [x] Todo
    ;; * [x] Todo
    ;; - [*] Todo
    ;; * [*] Todo
    (,asciidoc--regexp-todo-markup
     (1 'asciidoc-face-bullet-list-markup)
     (2 'asciidoc-face-box-todo-markup))


    ;; Headers
    (,asciidoc--regexp-heading-0 . asciidoc-face-heading-level-0)
    (,asciidoc--regexp-heading-1 . asciidoc-face-heading-level-1)
    (,asciidoc--regexp-heading-2 . asciidoc-face-heading-level-2)
    (,asciidoc--regexp-heading-3 . asciidoc-face-heading-level-3)
    (,asciidoc--regexp-heading-4 . asciidoc-face-heading-level-4)
    (,asciidoc--regexp-heading-5 . asciidoc-face-heading-level-5)

    ;; Unconstrained strong (bold)
    ;; [attributes list]**Bold text**
    ;; │           │ │        └─ 4
    ;; │           │ └─ 3
    ;; │           └─ 2
    ;; └─ 1
    (,asciidoc--regexp-strong-unconstrained
     (1 'asciidoc-face-attribute-list)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-bold-markup)
     (4 'asciidoc-face-separator-punctuation))

    ;; Constrained strong (bold)
    ;; [attributes list]*Bold text*
    ;; │                ││        └─ 4
    ;; │                │└─ 3
    ;; │                └─ 2
    ;; └─ 1
    (,asciidoc--regexp-strong-constrained
     (1 'asciidoc-face-attribute-list)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-bold-markup)
     (4 'asciidoc-face-separator-punctuation))

    ;;
    (,asciidoc--regexp-emphasis
     (1 'asciidoc-face-separator-punctuation)
     (2 'asciidoc-face-emphasis)
     (3 'asciidoc-face-separator-punctuation))

    (,asciidoc--regexp-emphasis-inline
     (1 'asciidoc-face-separator-punctuation)
     (2 'asciidoc-face-emphasis)
     (3 'asciidoc-face-separator-punctuation))

    ;; Monospace
    (,asciidoc--regexp-monospace-unconstrained
     (1 'asciidoc-face-attribute-list)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-inline-code)
     (4 'asciidoc-face-separator-punctuation))

    (,asciidoc--regexp-monospace-constrained
     (1 'asciidoc-face-attribute-list)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-inline-code)
     (4 'asciidoc-face-separator-punctuation))

    ;; ;; footnote:id[Text]
    ;; ;; │       ││ ││   └─ 6
    ;; ;; │       ││ │└───── 5
    ;; ;; │       ││ └────── 4
    ;; ;; │       │└──────── 3
    ;; ;; │       └───────── 2
    ;; ;; └───────────────── 1
    ;; (,asciidoc--regexp-footnote
    ;;  (1 'asciidoc-face-footnote)
    ;;  (2 'asciidoc-face-separator-punctuation)
    ;;  (3 'asciidoc-face-id)
    ;;  (4 'asciidoc-face-bracket)
    ;;  (5 'asciidoc-face-footnote-text)
    ;;  (6 'asciidoc-face-bracket))

    ;; kbd:[Text]
    ;;  │ ││ │  └─ 5
    ;;  │ ││ └──── 4
    ;;  │ │└────── 3
    ;;  │ └─────── 2
    ;;  └───────── 1
    (,asciidoc--regexp-kbd
     (1 'asciidoc-face-kbd)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-bracket)
     (4 'asciidoc-face-kbd-text)
     (5 'asciidoc-face-bracket))

    ;; menu:File[]
    ;; menu:File[Save > Save as])
    ;; Original regexp from VS Code plugin
    ;; (?<!\\\\)(menu):(\\p{Word}|\\p{Word}.*?\\S)\\[\\p{Blank}*(.+?)?\\]
    ;;          │     ││                            ││                  └─ 6
    ;;          │     ││                            │└─ 5
    ;;          │     ││                            └─ 4
    ;;          │     │└─ 3
    ;;          │     └─ 2
    ;;          └─ 1
    (,asciidoc--regexp-menu-macro
     (1 'asciidoc-face-macro-name)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-attribute-value)
     (4 'asciidoc-face-bracket)
     (5 'asciidoc-face-unquoted-string)
     (6 'asciidoc-face-bracket))

    ;; One line note
    ;; NOTE: Text
    ;; │   └──── 2
    ;; └──────── 1
    (,asciidoc--regexp-note-one-line
     (1 'asciidoc-face-note)
     (2 'asciidoc-face-separator-punctuation))

    ;; Multiline note
    ;; [NOTE] ── 1
    ;; ==== ──── 2
    ;; Text
    ;; ==== ──── 3
    (,asciidoc--regexp-note-multi-line
     (1 'asciidoc-face-note)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-separator-punctuation))

    (,asciidoc--regexp-id . asciidoc-face-id)
    (,asciidoc--regexp-comment-block . asciidoc-face-comment)
    (,asciidoc--regexp-comment . asciidoc-face-comment)

    ;; include::text[attribute]
    ;;  │     │  │  │    │    └─ 6
    ;;  │     │  │  │    └──── 5
    ;;  │     │  │  └─────── 4
    ;;  │     │  └──────── 3
    ;;  │     └───────── 2
    ;;  └───────────── 1
    (,asciidoc--regexp-include-directive
     (1 'asciidoc-face-function)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-default)
     (4 'asciidoc-face-bracket)
     (5 'asciidoc-face-unquoted-string)
     (6 'asciidoc-face-bracket))

    ;; Subscript
    ;; Water: H2O
    ;; H[.Property]~2~O
    ;;  │          ││└─ 4
    ;;  │          │└─ 3
    ;;  │          └─ 2
    ;;  └─ 1
    (,asciidoc--regexp-subscript
     (1 'asciidoc-face-attribute-name)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-subscript)
     (4 'asciidoc-face-separator-punctuation))

    ;; Superscript
    ;; Energy: E = mc^2^
    ;; E = mc[.Property]^2^
    ;;       │          ││└─ 4
    ;;       │          │└─ 3
    ;;       │          └─ 2
    ;;       └─ 1
    (,asciidoc--regexp-superscript
     (1 'asciidoc-face-attribute-name)
     (2 'asciidoc-face-separator-punctuation)
     (3 'asciidoc-face-superscript)
     (4 'asciidoc-face-separator-punctuation))

    ;; <<xref>>
    (,asciidoc--regexp-xref-reference-1
     (1 'asciidoc-face-constant)
     (2 'asciidoc-face-attribute-list)
     (3 'asciidoc-face-unquoted-string)
     (4 'asciidoc-face-constant))

    ;; xref:[link]
    (,asciidoc--regexp-xref-reference-2
     (1 'asciidoc-face-function-name)
     (2 'asciidoc-face-attribute-list)
     (3 'asciidoc-face-unquoted-string))

    ;; Unordered list
    ;; - list item
    ;; * list item
    ;; • list item
    (,asciidoc--regexp-list-unordered
     (1 'asciidoc-face-bullet-list-markup))

    ;; Ordered list
    (,asciidoc--regexp-list-ordered
     (1 'asciidoc-face-bullet-list-markup))
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
                nil nil nil nil
                (font-lock-multiline . t)
                (font-lock-mark-block-function . asciidoc-font-lock-mark-block-function))))


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.adoc\\'" . asciidoc-mode))


(provide 'asciidoc-mode)

;;; asciidoc-mode.el ends here
