# Tool Requirements Guide for ATM10 PMMO

## Overview

This document outlines the proper skill requirements for different types of tools in ATM10.

## Tool Type Requirements

### Standard Tools
Standard tools should require:
- `smithing`: Crafting skill requirement
- Specific tool skill for use (`mining` for pickaxes, `farming` for hoes, etc.)

They should NOT have:
- `combat` requirements unless they are specifically designed to be weapons as well

### Tool Types and Their Required Skills

| Tool Type | Primary Skill | Secondary Skill | Usage Skill |
|-----------|--------------|----------------|------------|
| Pickaxe | mining | smithing | mining |
| Axe | woodcutting | smithing | woodcutting |
| Shovel | excavation | smithing | excavation |
| Hoe | farming | smithing | farming |
| Shears | farming | smithing | farming |
| Paxel | mining | smithing | multiple |

### Dual-Purpose Tools
Some tools are legitimately designed to be both tools and weapons:

- Battle Axes
- War Hammers
- Combat Spades/Shovels

These should retain their `combat` requirements in the WEAPON section.

## Implementation

The `RemoveCombatFromTools.ps1` script automatically:

1. Identifies tool items by name patterns
2. Preserves combat requirements for actual weapon-tools (battle axes, etc.)
3. Removes combat requirements from standard tools
4. Reports statistics on what was modified

## When Adding New Tools

When adding new tools:

1. Use appropriate skill requirements for the tool type
2. Only include combat requirements if the tool is designed to be a weapon
3. For multi-tools (like paxels), include requirements for all relevant tool skills

## Examples

### Correct Requirements

**Iron Pickaxe (Standard Tool)**
```json
"requirements": {
  "TOOL": {
    "mining": 50,
    "smithing": 50
  },
  "USE": {
    "mining": 50
  }
}
```

**Battle Axe (Dual-Purpose Tool)**
```json
"requirements": {
  "TOOL": {
    "woodcutting": 75,
    "smithing": 75
  },
  "WEAPON": {
    "combat": 75
  },
  "USE": {
    "woodcutting": 75,
    "combat": 75
  }
}
```
