;;; head-provider-treesit.el --- Treesit provider for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools, languages
;; URL: https://example.org/head-mode

;;; Commentary:
;; Treesit provider: builds semantic path by ascending tree-sitter nodes.
;; - Ready when a treesit node exists at point.
;; - Node-type → semantic kind via maps/head-language-maps.el
;; - Name extraction via child-by-field-name 'name / 'identifier heuristics.
;;
;; Spec references:
;; - Providers: spec/04-providers.org
;; - Data Model: spec/05-data-model.org
;; - Language mappings: spec/13-language-mappings.org

;;; Code:

(require 'head-model)
(require 'head-providers)
(require 'head-language-maps)

(defun head--treesit--ready-p (buffer)
  "Return non-nil if treesit is available and has a node at point in BUFFER."
  (with-current-buffer buffer
    (and (fboundp 'treesit-node-at)
         (ignore-errors (treesit-node-at (point))))))

(defun head--treesit--child-name (node)
  "Return a display name for NODE via typical child fields."
  (let ((prefer-fields '("name" "identifier" "key" "declarator" "field")))
    (or
     (catch 'found
       (dolist (field prefer-fields)
         (let ((child (ignore-errors (treesit-node-child-by-field-name node field))))
           (when (and child (treesit-node-p child))
             (throw 'found (treesit-node-text child t))))))
     ;; Fallback to trimmed node text (bounded)
     (let ((text (treesit-node-text node t)))
       (cond
        ((> (length text) 80) (concat (substring text 0 77) "..."))
        (t text))))))

(defun head--treesit--node-id (node)
  "Construct a stable-ish id for NODE."
  (vector (treesit-node-type node)
          (treesit-node-start node)
          (treesit-node-end node)))

(defun head--treesit--section (lang node kind &optional priority)
  "Build Section plist for LANG NODE of KIND."
  (let* ((name (head--treesit--child-name node))
         (full name)
         (pos (treesit-node-start node))
         (id (list 'treesit lang (head--treesit--node-id node))))
    (apply #'head--make-section
           (list :id id
                 :kind kind
                 :display-name name
                 :full-name full
                 :position (copy-marker pos t)
                 :icon-id kind
                 :priority (or priority 0)
                 :tooltip (format "%s • %s" (symbol-name kind) full)
                 :props (list :node-type (treesit-node-type node)
                              :lang lang
                              :range (cons (treesit-node-start node)
                                           (treesit-node-end node)))))))

(defun head--treesit--ascend-path (buffer point)
  "Return a list of (node . kind) from nearest interesting NODE to root."
  (with-current-buffer buffer
    (save-excursion
      (goto-char point)
      (let* ((lang (head--language-detect buffer point))
             (n (ignore-errors (treesit-node-at (point))))
             (pairs '()))
        (when (and n lang)
          (while (treesit-node-p n)
            (let* ((nt (treesit-node-type n))
                   (parent (ignore-errors (treesit-node-parent n)))
                   (pk (when parent
                         (head--language-kind-lookup
                          lang (and parent (treesit-node-type parent)) nil)))
                   (k (head--language-kind-lookup lang nt pk)))
              (when k
                (push (cons n (cons lang k)) pairs)))
            (setq n (ignore-errors (treesit-node-parent n)))))
        (nreverse pairs)))))

(defun head--treesit-provider-current-path (buffer point)
  "Compute treesit semantic breadcrumb for BUFFER at POINT."
  (let* ((pairs (head--treesit--ascend-path buffer point)))
    (mapcar (lambda (p)
              (let ((node (car p))
                    (lang (cadr p))
                    (kind (cddr p)))
                (head--treesit--section lang node kind)))
            pairs)))

(defun head--treesit-provider-ready (buffer)
  "Return non-nil if treesit provider can serve BUFFER."
  (head--treesit--ready-p buffer))

(defun head--treesit-provider-capabilities ()
  "Return capabilities plist for treesit provider."
  (list :signatures nil :modifiers nil :rename nil))

;; Register provider
(head--provider-register
 'treesit
 (list :ready-p #'head--treesit-provider-ready
       :current-path #'head--treesit-provider-current-path
       :capabilities #'head--treesit-provider-capabilities))

(provide 'head-provider-treesit)

;;; head-provider-treesit.el ends here
