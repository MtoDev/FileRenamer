# ============================================================
# MEDIA FILE RENAMER
# Renames jpg, png, mp4 (and more) files with a numeric prefix
# sorted by their actual media/EXIF date, not file system dates.
# The tricky part here is "media date created" — this means the EXIF date for photos and the encoded date / media created metadata for videos.
# Windows File Explorer's sort doesn't expose this easily, so a script is the right approach.
#
# HOW TO USE:
#   1. Edit $folderPath below to point to your folder
#	2. Check if $counter is set to 1 or the value that you want
#   3. Optionally set $prefix (e.g. "holiday_") or leave empty
#   4. Open PowerShell (run as administrator), navigate to the folder containing the script (e.g. cd C:\Users\Admin\Desktop\FolderName) and run:
#        -		Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#        -		.\rename.ps1
#      (see bottom of file for explanation of these commands)
#
# DRY RUN (preview only, no renaming):
#   Comment out the Rename-Item line by adding # in front of it
#
# FILE COUNTER PADDING:
#   Default is 3 digits (001, 002 ... 999)
#   If you have 1000+ files, change D3 to D4 in the rename section
# ============================================================

# === CONFIGURATION ===
$folderPath = "C:\Users\Admin\Desktop\FolderName"   # <-- Change this to your folder path
$prefix = ""		# Optional extra prefix, e.g. "holiday_". Result will be: 001_holiday_filename.jpg

# === LOAD REQUIRED ASSEMBLY ===
# System.Drawing is a built-in .NET library that lets PowerShell read image files and extract their EXIF metadata
Add-Type -AssemblyName System.Drawing

function Get-MediaDate {
    param($file)

    $ext = $file.Extension.ToLower()

    # --- Images: read EXIF metadata ---
    # EXIF is metadata embedded in image files by cameras and phones.
    # Tag 36867 = DateTimeOriginal (when the photo was actually taken)
    # Tag 306   = DateTime (a fallback, less reliable — can be edit date)
    # PNG files often have no EXIF data at all — will fall back to LastWriteTime
    if ($ext -in @(".jpg", ".jpeg", ".png")) {
        try {
            $img = [System.Drawing.Image]::FromFile($file.FullName)
            $prop = $img.GetPropertyItem(36867)   # DateTimeOriginal
            $img.Dispose()
            $dateStr = [System.Text.Encoding]::ASCII.GetString($prop.Value).Trim([char]0)
            return [datetime]::ParseExact($dateStr, "yyyy:MM:dd HH:mm:ss", $null)
        } catch {}
        try {
            $img = [System.Drawing.Image]::FromFile($file.FullName)
            $prop = $img.GetPropertyItem(306)     # DateTime fallback
            $img.Dispose()
            $dateStr = [System.Text.Encoding]::ASCII.GetString($prop.Value).Trim([char]0)
            return [datetime]::ParseExact($dateStr, "yyyy:MM:dd HH:mm:ss", $null)
        } catch {}
    }

    # --- Videos: use Windows Shell COM object ---
    # The Shell COM object is the same engine Windows File Explorer uses
    # internally. Column 208 corresponds to "Media created" — the date
    # visible when you right-click a video > Properties > Details tab.
    # This is more reliable than file dates for videos from cameras/phones.
    # Supported formats: .mp4, .mov, .avi, .mkv (and others if Windows can read them)
    if ($ext -in @(".mp4", ".mov", ".avi", ".mkv")) {
        try {
            $shell = New-Object -ComObject Shell.Application
            $folder = $shell.Namespace($file.DirectoryName)
            $item = $folder.ParseName($file.Name)
            $dateStr = $folder.GetDetailsOf($item, 208)   # 208 = "Media created"
            if ($dateStr) {
                # Windows sometimes injects hidden unicode characters into this string (e.g. left-to-right marks). Strip anything non-printable before parsing.
                $dateStr = $dateStr -replace '[^\x20-\x7E]', '' -replace '\s+', ' '
                return [datetime]::Parse($dateStr)
            }
        } catch {}
    }

    # --- Fallback ---
    # If no EXIF or media metadata is found, use the file's LastWriteTime.
    # This is not ideal but better than failing. Check the printed output after running to spot any files that may have gotten wrong dates.
    return $file.LastWriteTime
}

# === GATHER AND SORT FILES ===
# Get all matching files in the folder (not subfolders)
# To include subfolders, add -Recurse to Get-ChildItem
$files = Get-ChildItem -Path $folderPath -File |
    Where-Object { $_.Extension -match '\.(jpg|jpeg|png|mp4|mov|avi|mkv)$' }

# Call Get-MediaDate on each file, bundle it with the file object, then sort the whole collection by that date ascending (oldest first)
$sorted = $files | ForEach-Object {
    [PSCustomObject]@{
        File      = $_
        MediaDate = Get-MediaDate $_
    }
} | Sort-Object MediaDate

# === RENAME ===
# D3 = zero-padded 3-digit counter: 001, 002 ... 999
# Change to D4 for 0001, 0002 ... 9999 if you have 1000+ files
$counter = 1
foreach ($entry in $sorted) {
    $file = $entry.File
    $num  = "{0:D3}" -f $counter
    $newName = "${num}_${prefix}$($file.Name)"
    $newPath = Join-Path $file.DirectoryName $newName

    # Prints each rename with the detected media date so you can verify
    Write-Host "$($file.Name)  -->  $newName  [$($entry.MediaDate)]"

    # THE ACTUAL RENAME — comment this line out (#) for a dry run / preview
    Rename-Item -Path $file.FullName -NewName $newName
    $counter++
}

Write-Host "`nDone! $($sorted.Count) files renamed."

# ============================================================
# COMMAND EXPLANATION
#
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   By default Windows blocks PowerShell scripts from running as a
#   security measure. This command temporarily lifts that restriction,
#   but only for the current PowerShell window (Scope Process).
#   The moment you close PowerShell, the restriction goes back to normal.
#   Nothing is permanently changed on your system.
#
# .\rename.ps1
#   The .\ means "look in the current directory".
#   PowerShell's working directory is wherever you navigated to with cd,
#   so before running this you need to cd into the folder where the
#   script is saved, for example:
#       cd C:\Users\You\Desktop
#       .\rename.ps1
#   Windows won't search for .ps1 files automatically the way it does
#   for programs — you must always tell it where to look, and .\ is
#   the shorthand for "right here".
# ============================================================
