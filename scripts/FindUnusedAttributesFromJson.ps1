param (
    [string]$AttributesJsonPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts/attributes.json",
    [string]$DefinitionsPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo/atm_10_pack/src/main/resources/data/atm10_pmmo/puffish_skills/categories/combat/definitions.json",
    [string]$OutputFile = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts/unused_attributes_report.json",
    [switch]$IncludeUsed = $false,
    [switch]$GroupByNamespace = $true
)

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

# Function to extract all attributes from attributes.json
function Get-AllAttributes {
    param (
        [object]$AttributesJson
    )
    
    return $AttributesJson.attributes.PSObject.Properties.Name
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
                            min = $null
                            max = $null
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

# Function to add min/max information to attribute data
function Add-AttributeRanges {
    param (
        [hashtable]$AttributesData,
        [object]$AttributesJson
    )
    
    foreach ($attr in $AttributesData.Keys) {
        if ($AttributesJson.attributes.PSObject.Properties.Name -contains $attr) {
            $AttributesData[$attr].min = $AttributesJson.attributes.$attr.min
            $AttributesData[$attr].max = $AttributesJson.attributes.$attr.max
        }
    }
}

# Function to group attributes by namespace
function Group-AttributesByNamespace {
    param (
        [string[]]$AttributesList
    )
    
    $grouped = @{}
    
    foreach ($attr in $AttributesList) {
        $parts = $attr -split ":"
        if ($parts.Length -gt 1) {
            $namespace = $parts[0]
            if (-not $grouped.ContainsKey($namespace)) {
                $grouped[$namespace] = @()
            }
            $grouped[$namespace] += $attr
        } else {
            # Handle attributes without a namespace
            if (-not $grouped.ContainsKey("unknown")) {
                $grouped["unknown"] = @()
            }
            $grouped["unknown"] += $attr
        }
    }
    
    return $grouped
}

# Main execution
Write-Host "Loading attributes from $AttributesJsonPath..."
$attributesJson = Get-JsonContent -Path $AttributesJsonPath
$allAttributes = Get-AllAttributes -AttributesJson $attributesJson

Write-Host "Loading definitions from $DefinitionsPath..."
$definitions = Get-JsonContent -Path $DefinitionsPath

Write-Host "Analyzing attributes usage..."
$usedAttributes = Get-UsedAttributes -Definitions $definitions
$usedAttributeNames = $usedAttributes.Keys

# Add min/max information to used attributes
Add-AttributeRanges -AttributesData $usedAttributes -AttributesJson $attributesJson

# Find unused attributes and add range information
$unusedAttributes = @{}
foreach ($attr in $allAttributes) {
    if ($attr -notin $usedAttributeNames) {
        $unusedAttributes[$attr] = @{
            min = $attributesJson.attributes.$attr.min
            max = $attributesJson.attributes.$attr.max
        }
    }
}

# Prepare the report
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    total_attributes = $allAttributes.Count
    used_attributes_count = $usedAttributeNames.Count
    unused_attributes_count = $unusedAttributes.Count
}

# Group attributes by namespace if requested
if ($GroupByNamespace) {
    if ($unusedAttributes.Count -gt 0) {
        $report.unused_attributes_by_namespace = Group-AttributesByNamespace -AttributesList $unusedAttributes.Keys
    } else {
        $report.unused_attributes_by_namespace = @{}
    }
    
    if ($IncludeUsed) {
        if ($usedAttributes.Count -gt 0) {
            $report.used_attributes_by_namespace = Group-AttributesByNamespace -AttributesList $usedAttributes.Keys
        } else {
            $report.used_attributes_by_namespace = @{}
        }
    }
}

# Include detailed attribute information
if ($IncludeUsed) {
    $report.used_attributes = $usedAttributes
}

$report.unused_attributes = $unusedAttributes

# Output the report
$jsonReport = $report | ConvertTo-Json -Depth 5
$jsonReport | Out-File -FilePath $OutputFile -Encoding UTF8

# Display summary
Write-Host "`nAttribute Usage Summary:"
Write-Host "----------------------"
Write-Host "Total attributes: $($allAttributes.Count)"
Write-Host "Used attributes: $($usedAttributeNames.Count)"
Write-Host "Unused attributes: $($unusedAttributes.Count)"

# Show some examples of unused attributes by namespace
if ($unusedAttributes.Count -gt 0 -and $GroupByNamespace) {
    $namespaces = $report.unused_attributes_by_namespace.Keys | Sort-Object
    
    Write-Host "`nUnused attributes by namespace:"
    foreach ($namespace in $namespaces) {
        $count = $report.unused_attributes_by_namespace[$namespace].Count
        Write-Host "  $namespace`: $count attributes"
        
        # Show a few examples from each namespace
        $examples = $report.unused_attributes_by_namespace[$namespace] | Select-Object -First 3
        foreach ($example in $examples) {
            Write-Host "    - $example"
        }
        
        # Show ellipsis if there are more
        if ($count -gt 3) {
            Write-Host "    - ... and $($count - 3) more"
        }
    }
}

Write-Host "`nDetailed report saved to: $OutputFile"

# Provide suggestions for most valuable attributes to add
Write-Host "`nSuggestions for notable attributes to consider adding:"

# Check for common useful attributes that aren't being used
$notableAttributes = @(
    @{ name="minecraft:generic.luck"; desc="Affects loot quality and other random events" },
    @{ name="apothic_attributes:mining_speed"; desc="Increases mining speed for all blocks" },
    @{ name="apothic_attributes:experience_gained"; desc="Increases XP gained from all sources" },
    @{ name="minecraft:generic.max_absorption"; desc="Increases maximum absorption hearts (gold hearts)" },
    @{ name="minecraft:player.block_break_speed"; desc="Increases block breaking speed" },
    @{ name="apothic_attributes:projectile_damage"; desc="Increases all projectile damage, not just arrows" },
    @{ name="minecraft:generic.follow_range"; desc="Increases detection range for player's companions" },
    @{ name="additionalentityattributes:player.collection_range"; desc="Increases item pickup range" },
    @{ name="neoforge:swim_speed"; desc="Increases swimming speed" },
    @{ name="artifacts:generic.drinking_speed"; desc="Increases potion drinking speed" }
)

foreach ($attr in $notableAttributes) {
    if ($attr.name -notin $usedAttributeNames -and $unusedAttributes.ContainsKey($attr.name)) {
        Write-Host "  - $($attr.name): $($attr.desc)"
    }
}
