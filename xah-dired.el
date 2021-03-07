;;; xah-dired.el --- utility to process images, open in OS, zip dir, etc in dired. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2021 by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 1.1.20210307123123
;; Created: 14 January 2021
;; Package-Requires: ((emacs "25.1"))
;; Keywords: convenience, extensions, files, tools, unix
;; License: GPL v3
;; Homepage: http://ergoemacs.org/emacs/emacs_dired_convert_images.html

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Like it?
;; Buy Xah Emacs Tutorial
;; http://ergoemacs.org/emacs/buy_xah_emacs_tutorial.html
;; Thank you.


;;; Code:

(require 'dired)

(defun xah-process-image (@fileList @argsStr @newNameSuffix @newFileExt )
  "Wrapper to ImageMagick's “convert” shell command.
@fileList is a list of image file paths.
@argsStr is argument string passed to ImageMagick's “convert” command.
@newNameSuffix is the string appended to file. e.g. “_2” may result “_2.jpg”
@newFileExt is the new file's file extension. e.g. “.png”

URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2021-01-14"
  (let (($cmdName (if (string-equal system-type "windows-nt") "magick.exe convert" "convert" )))
    (mapc
     (lambda ($f)
       (let ( $newName $cmdStr )
         (setq $newName
               (concat
                (file-name-sans-extension $f)
                @newNameSuffix
                @newFileExt))
         (while (file-exists-p $newName)
           (setq $newName
                 (concat
                  (file-name-sans-extension $newName)
                  @newNameSuffix
                  (file-name-extension $newName t))))
         ;; relative paths used to get around Windows/Cygwin path remapping problem
         (setq $cmdStr
               (format
                "%s %s %s %s"
                $cmdName
                @argsStr
                (shell-quote-argument (file-relative-name $f))
                (shell-quote-argument (file-relative-name $newName))))
         (shell-command $cmdStr)
         (message "Ran:「%s」" $cmdStr)))
     @fileList )))

(defun xah-dired-scale-image (@fileList @scalePercent @quality @sharpen-p)
  "Create a scaled version of marked image files in `dired'.
New file names have “-s‹n›” appended before the file name extension, where ‹n› is the scaling factor in percent, such as 60.

If `universal-argument' is ask for png/jpg and sharpen options.

When called in lisp code,
 @fileList is a file fullpath list.
 @scalePercent is a integer.
 @quality is a integer, from 1 to 100. bigger is higher quality.
 @sharpen-p is true or false.

Require shell command ImageMagick.
URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2019-12-30 2021-01-20"
  (interactive
   (list (cond
          ((string-equal major-mode "dired-mode") (dired-get-marked-files))
          ((string-equal major-mode "image-mode") (list (buffer-file-name)))
          (t (list (read-from-minibuffer "file name:"))))
         (read-from-minibuffer "Scale %:")
         (if current-prefix-arg (string-to-number (read-string "quality:" "90")) 90)
         (if current-prefix-arg (y-or-n-p "Sharpen") t)))
  (let ( ($nameExt
          (if current-prefix-arg (if (y-or-n-p "to png?") ".png" ".jpg" ) ".jpg" )))
    (mapc
     (lambda ($f)
       (let* (($ext (file-name-extension $f))
              ($argStr (if (string-equal $ext "png")
                           (format "-scale %s%% " @scalePercent )
                         (format "-scale %s%% -quality %s%% %s " @scalePercent @quality (if @sharpen-p "-sharpen 1" "" )))))
         (xah-process-image
          (list $f) $argStr
          (format "-s%s" @scalePercent)
          (concat "." $ext ))))
     @fileList)
    ;;
    ))

(defun xah-dired-image-autocrop ()
  "Create auto-cropped version of image in `dired', current or marked files
The created file has “_crop.” in the name, in the same dir. The image format is same as the original.
Require shell command ImageMagick.
Version 2021-01-14"
  (interactive)
  (if (string-equal major-mode "dired-mode")
      (let (($flist (dired-get-marked-files)))
        (mapc
         (lambda ($f)
           (xah-process-image (list $f) "-trim" "_crop" (file-name-extension $f t)))
         $flist )
        (revert-buffer))
    nil
    ))

(defun xah-dired-image-remove-transparency ()
  "Create opaque version of image in `dired', current or marked files.
Works on png images only. The created file has the name, in the same dir.
Require shell command ImageMagick.
URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2021-01-14"
  (interactive)
  (if (string-equal major-mode "dired-mode")
      (let (($flist (dired-get-marked-files))
            $fExt
            )
        (mapc
         (lambda ($f)
           (setq $fExt (file-name-extension $f))
           (if (not (string-equal $fExt "png"))
               (message "Skipping %s" $f)
             (xah-process-image (list $f) "-flatten" "_opa" (concat "." $fExt ))))
         $flist ))
    (revert-buffer)))

(defun xah-dired-2jpg (@fileList)
  "Create a JPG version of images of marked files in `dired'.
If `universal-argument' is called first, ask for jpeg quality. (default is 90)

Require shell command ImageMagick.
URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2018-11-28 2021-01-18"
  (interactive
   (let (
         ($fileList
          (cond
           ((string-equal major-mode "dired-mode") (dired-get-marked-files))
           ((string-equal major-mode "image-mode") (list (buffer-file-name)))
           (t (list (read-from-minibuffer "file name:"))))))
     (list $fileList)))
  (let ((quality
         (if current-prefix-arg
             (progn (string-to-number (read-string "quality:" "85")))
           (progn 90))))
    (xah-process-image @fileList (format "-quality %s%%" quality ) "-2" ".jpg" )
    (revert-buffer)))

(defun xah-dired-2png (@fileList)
  "Create a png version of images of marked files in `dired'.
Require shell command ImageMagick.
URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2016-07-19 2021-01-18"
  (interactive
   (let (
         ($fileList
          (cond
           ((string-equal major-mode "dired-mode") (dired-get-marked-files))
           ((string-equal major-mode "image-mode") (list (buffer-file-name)))
           (t (list (read-from-minibuffer "file name:"))))))
     (list $fileList)))
  (xah-process-image @fileList "" "-2" ".png" )
  (revert-buffer))

(defun xah-dired-optimize-png (@fileList)
  "optimize the png file of current file or current/marked files in `dired'.
Require shell command optipng.
Output is in buffer *xah optimize png output*
Version 2021-01-14 2021-02-08"
  (interactive
   (list
    (cond
     ((string-equal major-mode "dired-mode") (dired-get-marked-files))
     ((string-equal major-mode "image-mode") (list (buffer-file-name)))
     (t (list (read-from-minibuffer "file name:"))))))
  (let (
        (outputBuf (get-buffer-create "*xah optimize png output*"))
        (async-shell-command-buffer 'new-buffer))
    (with-current-buffer outputBuf
      (mapc (lambda ($f)
              (async-shell-command
               (format "optipng %s"
                       (shell-quote-argument (file-relative-name $f))))
              ;; (start-process "optipng" outputBuf "optipng" (file-relative-name $f))
              ;; (message "wait for optimizing %s" (file-relative-name $f))
              ;; (call-process "optipng" nil outputBuf nil (file-relative-name $f))
              (insert "\nhh========================================\n"))
            @fileList))
    ;; (switch-to-buffer-other-window outputBuf)
    ;; (message "Async optimizing png. Output at buffer %s" outputBuf)
    ))

(defun xah-dired-2drawing (@fileList @grayscale-p @max-colors-count)
  "Create a png version of (drawing type) images of marked files in `dired'.
Basically, make it grayscale, and reduce colors to any of {2, 4, 16, 256}.
Require shell command ImageMagick.
Version 2017-02-02"
  (interactive
   (let (
         ($fileList
          (cond
           ((string-equal major-mode "dired-mode") (dired-get-marked-files))
           ((string-equal major-mode "image-mode") (list (buffer-file-name)))
           (t (list (read-from-minibuffer "file name:"))))))
     (list $fileList
           (yes-or-no-p "Grayscale?")
           (ido-completing-read "Max number of colors:" '( "2" "4" "16" "256" )))))
  (xah-process-image @fileList
                     (format "+dither %s -depth %s"
                             (if @grayscale-p "-type grayscale" "")
                             ;; image magick “-colors” must be at least 8
                             ;; (if (< (string-to-number @max-colors-count) 3)
                             ;;     8
                             ;;     (expt 2 (string-to-number @max-colors-count)))
                             (cond
                              ((equal @max-colors-count "256") 8)
                              ((equal @max-colors-count "16") 4)
                              ((equal @max-colors-count "4") 2)
                              ((equal @max-colors-count "2") 1)
                              (t (error "logic error 0444533051: impossible condition on @max-colors-count: %s" @max-colors-count))))  "-2" ".png" ))

(defun xah-dired-show-metadata (@fileList)
  "Display metatata of buffer image file or current/marked files in `dired'.
 (typically image files)
Output in buffer *xah metadata output*

This command require the shell command exiftool.
URL `http://xahlee.info/img/metadata_in_image_files.html'

URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2019-12-04 2021-01-24"
  (interactive
   (list
    (cond
     ((string-equal major-mode "dired-mode") (dired-get-marked-files))
     ((string-equal major-mode "image-mode") (list (buffer-file-name)))
     (t (list (read-from-minibuffer "file name:"))))))
  (let ( (outputBuf (get-buffer-create "*xah metadata output*")))
    (switch-to-buffer outputBuf )
    (erase-buffer)
    (mapc (lambda (f)
            (call-process
             "exiftool"
             nil outputBuf nil
             (file-relative-name f))
            (insert "\nhh========================================\n"))
          @fileList)))

(defun xah-dired-remove-all-metadata (@fileList)
  "Remove all metatata of buffer image file or marked files in `dired'.
 (typically image files)
Output in buffer *xah metadata output*

This command require the shell command exiftool.
URL `http://xahlee.info/img/metadata_in_image_files.html'

URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2016-07-19 2021-03-07"
  (interactive
   (list
    (cond
     ((string-equal major-mode "dired-mode") (dired-get-marked-files))
     ((string-equal major-mode "image-mode") (list (buffer-file-name)))
     (t (list (read-from-minibuffer "file name:"))))))
  (let ( (process-connection-type nil)
         (outputBuf (get-buffer-create "*xah metadata output*")))
    (with-current-buffer outputBuf
      (mapc (lambda (x)
              (start-process "" outputBuf "exiftool" "-all="
                             "-overwrite_original"
                             (file-relative-name x))
              ;; (call-process "exiftool" nil outputBuf nil "-all=" "-overwrite_original" (file-relative-name f))
              (insert "\nhh========================================\n"))
            @fileList))
    (message "Done remove metadata. Output at buffer %s" outputBuf)))

(defun xah-dired-sort ()
  "Sort dired dir listing in different ways.
Prompt for a choice.
URL `http://ergoemacs.org/emacs/dired_sort.html'
Version 2018-12-23"
  (interactive)
  (let ($sort-by $arg)
    (setq $sort-by (ido-completing-read "Sort by:" '( "date" "size" "name" )))
    (cond
     ((equal $sort-by "name") (setq $arg "-Al "))
     ((equal $sort-by "date") (setq $arg "-Al -t"))
     ((equal $sort-by "size") (setq $arg "-Al -S"))
     ((equal $sort-by "dir") (setq $arg "-Al --group-directories-first"))
     (t (error "logic error 09535" )))
    (dired-sort-other $arg )))

(defun xah-dired-open-marked ()
  "Open marked files in `dired'.
URL `http://ergoemacs.org/emacs/emacs_dired_open_marked.html'
Version 2019-10-22"
  (interactive)
  (mapc 'find-file (dired-get-marked-files)))

(defun xah-dired-to-zip ()
  "Zip the current file in `dired'.
If multiple files are marked, only zip the first one.
Require unix zip command line tool.
URL `http://ergoemacs.org/emacs/emacs_dired_zip_dir.html'
Version 2021-01-14 2021-02-08"
  (interactive)
  (let ( (fName (elt (dired-get-marked-files) 0)))
    (async-shell-command
     (format
      "zip -r %s %s"
      (shell-quote-argument (concat (file-relative-name fName) ".zip"))
      (shell-quote-argument (file-relative-name fName))))))

(defvar xah-open-in-gimp-path nil "Microsoft Windows Gimp executable path used by `xah-open-in-gimp'.")
(setq xah-open-in-gimp-path "C:\\Program Files\\GIMP 2\\bin\\gimp-2.10.exe")

(defun xah-open-in-gimp ()
  "Open the current file or `dired' marked files in image editor gimp.
Works in linux and Mac.
On Microsoft Windows, it uses `xah-open-in-gimp-path' to locate gimp program.

URL `http://ergoemacs.org/emacs/emacs_dired_convert_images.html'
Version 2017-11-02 2021-01-30"
  (interactive)
  (let* (
         (async-shell-command-buffer 'new-buffer)
         ($fileList
          (if (string-equal major-mode "dired-mode")
              (dired-get-marked-files)
            (list (buffer-file-name))))
         ($do-it-p (if (<= (length $fileList) 20)
                       t
                     (y-or-n-p "Open more than 20 files? "))))
    (when $do-it-p
      (cond
       ((string-equal system-type "windows-nt")
        (mapc
         (lambda ($fpath)
           (let (
                 ;; ($cmdStr
                 ;;  (format
                 ;;   "PowerShell -Command Start-Process -FilePath %s -ArgumentList %s"
                 ;;   (shell-quote-argument xah-open-in-gimp-path)
                 ;;   (shell-quote-argument (expand-file-name $fpath ))))
                 ($cmdStr
                  (format "%s %s"
                          (shell-quote-argument xah-open-in-gimp-path)
                          (shell-quote-argument (file-relative-name $fpath))))
                 ;;
                 )
             (message "%s" $cmdStr)
             (async-shell-command $cmdStr )))
         $fileList))
       ((string-equal system-type "darwin")
        (mapc
         (lambda ($fpath)
           (async-shell-command
            (format "open -a /Applications/GIMP.app \"%s\"" $fpath))) $fileList))
       ((string-equal system-type "gnu/linux")
        (mapc
         (lambda ($fpath) (let ((process-connection-type nil)) (start-process "" nil "gimp" $fpath))) $fileList))))))

(defvar xah-dired-irfanview-path nil "Microsoft Windows IrfanView executable path used by `xah-dired-open-in-irfanview'.")
(setq xah-dired-irfanview-path "C:\\Program Files\\IrfanView\\i_view64.exe")

(defun xah-dired-open-in-irfanview ()
  "Open the current file or `dired' marked files in Windows's IrfanView.
This uses `xah-dired-irfanview-path' to locate IrfanView program.
Version 2021-02-07 2021-02-08"
  (interactive)
  (when (not (string-equal system-type "windows-nt"))
    (user-error "Error 84752: this command only runs in Windows"))
  (let* (
         (async-shell-command-buffer 'new-buffer)
         (shell-command-dont-erase-buffer t)
         ($file-list
          (if (string-equal major-mode "dired-mode")
              (dired-get-marked-files)
            (list (buffer-file-name))))
         ($do-it-p (if (<= (length $file-list) 5)
                       t
                     (y-or-n-p "Open more than 5 files? "))))
    (when $do-it-p
      (mapc
       (lambda ($f)
         (async-shell-command
          (format "%s %s"
                  (shell-quote-argument xah-dired-irfanview-path)
                  (shell-quote-argument (file-relative-name $f)))
          "*xah open in irfanview output*"
          )) $file-list))))

(defun xah-dired-open-in-textedit ()
  "Open the current file or `dired' marked files in Mac's TextEdit.
This command is for macOS only.

URL `http://ergoemacs.org/emacs/emacs_dired_open_file_in_ext_apps.html'
Version 2017-11-21 2021-02-07"
  (interactive)
  (when (not (string-equal system-type "darwin"))
    (user-error "Error 84752: this command only runs in Mac"))
  (let* (
         ($file-list
          (if (string-equal major-mode "dired-mode")
              (dired-get-marked-files)
            (list (buffer-file-name))))
         ($do-it-p (if (<= (length $file-list) 5)
                       t
                     (y-or-n-p "Open more than 5 files? "))))
    (when $do-it-p
      (mapc
       (lambda ($fpath)
         (shell-command
          (format "open -a TextEdit.app \"%s\"" $fpath))) $file-list))))

(provide 'xah-dired)

;;; xah-dired.el ends here
