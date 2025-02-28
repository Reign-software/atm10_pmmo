# PowerShell script to modify JSON files
# Set the directory path to scan - change this to your target directory
$directoryPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\atm_10_pack\src\main\resources\data\ae2\pmmo\items"

# Get all JSON files in the directory and subdirectories
$jsonFiles = Get-ChildItem -Path $directoryPath -Filter "*.json" -Recurse

foreach ($file in $jsonFiles) {
    Write-Host "Processing: $($file.FullName)"
    
    # Read the JSON content
    $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
    
    $modified = $false
    
    # Check if xp_values exists
    if (-not $jsonContent.PSObject.Properties["xp_values"]) {
        $jsonContent | Add-Member -NotePropertyName "xp_values" -NotePropertyValue @{}
        $modified = $true
    }
    
    # Check if xp_values.CRAFT exists
    if (-not $jsonContent.xp_values.PSObject.Properties["CRAFT"]) {
        $jsonContent.xp_values | Add-Member -NotePropertyName "CRAFT" -NotePropertyValue @{}
        $modified = $true
    }
    
    # Add/set technology: 10 in xp_values.CRAFT
    if (-not $jsonContent.xp_values.CRAFT.PSObject.Properties["technology"]) {
        $jsonContent.xp_values.CRAFT | Add-Member -NotePropertyName "technology" -NotePropertyValue 10 -Force
        $modified = $true
    }
    
    # Check if requirements exists
    if (-not $jsonContent.PSObject.Properties["requirements"]) {
        $jsonContent | Add-Member -NotePropertyName "requirements" -NotePropertyValue @{}
        $modified = $true
    }
    
    # Check if requirements.PLACE exists
    if (-not $jsonContent.requirements.PSObject.Properties["PLACE"]) {
        $jsonContent.requirements | Add-Member -NotePropertyName "PLACE" -NotePropertyValue @{}
        $modified = $true
    }
    
    # Add/set technology: 200 in requirements.PLACE
    if (-not $jsonContent.requirements.PLACE.PSObject.Properties["technology"] -or 
        $jsonContent.requirements.PLACE.technology -ne 200) {
        $jsonContent.requirements.PLACE | Add-Member -NotePropertyName "technology" -NotePropertyValue 200 -Force
        $modified = $true
    }
    
    # Save changes if any modifications were made
    if ($modified) {
        $jsonContent | ConvertTo-Json -Depth 20 | Set-Content -Path $file.FullName
        Write-Host "Updated: $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "No changes needed for: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "Processing complete!" -ForegroundColor Cyan