param (
    [string]$AttributesFilePath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts/Attributes.cs",
    [string]$OutputJsonPath = "C:\Users\JBurl\source\repos\JBurlison\atm10_pmmo\scripts/attributes.json"
)

function Convert-AttributesToJson {
    param (
        [string]$FilePath
    )
    
    try {
        # Read the C# file
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Create result object
        $result = @{
            attributes = [ordered]@{}
        }
        
        # Extract dictionary entries using regex
        $pattern = '{\s*"([^"]+)",\s*\(([^,]+),\s*([^\)]+)\)\s*}'
        $matches = [regex]::Matches($content, $pattern)
        
        # Process each match
        foreach ($match in $matches) {
            $attributeName = $match.Groups[1].Value
            $minValue = $match.Groups[2].Value.Trim()
            $maxValue = $match.Groups[3].Value.Trim()
            
            # Handle special cases for C# constants
            if ($minValue -eq "double.MaxValue") { $minValue = "1.7976931348623157E+308" }
            if ($maxValue -eq "double.MaxValue") { $maxValue = "1.7976931348623157E+308" }
            if ($minValue -eq "int.MaxValue") { $minValue = "2147483647" }
            if ($maxValue -eq "int.MaxValue") { $maxValue = "2147483647" }
            
            # Add to result
            $result.attributes[$attributeName] = @{
                min = [double]$minValue
                max = [double]$maxValue
            }
        }
        
        return $result
    }
    catch {
        Write-Error "Error processing $FilePath"
        exit 1
    }
}

# Convert attributes and save to JSON
Write-Host "Converting attributes from $AttributesFilePath to JSON format..."
$attributes = Convert-AttributesToJson -FilePath $AttributesFilePath
$jsonContent = $attributes | ConvertTo-Json -Depth 5 -Compress:$false

# Save to file
$jsonContent | Out-File -FilePath $OutputJsonPath -Encoding UTF8
Write-Host "JSON file successfully created at: $OutputJsonPath"
