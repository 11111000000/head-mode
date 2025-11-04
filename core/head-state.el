;;; head-state.el --- Per-window state management for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Per-window state handling for head-mode. The header-line is window-local,
;; so we attach state to windows via window-parameters.
;;
;; State fields (plist semantics; see spec/05-data-model.org#state-model):
;; - :active-provider
;; - :last-path
;; - :last-identity
;; - :last-output
;; - :width-cache
;; - :profile
;; - :dirty-flags  ;; plist of flags: :content t, :size t, :theme t

;;; Code:

(require 'cl-lib)

(defconst head--state-parameter 'head--state
  "Window-parameter key used to store head-mode state.")

(defun head--state--default ()
  "Return a fresh default state plist."
  (list :active-provider nil
        :last-path nil
        :last-identity nil
        :last-output nil
        :width-cache (make-hash-table :test 'equal)
        :profile nil
        :dirty-flags (list :content t :size t)))

(defun head--state-get (&optional window)
  "Return state plist for WINDOW. Create one if missing.
WINDOW defaults to the selected window."
  (let* ((w (or window (selected-window)))
         (st (window-parameter w head--state-parameter)))
    (unless (and (listp st) (plist-member st :dirty-flags))
      (setq st (head--state--default))
      (set-window-parameter w head--state-parameter st))
    st))

(defun head--state-set (state &optional window)
  "Set STATE plist for WINDOW. WINDOW defaults to selected window."
  (let ((w (or window (selected-window))))
    (set-window-parameter w head--state-parameter state)))

(defun head--state-clear (&optional window)
  "Clear stored state for WINDOW. WINDOW defaults to selected window."
  (let ((w (or window (selected-window))))
    (set-window-parameter w head--state-parameter nil)))

(defun head--state-update (key value &optional window)
  "Update KEY in state for WINDOW to VALUE. Return the updated state."
  (let* ((w (or window (selected-window)))
         (st (copy-sequence (head--state-get w))))
    (setq st (plist-put st key value))
    (set-window-parameter w head--state-parameter st)
    st))

(defun head--state-dirty-p (&optional window)
  "Return non-nil if the state for WINDOW has any dirty flags set."
  (let* ((st (head--state-get window))
         (df (plist-get st :dirty-flags)))
    (and df (cl-some (lambda (kv) (cdr kv))
                     (cl-loop for (k v) on df by #'cddr collect (cons k v))))))

(defun head--state-mark-dirty (kind &optional window)
  "Mark DIRTY flag of KIND in WINDOW state. KIND is a keyword like :content or :size."
  (let* ((st (head--state-get window))
         (df (plist-get st :dirty-flags)))
    (setq df (plist-put (or df (list)) kind t))
    (head--state-update :dirty-flags df window)))

(defun head--state-clear-dirty (&optional window)
  "Clear all dirty flags in WINDOW."
  (let* ((st (head--state-get window)))
    (head--state-update :dirty-flags nil window)))

(defun head--for-each-window (fn)
  "Call FN for each live window in all frames.
FN is called with one argument: window."
  (dolist (fr (frame-list))
    (dolist (w (window-list fr 'no-minibuf 'visible))
      (when (window-live-p w)
        (funcall fn w)))))

(provide 'head-state)

;;; head-state.el ends here
