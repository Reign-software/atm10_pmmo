# Armor Classification Guide for ATM10 PMMO

## Overview

This document outlines the classification of armor types in ATM10 and their appropriate skill requirements.

## Armor Type Classification

### Regular Armor (Non-Tech)
Regular armors should only require:
- `smithing`: Crafting skill
- `endurance`: Wearing skill

Examples:
- Iron, Gold, Diamond armor sets
- Compressed material armors (Compressed Iron, etc.)
- Alloy-based armors with no special tech features
- Most gem/mineral-based armors

### Tech Armor
Tech armors should require:
- `smithing`: Crafting skill
- `endurance`: Wearing skill
- `technology`: Both for crafting and wearing

Characteristics that identify tech armor:
- Provides energy storage
- Has powered abilities
- Integrates with tech systems
- Uses circuits/capacitors/batteries

Examples:
- Jetpacks
- Quantum armor
- Powered suits
- Mekanism MekaSuit
- Hazmat suits

### Magic Armor
Magic armors should require:
- `smithing`: Crafting skill
- `endurance`: Wearing skill
- `magic`: Both for crafting and wearing

Characteristics that identify magic armor:
- Uses magical materials
- Provides magical abilities
- Integrates with spell/magic systems

Examples:
- Wizard robes
- Forbidden arcanus armors
- Twilight Forest phantom armor
- Ars Nouveau armors

## Tech Armor Identification

Armor is considered tech-based ONLY if it contains one of the following keywords:

1. jetpack
2. quantum
3. hazmat
4. power/powered
5. flux
6. energized
7. meka
8. modular
9. nano
10. electric
11. energy
12. reactor
13. circuit
14. capacitor
15. battery
16. industrial

Any armor not matching these patterns will be considered non-tech and should NOT have technology skill requirements.

## Implementation Notes
- The `RemoveInvalidTechRequirements.ps1` script automatically identifies tech armor using keyword patterns
- Any armor not matching tech patterns will have technology requirements removed
- The script runs through all mod directories and makes these adjustments automatically
- When adding new armor items, follow this classification guide to apply appropriate requirements
- If in doubt, check the armor's functionality rather than just its base material
