;; add ~/.emacs.d to load-path
;; (add-to-list 'load-path user-emacs-directory)

(setq aed-directory (concat user-emacs-directory (file-name-as-directory "aed")))
(setq var-run-directory (concat user-emacs-directory (file-name-as-directory "var") (file-name-as-directory "run")))

;; functions

(defun aed/load (file-name)
  "Searches for FILE-NAME.el in ~/.emacs.d/ (or whatever
user-emacs-directory is), and loads it. If not found, loads
~/.emacs.d/ael/FILE-NAME.el instead."
  (setq aed-file-name
	(concat user-emacs-directory (file-name-as-directory "aed") file-name))
  (setq personal-file-name
	(concat user-emacs-directory file-name))
  (unless (load personal-file-name t) (load aed-file-name)))

(defun aed/require-package (package &optional min-version no-refresh)
  "Install given PACKAGE, optionally requiring MIN-VERSION.
If NO-REFRESH is non-nil, the available package lists will not be
re-downloaded in order to locate PACKAGE."
  (if (package-installed-p package min-version)
      t
    (if (or (assoc package package-archive-contents) no-refresh)
        (package-install package)
      (progn
        (package-refresh-contents)
        (aed/require-package package min-version t)))))

(defun aed/toggle-line-comment ()
  "Comments out the current line if it's uncommented, or uncomments the current lien if it's commented."
  ;; from <http://stackoverflow.com/a/20064658>
  (interactive)
  (let ((start (line-beginning-position))
	(end (line-end-position)))
    (when (region-active-p)
      (setq start (save-excursion
		    (goto-char (region-beginning))
		    (beginning-of-line)
		    (point))
	    end (save-excursion
		  (goto-char (region-end))
		  (end-of-line)
		  (point))))
    (comment-or-uncomment-region start end)))

(defun aed/goto-paren-or-self-insert (arg)
  "Go to the matching parenthesis if on parenthesis AND last command is a movement command, otherwise insert %.
vi style of % jumping to matching brace."
  (interactive "p")
  (message "%s" last-command)
  (if (not (memq last-command '(
                                set-mark
                                cua-set-mark
                                aed/goto-paren-or-self-insert
                                down-list
                                up-list
                                end-of-defun
                                beginning-of-defun
                                backward-sexp
                                forward-sexp
                                backward-up-list
                                forward-paragraph
                                backward-paragraph
                                end-of-buffer
                                beginning-of-buffer
                                backward-word
                                forward-word
                                mwheel-scroll
                                backward-word
                                forward-word
                                mouse-start-secondary
                                mouse-yank-secondary
                                mouse-secondary-save-then-kill
                                move-end-of-line
                                move-beginning-of-line
                                backward-char
                                forward-char
                                scroll-up
                                scroll-down
                                scroll-left
                                scroll-right
                                mouse-set-point
                                next-buffer
                                previous-buffer
                                previous-line
                                next-line
                                left-char
                                right-char)))
      (self-insert-command (or arg 1))
    (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
          ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
          (t (self-insert-command (or arg 1))))))

(defun aed/backward-kill-word (&optional arg)
  "Replacement for the backward-kill-word command
If the region is active, then invoke kill-region.  Otherwise, use
the following custom backward-kill-word procedure.
If the previous word is on the same line, then kill the previous
word.  Otherwise, if the previous word is on a prior line, then kill
to the beginning of the line.  If point is already at the beginning
of the line, then kill to the end of the previous line.

With argument ARG and region inactive, do this that many times."
  (interactive "p")
  (if (use-region-p)
      (kill-region (mark) (point))
    (let (count)
      (dotimes (count arg)
        (if (bolp)
            (delete-backward-char 1)
          (kill-region (max (save-excursion (backward-word)(point))
                            (line-beginning-position))
                       (point)))))))

;; features

(defun aed/no-startup-banner ()
  "Don't display the Emacs startup banner."
  (setq inhibit-startup-message t)
  (setq	initial-scratch-message nil)
  (setq	inhibit-startup-buffer-menu t)
  (setq	inhibit-startup-echo-area-message t))

(defun aed/fonts ()
  "Use some sensible monospace on OS X and Windows."
  (cond ((eq system-type 'darwin)
	 (set-face-attribute 'default nil :family "Menlo")
	 (set-face-attribute 'default nil :height 100))
	((eq system-type 'windows-nt)
	 (set-face-attribute 'default nil :family "Consolas")
	 (set-face-attribute 'default nil :height 80))))

(defun aed/saveplace ()
  "Save/restore the point (cursor) when exiting Emacs."
  (require 'saveplace)
  (setq-default save-place t)
  (make-directory var-run-directory t)
  (setq save-place-file (concat var-run-directory "places.el")))

(defun aed/modeline-column-numbers ()
  "Display the column number after the line number in the modeline."
  (column-number-mode t))

(defun aed/init-packages ()
  "Setup package archives and initialize the package system."
  (require 'package)
  (add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/")) (package-initialize)
  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
  (add-to-list 'package-archives '("SC" . "http://joseito.republika.pl/sunrise-commander/") t)
  (setq package-enable-at-startup nil)
  (package-initialize))

(defun aed/load-custom ()
  "Save customize settings to ~/.emacs.d/custom.el, and ensure they're loaded"
  (setq custom-file (concat user-emacs-directory "custom.el"))
  (load custom-file t))

(defun aed/no-toolbar ()
  "Turn off the toolbar."
  (tool-bar-mode -1))

(defun aed/no-bells ()
  "Turn off all bells, because I like a silent text editor."
  (setq ring-bell-function 'ignore))

(defun aed/percent-paren ()
  "Overload the % key to jump to the matching parenthesis if we're currently on one (ala vi), or insert one if we're not."
  (global-set-key (kbd "%") 'aed/goto-paren-or-self-insert))

(defun aed/highlight-paren ()
  "Highlights the matching parenthesis if the point is on a parenthesis, otherwise highlight the innermost parentheses surrounding the point."
  ;; highlights the matching parenthesis at the point
  (show-paren-mode t)
  ;; highlights the parentheses surrounding the current point
  (aed/require-package 'highlight-parentheses)
  (define-globalized-minor-mode global-highlight-parentheses-mode
    highlight-parentheses-mode
    (lambda ()
      (highlight-parentheses-mode t)))
  (global-highlight-parentheses-mode t))

(defun aed/evil ()
  "Use Evil, the Vim emulation mode. Press C-z to go to Vim mode; C-z to go back to Emacs mode."
  (aed/require-package 'evil)
  (setq evil-default-state 'emacs)
  (setq evil-want-C-u-scroll t)
  (evil-mode 1)
  (evil-set-initial-state 'man-mode 'emacs)
  (when t ;; window-system
    (define-key evil-emacs-state-map [escape] 'evil-normal-state)
    (define-key evil-normal-state-map [escape] 'evil-emacs-state)))

(defun aed/highlight-current-line ()
  "Highlight the current line."
  (global-hl-line-mode 1))

(defun aed/rebind-C-w-backward-kill-word ()
  "Make C-w delete the previous word, like it does in the shell in Vi."
  (global-set-key "\C-w" 'aed/backward-kill-word))

(defun aed/ido ()
  "Enable ido-mode. See <http://www.masteringemacs.org/articles/2010/10/10/introduction-to-ido-mode/> for a nice tutorial on ido."
  (ido-mode t)
  (setq ido-enable-flex-matching t)
  (setq ido-everywhere t)
  (setq ido-use-filename-at-point 'guess)
  (setq ido-create-new-buffer 'always)
  (setq ido-enable-last-directory-history nil)
  (add-to-list 'ido-ignore-files "\\.DS_Store")
  (aed/require-package 'ido-ubiquitous)
  (ido-ubiquitous))

(defun aed/writegood ()
  (aed/require-package 'writegood-mode))

(defun aed/console-no-menu-bar ()
  "Disable the menu bar if we're running in the console."
  (if window-system () (menu-bar-mode -1)))

(defun aed/backup-directory ()
  "Put backup files in ~/.emacs/{autosaves,backups} and keep a reasonable number of copies."
  ;; <http://snarfed.org/gnu_emacs_backup_files>
  ;; <http://stackoverflow.com/questions/151945/how-do-i-control-how-emacs-makes-backup-files>
  (setq backup-by-copying t)
  (setq auto-save-directory (concat user-emacs-directory (file-name-as-directory "autosaves")))
  (setq backups-directory (concat user-emacs-directory (file-name-as-directory "backups")))
  (make-directory auto-save-directory t)
  (make-directory backups-directory t)
  (setq auto-save-file-name-transforms '((".*" "~/.emacs.d/autosaves/\\1" t)))
  (setq backup-directory-alist '((".*" . "~/.emacs.d/backups/")))
  (setq delete-old-versions t
	kept-new-versions 6
	kept-old-versions 2
	version-control t))

(defun aed/osx-like ()
  "Define some keys that people expect with modern GUIs: Cmd-+ to increase font size, Cmd-- to decrease font size, and Cmd-W to close the current window."
  (global-set-key (kbd "s-x") 'kill-region)
  (global-set-key (kbd "s-c") 'ns-copy-including-secondary)
  (global-set-key (kbd "s-v") 'cua-paste)
  (global-set-key (kbd "s-+") 'text-scale-adjust)
  (global-set-key (kbd "s-_") 'text-scale-adjust)
  (global-set-key (kbd "s-w") 'delete-window)
  (global-set-key (kbd "M-<up>") 'backward-paragraph)
  (global-set-key (kbd "M-<down>") 'forward-paragraph)
  (global-set-key (kbd "s-[") 'previous-buffer)
  (global-set-key (kbd "s-]") 'next-buffer)
  (global-set-key (kbd "s-<left>") 'beginning-of-line)
  (global-set-key (kbd "s-<right>") 'end-of-line)
  (global-set-key (kbd "s-<up>") 'beginning-of-buffer)
  (global-set-key (kbd "s-<down>") 'end-of-buffer)

  (setq cursor-type '(bar . 1))  ;; cursor is a vertical bar, 1 pixel wide
  (setq evil-emacs-state-cursor '("black" (bar . 1)))  ;; ... if evil is loaded
  (blink-cursor-mode t)  ;; blink cursor
  )

(defun aed/xcode-like ()
  "Define some programming-related keys inspired by Xcode: Cmd-b to build the project, Ctrl-Cmd-up to go to the alternate file."
  (global-set-key (kbd "s-b") 'recompile) ;; build
  (global-set-key (kbd "s-B") 'compile) ;; build, ask for command
  (global-set-key (kbd "C-s-<up>") 'ff-find-other-file) ;; alt file
  (global-set-key '[(s-double-mouse-1)] 'find-tag) ;; cmd-double-click to go to symbol definition ;; [todo] not working
  (global-set-key (kbd "M-s-/") 'dash-at-point)
  (global-set-key (kbd "M-s-?") 'dash-at-point))

(defun aed/strip-whitespace-on-save ()
  "Strip all whitespace when saving."
  (add-hook 'before-save-hook 'delete-trailing-whitespace))

(defun aed/highlight-word-at-point ()
  "Highlight all occurences of the word at the point."
  (aed/require-package 'idle-highlight-mode)
  (setq idle-highlight-idle-time 0.2)
  (add-hook 'prog-mode-hook 'idle-highlight-mode))

(defun aed/projectile ()
  (aed/require-package 'projectile)
  (projectile-global-mode))

(defun aed/grok-vim-modelines ()
  "Understand some Vim modelines, so that we can properly set tab stop settings, spaces-or-tabs, etc."
  (add-to-list 'load-path (concat aed-directory (file-name-as-directory "emacs-vim-modeline")))
  (require 'vim-modeline)
  (add-to-list 'find-file-hook 'vim-modeline/do))

(defun aed/console-mouse ()
  "Enable the mouse in the console."
  (unless window-system
    (require 'mouse)
    (xterm-mouse-mode t)
    ;; (global-set-key [mouse-4] '(lambda ()
    ;; 				 (interactive)
    ;; 				 (scroll-down-command)))
    ;; (global-set-key [mouse-5] '(lambda ()
    ;; 				 (interactive)
    ;; 				 (scroll-up-command)))
    (setq mouse-sel-mode t)
    (defun track-mouse (e)))

  ;; re-enable xterm-mouse-mode when reattaching with emacsclient
  (add-hook 'server-visit-hook (lambda () (xterm-mouse-mode t))))

(defun aed/autopair ()
  "Enable autopair, which automatically inserts closing parentheses and quotes as you type them."
  (aed/require-package 'autopair)
  (autopair-global-mode))

(defun aed/eshell ()
  "Define some eshell settings and aliases. more/less in eshell will view the file in Emacs instead, and emacs/ec will open the file in another buffer."
  (defalias 'sh 'eshell)
  (setq eshell-banner-message "")
  (setq eshell-banner-shorthand t)
  (defun eshell/emacs (file-name)
    find-file-other-window file-name)
  (defalias 'eshell/ec 'eshell/emacs)
  (defun eshell/less (&rest args)
    "Invoke `view-file' on a file. \"less +42 foo\" will go to line 42 in
    the buffer for foo."
    (while args
      (if (string-match "\\`\\+\\([0-9]+\\)\\'" (car args))
          (let* ((line (string-to-number (match-string 1 (pop args))))
                 (file (pop args)))
            (view-file file)
            (goto-line line))
        (view-file (pop args)))))
  (defalias 'eshell/more 'eshell/less)
  (defun eshell/term () ()) ;; open -a iTerm .
  (when (featurep 'evil) (evil-set-initial-state 'eshell-mode 'emacs)))

(defun aed/sr-speedbar ()
  "Speedbar, but in the same frame. Invoke with M-x sr-speedbar."
  (aed/require-package 'sr-speedbar))

(defun aed/ibuffer ()
  "Use ibuffer for C-x C-b."
  (global-set-key (kbd "C-x C-b") 'ibuffer))

(defun aed/ace-jump-mode ()
  "Enable the awesome ace-jump-mode: quickly navigate to anywhere on the screen."
  (aed/require-package 'ace-jump-mode)
  (global-set-key (kbd "C-c C-SPC") 'ace-jump-word-mode)
  (global-set-key (kbd "C-x C-SPC") 'ace-jump-mode-pop-mark)
  (when (featurep 'evil) (define-key evil-normal-state-map (kbd "SPC") 'ace-jump-mode)))

(defun aed/rebind-C-O-previous-window ()
  "Make C-x O (that's C-x Shift-o) go to the previous window."
  (global-set-key (kbd "C-x O") 'previous-multiframe-window))

(defun aed/undo-tree ()
  "Enable undo-tree, which enables branching undo/redo."
  (aed/require-package 'undo-tree))

(defun aed/rebind-C-x-C-u-undo ()
  "Rebind C-x C-u to undo."
  (global-set-key (kbd "C-x C-u") (if (featurep 'undo-tree) 'undo-tree-undo 'undo)))

(defun aed/persistent-M-x-history ()
  "Make history of M-x commands persistent."
  (savehist-mode 1))

(defun aed/smartscan ()
  "smartscan-mode <https://github.com/mickeynp/smart-scan>. Use M-n/M-p to move to the previous/next matching word in the current buffer, similarly to * and # in vim. Use M-' to replace all symbols in the current buffer, and M-' to replace symbols in the current defun."
  (aed/require-package 'smartscan)
  (global-smartscan-mode 1))

(defun aed/y-or-n-instead-of-yes-or-no ()
  "Use y or n as confirmation of prompts, rather than yes or no."
  (fset 'yes-or-no-p 'y-or-n-p))

(defun aed/describe-face-at-point ()
  "Define a describe-face-at-point function, which describes the face at the point."
  (defun describe-face-at-point (pos)
    "Describes the face at the point."
    (interactive "d")
    (let ((face (or (get-char-property (point) 'read-face-name)
		    (get-char-property (point) 'face))))
      (if face (message "Face: %s" face) (message "No face at %d" pos)))))

(defun aed/linum-relative ()
  "Add the current line number to the fringe of the window, and relative line numbers before and after the current line number. This enables you to easily jump up and down the screen by typing M-<line number> <up>."
  (aed/require-package 'linum-relative)
  (require 'linum-relative)
  (setq linum-relative-current-symbol "")
  (setq linum-relative-format "%4s ")
  (global-linum-mode t))

(defun aed/srcoll-preserve-screen-position ()
  "When scrolling, preserve the absolute position of the line that the point is on."
  (setq scroll-preserve-screen-position t))

(defun aed/expand-region ()
  "Use M-] to quickly select text from the region."
  (aed/require-package 'expand-region)
  (global-set-key (kbd "M-[") 'er/expand-region))

(defun aed/uniquify-buffer-names ()
  "Display more useful buffer names if the same filename from different directories are loaded at the same time."
  (require 'uniquify)
  (setq uniquify-buffer-name-style 'post-forward-angle-brackets))

(defun aed/anzu ()
  "anzu-mode: When searching, show how many matches there are for the search in the modeline, and which match you are at."
  (aed/require-package 'anzu)
  (global-anzu-mode +1)
  (global-set-key (kbd "M-%") 'anzu-query-replace)
  (global-set-key (kbd "C-M-%") 'anzu-query-replace-regexp))

(defun aed/hippie-expand ()
  "Remap M-/ from dabbrev-expand to hippie-expand."
  (setq hippie-expand-try-functions-list '(try-expand-dabbrev try-expand-dabbrev-all-buffers try-expand-dabbrev-from-kill try-complete-file-name-partially try-complete-file-name try-expand-all-abbrevs try-expand-list try-expand-line try-complete-lisp-symbol-partially try-complete-lisp-symbol))
  (global-set-key (kbd "M-/") 'hippie-expand))

(defun aed/rebind-M-semicolon-toggle-line-comment ()
  "Remap M-; to comment out the current line if it's uncommented, or uncomment the line if it is commented."
  (global-set-key (kbd "M-;") 'aed/toggle-line-comment)
  (global-set-key (kbd "s-/") 'aed/toggle-line-comment))

(defun aed/save-before-compile ()
  (setq compilation-ask-about-save nil))

(defun aed/auto-indent ()
  (aed/require-package 'auto-indent-mode)
  (auto-indent-global-mode)

  (setq local-function-key-map (delq '(kp-tab . [9]) local-function-key-map)))

(defun aed/interactive-aliases ()
  (defalias 'e! 'revert-buffer) ;; ala vim
  (defalias 'qrr 'query-replace-regexp)
  (defalias 'make 'recompile))

(defun aed/cua-features ()
  "CUA (Common User Access) features. Turns out this is far more than just the C-x/C-c/C-v bindings that many people think.

1. Typing text while a region is active deletes it.
2. Use C-RET to mark a rectangle, with a surprising number of features. e.g. Press RET while in rectangle selection mode to move the point to the next corner, and then start typing to insert text at the point. See link 2 for more info.
For more info:
3. Global mark, where all text that's yanked (pasted) will go to the global mark instead of the current point.

1. <http://www.gnu.org/software/emacs/manual/html_node/emacs/CUA-Bindings.html>.
2. <http://www.cua.dk/cua.html>"
  (setq cua-enable-cua-keys nil)
  (cua-mode 1)
  ;; re-enable C-w & M-w for cut/paste in rectangle mode
  (define-key cua--rectangle-keymap (kbd "C-w") 'cua-cut-rectangle)
  (define-key cua--rectangle-keymap (kbd "M-w") 'cua-copy-rectangle))

(defun aed/modeline-color ()
  (lexical-let ((default-color (cons (face-background 'mode-line)
                                     (face-foreground 'mode-line))))
    (add-hook 'post-command-hook
              (lambda ()
                (let ((color (cond ((minibufferp) default-color)
                                   ((evil-insert-state-p) '("#e80000" . "#ffffff"))
                                   ((evil-emacs-state-p) default-color)
                                   ((buffer-modified-p) '("#006fa0" . "#ffffff"))
                                   (t default-color))))
                  (set-face-background 'mode-line (car color))
                  (set-face-foreground 'mode-line (cdr color)))))))

(defun aed/dash-at-point ()
  (aed/require-package 'dash-at-point))

(defun aed/clickable-urls ()
  (define-globalized-minor-mode global-goto-address-mode
    goto-address-mode
    (lambda ()
      (goto-address-mode t)))
  (global-goto-address-mode t))

(defun aed/ctrl-digits ()
  (defun next-line-with-argument (arg)
    (interactive "p")
    ;; (cua-cancel)
    ;; (cua-set-mark)
    (call-interactively 'digit-argument)
    (next-line (prefix-numeric-value prefix-arg))
    (setq prefix-arg "0"))

  ;; i have no idea how to use dolist and dotimes, so this is just
  ;; written out explicitly.
  (global-set-key (kbd "C-1") 'next-line-with-argument)
  (global-set-key (kbd "C-2") 'next-line-with-argument)
  (global-set-key (kbd "C-3") 'next-line-with-argument)
  (global-set-key (kbd "C-4") 'next-line-with-argument)
  (global-set-key (kbd "C-4") 'next-line-with-argument)
  (global-set-key (kbd "C-5") 'next-line-with-argument)
  (global-set-key (kbd "C-6") 'next-line-with-argument)
  (global-set-key (kbd "C-7") 'next-line-with-argument)
  (global-set-key (kbd "C-8") 'next-line-with-argument))

(defun aed/use-shell-environment ()
  (when (memq window-system '(mac ns))
    (aed/require-package 'exec-path-from-shell)
    (exec-path-from-shell-initialize)))

(defun aed/navigate-windows-via-keyboard ()
  (aed/require-package 'windmove)
  (global-set-key (kbd "C-S-<left>") 'windmove-left)
  (global-set-key (kbd "C-S-<right>") 'windmove-right)
  (global-set-key (kbd "C-S-<up>") 'windmove-up)
  (global-set-key (kbd "C-S-<down>")  'windmove-down))

(defun aed/adaptive-wrap ()
  (when (fboundp 'adaptive-wrap-prefix-mode)
    (defun my-activate-adaptive-wrap-prefix-mode ()
      "Toggle `visual-line-mode' and `adaptive-wrap-prefix-mode' simultaneously."
      (adaptive-wrap-prefix-mode (if visual-line-mode 1 -1)))
    (add-hook 'visual-line-mode-hook 'my-activate-adaptive-wrap-prefix-mode))
  (global-visual-line-mode))

(defun aed/company-mode ()
  (aed/require-package 'company)
  (add-hook 'after-init-hook 'global-company-mode)

  (defun company-dabbrev-case-sensitive (command &optional arg &rest ignored)
    "dabbrev-like `company-mode' completion back-end; case-sensitive."
    (interactive (list 'interactive))
    (case command
      (interactive (company-begin-backend 'company-dabbrev))
      (prefix (company-grab-word))
      (candidates
               (company-dabbrev--search (company-dabbrev--make-regexp arg)
                                        company-dabbrev-time-limit
                                        company-dabbrev-other-buffers))
      (duplicates t)))

  (provide 'company-dabbrev-case-sensitive))

(defun aed/keyfreq ()
  (aed/require-package 'keyfreq)
  (keyfreq-mode 1)
  (keyfreq-autosave-mode 1))

(defun aed/discover ()
  (aed/require-package 'discover)
  (global-discover-mode))

(defun aed/ag ()
  (setq ag-executable (executable-find "ag"))
  (when ag-executable (progn (aed/require-package 'ag)
			     (require 'ag))))

(defun aed/smex ()
  "Completion for M-x commands."
  (aed/require-package 'smex)
  (smex-initialize)
  (smex-initialize-ido)
  (global-set-key (kbd "M-x") 'smex)

  ;; smex doesn't work for describe-variable and describe-function, so
  ;; use icomplete-mode for that.
  (icomplete-mode 1))

(defun aed/revert-all-buffers ()
  (defun revert-all-buffers ()
    "Refreshes all open buffers from their respective files."
    (interactive)
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (and (buffer-file-name) (file-exists-p (buffer-file-name)) (not (buffer-modified-p)))
          (revert-buffer t t t) )))
    (message "Refreshed open files.")))



;; mode-specific

(defun aed/ggtags ()
  "Use ggtags as the tags mode."
  (aed/require-package 'ggtags)
  (add-hook 'prog-mode-hook
            (lambda ()
              (when (derived-mode-p 'c-mode 'c++-mode 'java-mode) (ggtags-mode 1))
              (modify-syntax-entry ?_ "w"))))

(defun aed/c-mode-slash-slash-comments ()
  "Use // for C comments, instead of /* */."
  (add-hook 'c-mode-hook (lambda () (setq comment-start "//"
                                          comment-end   ""))))

(defun aed/c-mode-hide-ifdefs ()
  (add-hook 'c-mode-hook 'hide-ifdef-mode))



;; unused features

(defun aed/pretty-symbols ()
  "This breaks list-colors-display :(."
  (aed/require-package 'pretty-symbols)
  (define-globalized-minor-mode global-pretty-symbols-mode
    pretty-symbols-mode
    (lambda ()
      (pretty-symbols-mode t)))
  (global-pretty-symbols-mode t))

(defun aed/auto-complete+yasnippet ()
  "TODO: Probably the best we can do without understanding the project, include paths, etc, which varies depending on the build setup. And company-mode seems better."
  (aed/require-package 'yasnippet)
  (require 'yasnippet)
  (yas-global-mode 1)

  (aed/require-package 'auto-complete)
  (require 'auto-complete-config)
  (ac-config-default)
  (setq ac-delay 0.1)
  (setq ac-ignore-case nil)

  (aed/require-package 'pos-tip)
  (require 'pos-tip)

  ;; use clang as source for completion for C-like languages
  (setq ac-clang-complete-executable (executable-find "clang-complete"))
  (if ac-clang-complete-executable
      (progn (aed/require-package 'auto-complete-clang-async)
             (defadvice ac-cc-mode-setup (after aed/ac-cc-mode-add-clang-async ())
               "Add clang-async to autocomplete source for C modes."
               (setq ac-sources (cons 'ac-source-clang-async ac-sources))
               (ac-clang-launch-completion-process))
             (ad-activate 'ac-cc-mode-setup))
    (progn (aed/require-package 'auto-complete-clang)
           (require 'auto-complete-clang)
           (defadvice ac-cc-mode-setup (after aed/ac-cc-mode-add-clang ())
             "Add clang to autocomplete source for C modes."
             (setq ac-sources (cons 'ac-source-clang ac-sources)))
           (ad-activate 'ac-cc-mode-setup))))

(defun aed/irony-mode ()
  (aed/require-package 'yasnippet)
  (require 'yasnippet)
  ;; (yas-global-mode 1)

  (aed/require-package 'auto-complete)
  (require 'auto-complete-config)
  (ac-config-default)
  (setq ac-delay 0.1)
  (setq ac-ignore-case nil)

  (aed/require-package 'pos-tip)
  (require 'pos-tip)

  (add-to-list 'load-path (expand-file-name "~/Code/emacs/irony-mode/elisp/"))
  (require 'irony) ;Note: hit `C-c C-b' to open build menu

  ;; the ac plugin will be activated in each buffer using irony-mode
  (irony-enable 'ac)             ; hit C-RET to trigger completion

  (defun my-c++-hooks ()
    "Enable the hooks in the preferred order: 'yas -> auto-complete -> irony'."
    ;; if yas is not set before (auto-complete-mode 1), overlays may persist after
    ;; an expansion.
    (yas/minor-mode-on)
    (auto-complete-mode 1)

    ;; avoid enabling irony-mode in modes that inherits c-mode, e.g: php-mode
    (when (member major-mode irony-known-modes)
      (irony-mode 1)))

  (add-hook 'c++-mode-hook 'my-c++-hooks)
  (add-hook 'c-mode-hook 'my-c++-hooks))

(defun aed/mac-use-option-for-meta-commmand-for-super ()
  (when (boundp 'mac-option-modifier)
    (setq mac-option-modifier 'meta))
  (when (boundp 'mac-command-modifier)
    (setq mac-command-modifier 'super)))

(defun aed/compile-follow-buffer ()
  (setq compilation-scroll-output 'first-error))

(defun aed/require-magit ()
  (aed/require-package 'magit))

(defun aed/require-markdown-mode ()
  (aed/require-package 'markdown-mode)
  ;; leave my meta arrow keys alone, please!
  (define-key markdown-mode-map (kbd "M-<up>") nil)
  (define-key markdown-mode-map (kbd "M-<down>") nil)
  (define-key markdown-mode-map (kbd "M-<left>") nil)
  (define-key markdown-mode-map (kbd "M-<right>") nil))

(defun aed/rainbow-delimeters ()
  (aed/require-package 'rainbow-delimiters)
  (global-rainbow-delimiters-mode))

(defun aed/detach-window ()
  (defun detach-window ()
    "Close current window and re-open it in new frame."
    (interactive)
    (let ((current-buffer (window-buffer)))
      (delete-window)
      (select-frame (make-frame))
      (set-window-buffer (selected-window) current-buffer)))
  (global-set-key (kbd "C-x 5 3") 'detach-window))

(defun aed/indicate-empty-lines ()
  (setq-default indicate-empty-lines t))

(defun aed/diff-hl ()
  (aed/require-package 'diff-hl)
  (global-diff-hl-mode))

(defun aed/binary-line-move ()
  (lexical-let ((beg -1)
                (end -1)
                (prev-mid -1))

    (defun backward-binary ()
      (interactive)
      (if (/= prev-mid (point))
          (setq beg -1 end -1)
        (setq end prev-mid))
      (if (< beg 0) (setq beg (line-beginning-position)
                          end (point)))
      (setq prev-mid (/ (+ beg end) 2))
      (goto-char prev-mid))

    (defun forward-binary ()
      (interactive)
      (if (/= prev-mid (point))
          (setq beg -1 end -1)
        (setq beg prev-mid))
      (if (< end 0) (setq beg (point)
                          end (line-end-position)))
      (setq prev-mid (/ (+ beg end ) 2))
      (goto-char prev-mid))
    )

  (global-set-key (kbd "M-9") 'backward-binary)
  (global-set-key (kbd "M-0") 'forward-binary))

(defun aed/binary-line-move ()
  (lexical-let ((beg -1)
                (end -1)
                (prev-mid -1))

    (defun backward-binary ()
      (interactive)
      (if (/= prev-mid (point))
          (setq beg -1 end -1)
        (setq end prev-mid))
      (if (< beg 0) (setq beg (line-beginning-position)
                          end (point)))
      (setq prev-mid (/ (+ beg end) 2))
      (goto-char prev-mid))

    (defun forward-binary ()
      (interactive)
      (if (/= prev-mid (point))
          (setq beg -1 end -1)
        (setq beg prev-mid))
      (if (< end 0) (setq beg (point)
                          end (line-end-position)))
      (setq prev-mid (/ (+ beg end ) 2))
      (goto-char prev-mid))
    )

  (global-set-key (kbd "M-9") 'backward-binary)
  (global-set-key (kbd "M-0") 'forward-binary))

(defun aed/smooth-scroll ()
  (aed/require-package 'sublimity)
  (require 'sublimity)
  (require 'sublimity-scroll)
  (setq sublimity-scroll-weight 3
        sublimity-scroll-drift-length 1)
  (sublimity-mode 1))

;; Functions

(defun aed-edit ()
  "Edit ~/.emacs.d/aed/init.el."
  (interactive)
  (find-file (concat aed-directory "init.el")))

;; enable features

(aed/init-packages)
(aed/use-shell-environment)
(aed/fonts)
(aed/saveplace)
(aed/modeline-column-numbers)
(aed/no-toolbar)
(aed/no-bells)
(aed/percent-paren)
(aed/highlight-paren)
(aed/evil)
(aed/highlight-current-line)
(aed/rebind-C-w-backward-kill-word)
(aed/console-no-menu-bar)
(aed/backup-directory)
(aed/osx-like)
(aed/xcode-like)
(aed/strip-whitespace-on-save)
(aed/ggtags)
(aed/highlight-word-at-point)
(aed/grok-vim-modelines)
(aed/console-mouse)
(aed/autopair)
(aed/eshell)
(aed/sr-speedbar)
(aed/ibuffer)
(aed/ace-jump-mode)
(aed/rebind-C-O-previous-window)
(aed/undo-tree)
(aed/rebind-C-x-C-u-undo)
(aed/persistent-M-x-history)
(aed/c-mode-slash-slash-comments)
(aed/smartscan)
(aed/y-or-n-instead-of-yes-or-no)
(aed/describe-face-at-point)
;; (aed/linum-relative)
(aed/srcoll-preserve-screen-position)
(aed/expand-region)
(aed/uniquify-buffer-names)
(aed/anzu)
(aed/hippie-expand)
(aed/load-custom)
(aed/rebind-M-semicolon-toggle-line-comment)
(aed/save-before-compile)
(aed/auto-indent)
(aed/interactive-aliases)
(aed/ido)
(aed/dash-at-point)
(aed/modeline-color)
(aed/cua-features)
(aed/ctrl-digits)
(aed/navigate-windows-via-keyboard)
(aed/adaptive-wrap)
(aed/writegood)
(aed/company-mode)
;; (aed/auto-complete+yasnippet)
;; (aed/irony-mode)

(aed/diff-hl)
(aed/keyfreq)
(aed/smex)
(aed/c-mode-hide-ifdefs)
;; (aed/icicles)
(aed/revert-all-buffers)
(aed/mac-use-option-for-meta-commmand-for-super)
(aed/projectile)
(aed/compile-follow-buffer)
(aed/require-magit)
(aed/require-markdown-mode)
(aed/no-startup-banner)
(aed/rainbow-delimeters)
(aed/detach-window)
(aed/indicate-empty-lines)
(aed/binary-line-move)
(aed/smooth-scroll)

;; todo

(setq ns-use-srgb-colorspace t)
(setq ispell-program-name "aspell")

;; things to install: aspell
