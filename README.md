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
- Installed Godot (Standard build) and created the `Soul-on-a-String` project.
- Added a `Node2D` root with a `Sprite2D` placeholder and confirmed the scene runs (F5) with no errors.
- Created a private GitHub repository: [`mellovy/Soul-on-a-String`](https://github.com/mellovy/Soul-on-a-String).
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

## Built With
- [Godot Engine](https://godotengine.org/)
- Git + Git LFS

---

### Week 2 — Gameplay Mechanics & Game Feel

**Goal:** Build the core player-controlled mechanic and add a "game feel" / juice element.

Core mechanic: The player walks around the scene using CharacterBody2D, and colliding with an NPC (Area2D) triggers the start of a conversation — the foundation for the game's dialogue/relationship system.

**What was done:**

Set up custom Input Map actions: move_left, move_right, move_forward, move_back.
Created a Player scene (CharacterBody2D + Sprite2D + CollisionShape2D) with a script reading input and moving the body via move_and_slide().
Created an NPC scene (Area2D + Sprite2D + CollisionShape2D) that detects when the player enters its area and triggers a conversation-start event.
Added a squash-and-stretch juice effect on the player sprite while moving, easing back to normal scale when idle.
Playtested and adjusted movement speed and sprite scale for a readable top-down feel.
Committed and pushed a playable build.

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
Week 3: GUI, menu, save/load, script + chapters

---
