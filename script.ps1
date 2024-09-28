# PowerShell Script to Extract Translatable Strings from Blade Files
# This script scans through Blade template files in the specified directory, extracts strings passed to the translation function, and outputs them in a JSON format.
# It is customizable for different use cases and file structures, making it suitable for Laravel projects or any other frameworks with similar i18n (internationalization) needs.
# Author: tauseedzaman
# License: MIT License

# Define the regex pattern to match translation function arguments.
# The pattern matches Laravel's translation helper function '__()' with strings wrapped in single or double quotes.
$pattern = '__\(["'']([^"'']+)["'']\)'

# Set the path to the Blade files directory.
$bladeDirectoryPath = "path\to\resources\views"
# This file will store the JSON output of all unique translatable strings.
$outputFilePath = "path\to\extracted.json"

if (-not (Test-Path $bladeDirectoryPath)) {
    Write-Host "Error: The specified directory '$bladeDirectoryPath' does not exist." -ForegroundColor Red
    exit 1
}

if (Test-Path $outputFilePath) {
    Clear-Content $outputFilePath
    Write-Host "Existing output file '$outputFilePath' cleared."
} 
else {
    # If the file does not exist, create it.
    New-Item -Path $outputFilePath -ItemType File | Out-Null
}

# Initialize a hashtable to store unique arguments (translatable strings) and counters for tracking progress.
$uniqueMatches = @{}    

$totalFilesProcessed = 0         
$totalMatchedFound = 0           
$totalUniqueMatches = 0            

# Exclude the 'resources/views/admin' directory to avoid admin-specific files if needed.
Write-Host "Starting to process files from the '$bladeDirectoryPath' directory..."

# Use Get-ChildItem to get all .blade.php files in the specified directory, excluding the 'admin' subdirectory.
Get-ChildItem -Path $bladeDirectoryPath -File -Recurse -Include *.blade.php |
Where-Object { $_.FullName -notlike "*resources\views\admin*" } | ForEach-Object {

    $totalFilesProcessed++

    # Read the content of each file.
    $content = Get-Content $_.FullName -Raw
    Write-Host "Processing file: $($_.FullName)"

    # If the file is empty or contains only whitespace, skip to the next file.
    if ([string]::IsNullOrWhiteSpace($content)) {
        Write-Host "File '$($_.FullName)' is empty. Skipping to the next file..."
        return
    }

    # Use regex to find all matches in the file based on the defined pattern.
    $matches = [regex]::Matches($content, $pattern)
    $totalMatchedFound += $matches.Count

    # Loop through each match found in the file.
    foreach ($match in $matches) {
        $matchedArg = $match.Groups[1].Value # Extract the matched translation string.

        # Add the argument to the hashtable if it's not already stored (ensure uniqueness).
        if (-not $uniqueMatches.ContainsKey($matchedArg)) {
            $uniqueMatches[$matchedArg] = $matchedArg 
            $totalUniqueMatches++
        }
    }
    Write-Host "-------------------------------------------------------------"
}

# Convert the hashtable of unique arguments to JSON format and write the results to the output file.
$uniqueMatches | ConvertTo-Json | Add-Content -Path $outputFilePath

Write-Host "Extraction complete. Results have been saved to '$outputFilePath'."

# Print the process summary
Write-Host "-------------------------------------------------------------"
Write-Host "Process Summary:"
Write-Host "Total files processed: $totalFilesProcessed" 
Write-Host "Total translatable strings extracted: $totalMatchedFound" 
Write-Host "Total unique translatable strings extracted: $totalUniqueMatches" 