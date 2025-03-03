# Archery Weapon Tiers for PMMO

This document outlines the tier system for archery weapons (bows and crossbows) in ATM10, with their corresponding XP rewards and requirements.

## XP Values for Crafting

The `AddArcheryXPToBows.ps1` script adds archery XP to all bow/crossbow items based on their material tier. Higher tier bows grant more XP when crafted, encouraging progression.

### Tier System

| Material Category | XP Value | Examples |
|-------------------|----------|----------|
| **Basic Materials** | 500 | Wooden Bow, Simple Bow, Training Bow |
| **Early Game** | 1000-1500 | Iron Bow, Copper Crossbow, Bronze Bow |
| **Mid Game** | 2000-2500 | Golden Bow, Silver Crossbow, Electrum Bow |
| **Advanced Game** | 5000-6000 | Diamond Bow, Ruby Crossbow, Obsidian Bow |
| **Late Game** | 8000-12000 | Netherite Bow, Enderium Crossbow, Refined Bow |
| **Special Materials** | 15000-25000 | Allthemodium Bow, Vibranium Crossbow |
| **End Game** | 30000 | Draconic Bow, Chaotic Crossbow, Infinity Bow |

## Material Keywords

The script identifies the tier based on these material keywords in the item name:

### Basic (500 XP)
- simple, training, wooden, basic

### Early Game (1000-1500 XP)
- iron, stone, copper, tin, bronze, steel

### Mid Game (2000-2500 XP)
- gold, golden, silver, electrum, brass

### Advanced Game (5000-6000 XP)
- diamond, emerald, sapphire, ruby, obsidian, osmium

### Late Game (8000-12000 XP)
- netherite, nether, reinforced, enderium, signalum, lumium, refined

### Special Materials (15000-25000 XP)
- allthemodium, vibranium, unobtainium

### End Game (30000 XP)
- draconic, chaotic, wyvern, dragon, infinity, ultimate, creative, awakened

## Additional Features

1. **USE Requirements**: The script adds archery skill requirements based on the weapon's tier
2. **DEAL_DAMAGE XP**: Also adds a small amount of archery XP when dealing damage with the weapon
3. **Default Value**: If no tier is detected, a default value of 500 XP is applied

## Implementation Details

When the script runs, it:

1. Identifies all bow and crossbow items in the modpack
2. Determines their tier based on material keywords
3. Adds appropriate archery XP for crafting
4. Adds a scaled archery skill requirement based on the XP value
5. Ensures damage with the weapon grants archery XP

## Usage Examples

A few examples of how different bows would be configured:

### Vanilla Bow
- Archery XP on craft: 500
- Archery requirement: 50

### Diamond Bow
- Archery XP on craft: 5000
- Archery requirement: 250

### Draconic Bow
- Archery XP on craft: 30000
- Archery requirement: 500
