<#
.SYNOPSIS
    Desktop & Folder File Organizer Engine
.DESCRIPTION
    Scans a directory and sorts files into categorized subfolders with collision protection and undo support.
#>

param (
    [string]$TargetDirectory = "",
    [switch]$Preview,
    [switch]$Undo,
    [switch]$Silent
)

# Set target directory default to current folder or Desktop if empty
if ([string]::IsNullOrWhiteSpace($TargetDirectory)) {
    $TargetDirectory = (Get-Location).Path
}

if (-not (Test-Path -LiteralPath $TargetDirectory)) {
    if (-not $Silent) {
        Write-Host "Directory not found: $TargetDirectory" -ForegroundColor Red
    }
    return @{ Success = $false; Message = "Directory not found: $TargetDirectory"; MovedCount = 0 }
}

$AppDataDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath "FileOrganizer"
if (-not (Test-Path -LiteralPath $AppDataDir)) {
    New-Item -ItemType Directory -Path $AppDataDir -Force | Out-Null
}
# Create a unique history file key based on target directory path
$dirHash = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TargetDirectory.ToLower())).Replace('/', '_').Replace('+', '-').Replace('=', '')
$HistoryFilePath = Join-Path -Path $AppDataDir -ChildPath "history_$dirHash.json"

# List of files to strictly exclude from being moved (all lowercase)
$ExcludedFileNames = @(
    "desktop.ini",
    "thumbs.db",
    ".ds_store",
    ".organizer_history.json",
    ".file_organizer_history.json",
    "organizer.ps1",
    "fileorganizergui.ps1",
    "organizer.py",
    "organize_desktop_now.bat",
    "organize_current_folder.bat",
    "launch_organizer_gui.bat",
    "undo_desktop_organization.bat",
    "organize-desktop.bat",
    "organize-current-folder.bat",
    "readme.md"
)

# Excluded extensions (shortcuts and system links)
$ExcludedExtensions = @(".lnk", ".url")

# Category definitions
$CategoryRules = [ordered]@{
    "Screenshots" = @{
        "Type" = "Pattern"
        "Extensions" = @(".png", ".jpg", ".jpeg", ".bmp", ".webp")
        "Patterns" = @("*screenshot*", "*screen shot*", "*snip*", "*capture*", "*snippingtool*", "*win_scr*")
    }
    "PDFs & Documents" = @{
        "Type" = "Extension"
        "Extensions" = @(".pdf", ".docx", ".doc", ".txt", ".rtf", ".odt", ".xlsx", ".xls", ".csv", ".pptx", ".ppt", ".epub", ".pages", ".numbers", ".key", ".tsv", ".md", ".xopp")
    }
    "Images & Photos" = @{
        "Type" = "Extension"
        "Extensions" = @(".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".bmp", ".ico", ".tiff", ".tif", ".raw", ".heic", ".psd", ".ai", ".eps", ".avif")
    }
    "Videos" = @{
        "Type" = "Extension"
        "Extensions" = @(".mp4", ".mkv", ".mov", ".avi", ".wmv", ".flv", ".webm", ".m4v", ".3gp", ".ts", ".vob", ".mpg", ".mpeg")
    }
    "Audio & Music" = @{
        "Type" = "Extension"
        "Extensions" = @(".mp3", ".wav", ".aac", ".flac", ".ogg", ".m4a", ".wma", ".opus", ".mid", ".midi")
    }
    "Archives & Compressed" = @{
        "Type" = "Extension"
        "Extensions" = @(".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".xz", ".tgz", ".iso", ".cab", ".dmg")
    }
    "Installers & Executables" = @{
        "Type" = "Extension"
        "Extensions" = @(".exe", ".msi", ".msix", ".appx", ".reg")
    }
    "Code & Development" = @{
        "Type" = "Extension"
        "Extensions" = @(".py", ".js", ".jsx", ".ts", ".tsx", ".html", ".htm", ".css", ".scss", ".json", ".xml", ".yaml", ".yml", ".sql", ".cpp", ".c", ".h", ".cs", ".java", ".go", ".rs", ".php", ".rb", ".sh", ".ps1")
    }
    "Others" = @{
        "Type" = "Fallback"
    }
}

# Function to determine Category
function Get-FileCategory {
    param ([System.IO.FileInfo]$File)

    $fileName = $File.Name.ToLower()
    $ext = $File.Extension.ToLower()

    # 1. Check Screenshot pattern
    $screenshotRule = $CategoryRules["Screenshots"]
    if ($screenshotRule.Extensions -contains $ext) {
        foreach ($pattern in $screenshotRule.Patterns) {
            if ($fileName -like $pattern) {
                return "Screenshots"
            }
        }
    }

    # 2. Check standard categories
    foreach ($category in $CategoryRules.Keys) {
        if ($category -eq "Screenshots" -or $category -eq "Others") { continue }
        $rule = $CategoryRules[$category]
        if ($rule.Extensions -contains $ext) {
            return $category
        }
    }

    return "Others"
}

# Function to get safe unique destination path
function Get-UniqueDestinationPath {
    param (
        [string]$TargetFolder,
        [string]$OriginalFileName
    )

    $destPath = Join-Path -Path $TargetFolder -ChildPath $OriginalFileName
    if (-not (Test-Path -LiteralPath $destPath)) {
        return $destPath
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OriginalFileName)
    $extension = [System.IO.Path]::GetExtension($OriginalFileName)

    $counter = 1
    while (Test-Path -LiteralPath $destPath) {
        $newName = "{0} ({1}){2}" -f $baseName, $counter, $extension
        $destPath = Join-Path -Path $TargetFolder -ChildPath $newName
        $counter++
    }

    return $destPath
}

# Function to perform UNDO
function Undo-LastOrganization {
    param ([string]$Dir)

    $appData = Join-Path -Path $env:LOCALAPPDATA -ChildPath "FileOrganizer"
    $dHash = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Dir.ToLower())).Replace('/', '_').Replace('+', '-').Replace('=', '')
    $histFile = Join-Path -Path $appData -ChildPath "history_$dHash.json"
    
    # Also check legacy local file for backward compatibility
    if (-not (Test-Path -LiteralPath $histFile)) {
        $legacyHist = Join-Path -Path $Dir -ChildPath ".organizer_history.json"
        if (Test-Path -LiteralPath $legacyHist) {
            $histFile = $legacyHist
        }
    }

    if (-not (Test-Path -LiteralPath $histFile)) {
        if (-not $Silent) {
            Write-Host "No undo history found for: $Dir" -ForegroundColor Yellow
        }
        return @{ Success = $false; Message = "No history found for this folder."; RestoredCount = 0 }
    }

    try {
        $rawJson = Get-Content -LiteralPath $histFile -Raw -Encoding UTF8
        $historyData = $rawJson | ConvertFrom-Json
    } catch {
        return @{ Success = $false; Message = "Failed to parse history: $_"; RestoredCount = 0 }
    }

    if (-not $historyData.Transactions -or $historyData.Transactions.Count -eq 0) {
        return @{ Success = $false; Message = "No transactions to undo."; RestoredCount = 0 }
    }

    # Get the latest transaction batch
    $lastTransaction = $historyData.Transactions[-1]
    $moves = $lastTransaction.Moves
    $restoredCount = 0
    $createdFolders = $lastTransaction.FoldersCreated

    foreach ($item in $moves) {
        $currentPath = $item.NewPath
        $origPath = $item.OriginalPath

        if (Test-Path -LiteralPath $currentPath) {
            try {
                Move-Item -LiteralPath $currentPath -Destination $origPath -Force
                $restoredCount++
            } catch {
                Write-Warning "Could not restore: $currentPath -> $origPath ($($_))"
            }
        }
    }

    # Clean up any empty category folders that were created
    if ($createdFolders) {
        foreach ($folderPath in $createdFolders) {
            if ((Test-Path -LiteralPath $folderPath) -and (Get-ChildItem -LiteralPath $folderPath -Force).Count -eq 0) {
                Remove-Item -LiteralPath $folderPath -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }

    # Update history file by removing the popped transaction
    $remainingTransactions = @()
    if ($historyData.Transactions.Count -gt 1) {
        $remainingTransactions = $historyData.Transactions[0..($historyData.Transactions.Count - 2)]
    }

    if ($remainingTransactions.Count -gt 0) {
        $historyData.Transactions = $remainingTransactions
        $historyData | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $histFile -Encoding UTF8
    } else {
        Remove-Item -LiteralPath $histFile -Force -ErrorAction SilentlyContinue
    }

    return @{
        Success = $true
        Message = "Restored $restoredCount files to their original positions."
        RestoredCount = $restoredCount
    }
}

# ----------------- MAIN EXECUTION -----------------

if ($Undo) {
    $undoResult = Undo-LastOrganization -Dir $TargetDirectory
    if (-not $Silent) {
        Write-Host $undoResult.Message -ForegroundColor Green
    }
    return $undoResult
}

# Scan directory for files (only top level, exclude directories)
$allFiles = Get-ChildItem -LiteralPath $TargetDirectory -File -Force

$planList = @()
$categoryCounts = @{}

foreach ($file in $allFiles) {
    $fileNameLower = $file.Name.ToLower()
    $extLower = $file.Extension.ToLower()

    # Skip excluded files & shortcuts
    if ($ExcludedFileNames -contains $fileNameLower) { continue }
    if ($ExcludedExtensions -contains $extLower) { continue }

    $category = Get-FileCategory -File $file
    $categoryDir = Join-Path -Path $TargetDirectory -ChildPath $category
    $destinationPath = Get-UniqueDestinationPath -TargetFolder $categoryDir -OriginalFileName $file.Name

    $planList += [PSCustomObject]@{
        OriginalFile = $file.Name
        OriginalPath = $file.FullName
        Category     = $category
        Destination  = $destinationPath
        Size         = $file.Length
    }

    if (-not $categoryCounts.ContainsKey($category)) {
        $categoryCounts[$category] = 0
    }
    $categoryCounts[$category]++
}

if ($Preview) {
    if (-not $Silent) {
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host " FILE ORGANIZER PREVIEW ($($planList.Count) files found)" -ForegroundColor Cyan
        Write-Host " Target: $TargetDirectory" -ForegroundColor Gray
        Write-Host "==========================================" -ForegroundColor Cyan
        foreach ($cat in $categoryCounts.Keys) {
            Write-Host "  [$cat]: $($categoryCounts[$cat]) files" -ForegroundColor Yellow
        }
        Write-Host "------------------------------------------" -ForegroundColor Gray
    }
    return $planList
}

# Perform actual organization
if ($planList.Count -eq 0) {
    if (-not $Silent) {
        Write-Host "All files are already organized! No files to move." -ForegroundColor Green
    }
    return @{ Success = $true; MovedCount = 0; Message = "No files needed organizing." }
}

$movesLog = @()
$createdFolders = @()

foreach ($item in $planList) {
    $destFolder = [System.IO.Path]::GetDirectoryName($item.Destination)
    if (-not (Test-Path -LiteralPath $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
        if ($createdFolders -notcontains $destFolder) {
            $createdFolders += $destFolder
        }
    }

    try {
        Move-Item -LiteralPath $item.OriginalPath -Destination $item.Destination -Force
        $movesLog += [PSCustomObject]@{
            OriginalPath = $item.OriginalPath
            NewPath      = $item.Destination
            Category     = $item.Category
            FileName     = $item.OriginalFile
        }
    } catch {
        Write-Warning "Failed to move '$($item.OriginalFile)': $_"
    }
}

# Save transaction to history
$currentTransaction = [PSCustomObject]@{
    Timestamp      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    TargetDir      = $TargetDirectory
    MovedCount     = $movesLog.Count
    FoldersCreated = $createdFolders
    Moves          = $movesLog
}

$historyObj = @{ Transactions = @() }
if (Test-Path -LiteralPath $HistoryFilePath) {
    try {
        $existing = Get-Content -LiteralPath $HistoryFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existing.Transactions) {
            $historyObj.Transactions = @($existing.Transactions)
        }
    } catch { }
}

$historyObj.Transactions += $currentTransaction
$historyObj | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $HistoryFilePath -Encoding UTF8

if (-not $Silent) {
    Write-Host "Successfully organized $($movesLog.Count) files into categorized folders!" -ForegroundColor Green
}

return @{
    Success    = $true
    MovedCount = $movesLog.Count
    Categories = $categoryCounts
    Message    = "Successfully organized $($movesLog.Count) files."
}
