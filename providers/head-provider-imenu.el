;;; head-provider-imenu.el --- Imenu/which-function fallback for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Minimal fallback provider using which-function.
;; When richer providers are unavailable, shows the current top symbol.

;;; Code:

(require 'head-model)
(require 'head-providers)
(require 'which-func)

(defun head--imenu--name-at-point ()
  "Return the which-function name at point, or nil."
  (when (and (boundp 'which-function-mode)
             (fboundp 'which-function))
    (which-function)))

(defun head--imenu-provider-ready (_buffer)
  "Return non-nil if fallback can provide something."
  (and (fboundp 'which-function) (not (null (head--imenu--name-at-point)))))

(defun head--imenu-provider-current-path (buffer point)
  "Return a one-section path from which-function for BUFFER at POINT."
  (with-current-buffer buffer
    (save-excursion
      (goto-char point)
      (let ((name (head--imenu--name-at-point)))
        (when name
          (list
           (apply #'head--make-section
                  (list :id (list 'imenu name (point))
                        :kind 'function
                        :display-name name
                        :full-name name
                        :position (copy-marker (point) t)
                        :icon-id 'function
                        :priority 0
                        :tooltip (format "function • %s" name)))))))))

(defun head--imenu-provider-capabilities ()
  "Return capabilities plist for imenu fallback."
  (list :signatures nil :modifiers nil :rename nil))

;; Register provider
(head--provider-register
 'imenu
 (list :ready-p #'head--imenu-provider-ready
       :current-path #'head--imenu-provider-current-path
       :capabilities #'head--imenu-provider-capabilities))

(provide 'head-provider-imenu)

;;; head-provider-imenu.el ends here
