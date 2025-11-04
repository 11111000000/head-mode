;;; head-events.el --- Event orchestration for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Sets up and tears down event hooks required by head-mode.
;; - post-command-hook: cheap guard to detect context changes.
;; - window-size-change-functions: mark size dirty and trigger recompute.
;;
;; References: spec/03-architecture.org#event-flow

;;; Code:

(require 'cl-lib)
(require 'head-state)

(defvar-local head--events-installed-p nil
  "Non-nil when buffer-local post-command hook is installed for head-mode.")

(defvar head--events-window-size-hook-installed nil
  "Non-nil when global window-size-change hook has been installed.")

(defun head--events--compute-identity (&optional window)
  "Compute a cheap identity token for WINDOW to detect context changes.
Uses point, window-start and window-width heuristics.
WINDOW defaults to selected window."
  (let* ((w (or window (selected-window)))
         (buf (window-buffer w)))
    (with-current-buffer buf
      (list (buffer-chars-modified-tick)
            (point)
            (window-start w)
            (window-total-width w)))))

(defun head--events--guard-and-maybe-update (&optional window reason)
  "Guard against unnecessary recompute and call head-core--maybe-update if needed.
WINDOW defaults to selected window. REASON is a keyword describing the trigger."
  (let* ((w (or window (selected-window)))
         (buf (window-buffer w)))
    (with-current-buffer buf
      (when (bound-and-true-p head--active-p)
        (let* ((st (head--state-get w))
               (prev-id (plist-get st :last-identity))
               (id (head--events--compute-identity w)))
          (unless (equal prev-id id)
            (setq st (head--state-update :last-identity id w))
            (head--state-mark-dirty :content w)))
        (when (and (fboundp 'head-core--maybe-update)
                   (head--state-dirty-p w))
          (with-selected-window w
            (head-core--maybe-update (or reason :post-command))))))))

(defun head--on-post-command ()
  "Post-command hook for head-mode: detect changes and maybe update."
  (head--events--guard-and-maybe-update (selected-window) :post-command))

(defun head--on-window-size-change (frame)
  "Hook for `window-size-change-functions'. FRAME is the changed frame.
Mark visible windows dirty by size and recompute."
  (ignore frame)
  (dolist (w (window-list nil 'no-minibuf 'visible))
    (let ((buf (window-buffer w)))
      (with-current-buffer buf
        (when (bound-and-true-p head--active-p)
          (head--state-mark-dirty :size w)
          (when (fboundp 'head-core--maybe-update)
            (with-selected-window w
              (head-core--maybe-update :size-change))))))))

(defun head--events-install ()
  "Install event hooks for the current buffer."
  (unless head--events-installed-p
    (add-hook 'post-command-hook #'head--on-post-command nil t)
    (setq head--events-installed-p t))
  (unless head--events-window-size-hook-installed
    (add-hook 'window-size-change-functions #'head--on-window-size-change)
    (setq head--events-window-size-hook-installed t)))

(defun head--events-uninstall ()
  "Uninstall event hooks for the current buffer.
If this was the last active buffer, also remove the global size-change hook."
  (when head--events-installed-p
    (remove-hook 'post-command-hook #'head--on-post-command t)
    (setq head--events-installed-p nil))
  ;; Check if any buffer remains active; if none, drop global hook.
  (let ((any-active nil))
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (bound-and-true-p head--active-p)
          (setq any-active t))))
    (unless any-active
      (when head--events-window-size-hook-installed
        (remove-hook 'window-size-change-functions #'head--on-window-size-change)
        (setq head--events-window-size-hook-installed nil)))))

(provide 'head-events)

;;; head-events.el ends here
