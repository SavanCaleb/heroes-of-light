# Heroes of Light — Godot version

The next version of Heroes of Light, rebuilt in the free [Godot 4](https://godotengine.org) game engine for richer animation and graphics, and for real iPhone and Android apps later. The web version in the folder above stays playable while this one grows.

## Open it

1. Install Godot 4.7 (on Windows: `winget install GodotEngine.GodotEngine`).
2. Open Godot, click **Import**, and pick `godot/project.godot`.
3. Press **F5** to play.

Controls: arrow keys or A/D to move, Space/W/Up to jump, J/X/F to attack (press it three times for punch, punch, kick).

## What's here so far

- **Jointed cartoon characters** (`scripts/rig.gd`, `scripts/part.gd`): every hero is built from separate parts (head, hair, torso, arms, legs, shoes) that bend at the joints. Poses blend smoothly, and the body squashes and stretches on jumps and landings. Characters blink, breathe and open their mouths when they fight, and hair, Mango the monkey and Sarah's butterfly all move.
- **The Garden of Hope** (`scripts/level.gd`, `scripts/backdrop.gd`): sky with turning sun rays, drifting clouds, two layers of hills with trees, a spinning windmill, a cottage with chimney smoke, foreground bushes, floating pollen and falling petals.
- **Fighting** (`scripts/fighter.gd`): punch-punch-kick combo, air kick, double jump (Alisa, Savan), floating (Sarah), shadow minions that chase and punch.
- **Game feel** (`scripts/main.gd`, `scripts/fx.gd`): hit-stop freezes, screen shake, sparks, damage numbers, a combo counter, doves when shadows are freed, spinning coins, a candle checkpoint and the glowing cross at the end.

## Test without playing

`-- demo` makes the hero play by itself, and `-- hero=N` picks a hero (0 Alisa … 7 Savan). Godot can record frames to check the look:

```
godot --path godot --write-movie frames/run/f.png --fixed-fps 30 --quit-after 300 -- demo hero=3
```

`tests/lineup.tscn` shows all eight heroes side by side in different poses.
