;;; head-providers.el --- Provider registry and selection -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Provider registry and selection logic.
;; See spec/04-providers.org and spec/05-data-model.org#provider-contract

;;; Code:

(require 'cl-lib)
(require 'head-model)

(defgroup head-mode-providers nil
  "Provider configuration for head-mode."
  :group 'head-mode)

(defcustom head-mode-providers-priority '(lsp treesit imenu org null)
  "Ordered list of provider keys by priority."
  :type '(repeat symbol)
  :group 'head-mode-providers)

(defvar head--providers (make-hash-table :test 'eq)
  "Registry of providers keyed by symbol.")

(defun head--provider-register (key provider)
  "Register PROVIDER under KEY. PROVIDER is a plist of functions.
Expected keys:
  :init (fn buffer) optional
  :dispose (fn buffer) optional
  :ready-p (fn buffer) -> non-nil if provider can serve
  :current-path (fn buffer point) -> list of Sections
  :capabilities (fn) -> plist of capabilities"
  (puthash key provider head--providers))

(defun head-mode-register-provider (major-mode key)
  "Associate MAJOR-MODE with provider KEY."
  (let* ((sym 'head--provider-mode-map)
         (map (and (boundp sym) (symbol-value sym))))
    (unless map
      (setq map (make-hash-table :test 'eq))
      (set sym map))
    (puthash major-mode key map)))

(defvar head--provider-mode-map (make-hash-table :test 'eq)
  "Map from major-mode to preferred provider key.")

(defun head--provider-for-mode (buffer)
  "Return provider key preferred for BUFFER's major-mode if any."
  (with-current-buffer buffer
    (or (gethash major-mode head--provider-mode-map) nil)))

(defun head--provider-get (key)
  "Return provider descriptor plist for KEY."
  (gethash key head--providers))

(defun head--provider-ready-p (provider buffer)
  "Return non-nil if PROVIDER is ready for BUFFER."
  (let ((fn (plist-get provider :ready-p)))
    (if (functionp fn)
        (ignore-errors (funcall fn buffer))
      t)))

(defun head--select-provider (buffer)
  "Select an available provider for BUFFER based on priority and readiness.
Returns a cons (KEY . PROVIDER-PLIST)."
  (let* ((preferred (head--provider-for-mode buffer))
         (order (if preferred
                    (cons preferred (cl-remove preferred head-mode-providers-priority))
                  head-mode-providers-priority))
         (chosen nil))
    (cl-dolist (key order)
      (let ((prov (head--provider-get key)))
        (when (and prov (head--provider-ready-p prov buffer))
          (setq chosen (cons key prov))
          (cl-return))))
    chosen))

(defun head--provider-current-path (provider buffer point)
  "Invoke PROVIDER's current-path for BUFFER at POINT.
Return a list of Section plists, or nil."
  (let ((fn (plist-get provider :current-path)))
    (when (functionp fn)
      (ignore-errors (funcall fn buffer point)))))

;; Built-in null provider (safe default)
(defun head--null-provider-ready (_buffer) t)
(defun head--null-provider-current-path (_buffer _point) nil)

(head--provider-register
 'null
 (list :ready-p #'head--null-provider-ready
       :current-path #'head--null-provider-current-path
       :capabilities (lambda () nil)))

(provide 'head-providers)

;;; head-providers.el ends here
