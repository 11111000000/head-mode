;;; head-language-maps.el --- Treesit language→kind mappings -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: languages, tools
;; URL: https://example.org/head-mode

;;; Commentary:
;; Mapping from tree-sitter node types to canonical semantic kinds.
;; See spec/13-language-mappings.org for design and coverage.
;;
;; This module provides:
;; - head--language-kind-lookup(lang node-type parent-kind) -> kind symbol or nil
;; - head--language-detect(buffer point) -> language symbol or nil

;;; Code:

(require 'cl-lib)

(defvar head--language-kind-map
  '((python
     ("module" . file)
     ("class_definition" . class)
     ("function_definition" . function)
     ("type_alias" . alias))
    (javascript
     ("program" . module)
     ("class_declaration" . class)
     ("function_declaration" . function)
     ("method_definition" . method)
     ("interface_declaration" . interface)
     ("enum_declaration" . enum))
    (typescript
     ("program" . module)
     ("class_declaration" . class)
     ("function_declaration" . function)
     ("method_definition" . method)
     ("namespace_declaration" . namespace)
     ("interface_declaration" . interface)
     ("enum_declaration" . enum))
    (tsx
     ("program" . module)
     ("class_declaration" . class)
     ("function_declaration" . function)
     ("method_definition" . method))
    (rust
     ("mod_item" . module)
     ("struct_item" . struct)
     ("enum_item" . enum)
     ("trait_item" . trait)
     ("impl_item" . impl)
     ("fn_item" . function)
     ("method_declaration" . method)
     ("type_item" . alias)
     ("type_alias" . alias)
     ("const_item" . constant))
    (go
     ("package_clause" . package)
     ("type_declaration" . type)
     ("type_spec" . type)
     ("function_declaration" . function)
     ("method_declaration" . method)
     ("const_declaration" . constant))
    (c
     ("translation_unit" . file)
     ("function_definition" . function)
     ("struct_specifier" . struct)
     ("enum_specifier" . enum))
    (cpp
     ("translation_unit" . file)
     ("namespace_definition" . namespace)
     ("class_specifier" . class)
     ("struct_specifier" . struct)
     ("function_definition" . function)
     ("constructor_declaration" . constructor)
     ("destructor_declaration" . destructor)
     ("field_declaration" . field)
     ("enum_specifier" . enum))
    (java
     ("program" . file)
     ("package_declaration" . package)
     ("class_declaration" . class)
     ("interface_declaration" . interface)
     ("enum_declaration" . enum)
     ("method_declaration" . method)
     ("constructor_declaration" . constructor)
     ("field_declaration" . field))
    (elisp
     ("source_file" . file)
     ("defun" . function)
     ("defmacro" . function)
     ("cl_defmethod" . method)
     ("cl_defstruct" . struct))
    (ruby
     ("program" . file)
     ("module" . namespace)
     ("class" . class)
     ("method" . method))
    (kotlin
     ("kotlin_file" . file)
     ("package_header" . package)
     ("class_declaration" . class)
     ("interface_declaration" . interface)
     ("object_declaration" . class)
     ("function_declaration" . function)
     ("property_declaration" . property)))
  "Language-specific mapping of treesit node types to semantic kinds.")

(defun head--language-kind-lookup (lang node-type &optional _parent-kind)
  "Lookup semantic kind for LANG and NODE-TYPE.
Return a kind symbol or nil."
  (let ((table (alist-get lang head--language-kind-map)))
    (when table
      (alist-get node-type table nil nil #'string=))))

(defun head--language-detect (buffer point)
  "Detect treesit language symbol at POINT in BUFFER."
  (with-current-buffer buffer
    (when (and (fboundp 'treesit-language-at) (fboundp 'treesit-node-at))
      (save-excursion
        (goto-char point)
        (or (treesit-language-at (point))
            ;; Fallback heuristic by mode
            (pcase major-mode
              ('python-ts-mode 'python)
              ('js-ts-mode 'javascript)
              ('typescript-ts-mode 'typescript)
              ('tsx-ts-mode 'tsx)
              ('rust-ts-mode 'rust)
              ('go-ts-mode 'go)
              ('c-ts-mode 'c)
              ('c++-ts-mode 'cpp)
              ('java-ts-mode 'java)
              ('kotlin-ts-mode 'kotlin)
              ('emacs-lisp-mode 'elisp)
              (_ nil)))))))

(provide 'head-language-maps)

;;; head-language-maps.el ends here
