;;; ratex-render.el --- Async rendering client -*- lexical-binding: t; -*-

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'ratex-core)
(require 'ratex-math-detect)
(require 'ratex-overlays)

(defvar-local ratex--last-request-id nil)
(defvar-local ratex--render-cache (make-hash-table :test #'equal))
(defvar-local ratex--last-error nil)
(defvar-local ratex--active-fragment nil)

(defun ratex-render-fragment-at-point ()
  "Render the last formula fragment when point is outside it."
  (interactive)
  (let ((fragment (ratex-fragment-at-point)))
    (cond
     (fragment
      (setq ratex--active-fragment fragment)
      (ratex-clear-overlay))
     (ratex--active-fragment
      (let ((to-render ratex--active-fragment))
        (setq ratex--active-fragment nil)
        (ratex--render-fragment to-render)))
     (t
      (ratex-clear-overlay)))))

(defun ratex-handle-post-command ()
  "Update preview state after each command."
  (when ratex-mode
    (ratex-render-fragment-at-point)))

(defun ratex--render-fragment (fragment)
  "Render FRAGMENT plist."
  (let* ((content (string-trim (plist-get fragment :content)))
         (cache-key (list content ratex-font-size ratex-svg-padding))
         (cached (gethash cache-key ratex--render-cache)))
    (if cached
        (ratex--display-response fragment cached)
      (setq ratex--last-request-id
            (ratex-request
             `((type . "render")
               (latex . ,content)
               (font_size . ,ratex-font-size)
               (padding . ,ratex-svg-padding)
               (embed_glyphs . t))
             (lambda (response)
               (when (equal (alist-get 'id response) ratex--last-request-id)
                 (when (alist-get 'ok response)
                   (puthash cache-key response ratex--render-cache))
                 (unless (ratex-fragment-at-point)
                   (ratex--display-response fragment response)))))))))

(defun ratex--display-response (fragment response)
  "Display backend RESPONSE for FRAGMENT."
  (if (not (alist-get 'ok response))
      (progn
        (setq ratex--last-error (alist-get 'error response))
        (ratex-clear-overlay)
        (when ratex--last-error
          (message "RaTeX render failed: %s" ratex--last-error)))
    (let* ((svg (alist-get 'svg response))
           (baseline (or (alist-get 'baseline response) 0.0))
           (height (max 0.001 (or (alist-get 'height response) 0.0)))
           (image (create-image
                   svg
                   'svg t
                   :ascent (floor (* 100.0 (/ baseline height))))))
      (setq ratex--last-error nil)
      (ratex-show-overlay
       (plist-get fragment :begin)
       (plist-get fragment :end)
       image
       (format "RaTeX %s" (if (alist-get 'cached response) "cached" "rendered"))))))

(provide 'ratex-render)

;;; ratex-render.el ends here
