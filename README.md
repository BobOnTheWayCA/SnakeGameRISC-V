# RISC-V Snake Game

A simple snake game for **RARS** (RISC-V Assembler and Runtime Simulator). It demonstrates keyboard and timer **interrupts**, memory-mapped I/O display, and an **LCG** pseudo-random number generator.

> This project depends on RARS **Keyboard & Display MMIO Simulator** and **Timer Tool**. Other simulators (Venus/Spike/QEMU) do not provide these peripherals without porting.

---

## Repository Layout


Key labels/functions:
- `snakeGame`: Level selection, initialization, game loop.
- `handler`: Interrupt handler (keyboard + timer), register save/restore via `uscratch` and `iTrapData`, returns with `uret`.
- `random`: Linear Congruential Generator returning `0..8` (add 1 when used as row/col).
- `printAllWalls`, `printStr`, `printChar`, `waitForDisplayReady`: MMIO helpers.

LCG globals in `common.s`:



---

## How to Run (macOS / Windows / Linux)

**Requirements**
- Java 17 (Temurin/OpenJDK recommended)
- RARS 1.6 (or the course-provided build)

**Steps**
1. Open **RARS** → **File → Open…** and select `snake.s`  
2. Click **Assemble** (F3).
3. Open **Tools → Keyboard and Display MMIO Simulator** for game display
   - Click **Connect To Program**  
   - Enable **DAD**  
   - Set **Delay length** to a small value (e.g., **5** instruction executions)
4. Open **Tools → Timer** to start the game
   - Click **Connect To Program**, then **Play**
5. In the main window, set the run-speed slider **“Run Speed at Max”**.
6. Click **Go** (F5). Choose a level with **`1`/`2`/`3`**, then control the snake with **lowercase** `w a s d`.

**After re-assemble or any Reset**: reconnect **both** tools and press **Play** on the Timer before running again.

---

## Game Rules

- **Levels and time**

| Level | Initial Time (s) | Bonus per Apple (s) |
|------:|------------------:|--------------------:|
| 1     | 120               | 8                   |
| 2     | 30                | 5                   |
| 3     | 15                | 3                   |

- Map: 11 rows × 21 columns, `#` forms the walls.  
- Snake: head `@`, body `***` (fixed length). Starts near center moving right; advances **every 1 s**.  
- Eating an apple increases score and adds the level’s bonus time (accounting for the 1 s spent moving).  
- Hitting a wall or the timer reaching 0 ends the game.  
- Only **lowercase** `w a s d` are valid commands.

---

## Interrupts and MMIO (Quick Reference)

- Enable interrupts:
  - `ustatus` bit 0 = 1
  - `uie` bit 4 (timer) and bit 8 (external/keyboard) = 1
  - `utvec` = address of `handler`
- Keyboard control register: `0xFFFF0000`  
  - Set **bit 1** (write value **2**) to allow the next keyboard interrupt.
- Display:
  - Control at `0xFFFF0008` (bit 0 = ready)  
  - Data at `0xFFFF000C` (bell `0x07` + row in bits 8–19 + col in bits 20–31)
- Timer:
  - `time` (RO, milliseconds since start) and `timecmp` (interrupt when `time >= timecmp`)  
  - After each timer interrupt, program the **next** `timecmp` (e.g., `time + 1000`).

---

## License and Credits

- Course starter material: **CMPUT 229 Public Materials License v1.0**  
- University of Alberta, Department of Computing Science  
- Student work by **Shijie (Bob) Bu**


<div align="right">

<img src="UofAlbertalogo.svg" alt="University of Alberta Logo" width="330px" style="vertical-align: middle;">
</p>
<p style="margin: 0; font-size: 14px; font-weight: bold;">
Department of Computing Science
</p>
<p style="margin: 0; font-size: 14px; font-weight: bold;">
November 2022, Edmonton, AB, Canada
</p>

</div>
