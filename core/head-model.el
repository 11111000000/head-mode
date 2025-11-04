;;; head-model.el --- Data model for head-mode sections -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Defines the Section object as a plist and helpers.
;; See spec/05-data-model.org#section-object

;;; Code:

(require 'cl-lib)

(defun head--make-section (&rest kvs)
  "Create a Section plist from KVS with basic validation.
Required keys: :id, :kind, :display-name.
Optional keys: :full-name :position :icon-id :priority :tooltip :props."
  (let ((id (plist-get kvs :id))
        (kind (plist-get kvs :kind))
        (name (plist-get kvs :display-name)))
    (unless id (error "Section missing :id"))
    (unless kind (error "Section missing :kind"))
    (unless name (error "Section missing :display-name"))
    ;; Normalize priority to number; default medium.
    (let ((prio (plist-get kvs :priority)))
      (unless (numberp prio)
        (setq kvs (plist-put kvs :priority 0))))
    kvs))

(defun head--section-id (section)
  "Return SECTION id."
  (plist-get section :id))

(defun head--section-display-name (section)
  "Return SECTION display name."
  (or (plist-get section :display-name) ""))

(defun head--sections-equal-ids (a b)
  "Return non-nil if lists of sections A and B have the same ids in order."
  (and (listp a) (listp b)
       (= (length a) (length b))
       (cl-every #'identity
                 (cl-mapcar (lambda (x y)
                              (equal (head--section-id x)
                                     (head--section-id y)))
                            a b))))

(provide 'head-model)

;;; head-model.el ends here
