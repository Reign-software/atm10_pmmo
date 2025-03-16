# Script to set all farmland-related farming requirements to 10

# Root directory containing mod data
$rootPath = "D:\src\atm10_pmmo\atm10_pmmo\atm_10_pack\src\main\resources\data"

# Target requirement value
$requirementValue = 10

# Keywords to identify farmland-related blocks
$farmlandKeywords = @("farmland")

# Stats tracking
$processedFiles = 0
$modifiedFiles = 0
$modStats = @{}

Write-Host "Starting farmland requirements standardization script (setting to ${requirementValue})..." -ForegroundColor Cyan

# Get all mod directories
$modDirs = Get-ChildItem -Path $rootPath -Directory

foreach ($mod in $modDirs) {
    $modName = $mod.Name
    $modFilesModified = 0
    
    # Process blocks directory (farmland is typically a block)
    $dirPath = Join-Path -Path $mod.FullName -ChildPath "pmmo\blocks"
    
    # Skip if the directory doesn't exist
    if (-not (Test-Path $dirPath)) {
        continue
    }
    
    Write-Host "Processing $modName blocks..." -ForegroundColor Yellow
    
    # Get all JSON files in the directory
    $files = Get-ChildItem -Path $dirPath -Filter "*.json" -Recurse
    
    foreach ($file in $files) {
        $processedFiles++
        
        # Check if filename contains any farmland-related keywords
        $isFarmlandRelated = $false
        foreach ($keyword in $farmlandKeywords) {
            if ($file.Name -like "*$keyword*") {
                $isFarmlandRelated = $true
                break
            }
        }
        
        # Skip if not farmland related
        if (-not $isFarmlandRelated) {
            continue
        }
        
        try {
            # Read the JSON content
            $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $modified = $false
            
            # Ensure requirements section exists
            if (-not $jsonContent.PSObject.Properties["requirements"]) {
                $jsonContent | Add-Member -MemberType NoteProperty -Name "requirements" -Value @{}
            }
            
            # Ensure PLACE, BREAK, and INTERACT sections exist in requirements
            foreach ($section in @("PLACE", "BREAK", "INTERACT")) {
                if (-not $jsonContent.requirements.PSObject.Properties[$section]) {
                    $jsonContent.requirements | Add-Member -MemberType NoteProperty -Name $section -Value @{}
                }
            }
            
            # Update farming requirements for PLACE and BREAK
            foreach ($section in @("PLACE", "BREAK")) {
                $currentValue = $null
                
                # Get current value if it exists
                if ($jsonContent.requirements.$section.PSObject.Properties["farming"]) {
                    $currentValue = $jsonContent.requirements.$section.farming
                }
                
                # Set to the target value if different
                if ($currentValue -ne $requirementValue) {
                    if (-not $jsonContent.requirements.$section.PSObject.Properties["farming"]) {
                        $jsonContent.requirements.$section | Add-Member -MemberType NoteProperty -Name "farming" -Value $requirementValue
                    } else {
                        $jsonContent.requirements.$section.farming = $requirementValue
                    }
                    
                    $modified = $true
                    Write-Host "  Updated $section farming requirement in $($file.Name): $currentValue -> $requirementValue" -ForegroundColor Green
                }
            }
            
            # Save changes if modified
            if ($modified) {
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $file.FullName -Encoding UTF8
                $modifiedFiles++
                $modFilesModified++
            }
        }
        catch {
            Write-Host "  Error processing $($file.Name): $_" -ForegroundColor Red
        }
    }
    
    # Save mod stats if any files were modified
    if ($modFilesModified -gt 0) {
        $modStats[$modName] = @{
            FilesModified = $modFilesModified
        }
    }
}

# Generate a summary report
Write-Host "`n=== Farmland Requirements Standardization Summary ===" -ForegroundColor Cyan
Write-Host "Files processed: $processedFiles" -ForegroundColor White
Write-Host "Farmland files modified: $modifiedFiles" -ForegroundColor Green

# Show stats by mod
Write-Host "`nModified files by mod:" -ForegroundColor Cyan
foreach ($mod in ($modStats.Keys | Sort-Object -Property { $modStats[$_].FilesModified } -Descending)) {
    $stats = $modStats[$mod]
    Write-Host "  $mod : $($stats.FilesModified) files" -ForegroundColor White
}

Write-Host "`nProcessing complete!" -ForegroundColor Green