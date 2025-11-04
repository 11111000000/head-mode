;;; head-mode.el --- Contextual header-line breadcrumbs -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; head-mode shows contextual breadcrumbs in the header-line.
;; See the specification in spec/* for goals, UX, architecture, and contracts:
;; - Goals and scope: spec/01-goals-and-scope.org
;; - UX and requirements: spec/02-ux-and-requirements.org
;; - Architecture: spec/03-architecture.org
;; - Data model and provider contract: spec/05-data-model.org
;; - Layout and rendering: spec/06-layout-and-rendering.org
;; - Icons and styles: spec/07-icons-and-styles.org
;; - Configuration and profiles: spec/08-configuration-and-profiles.org
;; - Interactions and menus: spec/09-interactions-and-menus.org
;; - Performance and reliability: spec/10-performance-and-reliability.org

;;; Code:

(eval-when-compile
  (require 'cl-lib))

(defgroup head-mode nil
  "Contextual breadcrumbs rendered in the header-line."
  :group 'convenience
  :link '(url-link :tag "Spec" "spec/README.org"))

(defcustom head-mode-separator "→"
  "Separator used between breadcrumb sections."
  :type 'string
  :group 'head-mode)

(defcustom head-mode-use-icons t
  "When non-nil, render icons for semantic kinds if available.
Text-only fallbacks are used when icons are unavailable."
  :type 'boolean
  :group 'head-mode)

(defcustom head-mode-show-file-section t
  "When non-nil, show project-relative file section at the left edge."
  :type 'boolean
  :group 'head-mode)

(defvar head-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Keybindings will be populated in later patches (see spec/09-interactions-and-menus.org).
    map)
  "Keymap for head-mode.")

;;;###autoload
(define-minor-mode head-mode
  "Render contextual breadcrumbs in the header-line for the current buffer.

This mode installs a header-line producer that shows the current
semantic path according to the active provider (LSP/treesit/imenu)
and the Org outline for Org buffers. It is designed to be fast,
non-intrusive, and extensible.

Side effects: assigns buffer-local `header-line-format' while enabled.
On disable, the previous header-line is restored.

For design details, see spec/03-architecture.org."
  :init-value nil
  :lighter " Head"
  :keymap head-mode-map
  (if head-mode
      (progn
        (require 'head-core)
        (head-core-activate))
    (when (featurep 'head-core)
      (head-core-deactivate))))

;;;###autoload
(defun head-mode-enable ()
  "Enable head-mode in the current buffer."
  (interactive)
  (head-mode 1))

;;;###autoload
(defun head-mode-disable ()
  "Disable head-mode in the current buffer."
  (interactive)
  (head-mode -1))

;;;###autoload
(defun head-mode-toggle ()
  "Toggle head-mode in the current buffer."
  (interactive)
  (if head-mode (head-mode-disable) (head-mode-enable)))

(provide 'head-mode)

;;; head-mode.el ends here
