# Super Mario Engine (16-Bit x86 Assembly)

[![Architecture](https://img.shields.io/badge/Architecture-16--bit%20x86%20Real%20Mode-blue.svg)](#technical-architecture--memory-design)
[![Assembler](https://img.shields.io/badge/Assembler-NASM-orange.svg)](#build--execution)
[![Emulator](https://img.shields.io/badge/Emulator-DOSBox%200.74--3%2B-green.svg)](#build--execution)
[![Course](https://img.shields.io/badge/Course-EL2003%20COAL%20(Fall%202026)-lightgrey.svg)](#project-overview)

A complete, retro side-scrolling platformer built from scratch in **16-bit x86 Assembly language** (NASM) for MS-DOS / DOSBox—without external libraries, C runtimes, or pre-built game engines. Every subsystem, including VGA Mode `13h` double-buffered graphics, custom `INT 09h` / `INT 08h` hardware interrupt handlers, 8.8 fixed-point kinematics, AABB collision detection, enemy AI, PC speaker audio, and a jump-table state machine, is implemented directly at the hardware level.

---

## Project Overview

* **Course:** EL2003 – Computer Organization and Assembly Language (BCS-3B, Fall 2026)
* **Institution:** National University of Computer & Emerging Sciences (FAST-NUCES), Chiniot-Faisalabad Campus
* **Lab Instructor:** `Nayab Ayesha`
* **Repository:** `COAL_Project_BCS_3B_25F-0510_25F-0570_25F-0685`

---

## Team Members & Module Distribution

All three members contributed across design, implementation, debugging, and documentation, with `data.asm` serving as the shared asset and game-table module:

| Member Name | Roll Number | Owned Source Files | Assigned Modules (Manual Sec. 6) | Core Responsibilities |
| :--- | :--- | :--- | :--- | :--- |
| **Ahmad Faraz** | `25F-0510` | `physics.asm`, `player.asm`, `enemies.asm`, `data.asm` *(level/enemy tables)* | **Modules 6, 9, 10, 11, 12** | 8.8 fixed-point player physics, variable jump height, two-axis tile collision, one-way scrolling camera, Goomba & Koopa Troopa/shell AI, stomp chains, and interactive blocks/power-ups. |
| **Ubaid Afzal** | `25F-0570` | `mario.asm`, `main.asm`, `isr.asm`, `life.asm`, `states.asm`, `audio.asm`, `data.asm` *(state/audio data)* | **Modules 1, 7, 8, 14, 15 + Bonus Audio** | `.COM` program entry/exit skeleton, `INT 09h` multi-key keyboard handler, `INT 08h`/`1Ch` timer hook & 300s clock, jump-table state machine, UI screens, level/game resets, and PC speaker sound effects. |
| **Hashim Nagi** | `25F-0685` | `video.asm`, `buffer.asm`, `draw.asm`, `text.asm`, `sprites.asm`, `hud.asm`, `data.asm` *(sprites/fonts)* | **Modules 2, 3, 4, 5, 13** | VGA Mode `13h` setup, 64 KB off-screen frame buffer (`REP STOSW`/`REP MOVSW`), $60\times12$ tile map rendering, 4-edge sprite clipping/mirroring/blinking, custom bitmap font renderer, and 32-bit HUD updates. |

---

## Repository Structure

```text
COAL_Project_BCS_3B_25F-0510_25F-0570_25F-0685/
├── src/
│   ├── mario.asm          # Top-level entry point (ORG 100h) and module includes
│   ├── main.asm           # Main game loop, frame pacing, and clean DOS exit routine
│   ├── data.asm           # Constants, sprite bitmaps, bitmap font, level maps, and entity tables
│   ├── video.asm          # VGA Mode 13h (320x200x256) initialization and text-mode restoration
│   ├── buffer.asm         # Off-screen frame buffer segment management, clear, and VGA blit
│   ├── draw.asm           # Tile rendering, scrolling viewport draw, and map coordinate lookup
│   ├── sprites.asm        # 16x16 & 16x32 sprite blitter with transparency, mirroring, clipping & blink
│   ├── text.asm           # Custom bitmap character and string rendering procedures
│   ├── hud.asm            # Top-row HUD renderer (6-digit score, coins, world, time, lives, hearts)
│   ├── isr.asm            # Custom INT 09h keyboard ISR and INT 08h/1Ch timer ISR + vector restore
│   ├── physics.asm        # 8.8 fixed-point velocity, gravity, friction, and axis-separated tile collision
│   ├── player.asm         # Mario state updates, Small/Super form transitions, block hits & flagpole logic
│   ├── enemies.asm        # Goomba, Koopa Troopa, sliding shell, and mushroom entity update loops
│   ├── states.asm         # Jump-table state machine and Title, Pause, Level Complete & Game Over screens
│   ├── life.asm           # Death sequence animation, life deduction, Life-Lost screen, and map/game resets
│   └── audio.asm          # PC speaker sound effects (jumps, coins, stomps, power-ups, win/death cues)
├── MARIO.COM              # Pre-assembled 16-bit DOS executable binary
├── build.bat              # Automated NASM build script
└── README.md              # Project documentation
```

---

## Build & Execution

### Prerequisites
* **Assembler:** Netwide Assembler (**NASM**) for 16-bit x86 (`-f bin`)
* **Emulator:** **DOSBox v0.74-3** or later

### Building from Source
Run the provided batch script inside DOSBox or a Windows command prompt with NASM in your `PATH`:
```bat
build.bat
```
Or assemble manually using NASM:
```bat
nasm -f bin src/mario.asm -o MARIO.COM
```

### Running in DOSBox
1. Launch **DOSBox v0.74-3** (or later).
2. Mount your project directory as drive `C:` and run `MARIO.COM`:
   ```dos
   mount c C:\path\to\COAL_Project_BCS_3B_25F-0510_25F-0570_25F-0685
   c:
   MARIO.COM
   ```
3. To exit cleanly back to the DOS prompt with all hardware interrupt vectors restored, select **EXIT** on the Title screen or press **Esc** on the Title screen.

---

## Controls & Debug Keys

### Player Controls (Hardware Scan Codes via `INT 09h`)

| Key | Make Scan Code | Break Scan Code | Action |
| :--- | :---: | :---: | :--- |
| **Left Arrow** | `E0h, 4Bh` | `E0h, CBh` | Walk / accelerate left (mirrors sprite left) |
| **Right Arrow** | `E0h, 4Dh` | `E0h, CDh` | Walk / accelerate right (mirrors sprite right) |
| **Up / Down Arrows** | `E0h, 48h` / `50h` | `E0h, C8h` / `D0h` | Navigate menu selection on the Title screen |
| **Space Bar** | `39h` | `B9h` | Jump (ground only; hold for higher jump, release early for short hop) |
| **Left Shift** | `2Ah` | `AAh` | Hold while moving horizontally to sprint at run speed |
| **P** | `19h` | `99h` | Toggle Pause / Resume during gameplay |
| **Enter** | `1Ch` | `9Ch` | Confirm selection on Title, Level Complete, and Game Over screens |
| **Esc** | `01h` | `81h` | Return to Title screen from gameplay/pause, or exit to DOS from Title screen |


---

## Technical Architecture & Memory Design

### 1. `.COM` Program Structure (`ORG 100h`)
The executable is built as a flat 16-bit DOS `.COM` binary (`ORG 100h`), sharing a single 64 KB segment (`CS = DS = SS`) for program instructions, static game data, and the runtime stack. All procedures adhere to stack-based parameter passing (`[BP + offset]`) and preserve all non-return registers across calls.

### 2. Off-Screen Frame Buffer Allocation & Flicker-Free Rendering
Because VGA Mode `13h` (`320 × 200`, 256 colors at segment `0A000h`) requires **64,000 bytes** (`0FA00h` bytes) per frame, storing a full back-buffer inside the `.COM` program's primary 64 KB segment would exhaust available code/data space.
* **Segment Allocation:** A separate 64 KB segment outside the `.COM` code/data segment is reserved for the off-screen frame buffer *(via DOS `INT 21h` memory block resize/allocation `AH=4Ah`/`48h` or the free paragraph segment immediately above the `.COM` program—verify exact method in `buffer.asm`)*.
* **Block Blitting:** At the start of each frame, `buffer.asm` clears the entire 64,000-byte back-buffer using `REP STOSW` (`32,000` words). All background sky, visible map tiles, items, enemies, Mario, and the HUD are rendered off-screen. Once per timer tick, the completed frame is copied into `0A000h` in a single `REP MOVSW` block transfer, eliminating screen tearing and flicker.

### 3. Dual Level Map Architecture
Two copies of the $60 \times 12$ byte level tile grid (`720` bytes each) are maintained in `data.asm`:
* **Original Map (Immutable):** Stores the pristine initial layout of bricks, `?` blocks, and floating coins.
* **Working Map (Mutable):** Modified dynamically during gameplay when Mario collects coins (`tile -> 0`), bumps `?` blocks (`tile -> empty block`), or shatters bricks as Super Mario (`tile -> 0`).
* **Instant Reset:** Whenever Mario loses a life or starts a new game, `ResetLevel` restores the working map from the original map in one `REP MOVSB` operation.

### 4. Fixed-Point Physics & 32-Bit Scoring
* **8.8 Fixed-Point Kinematics:** World coordinates (`world_x`, `world_y`) and velocities (`vx`, `vy`) are stored as signed 16-bit values where the high byte represents whole pixels and the low byte represents $1/256$ sub-pixel fractions. Rendering and camera routines extract only the integer pixel byte to prevent sub-pixel jitter.
* **32-Bit Score Arithmetic:** Because the score supports up to `999,999` (exceeding 16-bit unsigned `65,535`), the score is stored as a 32-bit double-word (`low word` + `high word`) and updated via `ADD` / `ADC` instructions before base-10 stack division for HUD display.

### 5. Custom Hardware Interrupt Handlers (`INT 09h` & `INT 08h`/`1Ch`)
* **Keyboard Handler (`INT 09h`):** Saves the original BIOS vector (`INT 21h, AH=35h`), intercepts hardware scan codes from I/O port `60h`, filters `E0h` extended prefixes, updates a 128-byte simultaneous key-state array (`1 = pressed`, `0 = released`), issues End-of-Interrupt (`OUT 20h, 20h`), and terminates with `IRET`.
* **Timer Handler (`INT 08h` / `INT 1Ch`):** Increments a global frame tick counter and chains to the original BIOS timer ISR so the 18.2 Hz / ~30 FPS game loop pacing and 300-second countdown run deterministically regardless of DOSBox CPU cycle speed.
* **Safe Vector Restoration:** Every exit path invokes the cleanup routine (`INT 21h, AH=25h`) to restore the original keyboard and timer interrupt vectors and return the display to `80×25` color text mode (`INT 10h, AX=0003h`) before exiting via `INT 21h, AH=4Ch`.

---

## Game States & State Machine

Game flow is governed by a central `game_state` byte variable dispatched every frame via an indexed jump table in `states.asm`:

| State | Description & Active Behavior | Transition Conditions |
| :--- | :--- | :--- |
| **`TITLE`** | Displays the bordered Title screen with game title, team credits, and menu selector (`START GAME` / `EXIT`). | `Up`/`Down` moves cursor; `Enter` on `START GAME` $\rightarrow$ **`PLAYING`**; `Enter` on `EXIT` or `Esc` $\rightarrow$ **`EXIT`**. |
| **`PLAYING`** | Executes the 10-step per-frame pipeline: syncs to timer tick, reads key table, updates Mario physics & two-axis tile collisions, updates enemies/shells/mushrooms, resolves entity collisions & scoring, updates 1-second timer & invulnerability blink, updates camera, and blits frame buffer + HUD. | `P` $\rightarrow$ **`PAUSED`**; `Esc` $\rightarrow$ **`TITLE`**; HP reaches `0`, pit fall ($y \ge 192$), or time $= 0$ $\rightarrow$ **`DYING`**; Flagpole touched $\rightarrow$ **`WIN SEQUENCE`**. |
| **`PAUSED`** | Freezes physics, enemy updates, and the countdown timer while keeping the current gameplay frame visible with a centered `PAUSED` overlay box. | `P` $\rightarrow$ **`PLAYING`**; `Esc` $\rightarrow$ **`TITLE`**. |
| **`DYING`** | Freezes enemies, timer, and player input. Plays Mario's upward death hop (~48 px) and gravity fall off-screen (skips upward hop on pit deaths) over ~1.5 seconds. | Animation finishes with `lives > 0` $\rightarrow$ **`LIFE LOST`**; Animation finishes with `lives == 0` $\rightarrow$ **`GAME OVER`**. |
| **`LIFE LOST`** | Displays a black status screen showing `WORLD 1-1`, Mario's sprite, and remaining lives for ~2 seconds, then calls `ResetLevel` (preserving score and coins, resetting timer to `300`, form to Small Mario, map, enemies, and camera to `0`). | ~2-second timer expires $\rightarrow$ **`PLAYING`**. |
| **`WIN SEQUENCE`** | Freezes timer and controls, awards flagpole height points (`100` to `5000`), slides Mario down the flagpole (~1 s), and walks him into the castle (~1 s). | Win animation completes $\rightarrow$ **`LEVEL COMPLETE`**. |
| **`LEVEL COMPLETE`** | Displays final statistics, multiplies remaining seconds by `50` (`time_left × 50`), adds the time bonus to the score, and shows the final score. | `Enter` $\rightarrow$ **`TITLE`** (subsequent start triggers `NewGame`). |
| **`GAME OVER`** | Displays the `GAME OVER` banner alongside final score, coins collected, and remaining time. | `Enter` $\rightarrow$ **`TITLE`** (subsequent start triggers `NewGame`). |
| **`EXIT`** | Restores original `INT 09h` and `INT 08h`/`1Ch` vectors, restores VGA text mode (`03h`), and returns cleanly to DOS (`INT 21h, AH=4Ch`). | Terminates process cleanly to DOS prompt. |

---

## Deviations & Known Limitations

### Deviations from Manual
* **Modular Multi-File Source Layout:** Instead of placing all code into a single monolithic `mario.asm` file, the source is cleanly partitioned across 16 specialized `.asm` modules (`video.asm`, `buffer.asm`, `physics.asm`, `isr.asm`, `states.asm`, etc.) included into `mario.asm` to improve team collaboration, maintainability, and merge cleanliness on GitHub.

### Known Limitations
1. **Single-Channel PC Speaker Audio:** Because DOSBox PC speaker hardware supports only one square-wave frequency at a time, rapid consecutive sound events overwrite any currently playing tone rather than mixing polyphonically.
2. **Fixed Single-Screen Vertical Viewport:** Consistent with the $60 \times 12$ tile specification, camera scrolling operates strictly along the horizontal X-axis without vertical camera panning.
3. **Axis-Aligned Bounding Box (AABB) Hitboxes:** Entity-to-entity and shell collisions use rectangular bounding boxes (`12×16` / `12×32` for Mario, `16×16` for enemies) rather than pixel-accurate masks, which can occasionally register corner grazes at high fall speeds.
4. **Hardcoded Level Data:** Level geometry and enemy spawn coordinates reside in static `.COM` data tables (`data.asm`) rather than loading external level files from disk via DOS file I/O (`INT 21h`).

---

## License & Academic Integrity

Developed exclusively by **Ahmad Faraz (`25F-0510`)**, **Ubaid Afzal (`25F-0570`)**, and **Hashim Nagi (`25F-0685`)** for **EL2003 – Computer Organization and Assembly Language** at FAST-NUCES Chiniot-Faisalabad Campus.
