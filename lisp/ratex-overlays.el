;;; ratex-overlays.el --- Overlay helpers -*- lexical-binding: t; -*-

;;; Code:

(defvar-local ratex--overlay nil)

(defun ratex-clear-overlay ()
  "Delete the active RaTeX overlay in the current buffer."
  (when (overlayp ratex--overlay)
    (delete-overlay ratex--overlay)
    (setq ratex--overlay nil)))

(defun ratex-show-overlay (beg end image &optional help-echo)
  "Show IMAGE at BEG..END with optional HELP-ECHO."
  (ratex-clear-overlay)
  (setq ratex--overlay (make-overlay beg end))
  (overlay-put ratex--overlay 'display image)
  (overlay-put ratex--overlay 'evaporate t)
  (when help-echo
    (overlay-put ratex--overlay 'help-echo help-echo)))

(provide 'ratex-overlays)

;;; ratex-overlays.el ends here

