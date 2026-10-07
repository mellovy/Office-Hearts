# Office Hearts — Story Data Schema (v2)

This is the single source of truth for story content. Route content is split
one file per route so writers can work in parallel:

| File                        | Owns chapters                                            |
|-----------------------------|----------------------------------------------------------|
| `scripts/story/story_common.gd` | `common_ch1`, `common_ch2`, `hub`, `hub_arthur`, `hub_dante`, `hub_leo` |
| `scripts/story/story_arthur.gd` | `arthur_ch2..arthur_ch6`, `arthur_end_good/true/bad` |
| `scripts/story/story_dante.gd`  | `dante_ch2..dante_ch6`, `dante_end_good/true/bad`    |
| `scripts/story/story_leo.gd`    | `leo_ch2..leo_ch6`, `leo_end_good/true/bad`          |
| `scripts/story/story_graph.gd`  | flowchart nodes/edges + route colors/names           |

Every route module is exactly:

```gdscript
extends RefCounted
const CHAPTERS: Dictionary = { "<chapter_id>": { ... }, ... }
```

`scripts/DialogueData.gd` (autoload **Story**) merges them and exposes
`Story.get_chapter(id)`, `Story.FLOW_NODES`, `Story.FLOW_EDGES`,
`Story.ROUTE_NAMES`, `Story.ROUTE_COLORS`.

---

## ChapterDict

| key        | type   | required | notes |
|------------|--------|----------|-------|
| `title`    | String | yes | banner title, e.g. `"Chapter 3 — Behind the Suit"` |
| `location` | String | yes | `"Place — Time"`; the engine splits on `—` to build the transition card |
| `bgm_key`  | String | yes | one of `upbeat` `tense` `mystery` `warm` `sad` |
| `bg_scene` | String | yes | backdrop art key (list below) |
| `route`    | String | yes | `common` \| `arthur` \| `dante` \| `leo` |
| `lines`    | Array  | yes | Array of LineDict |
| `choice`   | Dict   | no  | ChoiceDict — shown after all lines are read |
| `next`     | String | no  | chapter id to auto-advance to (only used when there is no `choice`) |
| `minigame` | Dict   | no  | MinigameDict — fires after all lines are read, **before** `choice`/`next` |
| `ending`   | String | no  | `good` \| `bad` \| `true` — marks an ending chapter |
| `ending_name` | String | endings | short ending name for the gallery, e.g. `"Executive Partnership"` |
| `ending_desc` | String | endings | 1–2 sentence blurb for the gallery |

## LineDict

| key        | type   | notes |
|------------|--------|-------|
| `speaker`  | String | `""` = narration (no portrait). Otherwise a SPEAKER label (below). |
| `text`     | String | BBCode allowed, e.g. `[i](Squints)[/i] Dialogue...` |
| `portrait` | String | optional char-key override (`arthur`/`dante`/`leo`/`maya`/`sterling`) |

**SPEAKER labels → portrait:** `MAYA`, `MAYA (NARRATION)` → `maya`;
`ARTHUR` → `arthur`; `DANTE` → `dante`; `LEO` → `leo`; `STERLING` → `sterling`.
Unknown speaker → no portrait.

## ChoiceDict

```gdscript
"choice": {
    "prompt": "Who do you help first?",
    "options": [ OptionDict, ... ],
}
```

## OptionDict

| key           | type   | notes |
|---------------|--------|-------|
| `text`        | String | button label |
| `next`        | String | chapter id |
| `char`        | String | optional — affection target (`arthur`/`dante`/`leo`) |
| `points`      | int    | optional — affection delta (may be negative) |
| `sets_flag`   | String | optional — flag set when chosen |
| `requires`    | Dict   | optional — VISIBILITY gate (AND of present keys): `{"char":"arthur","min":12}`, `{"flag":"arthur_evidence"}`, `{"not_flag":"hub_arthur_done"}` |
| `locked_hint` | String | optional — if set, an unmet `requires` shows the option **disabled** with this hint instead of hiding it |

**Rule:** every choice must keep at least one ungated option so the player can
never get stuck.

## MinigameDict

An optional chapter gate. When present, the engine runs the minigame in a modal
overlay after the chapter's last line, then continues to the `choice` / `next`.
Success sets `success_flag` (when given); failure (or `{forfeit:true}`) offers
**one** retry at a cost of −2 affection with the chapter's `route` character,
then continues without the flag. An unknown `id`, or a `success_flag` that is
already set, skips it silently (never deadlocks).

```gdscript
"minigame": {
    "id": "evidence_hunt",           # must exist in MinigameRegistry.PATHS
    "success_flag": "dante_evidence", # optional — omit for flavour-only beats
    "difficulty": 0.5,                # optional 0..1 (default 0.5)
    "prompt": "Sweep the archive.",   # optional line shown in the minigame
    "title": "",                      # optional heading (defaults to meta title)
}
```

| key            | type   | required | notes |
|----------------|--------|----------|-------|
| `id`           | String | yes | one of `evidence_hunt`, `latte_timing`, `password_deduction`, `watermark_forensics`, `surveillance_dodge`, `boardroom_rebuttal` |
| `success_flag` | String | no  | flag set on success; when it ends in `_evidence` it must match the chapter's `route` |
| `difficulty`   | float  | no  | 0..1 (default 0.5) |
| `prompt`       | String | no  | short instruction text |
| `title`        | String | no  | optional heading override |

**Assignment:** each route's `<route>_evidence` gate is (re)enforceable by its
minigame, so the true ending stays behind it: `boardroom_rebuttal` → `arthur_ch6`,
`evidence_hunt` → `dante_ch3`, `password_deduction` → `dante_ch4`,
`watermark_forensics` → `leo_ch4`, `surveillance_dodge` → `leo_ch6`, and
`latte_timing` → `dante_ch2` (flavour, no flag).

## Backdrop art keys (`bg_scene`)

`office_floor`, `common_office`, `hub_office`, `exec_office`, `exec_lounge`,
`boardroom`, `balcony_night`, `office_lobby_night`, `breakroom`, `archive`,
`it_hub`, `lobby_day`, `branch_office`, `design_studio`, `roof_garden`,
`server_room`, `roof_morning`, `cubicle_empty`, `neutral`

(Any unknown key falls back to `neutral`.)

---

## Flow graph (frozen ids)

```
common_ch1 → common_ch2 → hub
hub → hub_arthur → hub          (sets flag hub_arthur_done, +affection)
hub → hub_dante  → hub
hub → hub_leo    → hub
hub → arthur_ch2 | dante_ch2 | leo_ch2      (commit to a route)

<route>_ch2 → ch3 → ch4 → ch5 → ch6
<route>_ch6 → <route>_end_good   (requires flag <route>_evidence AND char>=12)
<route>_ch6 → <route>_end_true   (requires flag <route>_evidence AND char>=22)
<route>_ch6 → <route>_end_bad    (always available)
all endings → game_end
```

Each route **must** set its `<route>_evidence` flag in a choice during ch4 or
ch5, and grant meaningful affection along the way (roughly +3 to +5 per
positive choice). `MAX_AFFECTION` is 30; good ending ≈ 12+, true ≈ 22+.

Ranks: `Stranger(0) Colleague(5) Friend(10) Crush(16) Partner(24)`.
