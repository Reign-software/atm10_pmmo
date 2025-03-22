# List of skills to remove
$skillsToRemove = @(
    "farming"
)

# Define the root data directory
$rootDir = ".\atm_10_pack\src\main\resources\data"

# Stats counters
$filesProcessed = 0
$filesModified = 0
$skillReferencesRemoved = 0

# Process a JSON object to remove specified skills
function Remove-SkillsFromObject {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Object,
        [switch]$IsRoot = $false
    )
    
    $modified = $false
    
    # Process all properties of the object
    foreach ($property in @($Object.PSObject.Properties.Name)) {
        $value = $Object.$property
        
        # If the property is a skill to remove and the value is a number or array
        if ($skillsToRemove -contains $property) {
            $Object.PSObject.Properties.Remove($property)
            $script:skillReferencesRemoved++
            $modified = $true
            continue
        }
        
        # If the value is another object, process it recursively
        if ($value -is [PSCustomObject]) {
            $childModified = Remove-SkillsFromObject -Object $value
            if ($childModified) { $modified = $true }
        }
        
        # If the value is a dictionary/hashtable (common in requirements and xp_values)
        elseif ($value -is [PSCustomObject] -or $value -is [Hashtable]) {
            foreach ($skill in $skillsToRemove) {
                if ($value.PSObject.Properties.Name -contains $skill) {
                    $value.PSObject.Properties.Remove($skill)
                    $script:skillReferencesRemoved++
                    $modified = $true
                }
            }
        }
        
        # If the value is an array, process each element
        elseif ($value -is [Array]) {
            for ($i = 0; $i -lt $value.Count; $i++) {
                if ($value[$i] -is [PSCustomObject]) {
                    $childModified = Remove-SkillsFromObject -Object $value[$i]
                    if ($childModified) { $modified = $true }
                }
            }
        }
    }
    
    # Special handling for the skills.json file
    if ($IsRoot -and $Object.PSObject.Properties.Name -contains "skills") {
        foreach ($skill in $skillsToRemove) {
            if ($Object.skills.PSObject.Properties.Name -contains $skill) {
                $Object.skills.PSObject.Properties.Remove($skill)
                $script:skillReferencesRemoved++
                $modified = $true
            }
        }
        
        # Also check groupFor properties in remaining skills
        foreach ($skillName in $Object.skills.PSObject.Properties.Name) {
            $skill = $Object.skills.$skillName
            if ($skill.PSObject.Properties.Name -contains "groupFor") {
                foreach ($groupSkill in $skillsToRemove) {
                    if ($skill.groupFor.PSObject.Properties.Name -contains $groupSkill) {
                        $skill.groupFor.PSObject.Properties.Remove($groupSkill)
                        $script:skillReferencesRemoved++
                        $modified = $true
                    }
                }
            }
        }
    }
    
    return $modified
}

Write-Host "Starting to process JSON files in $rootDir" -ForegroundColor Cyan

# Find all JSON files
$jsonFiles = Get-ChildItem -Path $rootDir -Filter "*.json" -Recurse

foreach ($file in $jsonFiles) {
    $filesProcessed++
    
    try {
        # Read and parse the JSON file
        $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        
        # Process the JSON object
        $modified = Remove-SkillsFromObject -Object $json -IsRoot:$true
        
        # If modifications were made, save the file
        if ($modified) {
            $filesModified++
            
            # Convert back to JSON with proper formatting and save
            $jsonContent = $json | ConvertTo-Json -Depth 20
            $jsonContent | Set-Content -Path $file.FullName
            
            Write-Host "Updated: $($file.FullName)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error processing $($file.FullName): $_" -ForegroundColor Red
    }
    
    # Display progress every 100 files
    if ($filesProcessed % 100 -eq 0) {
        Write-Host "Processed $filesProcessed files..." -ForegroundColor Yellow
    }
}

Write-Host "`nRemove Skills Operation Complete!" -ForegroundColor Cyan
Write-Host "Files processed: $filesProcessed" -ForegroundColor White
Write-Host "Files modified: $filesModified" -ForegroundColor Green
Write-Host "Skill references removed: $skillReferencesRemoved" -ForegroundColor Yellow