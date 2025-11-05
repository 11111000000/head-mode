;;; head-icons.el --- Icon theme service for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, ui
;; URL: https://example.org/head-mode

;;; Commentary:
;; Minimal icon theme service with text fallback.
;; Future patches can extend this with nerd-font/all-the-icons themes.
;;
;; References:
;; - Icon theming: spec/07-icons-and-styles.org
;; - Configuration: spec/08-configuration-and-profiles.org

;;; Code:

(require 'cl-lib)

(defcustom head-mode-icon-theme 'text
  "Active icon theme for head-mode.
Currently supported themes: text (fallback-friendly).
Future themes may include nerd-font and all-the-icons."
  :type '(choice (const :tag "Text-only" text)
                 (const :tag "Nerd Font (placeholder)" nerd)
                 (const :tag "All-the-icons (placeholder)" all-the-icons))
  :group 'head-mode)

(defvar head--icon-theme-text
  '((project . "PR")
    (file . "F")
    (module . "MOD")
    (namespace . "NS")
    (package . "PKG")
    (class . "CLS")
    (struct . "STR")
    (interface . "IFC")
    (trait . "TRT")
    (enum . "ENM")
    (method . "m")
    (function . "fn")
    (constructor . "CTOR")
    (destructor . "DTOR")
    (property . "prop")
    (field . "fld")
    (constant . "const")
    (type . "type")
    (alias . "alias")
    (generic . "gen")
    (impl . "impl")
    (test . "test")
    (block . "blk")
    (if . "if")
    (for . "for")
    (while . "while")
    (switch . "switch")
    (try . "try")
    (org-src-block . "SRC"))
  "Text fallback icon theme mapping semantic kinds to mnemonics.")

(defun head-icons--Hn (n)
  "Return textual icon for Org heading level N."
  (format "H%d" n))

(defun head-icons--lookup-text (key kind)
  "Lookup KEY/KIND in text theme."
  (or (alist-get key head--icon-theme-text)
      (alist-get kind head--icon-theme-text)
      (when (and kind
                 (symbolp kind)
                 (string-match "^org-heading-level-\\([0-9]\\)" (symbol-name kind)))
        (head-icons--Hn (string-to-number (match-string 1 (symbol-name kind)))))))

(defun head-icons-lookup (icon-id kind)
  "Return icon string for ICON-ID/KIND according to `head-mode-icon-theme'."
  (pcase head-mode-icon-theme
    ('text (head-icons--lookup-text icon-id kind))
    ;; Placeholders for future themes; fall back to text for now.
    ((or 'nerd 'all-the-icons)
     (head-icons--lookup-text icon-id kind))
    (_ (head-icons--lookup-text icon-id kind))))

(provide 'head-icons)

;;; head-icons.el ends here
