$skillLevels = @{}
$maxKey = 13
$maxValue = 500

for ($i = 0; $i -le $maxKey; $i++) {
    Write-Output "$i = $([math]::Round(($i / $maxKey) * $maxValue))"
}
