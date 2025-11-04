;;; head-provider-org.el --- Org provider for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1") (org "9.4"))
;; Version: 0.1.0
;; Keywords: convenience, tools, outlines
;; URL: https://example.org/head-mode

;;; Commentary:
;; Org provider: builds breadcrumb path from Org outline.
;; - Outline path via org-back-to-heading/org-up-heading-safe ascent.
;; - SRC blocks add an extra "SRC lang" section.
;;
;; Spec references:
;; - Providers: spec/04-providers.org
;; - Data Model: spec/05-data-model.org
;; - Org specifics: spec/06-layout-and-rendering.org and spec/13-language-mappings.org

;;; Code:

(require 'org)
(require 'head-model)
(require 'head-providers)

(defgroup head-mode-org-provider nil
  "Org provider settings for head-mode."
  :group 'head-mode)

(defun head--org--in-src-block-p ()
  "Return cons (t . lang) if point is in org src block, otherwise nil."
  (when (and (boundp 'org-src-lang-modes) (fboundp 'org-element-context))
    (let* ((ctx (org-element-context)))
      (when (and (consp ctx) (eq (org-element-type ctx) 'src-block))
        (cons t (org-element-property :language ctx))))))

(defun head--org--collect-heading-positions ()
  "Return a list of markers from top-level to current heading.
If point is not in a heading subtree, return nil."
  (org-with-wide-buffer
   (save-excursion
     (let (positions)
       (unless (org-before-first-heading-p)
         (org-back-to-heading 'invisible-ok)
         (push (point) positions)
         (while (org-up-heading-safe)
           (push (point) positions))
         ;; positions now: current, parent, ..., top -> reverse to top..current
         (setq positions (nreverse positions)))
       (when positions
         (mapcar (lambda (pos) (copy-marker pos t)) positions))))))

(defun head--org--heading-title-at (marker)
  "Return the heading title at MARKER, including TODO/priority/tags for tooltip."
  (org-with-wide-buffer
   (save-excursion
     (goto-char marker)
     ;; Full heading string; use defaults (include TODO/priority/tags if present).
     (org-get-heading nil nil nil nil))))

(defun head--org--heading-display-name (marker)
  "Return concise display name for heading at MARKER (usually without tags)."
  (org-with-wide-buffer
   (save-excursion
     (goto-char marker)
     ;; Display name without tags and comments, keep TODO by default for visibility.
     (let* ((todo (org-get-todo-state))
            (title (org-get-heading t t t t)))
       (if todo
           (format "%s %s" todo title)
         title)))))

(defun head--org--kind-for-level (marker)
  "Return org-heading kind symbol for heading at MARKER, based on its outline level."
  (org-with-wide-buffer
   (save-excursion
     (goto-char marker)
     (let* ((lvl (org-outline-level))
            (lvl (max 1 (min 6 lvl))))
       (intern (format "org-heading-level-%d" lvl))))))

(defun head--org--make-heading-section (marker &optional priority)
  "Build Section plist for heading at MARKER, with optional PRIORITY number."
  (let* ((title (head--org--heading-display-name marker))
         (full (head--org--heading-title-at marker))
         (kind (head--org--kind-for-level marker))
         (id (list 'org (marker-position marker) full)))
    (apply #'head--make-section
           (list :id id
                 :kind kind
                 :display-name title
                 :full-name full
                 :position marker
                 :icon-id kind
                 :priority (or priority 0)
                 :tooltip full
                 :props (list :level (org-with-wide-buffer (save-excursion (goto-char marker) (org-outline-level))))))))

(defun head--org--src-section (lang marker)
  "Build Section plist for SRC block of language LANG at MARKER."
  (let* ((name (format "SRC %s" (or lang "?")))
         (id (list 'org 'src (marker-position marker) lang))
         (tooltip (format "Org source block (%s)" (or lang "unknown"))))
    (apply #'head--make-section
           (list :id id
                 :kind 'org-src-block
                 :display-name name
                 :full-name name
                 :position marker
                 :icon-id 'org-src-block
                 :priority 5
                 :tooltip tooltip
                 :props (list :language lang)))))

(defun head--org-provider-ready (buffer)
  "Return non-nil if Org provider is ready for BUFFER."
  (with-current-buffer buffer
    (derived-mode-p 'org-mode)))

(defun head--org-provider-current-path (buffer point)
  "Compute Org breadcrumb path for BUFFER at POINT."
  (with-current-buffer buffer
    (save-excursion
      (goto-char point)
      (let* ((src (head--org--in-src-block-p))
             (src-section (when src
                            (let ((lang (cdr src)))
                              (head--org--src-section lang (copy-marker (point) t)))))
             (markers (head--org--collect-heading-positions))
             (sections (mapcar #'head--org--make-heading-section markers)))
        (if src-section
            (cons src-section sections)
          sections)))))

(defun head--org-provider-capabilities ()
  "Return capability plist for Org provider."
  (list :signatures nil :modifiers nil :rename nil))

;; Register provider
(head--provider-register
 'org
 (list :ready-p #'head--org-provider-ready
       :current-path #'head--org-provider-current-path
       :capabilities #'head--org-provider-capabilities))

;; Prefer Org provider in org-mode
(head-mode-register-provider 'org-mode 'org)

(provide 'head-provider-org)

;;; head-provider-org.el ends here
