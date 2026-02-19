# MEDIA FILE RENAMER
Renames jpg, png, mp4 (and more) files with a numeric prefix sorted by their actual media/EXIF date, not file system dates.

The tricky part here is "media date created" — this means the EXIF date for photos and the encoded date / media created metadata for videos.
Windows File Explorer's sort doesn't expose this easily, so a script is the right approach.

<br>


# HOW TO USE:
   1. Edit $folderPath below to point to your folder
   2. Optionally set $prefix (e.g. "holiday_") or leave empty
   3. Open PowerShell (run as administrator), navigate to the folder containing the script (e.g. cd C:\Users\Admin\Desktop\FolderName) and run:
        -		Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
        -		.\rename.ps1
      (see bottom of file for explanation of these commands)


<br>


## DRY RUN (preview only, no renaming):
   Comment out the Rename-Item line by adding # in front of it


<br>


## FILE COUNTER PADDING:
   Default is 3 digits (001, 002 ... 999).
   
   If you have 1000+ files, change D3 to D4 in the rename section


<br>


# COMMAND EXPLANATION

## Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   By default Windows blocks PowerShell scripts from running as a security measure. This command temporarily lifts that restriction, but only for the current PowerShell window (Scope Process).
   The moment you close PowerShell, the restriction goes back to normal. Nothing is permanently changed on your system.

## .\rename.ps1
   The .\ means "look in the current directory".
   PowerShell's working directory is wherever you navigated to with cd, so before running this you need to cd into the folder where the script is saved, for example:
   
       - cd C:\Users\Admin\Desktop\FolderName
       - .\rename.ps1
       
   Windows won't search for .ps1 files automatically the way it does for programs — you must always tell it where to look, and .\ is the shorthand for "right here".
