;;; head-faces.el --- Faces for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: faces, ui
;; URL: https://example.org/head-mode

;;; Commentary:
;; Define faces used by head-mode rendering.
;; See spec/07-icons-and-styles.org#faces

;;; Code:

(defface head-mode-separator
  '((t :inherit header-line :foreground "gray60"))
  "Face for breadcrumb separators."
  :group 'head-mode)

(defface head-mode-section
  '((t :inherit header-line))
  "Face for breadcrumb sections."
  :group 'head-mode)

(defface head-mode-section-active
  '((t :inherit header-line :weight bold))
  "Face for the active (last) breadcrumb section."
  :group 'head-mode)

(defface head-mode-ellipsis
  '((t :inherit header-line :foreground "gray70"))
  "Face for the ellipsis glyph."
  :group 'head-mode)

(defface head-mode-icon
  '((t :inherit header-line))
  "Face used for icons."
  :group 'head-mode)

(defface head-mode-project
  '((t :inherit header-line :weight semi-bold))
  "Face for project section."
  :group 'head-mode)

(defface head-mode-file
  '((t :inherit header-line))
  "Face for file section."
  :group 'head-mode)

;; Org heading levels (basic defaults; themes can override)
(defface head-mode-org-h1 '((t :inherit header-line :weight bold)) "Org H1 face." :group 'head-mode)
(defface head-mode-org-h2 '((t :inherit header-line :weight semi-bold)) "Org H2 face." :group 'head-mode)
(defface head-mode-org-h3 '((t :inherit header-line)) "Org H3 face." :group 'head-mode)
(defface head-mode-org-h4 '((t :inherit header-line)) "Org H4 face." :group 'head-mode)
(defface head-mode-org-h5 '((t :inherit header-line)) "Org H5 face." :group 'head-mode)
(defface head-mode-org-h6 '((t :inherit header-line)) "Org H6 face." :group 'head-mode)

(provide 'head-faces)

;;; head-faces.el ends here
