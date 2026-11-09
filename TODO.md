# ctOS Rice TODO

What's still needed before ctOS counts as a full rice. Anything themed should use the palette in [`common/Theme.qml`](common/Theme.qml) so it all matches.

## Design system

See [`DESIGN.md`](DESIGN.md). These come first: existing literals are migrated before new work.

- [ ] **Migrate literals to tokens**: replace the ~86 hardcoded colours, sizes and durations in QML with `Theme.<token>`. Includes moving the greeter from `Settings.fontFamily` to `Theme.fontInsider`/`fontPublic` and removing the duplicate font defaults in the bar and greeter `GeneralDto`. Needs the spacing, motion and shape scales below
- [ ] **Spacing & layout**: choose screen-height scaling (`Units.vh`) or fixed pixels × display scale; define the spacing scale, stroke widths and bar/panel dimensions
- [ ] **Motion**: duration and easing tokens; which signature transitions to keep (typewriter, accent slide-in, ctOS → DedSec erosion); tie into the greeter's animation-mode setting
- [ ] **Shape**: where corner brackets are used and whether rounding is always zero
- [ ] **Iconography**: icon style (8-bit / early cell phone) and an icon theme that matches, for GTK too
- [ ] **Remaining principles**: motion restraint, accent use, information density
- [ ] **Colour**: check success green and error red against the source; define the full role list and hover/active/disabled states
- [ ] **Type scale**: sizes, weights and letter-spacing for both voices
- [ ] **Components**: inventory of `common/`, `bar/` and `greeter/` components, with when to use each
- [ ] **First template target**: kitty, to prove the `design/templates` pipeline end to end
- [ ] **Nimbus Sans dependency**: add the URW base-35 fonts to the install script / README dependencies
- [ ] **Nautilus**: insider or public?
- [ ] **References**: collect screenshots in `design/references/`; read the NYCTA Graphics Standards Manual and the Legion UI artists' portfolios

## Core look

- [ ] **Window decorations (Hyprland)**: borders are still the default cyan/green gradient, with default rounding, gaps and animations. Set ctOS colours, sharp or minimal corners, and custom animation curves
- [ ] **Terminal (kitty)**: has colours, font and padding so far. Still needed: cursor style, tab bar, background opacity/blur, ctOS-coloured borders
- [ ] **Shell prompt**: still plain bash. Add a themed prompt (e.g. starship), or switch to zsh/fish
- [ ] **App launcher (fuzzel)**: no config yet. Theme it, or build a Quickshell launcher so it matches the bar
- [ ] **File manager (nautilus)**: follows the GTK theme, see below
- [ ] **GTK 3/4 theme**: no `gtk.css`/`settings.ini` yet. This one change themes nautilus and most other apps
- [ ] **Qt theme**: qt5ct/qt6ct or Kvantum, so Qt apps match too
- [ ] **Icon theme**
- [ ] **Cursor theme**: set `HYPRCURSOR_THEME`/`XCURSOR_THEME` and the size
- [ ] **Fonts**: JetBrainsMono Nerd Font is installed. Decide on a UI font for GTK/Qt and set it everywhere

## Desktop shell pieces

- [ ] **Notifications**: no daemon installed (no mako/dunst/swaync). Install and theme one, or make a Quickshell one
- [ ] **OSD**: on-screen popups when volume or brightness keys are pressed
- [ ] **Power menu**: lock / logout / suspend / reboot / shutdown (replaces the bare `SUPER+SHIFT+M` exit)
- [x] **Bar: battery**: BAT meter (`++` charging, `--` discharging)
- [x] **Bar: network**: click the segment (or `SUPER+N`) to open nmtui
- [ ] **Network popup**: themed Quickshell menu (wifi list, signal, connect) to replace nmtui
- [ ] **Bar**: finish the WIP modules: tray, media, workspace click-to-switch
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
