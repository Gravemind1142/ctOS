# ctOS Rice TODO

What's still needed before ctOS counts as a full rice. Anything themed should use the palette in [`common/Theme.qml`](common/Theme.qml) so it all matches.

## Design system

See [`DESIGN.md`](DESIGN.md). These come first: existing literals are migrated before new work.

- [ ] **Migrate literals to tokens**: replace the hardcoded colours, sizes and durations in QML with `Theme.<token>`, following the allowed-literal rules in DESIGN.md → Rules. Also clear the deprecated tokens the build warns about (`ctosGray`, `secondary`, `backgroundBright`), and switch public surfaces (splash wordmark) to `Theme.fontPublic`
- [x] **Literal rules, opacity tokens, token cleanup**: see DESIGN.md → Rules, Opacity, and the `deprecated` token field
- [x] **DedSec**: levels, look and motion (DESIGN.md → DedSec)
- [ ] **DedSec components**: `Glitch`, `Scramble`, `Takeover`, with the first breach-level surface
- [x] **Font is not a user setting**: `fontFamily` removed from bar and greeter configs; QML and generated configs use `Theme.fontInsider`
- [x] **Spacing & layout**: logical px for docked chrome, `Units.vh` only for full-screen compositions; spacing scale, strokes, bar dimensions
- [x] **Motion**: duration and easing tokens, signature transitions, reduced-motion rules
- [ ] **Reduced motion**: wire the rules in DESIGN.md → Motion into the greeter's animation-mode setting
- [x] **Shape**: zero radius, stroke widths, the eight motifs from the references
- [x] **Iconography**: style and SVG conventions
- [ ] **Icon theme**: find or draw one that matches, for GTK too
- [x] **Remaining principles**: motion restraint, accent use, information density
- [x] **Colour**: palette sampled from references; role list and states
- [x] **Type scale**: sizes, weights and letter-spacing for both voices
- [x] **Components**: inventory of `common/`, `bar/` and `greeter/` components, with when to use each
- [ ] **New components**: window/panel frame with title strip, label block, tag, list row with badge (see DESIGN.md → Components)
- [x] **Extended palette**: ANSI 16 colours, terminal chrome and code-highlighting roles (`terminal`, `syntax` tokens)
- [ ] **First template target**: kitty, to prove the `design/templates` pipeline end to end (tokens ready)
- [ ] **Nimbus Sans dependency**: add the URW base-35 fonts to the install script / README dependencies
- [x] **Nautilus**: public (see DESIGN.md → Principle 1)
- [x] **Controls**: widget styles for Quickshell, GTK and Qt (DESIGN.md → Controls)
- [ ] **References**: more frames (profiler, hack prompts, camera view, boot); read the NYCTA Graphics Standards Manual and the Legion UI artists' portfolios

## Core look

- [x] **Window decorations (Hyprland)**: `ctos-look.conf` (frame, gaps, curves) and optional hyprbars title strips, generated from tokens
- [ ] **Title strip fidelity**: uppercase titles and the dim rule under the strip aren't possible with hyprbars; revisit if the plugin gains them
- [ ] **Terminal (kitty)**: has colours, font and padding so far. Still needed: cursor style, tab bar, background opacity/blur, ctOS-coloured borders
- [ ] **Shell prompt**: still plain bash. Add a themed prompt (e.g. starship), or switch to zsh/fish
- [ ] **App launcher (fuzzel)**: no config yet. Theme it, or build a Quickshell launcher so it matches the bar
- [ ] **File manager (nautilus)**: follows the GTK theme, see below
- [ ] **GTK 3/4 theme**: no `gtk.css`/`settings.ini` yet. This one change themes nautilus and most other apps. Spec in DESIGN.md → Controls; public and insider builds from one template
- [ ] **Qt theme**: qt6ct/qt5ct + Fusion with a ctOS colour scheme first; Kvantum only if needed
- [ ] **Icon theme**
- [ ] **Cursor theme**: set `HYPRCURSOR_THEME`/`XCURSOR_THEME` and the size
- [ ] **Fonts**: set `fontPublic` (Nimbus Sans) as the GTK/Qt UI font and `fontInsider` for insider apps (decided in DESIGN.md → Controls)

## Desktop shell pieces

- [ ] **Notifications**: no daemon installed (no mako/dunst/swaync). Install and theme one, or make a Quickshell one
- [ ] **OSD**: on-screen popups when volume or brightness keys are pressed
- [ ] **Power menu**: lock / logout / suspend / reboot / shutdown (replaces the bare `SUPER+SHIFT+M` exit)
  - [x] **Bar: session menu**: click the user segment; log out, reboot and shut down ask for a second press
  - [ ] Keybind to open it (needs an IPC handler on the bar), and drop the bare `SUPER+SHIFT+M` exit
- [x] **Bar: battery**: BAT meter (`++` charging, `--` discharging), click for the power menu (battery readout, power profile)
- [x] **Bar: CPU/MEM**: `!!` in warning while a process is over the threshold, click for the heaviest processes
- [x] **Bar: network**: click the segment for the network menu; `SUPER+N` (or the menu's ADVANCED) opens nmtui
- [x] **Network popup**: themed Quickshell menu (current link readout, wifi list with signal and security, connect with key entry, forget, Wi-Fi on/off)
- [x] **Bar: tray**: after the workspaces (now 4 by default), one cell with the app count, click for an icon grid of the apps and their themed menus
- [ ] **Bar**: finish the WIP modules: media
- [ ] **Clipboard history**: cliphist + a launcher picker
- [ ] **Screenshot tool**: binds done; `grim slurp wl-clipboard` need installing. Optionally an editor such as satty/swappy
- [ ] **Wallpaper**: hyprpaper set up. Optionally, switch wallpaper per workspace or rotate them

## Apps and CLI

- [ ] **Editor theme** (nvim / VS Code). Monoglow already exists for nvim
- [ ] **btop / htop theme**
- [ ] **Browser theme** (Firefox userChrome or a theme extension)
- [ ] **fastfetch**: done (DedSec logo)
- [ ] **GRUB / Plymouth boot theme**: carry the ctOS look from boot through the greeter

## Finishing

- [ ] **Keybind cheatsheet**: a popup overlay, or a section in the README
- [ ] **Install script**: add each finished item above as an optional step
- [ ] **Screenshots / showcase** in README
