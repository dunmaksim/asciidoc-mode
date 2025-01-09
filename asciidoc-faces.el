;;; asciidoc-faces.el --- Face definitions for asciidoc-mode -*- lexical-binding: t; -*-

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

;; This file contains the face definitions for `asciidoc-mode'.

;;; Code:

(require 'faces)
(require 'font-lock)

(defgroup asciidoc-faces nil "Faces used in AsciiDoc Mode."
  :group 'asciidoc
  :group 'faces)


(defface asciidoc-face-block-attribute-heading '((t :inherit default))
  "Face used for block attribute headings."
  :group 'asciidoc-faces)

(defvar asciidoc-face-block-attribute-heading 'asciiidoc-face-block-attribute-heading)


(defface asciidoc-face-block-title '((t :inherit default))
  "Face used for block titles."
  :group 'asciidoc-faces)

(defvar asciidoc-face-block-title 'asciidoc-face-block-title)


(defface asciidoc-face-symbol-other-constant '((t :inherit font-lock-constant-face))
  "Face used for constants."
  :group 'asciidoc-faces)

(defvar asciidoc-face-symbol-other-constant 'asciidoc-face-symbol-other-constant)


(defface asciidoc-face-numeric-constant '((t :inherit font-lock-number-face))
  "Face used for numeric constants."
  :group 'asciidoc-faces)

(defvar asciidoc-face-numeric-constant 'asciidoc-face-numeric-constant)



(defface asciidoc-face-bullet-list-markup '((t :inherit bold))
  "Face used for bullets in unordered lists."
  :group 'asciidoc-faces)

(defvar asciidoc-face-bullet-list-markup 'asciidoc-face-bullet-list-markup)



(defface asciidoc-face-box-todo-markup '((t :inherit font-lock-bracket-face))
  "Face used for checkbox items in todo-lists."
  :group 'asciidoc-faces)



(defface asciidoc-face-default '((t :inherit default))
  "Face used for default text."
  :group 'asciidoc-faces)

(defvar asciidoc-face-default 'asciidoc-face-default)


;; Attribute
;; :name:value[]
(defface asciidoc-face-attribute-name
  '((t (:inherit font-lock-keyword-face)))
  "Face for attribute name.")

(defvar
  asciidoc-face-attribute-name
  'asciidoc-face-attribute-name
  "Face name for attributes.")


(defface asciidoc-face-attribute-value '((t (
                                             :inherit default
                                             :foreground "blue")))
  "Face for attribute name."
  :group 'asciidoc-faces)

(defvar asciidoc-face-attribute-value 'asciidoc-face-attribute-value)



(defface asciidoc-face-heading-markup '((t (:inherit face-attribute)))
  "Face for headings markup."
  :group 'asciidoc-faces)

(defvar asciidoc-face-heading-markup 'asciidoc-face-heading-markup)



(defface asciidoc-face-heading-space '((t (:inherit font-lock-constant-face)))
  "Face for heading spaces."
  :group 'asciidoc-faces)

(defvar asciidoc-face-heading-space 'asciidoc-face-heading-space)



(defface asciidoc-face-comment
  '((t (:inherit font-lock-comment-face)))
  "Face used for comments."
  :group 'asciidoc-faces)

(defvar asciidoc-face-comment
  'asciidoc-face-comment
  "Face name for comment.")



(defface asciidoc-face-emphasis '((t (:inherit italic)))
  "Face used for emphasis."
  :group 'asciidoc-faces)

(defvar asciidoc-face-emphasis 'asciidoc-face-emphasis)



(defface asciidoc-face-subscript '((t (:inherit bold)))
  "Face used for subscript."
  :group 'asciidoc-faces)

(defvar asciidoc-face-subscript 'asciidoc-face-subscript)



(defface asciidoc-face-superscript '((t (:inherit bold)))
  "Face user for superscript."
  :group 'asciidoc-faces)

(defvar asciidoc-face-superscript 'asciidoc-face-superscript)



(defface asciidoc-face-bold '((t (:inherit bold)))
  "Face used for bold."
  :group 'asciidoc-faces)

(defvar asciidoc-face-bold 'asciidoc-face-bold)


(defface asciidoc-face-attribute-list '((t (:inherit bold)))
  "Face for bold text."
  :group 'asciidoc-faces)


(defface asciidoc-face-inline-code
  '((t (:inherit font-lock-builtin-face)))
  "Face for inline code."
  :group 'asciidoc-faces)

(defvar asciidoc-face-inline-code
  'asciidoc-face-inline-code
  "Face name for inline code.")



(defface asciidoc-face-footnote '((t (:inherit font-lock-keyword-face)))
  "Face for footnote: macros."
  :group 'asciidoc-faces)

(defvar asciidoc-face-footnote 'asciidoc-face-footnote)


(defface asciidoc-face-footnote-text
  '((t (:inherit font-lock-doc-face)))
  "Face for footnote text."
  :group 'asciidoc-faces)

(defvar
  asciidoc-face-footnote-text
  'asciidoc-face-footnote-text
  "Face name for footnote text.")



(defface asciidoc-face-kbd '((t (:inherit font-lock-keyword-face)))
  "Face for kbd: macros."
  :group 'asciidoc-faces)

(defvar asciidoc-face-kbd 'asciidoc-face-kbd "Face name for kbd macros name.")



(defface asciidoc-face-kbd-text '((t (:inherit warning)))
  "Face for :kbd:[Text] text."
  :group 'asciidoc-faces)

(defvar asciidoc-face-kbd-text 'asciidoc-face-kbd-text)


;; ADMONITIONS

(defface asciidoc-face-note '((t (:inherit (bold underline success))))
  "Face for note adminition."
  :group 'asciidoc-faces)

(defvar asciidoc-face-note 'asciidoc-face-note)



(defface asciidoc-face-tip '((t (:inherit (bold underline success))))
  "Face for tip admonition."
  :group 'asciidoc-faces)

(defvar asciidoc-face-tip 'asciidoc-face-tip)



(defface asciidoc-face-important '((t (:inherit (bold underline warning))))
  "Face for important admonition."
  :group 'asciidoc-faces)

(defvar asciidoc-face-important 'asciidoc-face-important)



(defface asciidoc-face-caution '((t (:inherit (bold underline error))))
  "Face for warning admonition."
  :group 'asciidoc-faces)

(defvar asciidoc-face-caution 'asciidoc-face-caution)



(defface asciidoc-face-warning '((t (:inherit (bold underline warning))))
  "Face for warning admonition."
  :group 'asciidoc-faces)

(defvar asciidoc-face-warning 'asciidoc-face-warning)



;; Block macro:
;; name::value[Additional text]
;;
;; Inline macro:
;; text name:value[Additional text] text

(defface asciidoc-face-macro-name
  '((t (:inherit (asciidoc-face-default font-lock-keyword-face))))
  "Face for macro name."
  :group 'asciidoc-faces)

(defvar asciidoc-face-macro-name 'asciidoc-face-macro-name)



(defface asciidoc-face-macro-value
  '((t (:inherit (asciidoc-face-default font-lock-function-name-face))))
  "Face for macro value."
  :group 'asciidoc-faces)

(defvar asciidoc-face-macro-value 'asciidoc-face-macro-value)



(defface asciidoc-face-macro-text
  '((t (
        :inherit asciidoc-face-default
        :foreground "yellow")))
  "Face for macro text."
  :group 'asciidoc-faces)

(defvar asciidoc-face-macro-text 'asciidoc-face-macro-text)



(defface asciidoc-face-comment-delimiter
  '((t (:inherit font-lock-comment-delimiter-face)))
  "Face for comment delimiters."
  :group 'asciidoc-faces)

(defvar asciidoc-face-comment-delimiter
  'asciidoc-face-comment-delimiter
  "Face name to use for delimiters.")



(defface asciidoc-face-bracket
  '((t (:inherit font-lock-bracket-face)))
  "Face used to highlight brackets, braces, and parens."
  :group 'asciidoc-faces)

(defvar asciidoc-face-bracket
  'asciidoc-face-bracket
  "Face name to use for brackets.")



(defface asciidoc-face-punctuation
  '((t (:inherit font-lock-punctuation-face)))
  "Face for highlighting punctuation characters."
  :group 'asciidoc-faces)

(defvar asciidoc-face-punctuation
  'asciidoc-face-punctuation
  "Face name to use for punctuation.")



(defface asciidoc-face-id
  '((t (:inherit font-lock-variable-name-face)))
  "Face for highlighting ID in text."
  :group 'asciidoc-faces)

(defvar asciidoc-face-id 'asciidoc-face-id)



(defface asciidoc-face-description
  '((t (:inherit font-lock-constant-face)))
  "Face for highlighting descriptions."
  :group 'asciidoc-faces)

(defvar asciidoc-face-description
  'asciidoc-face-description
  "Face name for descriptions.")



(defface asciidoc-face-function
  '((t (:inherit font-lock-function)))
  "Face for highlighting functions."
  :group 'asciidoc-faces)

(defvar asciidoc-face-function
  'asciidoc-face-function
  "Face name for functions.")



(defface asciidoc-face-unquoted-string
  '((t (:inherit font-lock-string-face)))
  "Face for highlighting unquoted strings."
  :group 'asciidoc-faces)

(defvar asciidoc-face-unquoted-string
  'asciidoc-face-unquoted-string
  "Face name for unquoted strings.")



(provide 'asciidoc-faces)

;;; asciidoc-faces.el ends here
