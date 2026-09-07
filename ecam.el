;;; ecam.el --- Emms Cover Art Modeline -*- lexical-binding: t; -*-

;; Copyright (C) 2026
;; Author: Sam Matthews
;; Version: 1.0
;; Package-Requires: ((emacs "30") (emms))
;; Keywords: emms music modeline

;;; Commentary:
;; Display album cover art in the EMMS modeline format string.

;;; Code:

(require 'emms)

;;; User Options

(defcustom ecam-size 24
  "Size of album cover in pixels (width and height)."
  :type 'integer)

(defcustom ecam-search-paths
  '("cover.jpg" "cover.png" "folder.jpg" "Folder.jpg" "album.jpg" "front.jpg")
  "List of filenames to search for as album covers in track directories."
  :type '(repeat string))

(defcustom ecam-image-type 'jpeg
  "Image type to use for album covers (jpeg or png)."
  :type '(choice (const jpeg) (const png)))

(defcustom ecam-enable t
  "Whether to display album covers in the modeline."
  :type 'boolean)

(defvar ecam-image nil
  "Current album cover image for modeline display.")

;;; Core Functions

(defun ecam-get-path ()
  "Get the path to the album cover for the current track."
  (when (emms-playlist-current-selected-track)
    (let* ((track (emms-playlist-current-selected-track))
           (file (emms-track-get track 'name)))
      (when file
        (let ((dir (file-name-directory file)))
          (catch 'found
            (dolist (cover-name ecam-search-paths)
              (let ((cover-path (concat dir cover-name)))
                (when (file-exists-p cover-path)
                  (throw 'found cover-path))))))))))

(defun ecam-scale-image (image-path size)
  "Scale an image to the specified size for modeline display.
IMAGE-PATH is the path to the image file.
SIZE is the width and height in pixels."
  (when (file-exists-p image-path)
    (create-image image-path ecam-image-type nil
                  :width size
                  :height size
                  :scale 1
									:ascent 'center)))

(defun ecam-update ()
  "Update the album cover image for the modeline."
  (when ecam-enable
    (let ((cover-path (ecam-get-path)))
      (if cover-path
          (setq ecam-image
                (ecam-scale-image cover-path ecam-size))
        (setq ecam-image nil))))
  (force-mode-line-update))

(defun ecam-propertized ()
  "Return a propertized string with the album cover image for use in format strings."
  (when (and ecam-enable ecam-image)
    (propertize " " 'display ecam-image)))

;;; Interactive Commands

;;;###autoload
(define-minor-mode ecam-mode
  "Display album covers in the EMMS modeline.
This mode hooks into EMMS events to update the cover display
as tracks change. The cover is displayed via the modeline
format string when using custom EMMS modeline config."
  :global t
  (if ecam-mode
      (progn
        (add-hook 'emms-player-started-hook #'ecam-update)
        (add-hook 'emms-player-next-hook #'ecam-update)
        (add-hook 'emms-player-previous-hook #'ecam-update)
        (add-hook 'emms-player-stopped-hook #'ecam-update)
        (ecam-update)
        (message "Ecam enabled"))
    (progn
      (remove-hook 'emms-player-started-hook #'ecam-update)
      (remove-hook 'emms-player-next-hook #'ecam-update)
      (remove-hook 'emms-player-previous-hook #'ecam-update)
      (remove-hook 'emms-player-stopped-hook #'ecam-update)
      (setq ecam-image nil)
      (force-mode-line-update)
      (message "EMMS modeline cover disabled"))))

(defun ecam-format()
  (let ((cover (ecam-propertized)))
		(concat
		  "[ "
      (emms-track-description (emms-playlist-current-selected-track))
      (if (and cover (> (length cover) 0)) " " "")
      cover
      " "
      "]")))

(provide 'ecam)

;;; ecam.el ends here
