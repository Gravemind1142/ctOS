# ctOS Design System

The single reference for how ctOS looks and moves. Every themed surface (Quickshell bar and greeter, terminal, compositor, GTK/Qt, CLI tools) follows it.

> **Status:** foundations defined (colour, type, spacing, shape, motion). QML literals are still being migrated onto tokens. See [TODO.md](TODO.md#design-system).

## How it works

```
design/tokens.json ──► design/build.py ──┬─► common/Theme.qml          (QML)
                                          └─► design/templates/<path>.tmpl ─► <path>   (everything else)
```

- **`design/tokens.json`** is the single source of truth. Change values here, never in generated files.
- **`common/Theme.qml`** is generated. QML components use `Theme.<token>`.
- **`design/templates/`** mirrors the repo layout. `design/templates/extras/.config/kitty/ctos.conf.tmpl` renders to `extras/.config/kitty/ctos.conf`.
- Generated files are committed, so installing doesn't need Python.

```sh
python3 design/build.py          # regenerate
python3 design/build.py --check  # fail if anything is stale
```

### Token format

Top-level keys are **sections** (they become `// SECTION` blocks in `Theme.qml`). Token names are camelCase and **globally unique**, because they become flat `Theme.<name>` properties.

```jsonc
"colors": {
    "background": "{ink900}",                 // reference to another token
    "error": "#f5412a",                       // literal; type is inferred (color/int/real/string/bool)
    "scrim": "#000000cc",                     // 8-digit colors use CSS order #RRGGBBAA (converted for QML)
    "focus": {                                // long form
        "value": "{cyan300}",
        "type": "color",                      // optional, overrides inference
        "mutable": true,                      // optional, writable instead of readonly
        "description": "Shown as a comment"   // optional
    },
    "ctosGray": {
        "value": "{gray200}",
        "deprecated": "frame"                 // optional: what to use instead
    }
}
```

A **deprecated** token keeps working, is marked in `Theme.qml`, and the build prints a warning for every QML use of it. Remove it once no uses remain.

Easings use `"type": "easing"` with a Qt curve name (`"OutCubic"`). QML gets `Easing.OutCubic`, templates get a cubic-bezier.

Placeholders in templates: `{{token}}`, or `{{token|bare}}` (no `#`) / `{{token|rgb}}` (`r, g, b`) for colors, `{{token|bezier}}` (`x1, y1, x2, y2`, the default) / `{{token|name}}` for easings, and `{{token|ds}}` (milliseconds → deciseconds, for Hyprland animation speeds) for durations.

### Token tiers

1. **Primitives:** raw values (`ink900`, `green400`). Components never use these directly.
2. **Semantic:** what a value is *for* (`background`, `textPrimary`, `success`). Components use these.

## Inspiration

ctOS is a desktop built as if Blume shipped its Central Operating System to your machine. The fictional software in **Watch Dogs (Ubisoft, 2014)** is the primary source. When a design question comes up, the first thing to ask is how ctOS would show it.

Screenshots live in [`design/references/`](design/references/README.md); what each frame shows is indexed there. Sourced findings from articles and the wiki are in [`design/research.md`](design/research.md).

### Key findings

- **ctOS is a utility, branded like one.** Its typeface is Helvetica, and its identity was modelled on the NYC Transit Authority Graphics Standards Manual. Sterile, ubiquitous, civic.
- **There are two voices.** The *system* speaks in clean neo-grotesk type. *Hacking* speaks in barebones type, 8-bit/DOS fonts and early cell-phone icons. The contrast between them is intentional. We split them by audience: Helvetica is public, monospace is insider (see Principle 1).
- **The world is the interface.** Indicators sit on the thing they control.
- **The WD1 profiler is the template:** name, labelled facts (occupation, income), one highlighted line. Terse and mostly monochrome; a flagged person gets a cyan tag and photo frame. WD2's colourful Material redesign is the direction not to follow.
- **Motion:** transitions instead of cuts. Hacking is shown as glitchy network lines, with dither, point clouds and tracking-UI "machine thought". The signature move is clean ctOS eroding into the hacker underworld.
- **Blume's voice:** short declarative fragments with full stops and triads ("Security. Civility. Connectivity."). Benevolent on the surface, authoritarian underneath.
- **DedSec defaces ctOS.** Black takeover, ASCII-art logo, content layered over ctOS surfaces.
- **Outlines, not fills.** Panels are black with a thin light outline. Solid fill is kept for *labels*: an inverted white block with black type, or a coloured category tag. _(observed, see [references](design/references/README.md))_
- **Colour is categorical.** Almost everything is black, white and grey. Cyan, red and green each mean one thing and appear in small doses.

### Precedence

When sources disagree, the higher one wins:

1. **Explicit project decisions,** recorded in this document. Where one departs from the game (the insider monospace voice, dark only), it says so.
2. **WD1 cutscene screens:** Aiden's phone, the terminals, the map dashboard.
3. **WD1 cinematic graphics:** the dossier, the point-cloud hack sequences.
4. **WD1 gameplay HUD:** profiler, phone menus, hacking puzzle, camera view. Fills gaps the cutscenes leave, never overrides them.
5. **Written sources:** articles and the wiki.
6. **WD2 and Legion:** only where WD1 says nothing.

**Practicality** can override 2–6 for a specific rule, and the rule says so where it does.

Known conflicts settled this way: the HUD sets content in sentence case, shows focus as a dashed outline, marks selection in cyan, puts text on translucent blocks and has a red ctOS logo. The cutscenes' uppercase labels, cyan ring and opaque panels win, and the brandmark is the official white ctOS lockup (`design/references/ctOS.webp`), not the HUD's red one.

### Primary: ctOS in Watch Dogs (2014)

The interfaces in the game, and what each one lends the desktop:

| In-game surface | What to study | Desktop counterpart |
| --- | --- | --- |
| **Profiler** (scanning a pedestrian) | Compact dossier: name, then terse uppercase labels with values (occupation, income), one "fact" line. Dense, factual, no decoration. | Greeter identity card, notifications, user/system info |
| **Hack prompts** (icons placed in the world) | Small square icons, one key or button hint, a thin progress fill while the action runs. | OSD (volume and brightness), keybind hints, tray |
| **Camera hacking view** | CCTV overlay with corner brackets, timestamp and coordinates in the margins, a framed viewport. | Lock screen, screenshot tool, frames around panels |
| **Aiden's smartphone** | Short vertical lists, one item highlighted, icon grid of apps, a minimal media player. | Launcher, power menu, media module, network popup |
| **Hacking puzzle** (signal through nodes) | Nodes joined by thin lines, signal lighting up as it passes. | Network/connection visuals, progress, loading |
| **Boot, loading and blackout screens** | ctOS mark, scrolling system text, glitch and dropout during transitions. | Greeter splash, Plymouth/GRUB, session start |
| **Blume corporate identity** | Sterile, confident, monochrome branding, the system's own voice. | Overall tone, wordmarks, copy |

### Secondary: DedSec (Watch Dogs 2)

DedSec's look is hacker-punk: glitch, pixel art, neon. In ctOS it's the **intruder**, not the system's own voice. Use it sparingly: for errors, alerts, "compromised" states and easter eggs (the fastfetch DedSec logo already does this). If DedSec styling spreads beyond those moments, the desktop stops reading as ctOS.

### Tertiary

- **Watch Dogs: Legion** (ctOS 3.0, London). A later, flatter take on the same system. Good for density and layout ideas, not for its palette.
- **Real-world surveillance and industrial interfaces:** CCTV on-screen displays, security-operations dashboards, control-room HMIs. They show how this look holds up when people stare at it for hours.
- **Terminal UIs** (btop, htop, nmtui). The monospace grid that ctOS already resembles.

### Adapting it to a desktop

Game UI is shown in short bursts on top of a 3D world. A desktop is looked at all day. So take the visual language, but adjust it:

- **Reading comes before spectacle.** Scan lines, glitch and typewriter effects belong in *transitions* (boot, unlock, hacks finishing), never in the resting state.
- **The resting state is calm.** No looping animation. Values change in place.
- **Surfaces are opaque or nearly so.** The game overlays a moving world, but a desktop overlays your work.
- **It must work at any scale and on multiple monitors.** The corner and frame motifs have to stay crisp at fractional scaling.
- **Faithful to the source.** This is a personal rice. Game marks, logos and recreated assets are fair game, and accuracy to ctOS wins over invention.

## Principles

### 1. You are an insider

The user is someone with **insider access to ctOS**. The desktop is what the system looks like from the inside: the operator's console, not the citizen's kiosk.

ctOS speaks in two voices, and which one to use depends on **who is looking**:

| Voice | Audience | Typeface | Character |
| --- | --- | --- | --- |
| **Public** | Citizens, passers-by, the outside world | Helvetica (neo-grotesk) | Sterile, civic, branded. The face Blume shows the city |
| **Insider** | Operators, engineers, hackers | Monospace | Raw, dense, functional. The system with the branding stripped away |

Insider is the default, because that's who uses this desktop. Public appears only where ctOS presents itself to someone who might be outside: branding, and any surface that could be seen before access is granted.

| Surface | Voice |
| --- | --- |
| Boot (GRUB, Plymouth), ctOS/Blume wordmarks | Public |
| Greeter and lock screen | Public, except technical readouts (the corner terminal, device IDs, status lines), which stay insider |
| Bar, launcher, notifications, OSD, popups, power menu, terminal | Insider |
| Third-party apps for developers and sysadmins (terminals, editors, system monitors, network/disk/audio tools) | Insider |
| All other third-party apps | Public |

For GTK/Qt apps, the public face is the global default, and insider apps are opted in individually. The two faces differ **only in typeface**: colours and controls are identical.

**Classifying an app:** insider if its desktop entry's `Categories` contains `Development`, `TerminalEmulator` or `System`, **unless** it also contains `Settings` (GNOME's date, region and user panels are tagged `System` but are consumer settings). Then apply overrides:

| App | Voice | Why |
| --- | --- | --- |
| Nautilus | Public | General-purpose file manager (`Utility;FileManager`) |
| nm-connection-editor, GNOME Disks, pavucontrol | Insider | Network, disk and audio tools, tagged `Settings`/`Utility`/`AudioVideo` |
| GNOME Settings and its panels | Public | Consumer settings |

### 2. Speak like ctOS

UI copy uses ctOS's vocabulary and Blume's style (see [research](design/research.md#blume-voice-and-brand)):
- **Labels are uppercase,** like the dossier's tags (`UTILITY RECORDS`) and the phone's sub-labels (`FREE`, `WPA PASSWORD`). Names and values keep their natural case.
- **Status lines use system language:** `LINK ESTABLISHED`, `SCAN COMPLETE`, `ACCESS GRANTED`. The desktop is infrastructure: systems, nodes, links.
- **Public-facing copy** is short declarative fragments with full stops ("Simple. Secure. Connected.").
- **Brand casing is always `ctOS`** (lowercase "ct").

### 3. Dark only

ctOS has a single dark theme, for practicality. There is no light mode. The public voice is expressed through type and copy, not by switching to Blume's white print branding.

### 4. DedSec is the intruder

DedSec styling (glitch, ASCII art, takeover) means the system itself is compromised, or you've deliberately invited it in. Ordinary errors stay in ctOS's own voice. See [DedSec](#dedsec) for the three levels.

### 5. Monochrome first, colour means something

The screen is black, white and grey. Colour is a **signal**, never decoration, and each hue has one job (see [Color](#color)). If removing a colour loses no meaning, remove it. A surface at rest should have at most one accent on it.

### 6. Dense, but ruled

ctOS packs a lot of data into small spaces (the dossier, the bank-account dump) and keeps it legible with structure: uppercase labels, aligned columns, dashed rules, framed panels. Prefer more information in a strict grid over less information with generous whitespace. Never let two blocks of data touch without a rule, a gap or a frame between them.

### 7. Still at rest, decisive in motion

Nothing loops while you aren't interacting (see [Motion](#motion)). When something does move it's quick and committed: no bounces, no springs, no slow fades. Values change in place.

## Color

Dark only (see [Principle 3](#3-dark-only)). Values are sampled from the [reference frames](design/references/README.md) and lifted only where a token has to be readable as text. Primitives are named by hue and lightness (`ink900`, `cyan300`); components use only the semantic roles below.

### Neutrals

The cinematics grade everything slightly cool, so the darks have a faint blue cast (`ink`). Light greys are neutral.

| Role | Token | Value | Contrast on `background` | Use |
| --- | --- | --- | --- | --- |
| Background | `background` | `#05080b` | — | Screens, the bar, the lock screen |
| Surface | `surface` | `#0b0f13` | — | A panel on the background |
| Raised | `backgroundBright` | `#151a20` | — | Hover rows, input wells |
| Frame | `frame` / `ctosGray` | `#d9d9d9` | 14.2 | Panel and window outlines, corner brackets, wordmark blocks |
| Subtle frame | `frameSubtle` | `#262c33` | 1.4 | Inner dividers, table rules. Decorative only |
| Muted fill | `fillMuted` | `#3a424b` | 2.0 | Meter tracks, inactive data shapes |
| Text | `textPrimary` | `#ffffff` | 20.1 | Values, titles |
| Text, dim | `textPrimaryDim` | `#cacaca` | 12.3 | Field labels |
| Text, dimmer | `textPrimaryDimmer` | `#b8b8bf` | 10.2 | Micro labels under a value |
| Secondary | `textSecondary` | `#7a7a7a` | 4.7 | Inactive values, hints |
| Disabled | `textDisabled` | `#4a4f55` | 2.4 | Disabled controls only |

### Signals

Each hue has **one meaning**. Don't borrow one for another job because it looks nice.

| Hue | Tokens | Meaning | Source |
| --- | --- | --- | --- |
| **Cyan** | `focus` `#5ae6f0`, `textAccent` `#33bdea`, `infoFill` `#2c9fb6` | The system's attention: focus, selection, the hack marker, the one highlighted line | Hack-marker triangle, phone selection ring, profiler, dossier "UTILITY RECORDS" tag |
| **Teal** | `networkLine` `#2e6f6c`, `networkNode` `#86e2cc` | Connections: links between nodes, signal paths | Network lines in the cinematics |
| **Green** | `success` `#4ef03a`, `successDim` `#3f8a30` | Done, live, granted. Also the terminal's own voice | Terminal `bash*` and status text |
| **Red** | `error` `#f5412a`, `errorFill` `#cc1c06` | Failure, alert, denied | Dossier "POLITICAL DONATIONS" tag |
| **Amber** | `warning` `#e5b422` | Needs attention but hasn't failed: low battery, degraded link | Extended palette (not in the references) |
| **Rose** | `secured` `#c8406a` | Locked or protected (not an error) | Badge on the phone's WPA-protected networks |

`scrim` (`#000000cc`) sits behind modal overlays.

### Extended palette: terminal and code

Terminals and editors need more hues than the UI does, so content gets an **extended palette**. The one-hue-one-meaning rule applies to UI chrome. Inside a terminal or editor buffer, hues are categories of data.

The source shows only the terminal's blue prompt and violet tmux index (both too dark to read as text, so lifted) and the green `bash*`. Amber is added because a terminal needs a yellow. Every colour except `ansiBlack` reaches at least 4.5:1 on `background`.

| ANSI | Normal | Bright |
| --- | --- | --- |
| Black | `ansiBlack` `#151a20` | `ansiBrightBlack` `#7a7a7a` (4.7:1) |
| Red | `ansiRed` `#f5412a` (5.4) | `ansiBrightRed` `#ff7a66` (7.9) |
| Green | `ansiGreen` `#4ef03a` (13.2) | `ansiBrightGreen` `#a2f797` (15.6) |
| Yellow | `ansiYellow` `#e5b422` (10.4) | `ansiBrightYellow` `#f5d36b` (13.8) |
| Blue | `ansiBlue` `#5875ec` (4.9) | `ansiBrightBlue` `#8fa3ff` (8.5) |
| Magenta | `ansiMagenta` `#ad66f0` (5.7) | `ansiBrightMagenta` `#d39cf7` (9.4) |
| Cyan | `ansiCyan` `#33bdea` (9.2) | `ansiBrightCyan` `#5ae6f0` (13.4) |
| White | `ansiWhite` `#cacaca` (12.3) | `ansiBrightWhite` `#ffffff` (20.1) |

Terminal chrome: `terminalBackground` = `background`, `terminalForeground` `#d9d9d9`, a white block `terminalCursor`, and selection as an inverted block (`terminalSelectionBackground` white, `terminalSelectionForeground` black), matching the selected state above.

**Code highlighting** stays mostly monochrome. Structure is shown in greys and white, and colour marks literals and names:

| Token | Colour | For |
| --- | --- | --- |
| `syntaxText` | grey `#d9d9d9` | Identifiers, plain text |
| `syntaxKeyword` | white | Keywords (bold where the editor allows) |
| `syntaxPunctuation` | grey `#cacaca` | Operators, brackets |
| `syntaxComment` | grey `#7a7a7a` | Comments |
| `syntaxString` | green | Strings |
| `syntaxConstant` | cyan | Numbers, booleans, constants |
| `syntaxFunction` | blue | Functions, methods |
| `syntaxType` | violet | Types, classes, interfaces |
| `syntaxSpecial` | amber | Escapes, regex, decorators, macros |
| `syntaxError` / `syntaxWarning` / `syntaxInfo` / `syntaxHint` | red / amber / cyan / grey | Diagnostics |
| `diffAdded` / `diffRemoved` / `diffChanged` | green / red / amber | Diffs and VCS gutters |

### Filled blocks

Filled blocks always carry **black text** (`labelText`), as in the dossier's stacked tags: `labelFill` (white, 15.9:1), `infoFill` (cyan, 6.7:1), `errorFill` (red, 3.7:1, so use it only for large or bold uppercase text).

### States

| State | Treatment |
| --- | --- |
| Rest | `textSecondary` for inactive values, `textPrimary` for live ones |
| Hover | Text steps up one level (`textSecondary` → `textPrimary`), or the row gets `backgroundBright`. No colour change |
| Focus | `focus` outline at `focusRing` (2px) on controls; `strokeMarker` (3px) for a ring around a round badge. Always visible on keyboard focus |
| Selected / active | Inverted block: `labelFill` with `labelText`. On the bar, the workspace crosshair |
| Pressed | Inverted block for one `durationFast` |
| Disabled | `textDisabled`, outline drops to `frameSubtle`. No hover |
| Busy | Thin progress fill, linear, in `textPrimary` (or `focus` for a hack) |

## Typography

Two families, chosen by audience (see [Principle 1](#1-you-are-an-insider)):
- **Public: `Theme.fontPublic`.** Nimbus Sans, the closest free Helvetica match, from the URW base-35 fonts that ship with Ghostscript. In the references: "SMART PHONE", "INSURANCE", "MOBILE DEVICE:".
- **Insider: `Theme.fontInsider`.** JetBrains Mono Nerd Font. Both families are fixed by the design system, not per-user settings, so generated configs (Hyprland title strips, terminal, GTK) always match the QML.

### Scale

Sizes are logical pixels (see [Spacing & Layout](#spacing--layout)).

| Token | px | Use |
| --- | --- | --- |
| `fontSize2xs` | 11 | Micro labels under a value (`FREE`, `WPA PASSWORD`), disclaimers |
| `fontSizeXs` | 12 | Meter labels, captions |
| `fontSizeSm` | 14 | Body text, field labels, terminal text |
| `fontSizeMd` | 16 | Bar segments, inputs |
| `fontSizeLg` | 18 | Emphasised readouts |
| `fontSizeXl` | 22 | Profiler values, card titles |
| `fontSizeDisplaySm` | 34 | Section headlines on full-screen surfaces |
| `fontSizeDisplayMd` | 48 | Clock |
| `fontSizeDisplayLg` | 64 | Splash wordmark |

Weights: `fontWeightLight` 300 (display sizes only), `fontWeightRegular` 400, `fontWeightMedium` 500 (default for insider UI text), `fontWeightBold` 600 (meters, emphasis).

### Casing and tracking

- **Labels are uppercase** with `trackingLabel` (1px). Values keep their natural case.
- The **profiler pattern**: a value at one size, its label one or two steps smaller in `textPrimaryDim` (above or below it), never in a different colour.
- **Masked input and spaced readouts** use `trackingWide` (5px).
- Public display type is tight, never tracked out. Monospace readouts are tabular by nature: pad numbers to a fixed width (`065%`, not `65%`) so they don't jitter.

## Spacing & Layout

**Units are logical pixels.** Wayland and Qt already apply the output scale, fractional included, so a token of `8` is 8px at 1× and 12px at 1.5×. `Units.vh` (screen height ÷ 1080) is only for **full-screen compositions** (greeter, lock screen, splash), where the layout has to fill the screen the way it does at 1080p. Docked chrome (bar, popups, OSD, notifications) uses plain tokens so it looks the same on every monitor.

### Scale

| Token | px | Typical use |
| --- | --- | --- |
| `space2xs` | 2 | Between a value and its micro label |
| `spaceXs` | 4 | Inside dense rows, icon to text in a tag |
| `spaceSm` | 6 | Between bar segments |
| `spaceMd` | 8 | Default padding inside a frame |
| `spaceLg` | 12 | Between groups in a panel |
| `spaceXl` | 16 | Panel padding |
| `space2xl` | 24 | Between panels |
| `space3xl` | 32 | Screen margins on full-screen surfaces |

### Dimensions

- **Bar:** `barHeight` 37px, with a `strokeHairline` border in `frame`. Like the map dashboard's tiled panels, the bar is one frame divided into cells: segments sit `segmentInset` (3px) inside it, separated by `Divider`s (`frameSubtle`), with no frame of their own. Meters are `barMeterWidth` (90px) wide. Clickable segments (network, audio, battery) follow the control states: on hover the brackets settle in around a `surfaceRaised` fill, on press an inverted block for one `durationFast`. The active workspace gets brackets. A workspace with windows shows the icon of the window last focused there, recoloured to `textPrimary` when active and `textSecondary` otherwise, with a round `pipSize` pip under it for each other window. An empty active workspace shows the crosshair; empty inactive ones are blank cells. The CPU and MEM meters swap their symbol for `!!` in `warning` while a process is over its threshold. The network segment shows no colour while linked; offline it reads `OFFLINE` in `textSecondary` with an `error` status dot. The left end is the ctOS logo in `labelText` on its own square `labelFill` block, flush with the bar's edges, then the `Brandmark` (public voice) inset `spaceSm` on every side so the `OS` sits clear of the border.
- **Bar popups** hang from the segment that opened it, sharing the bar's bottom rule: `surface` with a `strokeHairline` `frame` outline, `popupWidth` wide, a label block across the top, and rows that follow the list-row states. They drop in at `durationShort` with `easeEnter`, and the opening segment keeps its brackets while the popup is open. A popup from a segment on the right of the bar hangs left from its right edge. Shared pieces live in `BarPopup` and the `Popup*` components. The **network menu** (`popupWidthWide`) follows Aiden's network list: the current link as a profiler readout, then a row per network with a round `badgeSize` badge holding the signal glyph (bars lit by strength, the rest `fillMuted`), a `secured` dot on protected networks, the name and a micro label (`FREE`, `WPA2 PASSWORD`, `SAVED`, `ACCESS DENIED` in `error`). The linked network is an inverted block and the targeted row gets the `focus` ring round its badge. A key is typed into a masked well (`*`, `trackingWide`). Key hints (motif 10) sit in the footer. The **process menus** (CPU, MEM) read out the meter's value, then the heaviest processes as a ruled table: name and PID left, reading right (CPU in % of one core, like `top`; memory resident), flagged ones with the reading in `warning`. The header status reads `NOMINAL` or the flagged count.
- **Keybind cheatsheet:** the right end of the bar is a `[?] KEYS` key hint (motif 10), mirroring the logo block at the left; click it or press `SUPER+/`. It opens a full-screen overlay on the focused monitor: `scrim` over the desktop, then a dialog panel (`surface`, `strokeFrame` outline, label block header with the bind count) holding Hyprland's live binds in `cheatsheetColumnWidth` columns. Each group's name is a label block, and each row is a combo of key caps in a `cheatsheetKeysWidth` column and its action in uppercase, rows ruled apart. A `bindd` description names a bind (`Group: Action`, or just `Action`); undescribed binds get a label from their dispatcher, and series (`SUPER+1–0`, the arrows) collapse into one row. The panel drops in at `durationMedium` and leaves at `durationShort`; Escape or a click outside closes.
- **Panels** follow the reference's grid: framed rectangles that tile edge to edge with a `spaceMd`–`spaceLg` gutter, sub-panels nested inside a parent frame.

## Shape

**Everything is square.** `radius` is 0 for every container, bar, field and window. Circles exist only for **round controls and badges** (the phone's network icons, its selection ring, the map's D-pad), never for containers.

| Token | px | Use |
| --- | --- | --- |
| `strokeHairline` | 1 | Bar border, dividers, corner brackets, network lines, table rules |
| `strokeFrame` | 2 | Panel and window outlines |
| `strokeMarker` | 3 | Hack marker, focus ring |
| `cornerArm` | 7 | Length of one corner-bracket arm |
| `accentSize` | 4 | Greeter accent squares |
| `labelShadow` | 2 | Hard offset shadow under stacked tags |
| `accentSizeSm` | 2 | Accent squares around a small bar icon |
| `crosshairSize` | 9 | Active-workspace crosshair |
| `statusDot` | 6 | Round status dot on a badge or bar icon |
| `pipSize` | 3 | Workspace window pips, one per extra window |

### Motifs

From the reference frames, in the order you should reach for them:

1. **Full frame.** A `strokeFrame` outline in `frame` around a black panel. The default container: windows, popups, panels. A window gets a tiny uppercase title strip (`NEW WINDOW`).
2. **Corner brackets.** Four `cornerArm` L-shapes (`CornerFrame`). A **state, not a container**: they mark the one thing that is targeted (the active workspace, a hovered control), settling in from just outside at `durationFast`, like a camera locking on. Structure comes from frames and rules, so brackets never sit on items at rest. Also for camera-style viewports. _(Practicality: no reference shows brackets on individual items; the HUD frames whole screens with corner marks.)_
3. **Label block.** Solid `labelFill` with black uppercase text, flush against the content it names (`SMART PHONE`, `INSURANCE`). A label sits *on* the frame's edge or just above it, not floating inside.
4. **Tag stack.** Full-width filled bars, stacked with a `labelShadow` hard black offset, each a category (`infoFill`, `errorFill`, `labelFill`). For lists of categories and alerts.
5. **Hack marker.** An inverted outline triangle in `focus` at `strokeMarker`, attached to a label block. Marks the one thing being acted on.
6. **Network line.** A `strokeHairline` line in `networkLine` with small square nodes in `networkNode` spaced along it; dotted for routes. For connections and progress through a sequence.
7. **Dashed rule.** A dashed `frameSubtle` (or `textSecondary`) line between rows of dense data.
8. **Brandmark.** The official ctOS lockup (`Brandmark`): a wide `labelFill` block with a small regular `CT` in its bottom-right corner, then a bold `OS` whose letters (overshoot included) match the block's height, sitting on its baseline (the reference sets `OS` ~6% taller; we match them). `fontPublic`. Proportions are measured from [`ctOS.webp`](design/references/ctOS.webp) and fixed in the component. The dossier's variant, each letter of `ctOS` in its own outlined cell, is for a wordmark inside a panel header.
9. **Viewport marks.** For full-screen surfaces (lock screen, screenshot selection, splash): a faint full-screen frame with short ticks crossing it at the middle of each edge, solid right-angle triangles in the corners, and `+` marks at the edge midpoints and centre. From the HUD's camera and hacking views.
10. **Key hint.** A black block holding a key cap (the key's name in a small `strokeHairline` square) followed by the action in uppercase: `[B] EXIT`. For keybind hints, OSD and the cheatsheet. From the HUD.
11. **Texture.** A checkerboard dither or diagonal hatch in `frameSubtle` behind a card, to set it apart from what's under it. Static, and sparingly. From the HUD's profiler and conversation cards.

**Shadows and blur:** none, except the tag stack's hard offset. Depth comes from outlines and nesting.

### Windows

The compositor draws motif 1 around every app window, following the terminal in the references: a bright outer frame whose title strip is filled in the frame's own colour, with a small square icon and dark title text.

| Token | Value | Use |
| --- | --- | --- |
| `windowBorder` | 2px | Border width |
| `windowBorderActive` / `windowBorderInactive` | `frame` / `textSecondary` | Focused / unfocused border. Unfocused stays visible, like the background windows in the references |
| `windowGapsIn` / `windowGapsOut` | 4 / 8px | 8px gutter between windows, 8px to the screen edge |
| `windowTitleHeight` | 20px | Title strip and group tabs |
| `windowTitleBackgroundActive` / `windowTitleBackground` | `windowBorderActive` / `windowBorderInactive` | Focused / unfocused title strip, filled in the border colour so frame and strip are one block |
| `windowTitleText` | `labelText` | Title text and icon on the strip |
| `windowTitleTextSize` | 11px | Title text, insider font |

In Hyprland, `ctos-look.conf` provides the frame, gaps, square corners and animations. The optional `ctos-hyprbars.conf` adds the title strip through the hyprbars plugin, with the border drawn around the strip and a focus window rule switching the strip to the active colour. Grouped windows show tabs: the active one is an inverted block.

**Known gaps from the reference:** hyprbars shows the window's own title in its own case (`kitty`, not `NEW WINDOW`), and can't draw the dim rule under the strip.

## Opacity

Surfaces are opaque. Opacity is for imagery and transitions, not for colouring text or chrome (use a colour token for that).

| Token | Value | Use |
| --- | --- | --- |
| `opacityGhost` | 0.1 | A trace left behind as something leaves |
| `opacityDim` | 0.5 | Content pushed back: behind a modal, disabled imagery |
| `opacitySoft` | 0.9 | Imagery under or beside text, so it doesn't outshine it |

`tint` (`#ffffff1e`) is the faint white wash behind an image or avatar.

## Motion

Motion is for **transitions** (see [Adapting it to a desktop](#adapting-it-to-a-desktop)). The resting state never animates.

### Durations

| Token | ms | Use |
| --- | --- | --- |
| `durationInstant` | 50 | Opacity blips, glitch frames, typewriter characters |
| `durationFast` | 100 | Hover, press, accent slide |
| `durationShort` | 200 | Small elements entering or leaving |
| `durationMedium` | 300 | Panels, popups, layout shifts |
| `durationLong` | 500 | Screen-level transitions (splash, unlock) |
| `durationMeter` | 1000 | Meter fill catching up to a new value |
| `durationHack` | 2000 | A hack in progress (the WD1 profiler's ~2 s) |
| `durationConfirm` | 4000 | How long an armed destructive action (log out, reboot, shut down) waits for its confirming press |

Most UI motion should be `durationFast`–`durationMedium`. If something takes longer than `durationLong` it must be showing progress.

### Easing

| Token | Curve | Use |
| --- | --- | --- |
| `easeEnter` | OutCubic | Things arriving: fast start, soft landing |
| `easeExit` | InExpo | Things leaving: hold, then snap away. The signature ctOS exit |
| `easeMove` | InOutCubic | Moving or resizing in place |
| `easeSnap` | OutExpo | Accent slides, caret jumps |
| `easeLinear` | Linear | Progress fills, typewriter |

No bounce, elastic or overshoot curves.

### Signature moves

- **Typewriter** (`Typewriter`): text appears character by character at `durationInstant`. For status lines and labels changing *as the result of an action*, never for text at rest.
- **Accent slide** (`Accents`): corner squares fly in from outside and settle on the corners of what they frame. Marks something as acquired or focused.
- **Thin progress** (`ThinProgress`): a 1–3px fill, linear. Stutters (pauses, jumps) are allowed and in character.
- **Erosion** (ctOS → DedSec): clean UI broken up by glitch frames and dither while DedSec text unscrambles. Only for a breach or takeover (see [DedSec](#dedsec)).

### Reduced motion

The greeter's animation-mode setting is the switch. With motion reduced, transitions become cross-fades at `durationShort`, typewriters show their full text at once, and erosion is replaced by an instant swap to the error state.

## DedSec

DedSec is the intruder (see [Principle 4](#4-dedsec-is-the-intruder)), styled after WD1's defacement of ctOS: black, white, ASCII and glitch. No WD2 neon. It erodes in, holds still, and recovers once the problem is resolved.

### Levels

| Level | Name | When | Treatment |
| --- | --- | --- | --- |
| 0 | **Fault** | Ordinary errors: wrong password, a network that won't connect, a failed action | **Not DedSec.** ctOS's own voice: `error`, an `errorFill` tag, `ACCESS DENIED` typed in. Most errors stop here |
| 1 | **Breach** | The system itself is wrong: critical notifications, repeated failed logins, a crashed service, critical battery, an untrusted device | DedSec takes over **only the affected component** (a bar segment, a notification, the greeter card) |
| 2 | **Takeover** | Easter eggs and things you trigger on purpose: fastfetch, a DedSec keybind, the lock screen after many failed attempts | Full screen, like the defaced ctOS website: black page, ASCII mark |

### Look

- **Colour:** `dedsecBackground` (pure `#000000`, so the blue cast of ctOS's `background` drops away), `dedsecText` (white), and `dedsecSignal` (`error`) for the one fact that caused it. No new hue.
- **Type:** `fontInsider` only, never the public face. DedSec copy is lowercase and informal, against ctOS's uppercase labels (`ctOS sentinel offline. we see you.`).
- **Icons:** pixel art (see [Iconography](#iconography--assets)).
- **Mark:** the ASCII mask in [`extras/.config/fastfetch/dedsec.txt`](extras/.config/fastfetch/dedsec.txt). Level 1 uses a smaller version of about 8 lines.
- **Shape:** ctOS chrome is stripped. No frames, corner brackets or label blocks, just bare text on black.

### Motion

1. **Erosion in,** at most `durationLong`: two to four glitch frames (horizontal slices displaced, `durationGlitch` each), then a dither dissolve of the ctOS layer while the DedSec text unscrambles into place.
2. **Rest:** static. No looping glitch or flicker. It holds until the problem is resolved or dismissed.
3. **Recovery out:** the same in reverse at `durationShort`, back to clean ctOS.
4. **Reduced motion:** an instant swap both ways.

### Components (to build with the first surface that needs them)

| Component | Does |
| --- | --- |
| `Glitch` | Shader effect that slices and offsets whatever it wraps for a few frames |
| `Scramble` | Text that settles from random characters into its final wording (extends `Typewriter`) |
| `Takeover` | Swaps a component's ctOS content for its DedSec state and runs erosion and recovery |

## Controls

How standard widgets look, in Quickshell and in GTK/Qt themes alike. The references show few real controls (the dossier's form fields, square icon buttons and checkboxes; the phone's list and selection ring), so these extend them with practicality first: third-party apps must stay usable all day.

### Rules

- **Square, outlined, dark.** Controls sit on the background with thin outlines. No gradients, shadows, or rounding.
- **Inverted block = selected.** Wherever something is chosen, checked or the primary action, it becomes `labelFill` with `labelText`, like the dossier's label blocks.
- **Cyan = keyboard focus only.** Never used for selection, so focus and selection can't be confused.
- **Natural case in third-party apps.** GTK CSS can't uppercase text, and forcing it would break apps. Uppercase applies to copy we write.

### Metrics

| Token | px | Use |
| --- | --- | --- |
| `controlHeight` | 28 | Buttons, entries, combo boxes |
| `controlPadding` | 8 | Horizontal padding inside controls |
| `indicatorSize` | 14 | Checkbox and radio |
| `trackThickness` | 2 | Slider and progress tracks |
| `handleSize` | 12 | Slider handle |
| `scrollbarWidth` / `scrollbarWidthHover` | 4 / 8 | Overlay scrollbar |
| `focusRing` | 2 | Focus outline |

### Widgets

| Widget | Rest | Hover | Active / checked | Source |
| --- | --- | --- | --- | --- |
| **Button** | `backgroundBright` fill, `frameSubtle` 1px border, `textPrimary` | Border → `frame` | Pressed or toggled: inverted block | Dossier icon buttons |
| **Flat button** (toolbars, header bars) | No fill or border | `backgroundBright` fill | Inverted block | — |
| **Suggested action** | Inverted block | `textPrimary` fill | — | Dossier label block |
| **Destructive action** (dialog confirm only) | `error` fill with `labelText` (5.7:1) | `errorFill` fill | — | Dossier red tag |
| **Entry / text field** | `background` well, `frameSubtle` 1px border, placeholder `textSecondary` | Border → `textSecondary` | Focus: `focus` outline | Dossier form fields |
| **Combo box / dropdown** | As entry, with a square arrow cell on the right | As entry | Opens a menu | Dossier dropdown arrows |
| **Checkbox** | `indicatorSize` square, `frame` 1px outline | Fill `backgroundBright` | Inverted: `labelFill` square with a black tick. Indeterminate: black dash | Dossier checkboxes |
| **Radio** | Circle, `frame` 1px outline | Fill `backgroundBright` | Solid `textPrimary` inner dot | Round controls (phone, map D-pad) |
| **Switch** | Rectangular track, `frameSubtle` outline, square `textSecondary` knob at left | Knob → `textPrimary` | Track `labelFill`, black knob at right | — |
| **Slider** | `trackThickness` track in `fillMuted`, filled part `textPrimary`, square handle | Handle grows by 2px | Dragging: handle `focus` outline | Thin progress motif |
| **Progress bar** | As slider track, no handle, linear motion | — | — | `ThinProgress` |
| **Level bar** (battery, disk) | `textPrimary` fill; below 20%: `warning`; full: `success` | — | — | Bar meters |
| **Scrollbar** | Overlay, `scrollbarWidth`, `fillMuted` thumb, no track or steppers | `scrollbarWidthHover`, thumb `textSecondary` | Dragging: thumb `textPrimary` | — |
| **Menu / popover** | `surface`, `frame` 1px outline, no shadow | Item: inverted block | — | Full-frame motif |
| **List / tree row** | Transparent | `backgroundBright` | Selected: inverted block; selected in an unfocused view: `fillMuted` | Phone list, dossier tags |
| **Tabs** | Inactive: `textSecondary`, no border; tab strip has a 1px `frameSubtle` bottom rule | `textPrimary` | Active: inverted block | Dossier tag stack |
| **Header bar / title bar** | `background`, 1px `frameSubtle` bottom rule, title in `textPrimary` | — | Backdrop (unfocused window): title `textSecondary` | Terminal "NEW WINDOW" strip |
| **Tooltip** | Label block: `labelFill`, `labelText`, `fontSizeXs` | — | — | Label block motif |
| **Text selection** | Inverted: `labelFill` behind `labelText` | — | — | Same as the terminal |
| **Link** | `textAccent` | Underline | — | Profiler cyan |
| **Dialog** | `surface`, `strokeFrame` `frame` outline, title as a label block | — | — | Full frame + label block |

Disabled anything: text `textDisabled`, borders `frameSubtle`, no hover.

### Toolkits

- **GTK 3:** a full theme (`gtk.css` + `settings.ini`) can implement everything above.
- **GTK 4 / libadwaita:** libadwaita ignores most theming. Override its named colours (`window_bg_color`, `accent_bg_color`, …) and set radius to 0 in `~/.config/gtk-4.0/gtk.css`. Accept that some widgets keep the Adwaita shape.
- **Public and insider GTK themes** are two builds of one template that differ only in `font-family`. Insider apps are launched with `GTK_THEME=ctOS-Insider` from a desktop-entry override.
- **Qt:** start with qt6ct/qt5ct, the Fusion style, a ctOS colour scheme and fonts. That covers most apps with little work. Move to Kvantum only if Fusion's slight rounding and gradients prove too far from the look.
- **Fonts:** public UI font is `fontPublic` at `fontSizeSm` (14px ≈ 10.5pt); insider is `fontInsider` at the same size.
- **Window chrome:** client-side decorations get no shadow or border; Hyprland draws the window frame.

## Iconography & Assets

- **Style:** barebones flat glyphs, like the cutscene phone's (signal bars, stacked windows, hamburger, back arrow) and the dossier's broken heart. Solid monochrome shapes on a whole-pixel grid, no gradients. Icons are drawn in `textPrimary` or `frame`, never in a signal colour unless they *are* the signal.
- **Pixel art belongs to DedSec.** In the game's icon set, pixel-art icons are DedSec's (the Field Guide skull). ctOS's own icons stay smooth and flat.
- **Containers:** where an icon needs a shape around it, use the round badge (below). Where a category needs its own shape and the cutscenes show none, follow the HUD: hexagon for system and apps, diamond for targets and objectives.
- **Badges:** an icon in a round dark badge, with a small round status dot overlapping its lower-left edge (`secured`, `error`, `success`). From the phone's network list.
- **Glyphs:** the insider voice can use Nerd Font glyphs and box-drawing characters. Prefer text (`<>`, `++`, `--`) where ctOS would.
- **SVG conventions:** square viewBox on a whole-pixel grid, shapes aligned to that grid so they stay sharp at fractional scaling, fill `#ffffff` so QML can recolour them.
- **Where assets live:** next to the module that uses them: `bar/resources/`, `greeter/resources/`. Promote an asset to `common/resources/` once a second module needs it.
- **Logos:** `common/resources/ctos-logo.svg` (the diamond from the wallpaper) and `common/resources/blume-logo.svg` (the hexagon of cubes), white on a 48px grid, for anything outside QML (boot, wallpapers, fastfetch). QML can't recolour an SVG without QtQuick.Effects, so QML draws them with `CtosLogo` and `BlumeLogo`, which hold the same paths.

## Components

Reuse these before writing new ones. Shared ones go in `common/components`.

| Component | Where | Use it for |
| --- | --- | --- |
| `Accents` | common | Corner squares that slide onto something to mark it acquired/focused |
| `Brandmark` | common | The official ctOS lockup, scaled from its height (motif 8) |
| `CtosLogo` | common | The ctOS logo (a diamond wired to a solid square core) as a shape, in any colour |
| `BlumeLogo` | common | The Blume logo (a hexagon of three isometric cubes) as a shape, in any colour |
| `CornerFrame` | bar | Corner brackets around a row of content (motif 2), shown while `marked`; optional state fill |
| `Divider` | bar | 1px vertical rule between bar segments |
| `Segment` | bar | Shell for every bar segment: an inset `CornerFrame` whose brackets show while `marked` (hover by default), and with `interactive` the hover/pressed states plus `clicked`/`scrolled` signals. Content colours itself from `inkColor`/`labelColor` |
| `SimpleSegment` | bar | Bar segment: icon + one value; `live: false` steps the value down to `textSecondary` |
| `Meter` | bar | Bar segment: label, symbol, value and a thin level fill (CPU, RAM, battery); `fillColor` for level-bar states, `muted` for disabled, `flagged` swaps the symbol for a `warning` `!!` |
| `CpuMeter` / `MemoryMeter` | bar | `Meter` on `/proc`; flagged while `ProcessMonitor` has a process over the threshold, click to open the `ProcessMenu` |
| `ProcessMenu` | bar | Popup tiled under the CPU or MEM meter: the meter's reading and facts, then the heaviest processes from `ProcessMonitor`, flagged ones in `warning` |
| `AudioMeter` | bar | `Meter` on a Pipewire node: scroll for volume, click to mute |
| `BatteryMeter` | bar | `Meter` on the UPower battery; click to open the `PowerMenu`, brackets held while it is open |
| `PowerMenu` | bar | Popup tiled under its segment (`popupWidth`, menu treatment, label block header): battery readout and power-profile rows, the active one inverted. Click outside or Escape closes |
| `UserSegment` | bar | `SimpleSegment` with the operator's name; click to open the `SessionMenu`, brackets held while it is open |
| `SessionMenu` | bar | Popup tiled under its segment: operator readout (name, host, session, uptime) and session action rows. Log out, reboot and shut down arm on the first press as the destructive-action block (`error` fill) and run on a second press within `durationConfirm`; Escape disarms |
| `KeyCap` | common | One key's name in a hairline cap; `KeyHint` and the cheatsheet's key combos are built from it |
| `KeybindSegment` | bar | The `[?] KEYS` cell at the right end of the bar; click to open the `Cheatsheet`, brackets held while it is open |
| `Cheatsheet` | bar | Full-screen keybind overlay fed by the `Keybinds` service (`hyprctl binds -j`); toggled by the segment or `qs ipc call cheatsheet toggle` |
| `Clock` | bar | Date, time and zone as one ruled readout (`091126-0330-PST`), time bright, the rest dim |
| `SignalIcon` | bar | The phone's network glyph; dims and takes an `error` status dot without a link |
| `SystemLabel` | bar | The ctOS logo block and the brandmark, at the left of the bar |
| `Workspace` / `Workspaces` | bar | Workspace cells: lead app icon plus a pip per extra window; the active one gets brackets (and a crosshair when empty). Click to switch, with the control states on hover and press |
| `TintedIcon` | bar | An app icon recoloured to one tone (Qt Quick Effects), keeping its shading; `ready` false until it loads so a fallback can stand in |
| `Tray` | bar | One workspace-sized cell after the workspaces: the background-app count as a two-digit readout (`warning` while one needs attention); click to open the `TrayMenu` |
| `TrayItem` | bar | An app in the tray grid: its icon tinted, `warning` while it needs attention, control states while `targeted`; scroll goes to the app |
| `TrayMenu` | bar | Popup tiled under the tray: the apps as an icon grid (left click activates, middle click secondary, right click drills in), then an app's menu redrawn as list rows with a BACK row, separators as rules, `[X]`/`(•)` toggles, submenus drilled into the same way |
| `Surface` | greeter | A framed panel with an animated side bar |
| `IdentityCard` | greeter | The profiler pattern: name and labelled facts |
| `FieldGroup` / `PasswordField` | greeter | Labelled input with a block cursor and masked characters |
| `Status` | greeter | Labelled system facts (battery, network) on a `Surface` |
| `Session` | greeter | Session picker |
| `DeviceId` | greeter | The tesseract mark and device identifier |
| `Disclaimer` | greeter | Blume legal line with typewriter reveal |
| `Terminal` | greeter | Scrolling insider log text |
| `Time` | greeter | Large clock with accents and region line |
| `Splash` | greeter | ctOS boot splash with progress |
| `Spinner` | greeter | Square-grid loading indicator |
| `ThinProgress` | greeter | Thin progress fill with stutter |
| `Typewriter` | greeter | Text that types itself in |

**Promote next:** `CornerFrame` and `Divider` (the greeter and popups will need them), `ThinProgress` and `Typewriter` (OSD, notifications). **Missing,** from the references: a window/panel frame with title strip (motif 1), a label block (3), a tag (4), and a list row with badge (the phone list).

## Targets

Where tokens are applied outside QML. Each one is a template in `design/templates/`.

| Target | Template | Status |
| --- | --- | --- |
| Quickshell (bar, greeter) | generated `common/Theme.qml` | ✅ |
| kitty | _TBD_ (tokens ready: `terminal` section) | — |
| Hyprland | `extras/.config/hypr/ctos-look.conf.tmpl`, `ctos-hyprbars.conf.tmpl` | ✅ |
| GTK 3/4 | _TBD_ | — |
| Qt (qt5ct/qt6ct/Kvantum) | _TBD_ | — |
| fuzzel | _TBD_ | — |

## Rules

- Don't write color, size or duration literals in QML. Add a token and use `Theme.<token>`. Existing literals are migrated to tokens **before** new features are built.
- **Always tokens:** every colour; font family, size and weight; letter-spacing; spacing, padding and margins; stroke widths; durations and easings; resting opacities other than 0 and 1. Arithmetic on tokens is fine (`Theme.durationShort * 2` for a stagger, `parent.height - 2 * Theme.segmentInset`).
- **Literals allowed:**
  1. **Structural numbers:** `0`, `1`, `-1`, halving and centring (`/ 2`), rotations in multiples of 90, `z` order, counts and indices.
  2. **Values derived from data:** percentages, ratios and anything bound to state (`xScale: percentage / 100`).
  3. **Full-screen compositions** (greeter, lock screen, splash): layout sizes written as `N * Units.vh`, where `N` places something within that one composition. A value used in more than one place becomes a token.
  4. **Choreography keyframes:** intermediate targets inside a scripted animation sequence (`xScale: 0.73`, a scale passing through `0.4`). Their durations and easings still come from tokens.
  5. **Optical nudges:** small offsets that correct font metrics (`y: -2`), each with a comment saying so.
- Use semantic tokens in components, not primitives.
- Use semantic tokens in components, not primitives.
- Never edit `common/Theme.qml` or any template output by hand. Edit `design/tokens.json` or the `.tmpl` and run `design/build.py`.
