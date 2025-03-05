param (
    [string]$SkillsPath = "../atm_10_pack/data/atm10_pmmo/puffish_skills/categories/combat/skills.json",
    [string]$DefinitionsPath = "../atm_10_pack/data/atm10_pmmo/puffish_skills/categories/combat/definitions.json",
    [string]$OutputFile = "validation_report.json"
)

function Get-JsonContent {
    param (
        [string]$Path
    )
    
    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        
        # Remove comments (anything after //)
        $contentNoComments = $content -replace '//.*', ''
        
        return $contentNoComments | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Error "Error reading or parsing $Path"
        exit 1
    }
}

function Test-SkillsDefinitions {
    param (
        [PSObject]$Skills,
        [PSObject]$Definitions
    )
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        skills_file = $SkillsPath
        definitions_file = $DefinitionsPath
        skills_count = 0
        definitions_count = 0
        invalid_skills = @()
        unused_definitions = @()
        valid = $true
    }
    
    # Get list of all definition IDs
    $definitionIds = @($Definitions | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
    $report.definitions_count = $definitionIds.Count
    
    # Track which definitions are used
    $usedDefinitions = @{}
    foreach ($defId in $definitionIds) {
        $usedDefinitions[$defId] = $false
    }
    
    # Check each skill's definition
    $skillIds = @($Skills | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
    $report.skills_count = $skillIds.Count
    
    foreach ($skillId in $skillIds) {
        $skill = $Skills.$skillId
        $definitionId = $skill.definition
        
        if (-not $definitionId) {
            $report.invalid_skills += @{
                skill_id = $skillId
                issue = "Missing definition property"
            }
            $report.valid = $false
            continue
        }
        
        if (-not $definitionIds.Contains($definitionId)) {
            $report.invalid_skills += @{
                skill_id = $skillId
                definition = $definitionId
                issue = "Referenced definition does not exist"
            }
            $report.valid = $false
            continue
        }
        
        # Mark this definition as used
        $usedDefinitions[$definitionId] = $true
    }
    
    # Check for unused definitions
    foreach ($defId in $definitionIds) {
        if (-not $usedDefinitions[$defId]) {
            $report.unused_definitions += @{
                definition_id = $defId
                issue = "Definition not used by any skill"
            }
            # Note: We don't set valid = false for unused definitions since they don't break functionality
        }
    }
    
    return $report
}

# Main execution
Write-Host "Loading skills from $SkillsPath..."
$skills = Get-JsonContent -Path $SkillsPath

Write-Host "Loading definitions from $DefinitionsPath..."
$definitions = Get-JsonContent -Path $DefinitionsPath

Write-Host "Validating skills and definitions..."
$report = Test-SkillsDefinitions -Skills $skills -Definitions $definitions

# Output the report
$jsonReport = $report | ConvertTo-Json -Depth 5
$jsonReport | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "`nValidation Summary:"
Write-Host "----------------"
Write-Host "Skills count: $($report.skills_count)"
Write-Host "Definitions count: $($report.definitions_count)"
Write-Host "Invalid skills: $($report.invalid_skills.Count)"
Write-Host "Unused definitions: $($report.unused_definitions.Count)"
Write-Host "Overall valid: $($report.valid)"
Write-Host "`nDetailed report saved to: $OutputFile"

if (-not $report.valid) {
    Write-Host "`n⚠️ WARNING: Some skills reference undefined definitions!" -ForegroundColor Red
    foreach ($invalid in $report.invalid_skills) {
        Write-Host "  - Skill '$($invalid.skill_id)' references undefined definition '$($invalid.definition)'" -ForegroundColor Yellow
    }
    exit 1
}

if ($report.unused_definitions.Count -gt 0) {
    Write-Host "`n⚠️ NOTE: Some definitions are not used by any skill." -ForegroundColor Yellow
    Write-Host "This isn't an error, but you might want to clean up unused definitions or add skills that use them."
    foreach ($unused in $report.unused_definitions) {
        Write-Host "  - Definition '$($unused.definition_id)' is not used" -ForegroundColor Gray
    }
}

Write-Host "`n✅ All skills reference valid definitions!" -ForegroundColor Green
