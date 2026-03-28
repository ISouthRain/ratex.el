;;; ratex-core.el --- Process management for ratex.el -*- lexical-binding: t; -*-

;; Copyright (C) 2026

;; Author: ratex.el contributors
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1") (jsonrpc "1.0.24"))
;; Keywords: tex, math, tools

;;; Commentary:

;; Core backend process management for ratex.el.

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'subr-x)

(defgroup ratex nil
  "Inline math rendering with RaTeX."
  :group 'tex)

(defcustom ratex-backend-command
  '("cargo" "run" "--quiet" "--manifest-path" "backend/Cargo.toml")
  "Command used to start the RaTeX editor backend."
  :type '(repeat string))

(defcustom ratex-font-size 16.0
  "Default backend SVG font size."
  :type 'number)

(defcustom ratex-svg-padding 2.0
  "Default SVG padding sent to the backend."
  :type 'number)

(defvar ratex--process nil)
(defvar ratex--process-buffer " *ratex-backend*")
(defvar ratex--pending (make-hash-table :test #'eql))
(defvar ratex--next-id 0)
(defvar ratex--read-buffer "")

(defun ratex-backend-live-p ()
  "Return non-nil when the backend process is alive."
  (and ratex--process (process-live-p ratex--process)))

(defun ratex-start-backend ()
  "Start the backend process if needed."
  (unless (ratex-backend-live-p)
    (let* ((default-directory (ratex--project-root))
           (program (car ratex-backend-command))
           (args (cdr ratex-backend-command)))
      (setq ratex--read-buffer "")
      (setq ratex--process
            (make-process
             :name "ratex-backend"
             :buffer ratex--process-buffer
             :command (cons program args)
             :coding 'utf-8-unix
             :connection-type 'pipe
             :noquery t
             :filter #'ratex--process-filter
             :sentinel #'ratex--process-sentinel))))
  ratex--process)

(defun ratex-stop-backend ()
  "Stop the backend process."
  (interactive)
  (when (ratex-backend-live-p)
    (delete-process ratex--process))
  (setq ratex--process nil))

(defun ratex-request (payload callback)
  "Send PAYLOAD to backend and invoke CALLBACK with parsed response."
  (let* ((proc (ratex-start-backend))
         (id (cl-incf ratex--next-id))
         (data (append (list (cons 'id id)) payload)))
    (puthash id callback ratex--pending)
    (process-send-string proc (concat (json-encode data) "\n"))
    id))

(defun ratex-ping (callback)
  "Ping the backend and invoke CALLBACK with the response."
  (ratex-request '((type . "ping")) callback))

(defun ratex--process-filter (_proc chunk)
  "Process backend output CHUNK."
  (setq ratex--read-buffer (concat ratex--read-buffer chunk))
  (let (line)
    (while (string-match "\n" ratex--read-buffer)
      (setq line (substring ratex--read-buffer 0 (match-beginning 0)))
      (setq ratex--read-buffer (substring ratex--read-buffer (match-end 0)))
      (when (not (string-empty-p line))
        (ratex--dispatch-line line)))))

(defun ratex--dispatch-line (line)
  "Dispatch one backend output LINE."
  (let* ((json-object-type 'alist)
         (json-array-type 'list)
         (json-false :false)
         (data (ignore-errors (json-read-from-string line))))
    (when data
      (let* ((id (alist-get 'id data))
             (callback (gethash id ratex--pending)))
        (when callback
          (remhash id ratex--pending)
          (funcall callback data))))))

(defun ratex--process-sentinel (proc event)
  "Handle backend PROC EVENT."
  (unless (process-live-p proc)
    (maphash
     (lambda (_id callback)
       (funcall callback `((ok . :false) (error . ,(string-trim event)))))
     ratex--pending)
    (clrhash ratex--pending)
    (setq ratex--process nil)))

(defun ratex--project-root ()
  "Return the root directory for ratex.el."
  (or (locate-dominating-file default-directory "backend/Cargo.toml")
      default-directory))

(provide 'ratex-core)

;;; ratex-core.el ends here

