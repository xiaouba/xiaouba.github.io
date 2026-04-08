param(
    [switch]$Check,
    [string]$File
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Show-Usage {
    @"
Usage:
  .\publish.ps1 -Check -File "content/posts/post-name.md"
  .\publish.ps1 -File "content/posts/post-name.md"
  .\publish.ps1

Behavior:
  - Default: validate post front matter and run a Hugo build
  - -Check: validate only
  - -File: validate one target post; otherwise changed posts first, then all posts

Note:
  This script does not run git add / commit / push.
  After a successful build, review and commit files manually.
"@
}

function Add-UniqueFile {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Path
    )

    if ($Path -and -not $List.Contains($Path)) {
        $List.Add($Path) | Out-Null
    }
}

function Get-CheckFiles {
    $files = [System.Collections.Generic.List[string]]::new()

    if ($File) {
        Add-UniqueFile -List $files -Path $File
        return $files
    }

    git diff --name-only --diff-filter=AM -- 'content/posts/*.md' | ForEach-Object {
        Add-UniqueFile -List $files -Path $_
    }

    git diff --name-only --cached --diff-filter=AM -- 'content/posts/*.md' | ForEach-Object {
        Add-UniqueFile -List $files -Path $_
    }

    git ls-files --others --exclude-standard -- 'content/posts/*.md' | ForEach-Object {
        Add-UniqueFile -List $files -Path $_
    }

    if ($files.Count -eq 0) {
        git ls-files -- 'content/posts/*.md' | ForEach-Object {
            Add-UniqueFile -List $files -Path $_
        }
    }

    return $files
}

if ($args -contains "-h" -or $args -contains "--help") {
    Show-Usage
    exit 0
}

$checkFiles = Get-CheckFiles

if ($checkFiles.Count -eq 0) {
    Write-Host "No post files found to validate."
    exit 1
}

foreach ($path in $checkFiles) {
    if (-not (Test-Path $path)) {
        Write-Host "File not found: $path"
        exit 1
    }
}

Write-Host "==> Validating post front matter (title/date/draft)..."

$errors = [System.Collections.Generic.List[string]]::new()
$now = Get-Date

foreach ($path in $checkFiles) {
    $raw = Get-Content $path -Raw -Encoding UTF8

    if (-not $raw.StartsWith("---")) {
        $errors.Add("${path}: missing YAML front matter") | Out-Null
        continue
    }

    $parts = $raw -split '---', 3
    if ($parts.Count -lt 3) {
        $errors.Add("${path}: incomplete front matter") | Out-Null
        continue
    }

    $front = $parts[1]
    $title = $null
    $draft = $null
    $dateValue = $null

    foreach ($line in ($front -split "`r?`n")) {
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith("title:")) {
            $title = $trimmed.Split(":", 2)[1].Trim()
        } elseif ($trimmed.StartsWith("draft:")) {
            $draft = $trimmed.Split(":", 2)[1].Trim().ToLowerInvariant()
        } elseif ($trimmed.StartsWith("date:")) {
            $dateValue = $trimmed.Split(":", 2)[1].Trim()
        }
    }

    if (-not $title) {
        $errors.Add("${path}: missing title") | Out-Null
    }

    if (-not $draft) {
        $errors.Add("${path}: missing draft") | Out-Null
    } elseif ($draft -in @("true", "yes")) {
        $errors.Add("${path}: draft=true, cannot publish") | Out-Null
    }

    if ($dateValue) {
        $normalizedDate = $dateValue.Trim("'`"")
        try {
            $parsed = [DateTimeOffset]::Parse($normalizedDate)
            if ($parsed.LocalDateTime -gt $now) {
                $errors.Add("${path}: date is in the future ($normalizedDate)") | Out-Null
            }
        } catch {
            $errors.Add("${path}: date is not parseable ($normalizedDate)") | Out-Null
        }
    } else {
        $errors.Add("${path}: missing date") | Out-Null
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Validation failed:"
    $errors | ForEach-Object { Write-Host "- $_" }
    exit 2
}

Write-Host "Front matter validation passed."

if ($Check) {
    Write-Host "==> -Check mode: validation only."
    exit 0
}

Write-Host "==> Building site..."
hugo --gc --minify

Write-Host "==> Build finished."
Write-Host "Next steps:"
Write-Host "1. git status"
Write-Host '2. git add [files-you-want-to-publish]'
Write-Host '3. git commit -m "publish: post-title" or "fix: short-note"'
Write-Host "4. git push origin main"
