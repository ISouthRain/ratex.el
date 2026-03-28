;;; ratex-tests.el --- Tests for ratex.el -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'ratex-math-detect)

(ert-deftest ratex-detects-dollar-math ()
  (with-temp-buffer
    (insert "hello $x^2$ world")
    (goto-char 10)
    (let ((fragment (ratex-fragment-at-point)))
      (should (equal (plist-get fragment :content) "x^2")))))

(ert-deftest ratex-detects-bracket-math ()
  (with-temp-buffer
    (insert "a \\[x+1\\] b")
    (goto-char 7)
    (let ((fragment (ratex-fragment-at-point)))
      (should (equal (plist-get fragment :content) "x+1")))))

(provide 'ratex-tests)

;;; ratex-tests.el ends here
