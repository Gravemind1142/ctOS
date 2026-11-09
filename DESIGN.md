# ctOS Design System

The single reference for how ctOS looks and moves. Every themed surface (Quickshell bar and greeter, terminal, compositor, GTK/Qt, CLI tools) follows it.

> **Status:** boilerplate. Sections marked _TBD_ still need to be filled in.

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
    "background": "{gray800}",                // reference to another token
    "error": "#fc3e38",                       // literal; type is inferred (color/int/real/string/bool)
    "scrim": "#0e0e0ecc",                     // 8-digit colors use CSS order #RRGGBBAA (converted for QML)
    "fontFamily": {                           // long form
        "value": "JetBrainsMono Nerd Font",
        "type": "string",                     // optional, overrides inference
        "mutable": true,                      // optional, writable instead of readonly
        "description": "Shown as a comment"   // optional
    }
}
```

Placeholders in templates: `{{token}}`, or `{{token|bare}}` (no `#`) / `{{token|rgb}}` (`r, g, b`) for colors.

### Token tiers

1. **Primitives:** raw values (`gray800`, `accentGreen`). Components never use these directly.
2. **Semantic:** what a value is *for* (`background`, `textPrimary`, `success`). Components use these.

## Inspiration

ctOS is a desktop built as if Blume shipped its Central Operating System to your machine. The fictional software in **Watch Dogs (Ubisoft, 2014)** is the primary source. When a design question comes up, the first thing to ask is how ctOS would show it.

Screenshots live in [`design/references/`](design/references/README.md). Sourced findings from articles and the wiki are in [`design/research.md`](design/research.md).

### Key findings

- **ctOS is a utility, branded like one.** Its typeface is Helvetica, and its identity was modelled on the NYC Transit Authority Graphics Standards Manual. Sterile, ubiquitous, civic.
- **There are two voices.** The *system* speaks in clean neo-grotesk type. *Hacking* speaks in barebones type, 8-bit/DOS fonts and early cell-phone icons. The contrast between them is intentional. We split them by audience: Helvetica is public, monospace is insider (see Principle 1).
- **The world is the interface.** Indicators sit on the thing they control.
- **The WD1 profiler is the template:** name, labelled facts (occupation, income), one highlighted line. Terse and monochrome. WD2's colourful Material redesign is the direction not to follow.
- **Motion:** transitions instead of cuts. Hacking is shown as glitchy network lines, with dither, point clouds and tracking-UI "machine thought". The signature move is clean ctOS eroding into the hacker underworld.
- **Blume's voice:** short declarative fragments with full stops and triads ("Security. Civility. Connectivity."). Benevolent on the surface, authoritarian underneath.
- **DedSec defaces ctOS.** Black takeover, ASCII-art logo, content layered over ctOS surfaces.

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

For GTK/Qt apps, the public face is the global default, and insider apps are opted in individually. A desktop entry's `Categories` (`Development`, `System`) is the starting point for classifying an app, with manual overrides where categories mislead.

### 2. Speak like ctOS

UI copy uses ctOS's vocabulary and Blume's style (see [research](design/research.md#blume-voice-and-brand)):
- **Labels are uppercase,** like the profiler (`OCCUPATION`, `INCOME`).
- **Status lines use system language:** `LINK ESTABLISHED`, `SCAN COMPLETE`, `ACCESS GRANTED`. The desktop is infrastructure: systems, nodes, links.
- **Public-facing copy** is short declarative fragments with full stops ("Simple. Secure. Connected.").
- **Brand casing is always `ctOS`** (lowercase "ct").

### 3. Dark only

ctOS has a single dark theme, for practicality. There is no light mode. The public voice is expressed through type and copy, not by switching to Blume's white print branding.

### 4. DedSec is the intruder

DedSec styling (glitch, ASCII art, takeover) is reserved for errors, alerts and easter eggs. It is never used for ordinary states.

_TBD: further principles (motion restraint, accent use, density). Tracked in [TODO.md](TODO.md#design-system)._

## Color

Dark only (see [Principle 3](#3-dark-only)). Values follow the source wherever it shows them.

- **Accent: `accentCyan` `#33bdea`.** The WD1 profiler and hack-marker cyan, sampled from in-game screenshots (JPEG, so approximate). Used for `textAccent`.
- **Success `accentGreen` and error `accentRed`** are inherited from the Monoglow theme and not yet checked against the source.

_TBD: full role list, contrast, states (hover/active/disabled)._

## Typography

_TBD: family, size scale, weights, casing, letter-spacing._

Two families, chosen by audience (see [Principle 1](#1-you-are-an-insider)):
- **Public: `Theme.fontPublic`.** Nimbus Sans, the closest free Helvetica match, from the URW base-35 fonts that ship with Ghostscript.
- **Insider: `Theme.fontInsider`.** JetBrains Mono Nerd Font. This is the font the per-user `fontFamily` config overrides; the public face is fixed.

## Spacing & Layout

_TBD: spacing scale, relation to `Units.vh`, bar/panel dimensions, stroke widths._

## Shape

_TBD: corners, the corner-bracket/accent motif, borders vs. frames._

## Motion

_TBD: durations, easings, signature animations (typewriter, accent slide-in), reduced-motion behaviour._

## Iconography & Assets

_TBD: icon style, SVG conventions, where assets live._

## Components

_TBD: inventory of existing components in `common/components`, `bar/components` and `greeter/components`, with when to use each._

## Targets

Where tokens are applied outside QML. Each one is a template in `design/templates/`.

| Target | Template | Status |
| --- | --- | --- |
| Quickshell (bar, greeter) | generated `common/Theme.qml` | ✅ |
| kitty | _TBD_ | — |
| Hyprland | _TBD_ | — |
| GTK 3/4 | _TBD_ | — |
| Qt (qt5ct/qt6ct/Kvantum) | _TBD_ | — |
| fuzzel | _TBD_ | — |

## Rules

- Don't write color, size or duration literals in QML. Add a token and use `Theme.<token>`. Existing literals are migrated to tokens **before** new features are built.
- Use semantic tokens in components, not primitives.
- Never edit `common/Theme.qml` or any template output by hand. Edit `design/tokens.json` or the `.tmpl` and run `design/build.py`.
