$basePath = "E:\Projects\Minecraft\atm10_pmmo\atm_10_pack\src\main\resources\data"

$dict = @{}

Get-ChildItem -Path $basePath -Directory | ForEach-Object {
    $modName = $_.Name
    $enchantmentsPath = Join-Path -Path $_.FullName -ChildPath "pmmo\enchantments"

    if (Test-Path -Path $enchantmentsPath) {
        Get-ChildItem -Path $enchantmentsPath -Filter "*.json" | ForEach-Object {
            $dict[$_.BaseName] = 1
        }
    }
}

foreach ($key in $dict.Keys) {
    Write-Output "`"$key`" = $($dict[$key])"
}

$skillLevels = @{}
$maxKey = 13
$maxValue = 500

for ($i = 0; $i -le $maxKey; $i++) {
    $skillLevels[$i] = [math]::Round(($i / $maxKey) * $maxValue)
}
