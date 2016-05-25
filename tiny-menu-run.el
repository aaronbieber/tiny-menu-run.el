;;; tiny-menu-run.el --- Run a selected command from one menu.

;;; Commentary:

;; This is meant to be used simiarly to the much more feature-rich
;; "Hydra" package where keys are "chained" to create groups of
;; commands.  This package always presents an interactive menu in the
;; minibuffer, and can also generate a dynamic menu of all available
;; menus.
;;
;; To use the tiny menu, simply define the `tiny-menu-run-items'
;; variable and then map keys to the items using the
;; `tiny-menu-run-item' macro.
;;
;; `tiny-menu-run-items' is an alist of "items" where each "item" is a
;; menu of available options.  A menu is a list whose car is the name
;; of the menu and cdr is a list of menu items.  Each menu item is a
;; list with three elements: the raw character code a user must press
;; to select the item, the display name for the item, and the function
;; to be called when the item is selected.
;;
;; For example, it might look like this:
;;
;; '(("buffer-menu" ("Buffer operations"
;;                   ((?k "Kill" kill-this-buffer)
;;                    (?b "Bury" bury-buffer))))
;;   ("help-menu"   ("Help operations"
;;                   ((?f "Describe function" describe-function)
;;                    (?k "Describe key"      describe-key)))))
;;
;; This value defines two menus, one named "buffer-menu" and another
;; named "help-menu".  You can now bind a key to display a menu of the
;; menus by calling `tiny-menu-run' with no arguments, but the prompt
;; letters will simply be alphabetical.  It is much more ergonomic to
;; map specific keys to each of the menus, which is simplified by
;; using the `tiny-menu-run-item' macro, like this:
;; 
;; (define-key some-map (kbd "<key>") (tiny-menu-run-item "buffer-menu"))
;;
;; The macro returns an anonymous interactive function suitable for
;; key binding.
;;
;; It may also be useful (though not required) to use a custom prefix
;; key if all of the menus are related.  This is covered in other
;; Emacs documentation, but for the sake of convenience, this is how
;; you could do that:
;;
;; (define-prefix-command tiny-menu-map)
;; (define-key tiny-menu-map
;;   (kbd "<menu-key-1>") (tiny-menu-run-item "menu-1"))
;; (define-key tiny-menu-map
;;   (kbd "<menu-key-2>") (tiny-menu-run-item "menu-2"))
;; (define-key global-map (kbd "<prefix>") tiny-menu-map)

;;; Code:
(defface tiny-menu-run-heading-face
  '((t (:inherit 'font-lock-string-face)))
  "The menu heading shown in the selection menu for `tiny-menu-run'."
  :group 'tiny-menu-run)

(defvar tiny-menu-run-items
  '(())
  "An alist of menus.

The keys in the alist are simple strings used to reference the menu in
calls to `tiny-menu-run' and the values are lists with three elements:
A raw character to use as the selection key, such as `?a'; a string to
use in the menu display, and a function to call when that item is
selected.

The data structure should look like:

'((\"menu-1\" (?a \"First item\" function-to-call-for-item-1)
            (?b \"Second item\" function-to-call-for-item-2))
  (\"menu-2\" (?z \"First item\" function-to-call-for-item-1)
            (?x \"Second item\" function-to-call-for-item-2)))")

(defun tiny-menu-run (&optional menu)
  "Display the items in MENU and run the selected item.

If MENU is not given, a dynamically generated menu of available menus
is displayed."
  (interactive)
  (if (< (length tiny-menu-run-items) 1)
      (message "Configure tiny-menu-run-items first.")
    (let* ((menu (if (assoc menu tiny-menu-run-items)
                     (cadr (assoc menu tiny-menu-run-items))
                   (air-menu-of-menus)))
           (title (car menu))
           (items (append (cadr menu)
                          '((?q "Quit" nil))))
           (prompt (concat (propertize (concat title ": ") 'face 'default)
                           (mapconcat (lambda (i)
                                        (concat
                                         (propertize (concat
                                                      "[" (char-to-string (nth 0 i)) "] ")
                                                     'face 'tiny-menu-run-heading-face)
                                         (nth 1 i)))
                                      items ", ")))
                   (choices (mapcar (lambda (i) (nth 0 i)) items))
                   (choice (read-char-choice prompt choices)))
           (if (and (assoc choice items)
                    (functionp (nth 2 (assoc choice items))))
               (funcall (nth 2 (assoc choice items)))
             (message "Menu aborted.")))))

(defun air-menu-of-menus ()
  "Build menu items for all configured menus.

This allows `tiny-menu-run' to display an interactive menu of all
configured menus if the caller does not specify a menu name
explicitly."
  (let ((menu-key-char 97))
    `("Menus" ,(mapcar (lambda (i)
                (prog1
                    `(,menu-key-char ,(car (car (cdr i))) (lambda () (tiny-menu-run ,(car i))))
                  (setq menu-key-char (1+ menu-key-char))))
              tiny-menu-run-items))))

(defmacro tiny-menu-run-item (item)
  "Return a function suitable for binding to call the ITEM run menu.

This saves you the trouble of putting inline lambda functions in all
of the key binding declarations for your menus.  A key binding
declaration now looks like:

`(define-key some-map \"<key>\" (tiny-menu-run-item \"my-menu\"))'."
  `(lambda ()
     (interactive)
     (tiny-menu-run ,item)))

(provide 'tiny-menu-run)
;;; tiny-menu-run ends here
