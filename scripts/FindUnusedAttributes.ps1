param (
    [string]$AttributesFilePath = "../scripts/Attributes.cs",
    [string]$DefinitionsFilePath = "../atm_10_pack/data/atm10_pmmo/puffish_skills/categories/combat/definitions.json",
    [string]$OutputFile = "unused_attributes_report.json",
    [switch]$IncludeUsed = $false
)

# Function to extract attributes from C# file
function Get-AttributesFromCSharp {
    param (
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Extract attribute dictionary entries
        if ($content -match '(?s)Values\s*=\s*new\(\)\s*{(.+?)}') {
            $dictionaryContent = $matches[1]
            
            # Extract each attribute name
            $pattern = '{\s*"([^"]+)",'
            $matches = [regex]::Matches($dictionaryContent, $pattern)
            
            $attributes = @()
            foreach ($match in $matches) {
                $attributes += $match.Groups[1].Value
            }
            
            return $attributes
        }
        
        throw "Could not parse attributes dictionary from $FilePath"
    }
    catch {
        Write-Error "Error processing $FilePath"
        exit 1
    }
}

# Function to get JSON content with comment handling
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

# Function to extract used attributes from definitions.json
function Get-UsedAttributes {
    param (
        [object]$Definitions
    )
    
    $usedAttributes = @{}
    
    $definitionIds = @($Definitions | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
    
    foreach ($id in $definitionIds) {
        $definition = $Definitions.$id
        
        if ($definition.rewards) {
            foreach ($reward in $definition.rewards) {
                # Check if it's an attribute reward
                if ($reward.type -eq "puffish_skills:attribute" -and $reward.data -and $reward.data.attribute) {
                    $attributeName = $reward.data.attribute
                    
                    if (-not $usedAttributes.ContainsKey($attributeName)) {
                        $usedAttributes[$attributeName] = @{
                            count = 1
                            definitions = @($id)
                        }
                    }
                    else {
                        $usedAttributes[$attributeName].count++
                        $usedAttributes[$attributeName].definitions += $id
                    }
                }
            }
        }
    }
    
    return $usedAttributes
}

# Main script
Write-Host "Loading attributes from $AttributesFilePath..."
$allAttributes = Get-AttributesFromCSharp -FilePath $AttributesFilePath

Write-Host "Loading definitions from $DefinitionsFilePath..."
$definitions = Get-JsonContent -Path $DefinitionsFilePath

Write-Host "Analyzing attributes usage..."
$usedAttributes = Get-UsedAttributes -Definitions $definitions
$usedAttributeNames = $usedAttributes.Keys

# Find unused attributes
$unusedAttributes = $allAttributes | Where-Object { $_ -notin $usedAttributeNames }

# Generate report
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_attributes = $allAttributes.Count
    used_attributes_count = $usedAttributeNames.Count
    unused_attributes_count = $unusedAttributes.Count
    unused_attributes = $unusedAttributes
}

# Add used attributes to report if requested
if ($IncludeUsed) {
    $report.used_attributes = $usedAttributes
}

# Output the report
$jsonReport = $report | ConvertTo-Json -Depth 5
$jsonReport | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "`nAttribute Usage Summary:"
Write-Host "----------------------"
Write-Host "Total attributes: $($allAttributes.Count)"
Write-Host "Used attributes: $($usedAttributeNames.Count)"
Write-Host "Unused attributes: $($unusedAttributes.Count)"

# Show some examples of unused attributes
if ($unusedAttributes.Count -gt 0) {
    $exampleCount = [Math]::Min(10, $unusedAttributes.Count)
    Write-Host "`nExamples of unused attributes:"
    for ($i = 0; $i -lt $exampleCount; $i++) {
        Write-Host "  - $($unusedAttributes[$i])"
    }
    
    if ($unusedAttributes.Count -gt 10) {
        Write-Host "  ... and $($unusedAttributes.Count - 10) more."
    }
}

Write-Host "`nDetailed report saved to: $OutputFile"
