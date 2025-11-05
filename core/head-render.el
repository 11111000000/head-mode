;;; head-render.el --- Rendering for head-mode -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: ui, convenience
;; URL: https://example.org/head-mode

;;; Commentary:
;; Convert laid-out sections into propertized header-line content.
;; - Attaches faces, tooltips, and mouse keymaps.
;; - Mouse-1 jumps to section position; Mouse-3 reserved for context menu (later).
;;
;; References:
;; - spec/06-layout-and-rendering.org#rendering
;; - spec/09-interactions-and-menus.org

;;; Code:

(require 'cl-lib)
(require 'head-faces)

(defvar head-mode-separator)

(defun head-render--section-face (section is-last)
  "Return face for SECTION, considering IS-LAST."
  (let ((k (plist-get section :kind)))
    (cond
     (is-last 'head-mode-section-active)
     ((and k (symbolp k)
           (string-match-p "^org-heading-level-" (symbol-name k)))
      (pcase k
        ('org-heading-level-1 'head-mode-org-h1)
        ('org-heading-level-2 'head-mode-org-h2)
        ('org-heading-level-3 'head-mode-org-h3)
        ('org-heading-level-4 'head-mode-org-h4)
        ('org-heading-level-5 'head-mode-org-h5)
        ('org-heading-level-6 'head-mode-org-h6)
        (_ 'head-mode-section)))
     (t 'head-mode-section))))

(defun head-render--jump (marker)
  "Jump to MARKER if live."
  (when (markerp marker)
    (let ((buf (marker-buffer marker))
          (pos (marker-position marker)))
      (when (buffer-live-p buf)
        (pop-to-buffer-same-window buf)
        (goto-char pos)))))

(defun head-render--make-keymap (marker)
  "Return a local keymap for a section bound to MARKER."
  (let ((map (make-sparse-keymap)))
    (define-key map [header-line mouse-1]
      (lambda (_e) (interactive) (head-render--jump marker)))
    map))

(defun head-render-assemble (sections labels &optional sep)
  "Assemble header-line content from SECTIONS and LABELS.
SEP is the separator string (defaults to head-mode-separator)."
  (let* ((sep (or sep head-mode-separator " "))
         (pieces '()))
    (cl-loop
     for idx from 0
     for s in sections
     for lbl in labels
     do
     (let* ((is-ellipsis (string= lbl "…"))
            (is-last (= idx (1- (length sections))))
            (face (if is-ellipsis 'head-mode-ellipsis
                    (head-render--section-face s is-last)))
            (tooltip (and (not is-ellipsis) (plist-get s :tooltip)))
            (pos (and (not is-ellipsis) (or (plist-get s :position)
                                            (plist-get s :marker))))
            (seg (propertize lbl
                             'face face
                             'mouse-face 'mode-line-highlight
                             'help-echo tooltip
                             'keymap (and pos (head-render--make-keymap pos)))))
       (push seg pieces)
       ;; Add separator if not last
       (unless (= idx (1- (length sections)))
         (push (propertize sep 'face 'head-mode-separator) pieces))))
    ;; pieces were pushed in reverse order of segments+separators; reverse back
    (apply #'concat (nreverse pieces))))

(provide 'head-render)

;;; head-render.el ends here
