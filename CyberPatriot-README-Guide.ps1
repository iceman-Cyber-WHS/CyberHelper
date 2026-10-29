param(
    [string]$ReadmePath = "$env:USERPROFILE\Desktop\README.txt"
)

$ErrorActionPreference = "Stop"

# Check that the README exists.
if (-not (Test-Path -LiteralPath $ReadmePath -PathType Leaf)) {
    Write-Host "README not found: $ReadmePath" -ForegroundColor Red
    exit 1
}

$lines = Get-Content -LiteralPath $ReadmePath
$tasks = [System.Collections.Generic.List[string]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($line in $lines) {
    $text = $line.Trim()

    # Skip empty lines.
    if ([string]::IsNullOrWhiteSpace($text)) {
        continue
    }

    # Detect operating-system headings (Case-Insensitive):
    # Matches "WORKSTATION: Windows 11 IMAGE", "SERVER: LINUX", etc.
    if ($text -match '(?i)^#{0,6}\s*(?:(?:WORKSTATION|SERVER|IMAGE|OS|SYSTEM)\s*[:\-]?\s*)?(Windows(?:\s+\d+)?|Linux)\b') {
        # If we already have tasks from the previous OS, inject the double line break immediately
        if ($tasks.Count -gt 0) {
            $tasks.Add("")
            $tasks.Add("")
        }
        # Reset duplicate tracking for the new OS section
        $seen.Clear()
        continue
    }

    # Ignore subsection headings.
    if ($text -match '^#{1,6}\s+') {
        continue
    }

    # Remove Markdown list markers and numbering.
    $text = $text -replace '^\s*[-*+]\s+', ''
    $text = $text -replace '^\s*\d+[.)]\s+', ''
    $text = $text.Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        continue
    }

    # Ignore introductory labels, but retain actual task wording.
    if ($text -match '^(?i:requirements|instructions|tasks|scoring|overview|objectives)\s*:?\s*$') {
        continue
    }

    # Add the task if it hasn't been seen yet within this specific OS block
    if ($seen.Add($text)) {
        $tasks.Add($text)
    }
}

# Clean up any trailing empty lines if the file ended awkwardly
while ($tasks.Count -gt 0 -and $tasks[-1] -eq "") {
    $tasks.RemoveAt($tasks.Count - 1)
}

# Save the output to the Desktop.
$outputPath = Join-Path $env:USERPROFILE "Desktop\CyberPatriot-Tasks.txt"

if ($tasks.Count -eq 0) {
    Write-Host "No tasks found in the README." -ForegroundColor Yellow
    Write-Host "Check that the README contains valid OS headings like Windows or Linux."
    exit 0
}

# Save tasks exactly as ordered, preserving the custom spacing between OS sections
$tasks | Set-Content -LiteralPath $outputPath -Encoding UTF8

# Display the extracted tasks cleanly in the console
Write-Host ""
foreach ($task in $tasks) {
    Write-Host $task
}

Write-Host ""
Write-Host "Tasks saved to: $outputPath" -ForegroundColor Green
