;;; head-layout.el --- Width-aware layout and truncation -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1"))
;; Version: 0.1.0
;; Keywords: convenience, ui
;; URL: https://example.org/head-mode

;;; Commentary:
;; Layout policy for head-mode:
;; - Respect a width budget (absolute chars derived from window and percent).
;; - Preserve last N tail segments intact where possible.
;; - Middle-ellipsis truncation for long labels.
;; - Collapse head segments into a single ellipsis when needed.
;;
;; References:
;; - spec/06-layout-and-rendering.org
;; - spec/08-configuration-and-profiles.org#profiles

;;; Code:

(require 'subr-x)

(defvar head-mode-separator)
(defvar head-mode-tail-keep)
(defvar head-mode-max-width-percent)

(defun head-layout--window-width (&optional window)
  "Return text columns available in WINDOW (default: selected)."
  (let* ((w (or window (selected-window))))
    (max 0 (window-total-width w))))

(defun head-layout-compute-budget (&optional window)
  "Compute character budget for header-line in WINDOW.
Uses head-mode-max-width-percent of window width, clamped to at least 10."
  (let* ((cols (head-layout--window-width window))
         (pct (or head-mode-max-width-percent 0.6))
         (budget (floor (* cols (min 1.0 (max 0.1 pct))))))
    (max 10 budget)))

(defun head-layout--join-width (labels &optional sep)
  "Compute width of LABELS joined by SEP (string-width)."
  (let* ((s (or sep "")))
    (if (null labels) 0
      (let ((w 0)
            (first t))
        (dolist (l labels w)
          (setq w (+ w (string-width (or l ""))))
          (unless first
            (setq w (+ w (string-width s))))
          (setq first nil))))))

(defun head-layout--ellipsize-middle (s maxw)
  "Return S truncated to MAXW columns with a middle ellipsis if needed."
  (let* ((w (string-width s)))
    (cond
     ((<= w maxw) s)
     ((<= maxw 1) "…")
     ((<= maxw 3) "…")
     (t
      (let* ((half (max 1 (/ (- maxw 1) 2)))
             (left (truncate half))
             (right (- maxw 1 left))
             (lpart (truncate-string-to-width s left 0 ?\s))
             (rpart (truncate-string-to-width s right nil ?\s t)))
        (concat lpart "…" rpart))))))

(defun head-layout--shrink-labels-greedily (labels target &optional sep)
  "Greedily shrink LABELS (list of strings) with middle ellipsis until width ≤ TARGET.
Return a new list."
  (let ((sep (or sep ""))
        (out (copy-sequence labels))
        (guard 128))
    (while (and (> (head-layout--join-width out sep) target)
                (> guard 0))
      (setq guard (1- guard))
      ;; Find longest label index among OUT
      (let* ((maxw -1)
             (maxi -1))
        (dotimes (i (length out))
          (let* ((w (string-width (nth i out))))
            (when (> w maxw)
              (setq maxw w maxi i))))
        (when (>= maxi 0)
          (let* ((curr (nth maxi out))
                 (currw (string-width curr))
                 (excess (- (head-layout--join-width out sep) target))
                 (neww (max 1 (- currw (max 1 excess))))
                 (shrunk (head-layout--ellipsize-middle curr neww)))
            (setf (nth maxi out) shrunk)))))
    out))

(defun head-layout-fit (sections budget &optional sep tail-keep)
  "Return list of label strings for SECTIONS that fits within BUDGET chars.
SEP is the separator string (default head-mode-separator).
Preserve last TAIL-KEEP segments intact where possible (default head-mode-tail-keep).
If necessary, collapse head into a single ellipsis and shrink tail greedily."
  (let* ((sep (or sep head-mode-separator " "))
         (n (length sections))
         (keep (or tail-keep head-mode-tail-keep 2))
         (labels (mapcar (lambda (s) (or (plist-get s :display-name) "")) sections))
         (total (head-layout--join-width labels sep)))
    (cond
     ((<= total budget) labels)
     ((<= n keep)
      ;; Not enough head to collapse; shrink all greedily.
      (head-layout--shrink-labels-greedily labels budget sep))
     (t
      ;; Collapse head to a single ellipsis, keep last KEEP segments
      (let* ((tail (cl-subseq labels (max 0 (- n keep)) n))
             (head-ellipsis '("…"))
             (joined (append head-ellipsis tail))
             (need (head-layout--join-width joined sep)))
        (if (<= need budget)
            joined
          ;; shrink greedily over the tail (and if needed ellipsis stays as single char)
          (head-layout--shrink-labels-greedily joined budget sep)))))))

(provide 'head-layout)

;;; head-layout.el ends here
