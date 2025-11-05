;;; head-file-section.el --- File/project section builder -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Constructs the leftmost "file/project" Section.
;; - Uses project.el (when available) to compute project-relative path.
;; - Falls back to buffer-name when no file is associated.

;;; Code:

(require 'head-model)
(require 'project nil t)

(defun head--file-section (buffer)
  "Return a Section plist for BUFFER's file/project path."
  (with-current-buffer buffer
    (let* ((fname (buffer-file-name))
           (proj (when (and (featurep 'project) (fboundp 'project-current))
                   (ignore-errors (project-current))))
           (root (and proj (ignore-errors (project-root proj))))
           (display (cond
                     (fname
                      (if (and root (string-prefix-p root fname))
                          (file-relative-name fname root)
                        (file-name-nondirectory fname)))
                     (t (buffer-name))))
           (full (or fname (buffer-name)))
           (marker (copy-marker (point-min) t)))
      (apply #'head--make-section
             (list :id (list 'file full)
                   :kind 'file
                   :display-name display
                   :full-name full
                   :position marker
                   :icon-id 'file
                   :priority -10
                   :tooltip (or full display)
                   :props (and root (list :project-root root)))))))

(provide 'head-file-section)

;;; head-file-section.el ends here
