;;; head-core.el --- Core activation and header-line hook -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Core activation/deactivation and the update/render pipeline entry points.
;; This module wires state, events, provider selection, and cached rendering.
;;
;; References:
;; - Event flow and pipeline: spec/03-architecture.org
;; - Rendering rules: spec/06-layout-and-rendering.org
;; - Public API and configuration: spec/08-configuration-and-profiles.org

;;; Code:

(require 'subr-x)
(require 'head-state)
(require 'head-events)
(require 'head-providers)
(require 'head-model)

(defvar head-mode-separator) ;; from head-mode.el

(defvar-local head--saved-header-line nil
  "Saved value of `header-line-format' prior to enabling head-mode.")

(defvar-local head--active-p nil
  "Non-nil when head-mode is actively managing the header-line in this buffer.")

(defun head-core--compose-output (sections)
  "Compose display string from SECTIONS list.
Currently joins SECTION display names with `head-mode-separator'."
  (if (and (listp sections) sections)
      (mapconcat #'head--section-display-name sections (or head-mode-separator " "))
    ""))

(defun head-core--render ()
  "Render cached header-line for the selected window.
If no cached output exists, recompute once."
  (let* ((w (selected-window))
         (st (head--state-get w))
         (out (plist-get st :last-output)))
    (unless out
      (head-core--maybe-update :render)
      (setq st (head--state-get w))
      (setq out (plist-get st :last-output)))
    out))

(defun head-core--install-header ()
  "Install the header-line producer for head-mode."
  (setq header-line-format '(:eval (head-core--render))))

(defun head-core--uninstall-header ()
  "Uninstall the header-line producer and restore previous header-line."
  (setq header-line-format head--saved-header-line))

(defun head-core--select-and-current-path (buffer point)
  "Select a provider for BUFFER and compute current path at POINT.
Return a cons (KEY . SECTIONS). Updates state with active provider."
  (let* ((sel (head--select-provider buffer))
         (key (car sel))
         (prov (cdr sel))
         (sections (and prov (head--provider-current-path prov buffer point))))
    (cons key (or sections nil))))

(defun head-core--update-cache (w sections &optional provider-key)
  "Update state cache for window W with SECTIONS and PROVIDER-KEY.
Returns the new output string."
  (let* ((st (head--state-get w))
         (prev (plist-get st :last-path))
         (same (and prev (head--sections-equal-ids prev sections)))
         (output (plist-get st :last-output)))
    (unless (and same output)
      (setq output (head-core--compose-output sections)))
    (setq st (head--state-update :last-path sections w))
    (when provider-key
      (setq st (head--state-update :active-provider provider-key w)))
    (setq st (head--state-update :last-output output w))
    (head--state-clear-dirty w)
    output))

;;;###autoload
(defun head-core--maybe-update (&optional reason)
  "Recompute header-line for the selected window if needed.
REASON is a keyword describing the trigger, used for diagnostics."
  (ignore reason)
  (let* ((w (selected-window)))
    (when (and (window-live-p w)
               (bound-and-true-p head--active-p))
      (let* ((buf (window-buffer w))
             (st (head--state-get w))
             (dirty (head--state-dirty-p w)))
        (when (or dirty (not (plist-get st :last-output)))
          (let* ((res (head-core--select-and-current-path buf (with-current-buffer buf (point))))
                 (prov (car res))
                 (sections (cdr res)))
            (head-core--update-cache w sections prov)))))))

;;;###autoload
(defun head-core-activate ()
  "Activate head-mode core in the current buffer.
Saves the current `header-line-format', installs events and producer."
  (unless head--active-p
    (setq head--saved-header-line header-line-format)
    (head-core--install-header)
    (head--events-install)
    (setq head--active-p t)
    ;; Mark dirty and compute initial output.
    (head--state-mark-dirty :content (selected-window))
    (head-core--maybe-update :activate)))

;;;###autoload
(defun head-core-deactivate ()
  "Deactivate head-mode core in the current buffer.
Restores the previously saved `header-line-format'."
  (when head--active-p
    (head--events-uninstall)
    (head-core--uninstall-header)
    (head--state-clear (selected-window))
    (setq head--active-p nil
          head--saved-header-line nil)))

(provide 'head-core)

;;; head-core.el ends here
