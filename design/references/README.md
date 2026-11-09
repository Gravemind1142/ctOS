# References

Screenshots and footage frames from the Watch Dogs games, used to measure the design system against. Organise them however you like. The surfaces in [DESIGN.md → Inspiration](../../DESIGN.md#inspiration) are a good guide to what's worth capturing.

## Capturing

- **Native resolution, no compression.** PNG at 1080p or higher, so pixel sizes and line weights can be measured.
- **Clean frames.** Pause or catch the moment the UI has fully settled. Grab separate frames for mid-animation states.
- **Crops are welcome.** Save a full frame plus a tight crop of the UI element.
- **Motion:** a short clip (`.mp4`/`.webm`) or a numbered frame sequence (`-01`, `-02`, …).

## Index

Cutscene frames (2560×1440 for `52896`, 1920×1080 otherwise), then gameplay HUD frames and assets. They're video frames, so colours are graded and compressed: treat samples as approximate.

| Frame | Shows | Lends us |
| --- | --- | --- |
| `videoframe_39813.png` | Aiden's phone: network list for the Merlaut hotel | List rows with round icon badges and a status dot; micro labels under names (`FREE`, `WPA PASSWORD`); cyan selection ring; white label block with Helvetica (`THE MERLAUT HOTEL`); squarish mono for names and the clock |
| `videoframe_52896.png` | ctOS citizen dossier ("digital profile of YOU") | Cell wordmark (`ctOS`, one letter per box); stacked category tags with black text and hard offset shadow; thin white panel outline on pure black; dense micro form fields; uppercase section headers (`VITALS`) |
| `videoframe_74923.png` | Hacking a smartphone: point cloud with data readout | Inverted-triangle hack marker in cyan; Helvetica title in a white label block (`SMART PHONE`); monospace readout; dashed rules between data rows; teal network lines with nodes |
| `videoframe_113118.png` | Hacker terminal (`root@[none]`) | Window with a light 2–3px frame and tiny uppercase title strip (`NEW WINDOW`); blue-black background; terminal colours (blue prompt, green `bash*`) |
| `videoframe_113384.png` | Call-tracing map dashboard | Tiled grid of framed sub-panels; dotted route arcs; muted grey data fills (landmass); round D-pad control; teal network graph |

**Brand assets.** Official marks, used as-is rather than measured from footage.

| File | Shows | Lends us |
| --- | --- | --- |
| `ctOS.webp` | The official ctOS logo | The brandmark: a wide white block with a small regular `CT` in its bottom-right corner, then a bold white `OS` a little taller than the block (`Brandmark`) |

**Gameplay HUD.** Lower precedence than the cutscenes (see [DESIGN.md → Precedence](../../DESIGN.md#precedence)): it fills gaps, never overrides.

| Frame | Shows | Lends us |
| --- | --- | --- |
| `videoframe_574367.png` | Profiler on a guard, camera view | Profiler content model (name block, fact line, `Age:`/`Occupation:`/`Income:` lines on dark blocks); faint full-screen camera frame with midpoint ticks; centre reticle; key hints (`LT RT ZOOM`, `B EXIT`); segmented battery; mono world marker (`18m Reach`) |
| `videoframe_1034078.png` | Profiler on a flagged person, objective banner, hack prompt | Cyan `Potential Crime` tag and cyan photo frame; checkerboard dither behind the card; objective banner with hexagon icon and bottom rule; `//`-prefixed hint text |
| `videoframe_1049078.png` | Conversation intercept | Speech lines as white blocks with pointer tails; diagonal hatch texture; cyan status tag (`Scanning potential crime location.`); scanlines and chromatic aberration on the camera view |
| `videoframe_2905618.png` | Smartphone app grid | Mono app header (`Smartphone v0.01`); red ctOS logo block; tiles with sentence-case titles; dashed outline on the focused tile; cyan count badges; uppercase key hints |
| `videoframe_3092321.png` | Hacking puzzle | Nodes as dark circles with dashed rings; dotted white idle paths, cyan live path; white diamond goal with lock; solid corner triangles and `+` marks framing the screen |
| `watch-dogs-…-music-selection….webp` | Music player | List rows with title and grey artist line; cyan action buttons; cyan current filter; dashed outline on the focused row; thin white scrollbar |
| `Lib_icons_patched.webp` | WD1 icon atlas | Glyphs inside hexagons, diamonds and circles; category colours; pixel art on DedSec items |

### Sampled colours

Dominant (and, for strokes, brightest) pixels, quantised to steps of 8.

| What | Sample | Token |
| --- | --- | --- |
| Terminal / panel background | `#000810` | `ink900` |
| Dossier background | `#000000` | `black` |
| Map landmass | `#384048` | `ink500` |
| Label block fill | `#e0e0e0` | `gray100` |
| Phone sub-label | `#b8b8c0` | `gray300` |
| Hack-marker triangle | `#58e8f0` | `cyan300` |
| Selection ring | `#a8f0f0` (bloomed) | `cyan300` |
| Dossier cyan tag | `#30a0b8` | `cyan600` |
| Network lines / nodes | `#307070` / `#90f0d8` | `teal700` / `teal300` |
| Dossier red tag | `#c81800` | `red500` |
| Phone secured badge | `#c84068` | `rose500` |
| Terminal `bash*` green | `#50f038` | `green400` |
| Dim terminal green | `#408830` | `green700` |
| Terminal prompt blue | `#3048b0` | `blue400`, lifted to `#5875ec` |
| Terminal magenta | `#400070` | `violet400`, lifted to `#ad66f0` |

**HUD samples** (recorded, not tokens, because the cutscene values take precedence):

| What | Sample |
| --- | --- |
| HUD cyan (tags, filter, live path) | `#40d0e0`–`#30c8f0` |
| Music play button | `#28a0c0` |
| ctOS logo red | `#f04848` |
| Profiler fact text | `#a0a0a0` |
| Music artist line | `#707070` |
| Waypoint hexagon (yellow) | `#a8a038` |
