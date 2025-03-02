# Technology XP Balance Adjustments

This document explains the multiplier applied to Technology XP values for crafting items.

## Changes Made

- All Technology XP rewards from crafting have been multiplied by 20x
- This affects the `xp_values.CRAFT.technology` node in all item JSON files
- The change was implemented via the `TechXPMultiplier.ps1` script

## Reasoning

Technology skill was advancing too slowly compared to other skills in the modpack. Key issues were:

1. **Reward Imbalance**: Other skills like mining offered much higher XP per action
2. **Crafting Complexity**: Tech items are generally more complex to craft but weren't rewarding accordingly
3. **Progression Rate**: Players were hitting tech skill walls before being able to progress

## Expected Outcomes

The 20x multiplier is expected to:

- Allow players to progress through technology tiers at a more reasonable pace
- Better reward complex crafting operations like automation components
- Balance technology skill progression with other skill progressions

## Example XP Changes

| Item | Old XP | New XP |
|------|--------|--------|
| ME Drive | 10 | 200 |
| Basic Circuit | 5 | 100 |
| Advanced Circuit | 10 | 200 |
| Elite Circuit | 15 | 300 |
| Ultimate Circuit | 20 | 400 |
| Mekanism Machine Frame | 25 | 500 |
| Quantum Entangloporter | 50 | 1000 |

## Notes for Future Adjustments

If further balancing is needed, consider:

1. Evaluating skill progression rates after ~10 hours of gameplay
2. Adjusting specific mod items rather than applying a global multiplier
3. Introducing tiered XP rewards based on item complexity or material cost
4. Adding diminishing returns for mass-crafting simple tech items
