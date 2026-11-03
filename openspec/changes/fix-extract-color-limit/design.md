## Context

The Extract tab in Paletto allows users to extract colors from images via k-means clustering and manually pick colors using a magnifier overlay. The palette capacity is controlled by a single constant: `Constants.Palette.maxColorCount = 8`. When a user picks colors beyond the initial k-means seed, the round-robin replacement only cycles through the last 3 slots (`[5, 6, 7]` when max=8`), making the first 5 k-means slots permanently immutable once full. This gives the impression that only 5 "extra" colors can ever be picked.

The desired behavior:
- **Max palette size**: 10 colors total
- **K-means zone**: slots `[0, seedCount - 1]` — can be removed but can also be refilled if a slot is deleted
- **User-pick zone**: slots `[seedCount, maxCount - 1]` — all are replaceable in round-robin
- **Refill priority**: if k-means zone has empty slots (from deletion), new picks fill those first before cycling into user-pick zone

## Goals / Non-Goals

**Goals:**
- Increase max color count from 8 to 10
- Make all user-pick zone slots (not just 3) available for round-robin replacement
- Add k-means zone refill: new picks fill deleted k-means slots before entering round-robin
- Maintain existing undo behavior (replace registers previous color for undo)
- Auto-adapt all downstream clamp logic via constant change

**Non-Goals:**
- Changing the camera color picker behavior (separate feature)
- Adding an upper limit on user picks vs k-means count beyond the global max
- Migration of existing palettes (existing palettes with ≤ 10 colors remain valid)
- UI changes beyond fixing the underlying logic

## Decisions

### Decision 1: Expand `maxColorCount` from 8 to 10

**Chosen**: Change `Constants.Palette.maxColorCount` from `8` to `10`.

**Rationale**: The constant is the single source of truth used by all enforcement points (SettingsManager, extractColors, addPickedColor, SettingsView Stepper). Changing it here automatically widens every downstream clamp without additional code changes.

**Alternatives considered**:
- Add a separate `maxUserPickCount` constant — rejected because it would require duplicating clamp logic across SettingsManager, extractColors, and addPickedColor, increasing maintenance burden.

### Decision 2: Dynamic round-robin range (vs. fixed 3-slot window)

**Chosen**: Replace `let replaceRange = min(3, maxCount)` with `let replaceRange = maxCount - seedCount`.

**Current code** (L136–137):
```swift
let replaceRange = min(3, maxCount)           // hard-coded 3
let targetIndex = maxCount - replaceRange + (replaceIndex % replaceRange)
```

**New code**:
```swift
let seedCount = settingsManager.defaultColorCount
let userPickSlotCount = maxCount - seedCount   // dynamic: 10 - 5 = 5 slots [5,6,7,8,9]
let targetIndex = seedCount + (replaceIndex % userPickSlotCount)
```

**Rationale**: With max=10 and seed=5, the user-pick zone is 5 slots (`[5, 6, 7, 8, 9]`). The round-robin should cover all 5, not just the last 3. Making replaceRange dynamic (`maxCount - seedCount`) ensures the logic works for any seed count from 3 to 10.

**Alternatives considered**:
- Hard-code `replaceRange = 5` for max=10 — rejected because it breaks if user sets seed=3 (would need 7 user-pick slots but only 5 exist).
- Replace oldest slot (FIFO) — rejected because it destroys the most-recently-added user pick, which is confusing UX. Round-robin through all user-pick slots preserves diversity.

### Decision 3: K-means zone refill before round-robin

**Chosen**: Before entering round-robin, check if k-means zone has any empty slots (from prior deletion). If yes, fill the first empty slot rather than replacing a user-pick slot.

**New logic flow in `addPickedColor()`**:
```
if count < maxCount:
  → Append (existing behavior)

else:  // count == maxCount
  if k-means zone has empty slots (count < seedCount):
    → Find first empty slot in [0, seedCount-1]
    → Fill that slot
  else:
    → Round-robin replace in user-pick zone [seedCount, maxCount-1]
```

**Rationale**: This handles the edge case where a user deletes a k-means color (e.g., slot 2), then picks a new color. Without refill logic, the new pick would enter round-robin and never fill the gap in the k-means zone, leading to a permanently sparse k-means zone. Refill ensures the k-means zone stays compact unless intentionally emptied.

**Alternatives considered**:
- No refill (fills at end of array) — rejected: k-means zone becomes permanently fragmented after any deletion.
- Refill but only from user-pick zone — rejected: if user-pick zone also has no slots (full), the gap in k-means zone remains. The chosen approach refills k-means zone from anywhere, then falls back to round-robin in user-pick zone.

### Decision 4: Undo behavior for replace operations

**Chosen**: Keep the existing undo behavior (store previousColor at targetIndex, restore on undo). This means undoing a replace restores the color that was at that slot before the replace — NOT the original k-means color.

**Rationale**: This preserves the most recent state as the undo target. If a user picks 3 colors that cycle through slots 5→6→7, undoing one step at a time correctly reverses each replacement. Undoing all 3 steps eventually returns to the state before any user picks were added. Undoing back to the original k-means seed would require 3+ separate operations in the undo stack, which is confusing.

**Example** (max=10, seed=5, palette full at 10):
```
Initial: [A B C D E | F G H I J]  (A-E = k-means, F-J = user picks)

Pick K → slot 5 (F replaced, undo restores F)
Pick L → slot 6 (G replaced, undo restores G)
Pick M → slot 7 (H replaced, undo restores H)

Undo: restores H, slot 7 = H
Undo: restores G, slot 6 = G
Undo: restores F, slot 5 = F
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| User sets `defaultColorCount` very low (3), then k-means zone is only 3 slots and user-pick zone is 7. Round-robin covers 7 slots — harder to predict which slot gets replaced. | This is by design: low seed count = more flexibility for user picks. Document this behavior in the settings UI. |
| If user deletes a k-means slot and immediately picks a color, the new color appears in the "middle" of the k-means zone (not at the end), which may be visually confusing. | Refill fills the first empty slot (lowest index) — closest to original position. This is the most intuitive behavior. |
| Existing palettes with 8 colors remain valid after the change — but the user-pick zone shifts from 3 to 5 slots. | No migration needed. Existing palettes continue to work. The extra 2 slots (8, 9) become available on next user pick. |