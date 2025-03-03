# PMMO Perks Configuration Scripts

This directory contains scripts for managing PMMO perk configurations.

## Available Scripts

### UpdateArcheryPerks.ps1

This script scans the modpack for all bow and crossbow items, and adds them to the archery skill's `DEAL_DAMAGE` perk in the `perks.json` file.

#### How It Works

1. **Item Discovery**: The script searches through all mod files to identify bow and crossbow items:
   - Scans all JSON files in the modpack
   - Looks for filenames containing bow-related patterns
   - Checks file contents for bow/crossbow item IDs
   - Includes a hardcoded list of known bows/crossbows that might be missed

2. **Perks Update**: The script then updates the perks.json file:
   - Adds all discovered bows to the `applies_to` array for the archery skill
   - Creates a new archery perk entry if none exists
   - Maintains existing entries while adding new ones

3. **Output**: The script provides:
   - Detailed information about items found
   - Export of all discovered bow/crossbow items to a file
   - Summary of changes made

#### Usage

Run the script from PowerShell:

```
.\UpdateArcheryPerks.ps1
```

#### Pattern Matching

The script identifies bows and crossbows using these patterns:
- `bow`, `crossbow`, `longbow`, `shortbow`, `flatbow`, `recurve`, `arbalest`

It also includes exclusion patterns to avoid false positives like "bowl" or "elbow".

## Advanced Usage

### Adding Known Bow Items

If the script misses specific bow items, add them to the `$knownBows` array in the script:

```powershell
$knownBows = @(
    "minecraft:bow",
    "minecraft:crossbow",
    # Add your item here
    "modid:your_custom_bow"
)
```

### Customizing Exclusion Patterns

To prevent false positives, update the `$exclusionPatterns` array:

```powershell
$exclusionPatterns = @(
    "bowl", "elbow",
    # Add your exclusion pattern here
)
```

## Example JSON Updates

Before:
```json
{
  "perks": {
    "DEAL_DAMAGE": [
      {
        "applies_to": [
          "minecraft:bow",
          "minecraft:crossbow"
        ],
        "perk": "pmmo:damage_boost",
        "skill": "archery"
      }
    ]
  }
}
```

After:
```json
{
  "perks": {
    "DEAL_DAMAGE": [
      {
        "applies_to": [
          "minecraft:bow",
          "minecraft:crossbow",
          "silentgear:longbow",
          "twilightforest:seeker_bow",
          "mekanism:electric_bow"
          // ...many more bow items
        ],
        "perk": "pmmo:damage_boost",
        "skill": "archery"
      }
    ]
  }
}
```
