# Office Hearts

A visual novel otome game set in the corporate office.

**Genre:** Visual Novel / Romance

**Engine:** [Godot Engine](https://godotengine.org/) (Standard build, v4.7.2.stable)

**Status:** 🚧 In development

---

## Development Log

### Week 1 — Godot & Git Setup

**Goal:** Install tools, set up version control, and get a "Hello World" 2D scene running.

**What was done:**
- Installed Godot (Standard build) and created the `Office-Hearts` project.
- Added a `Node2D` root with a `Sprite2D` placeholder and confirmed the scene runs (F5) with no errors.
- Created a private GitHub repository: [`mellovy/Office-Hearts`](https://github.com/mellovy/Office-Hearts).
- Initialized Git (`git init`) and added a Godot-specific `.gitignore` (ignoring `.godot/` and export folders).
- Enabled Git LFS and tracked large binary formats: `*.png`, `*.wav`, `*.jpg`, `*.ogg`, `*.mp3`, `*.ttf`.
- Committed and pushed the initial project setup.

**Screenshots:**

Godot scene running with placeholder sprite:
<img width="1159" height="720" alt="image" src="https://github.com/user-attachments/assets/d7af6b90-3755-45db-98db-f943ca3b2c34" />

Git LFS tracking + commit/push in terminal:
<img width="613" height="876" alt="Screenshot 2026-09-10 214127" src="https://github.com/user-attachments/assets/ab71be84-04ab-4e38-86c3-7d9b812c80ef" />


**Commits:**
- `Add Godot .gitignore`
- `Track large art/audio files with Git LFS`
- `Week 1: project setup + Hello World`

---

### Week 2 — Gameplay Mechanics & Game Feel

**Goal:** Build the core player-controlled mechanic and add a "game feel" / juice element.

Core mechanic: The player walks around the scene using CharacterBody2D, and colliding with an NPC (Area2D) triggers the start of a conversation — the foundation for the game's dialogue/relationship system.

**What was done:**
- Set up custom Input Map actions: move_left, move_right, move_forward, move_back.
- Created a Player scene (CharacterBody2D + Sprite2D + CollisionShape2D) with a script reading input and moving the body via move_and_slide().
- Created an NPC scene (Area2D + Sprite2D + CollisionShape2D) that detects when the player enters its area and triggers a conversation-start event.
- Added a squash-and-stretch juice effect on the player sprite while moving, easing back to normal scale when idle.
- Playtested and adjusted movement speed and sprite scale for a readable top-down feel.
- Committed and pushed a playable build.

**Commits:**
Week 2: core mechanic + juice

---

### Week 3 — GUI, Menus, Save/Load & Story Content

**Goal:** Turn the prototype into a real visual novel framework with a proper interface, menu, saving, and the actual story content.

**What was done:**
- Added a proper GUI for the dialogue/game screen.
- Added a main menu.
- Added save and load slots so progress can be stored and resumed.
- Added the full script.
- Added chapters, which can be checked in the flowchart.

**Commits:**
Week 3: GUI + menus + save/load + story

---

### Week 4 — Art, Animation & AI Assets

**Goal:** Integrate AI-assisted art, add animation polish, and document tool usage.

**What was done:**
- Integrated 19 user-supplied background JPEGs (named by scene key) replacing placeholder art.
- AI-generated sprites processed through Gemini; all portrait assets (`arthur/dante/leo x neutral/happy/blush/sad`) AI-drafted and refined.
- Added tweened animation feedback (button hovers, toast heart pops, fade-in/out, typewriter text).
- Two-font system: `Nunito` (body, weight 400) + `PlayfairDisplay` (titles, weight 700 via `FontVariation`).
- Blush/sad overrides via 16 `expr` triggers on confessions/kisses/lows/bad endings.
- Fullscreen toggle (F11/Alt+Enter) persisted via `user://settings.cfg`.
- Dialogue box optimized: 250px wide, 4 lines fit, 30px body text.
- Main menu gear removed; Settings stays as rectangular button.
- No portraits for unsupplied characters (Sterling/Maya → `""`).
- Affection toast (`+3 ♥ ARTHUR` / `-2` in wine) with chime only on positives.
- BGM crossfade (0.7s) + ducking (~−12 dB under minigames, Music bus untouched).

**AI tool disclaimer:** Background assets and portrait sprites were generated using Google Gemini, with prompts specifying character description, art style (pastel office romance), and pose. The student refined and selected the best outputs; no third-party image models were used.

**Commits:**
Week 4: animation + particles + AI asset

---

### Week 5 — UI/UX/Audio

**Goal:** Polish every UI element, separate audio buses, and add accessibility.

**What was done:**
- HUD with weekly day counter, location top bar, chapter/foldout sidebar, and heart affection indicator (5 hearts max, colour-coded per character).
- Main menu: Start / Continue / Load / Gallery / Settings / Exit — each 360×64 rectangular cream/pill button, 8px spacing; Continue loads most recent save (disabled when no save exists).
- Pause menu retitled "Paused" with a **Settings** button that opens the same grouped settings panel.
- Audio: Master / Music / SFX volume sliders (rectangular cream/pink, 8px spacing) persisted via `user://settings.cfg`; BGM crossfade + ducking under minigames.
- **Accessibility group in Settings**: **Large Text** (increases dialogue body from 30px → ~34-36px, keeps 4 lines fitting in 250px box without clipping) and **Reduce Motion** (disables/shortens decorative motion: confetti drift, button hover pops, affection-toast drift; keeps all functionality; instant/near-instant instead of animated). Both persisted in `user://settings.cfg` and restore on startup.
- Dialogue quick row: Auto / Fast-forward / Skip buttons (Esc forfeit always works).

**Commits:**
Week 5: UI + audio + accessibility

---

### Week 6 — AI & Enemies

**Goal:** Add a proper enemy with a finite state machine and integrate it into the narrative.

**What was done:**
- Created `scripts/minigames/PursuitChase.gd` — a new minigame "After Hours Pursuit" where the player evades Sterling's night guard.
- Enemy FSM with explicit named states (`IDLE`, `PATROL`, `CHASE`, `ATTACK`, `RETURN`) and an enum + `_set_state()` / per-state update structure. Every transition has a clear condition (sight range, lost-sight timer, distance-to-player).
- Detection = sight radius **AND** facing vision cone (`cos` dot test vs `_half_angle`) **AND** line-of-sight (sampled against wall rects). Cone drawn on screen, coloured by state (lavender patrol / hot pink chase+attack), with a live `STATE` readout + alarm ring so the behaviour is readable.
- Player steers with Arrows/WASD or hold-mouse; caught costs a strike; win = reach EXIT, lose = strikes out or timer.
- Code-built `AnimationPlayer` with two named animations: `idle` (bob/breathe) and `move` (fast squash-stretch + pink tint), switched from FSM state (`idle` while IDLE/PATROL; `move` while CHASE/ATTACK/RETURN).
- `CPUParticles2D` `DustBurst` (one-shot, child of enemy holder) fires on the ATTACK lunge; `CPUParticles2D` `SparkleBurst` (gold, child of arena) fires when the player reaches the EXIT.
- Minigame attached to Arthur's Chapter 4 (`arthur_ch4` — The Boardroom Trap) as a Sterling guard encounter. **No `success_flag` key** — this minigame grants no `*_evidence` flag; true-ending gates depend solely on the existing six minigames.

**README note:** Week 6 requires noting what was AI-drafted vs. the student's own work. See the AI disclaimer above under Week 4.

**Commits:**
Week 6: enemy AI (FSM)

---

### Week 7 — Juice, Save/Load & Optimization

**Goal:** Add final polish, verify save/load workflows, and measure one real performance improvement.

**What was done:**
- Save/load with 3 slots (persisted via `user://`); Continue button on main menu resumes the most recent slot; if no save exists the button is visibly disabled (muted) and does nothing.
- Multiple save slots; juice/tweened feedback throughout (button scale pops, heart fills with elastic tween, affection toast drift).
- One measured performance optimization: the `DotLayer` polka-dot background was restructured from ~260 per-frame `draw_circle` calls (≈16k primitives every frame) to a single tiled texture (`_dot_tile`) that costs 1 draw call. Before/after profiler: ~1.8ms → ~0.05ms per frame on the title screen scene.
- No **Continue** button regression: main menu stack (Start / Continue / Load / Gallery / Settings / Exit) unchanged visual language, same rectangular cream/pink buttons, 8px spacing, focus order correct.
- Minigame test harness (`tools/test_minigames.gd`) widened to iterate `MinigameRegistry.ids()` (all 7 ids) so `pursuit_chase` is exercised alongside the existing six.

**Commits:**
Week 7: juice + save/load + optimization

---

### Build Summary

- **30 chapters** (Arthur / Dante / Leo routes, branching choices)
- **9 endings** (true ending requires all 6 minigame evidence flags; 8 others from choice branches)
- **3 romance routes** (Arthur, Dante, Leo)
- **6 minigames** (evidence_hunt, latte_timing, password_deduction, watermark_forensics, surveillance_dodge, pursuit_chase — the new FSM enemy encounter)
- **19 backgrounds** (user-supplied JPEGs named by scene key)
- **Weekly git commits** staged following the 4-coursework themes (Art/Animation, UI/UX/Audio, AI/Enemies, Juice/Save-Load/Optimization)

### AI Tools Used Per Week
- **Week 4**: Google Gemini for background asset integration and portrait sprite generation (prompts specified character description, pastel office romance style, pose). Student refined and selected best outputs.
- **Week 6**: Google Gemini referenced for enemy behaviour concept outlines; FSM design and code are the student's own work.
- Other weeks: no AI image tools used; all code, design, and content authored independently.

### Playtest Notes
- Week 5: 5-minute peer playtest — gameplay reported as **straightforward with no friction found**. No change was required, but the accessibility group (Large Text + Reduce Motion) was verified to apply live and persist between launches.
- Week 7: 5-minute peer playtest — save/load workflow confirmed working; Continue button behaviour tested (enabled with a save, muted without); performance optimization confirmed (tiled dot background reduces per-frame cost by ~97%). No regressions.