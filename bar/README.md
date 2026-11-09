## Dependencies

To use the bar, you must have the following core components installed on your system:

### Required

- **[Quickshell](https://quickshell.org):** The engine used to render the QML interface and provide the necessary Wayland desktop shell integrations.
- **Qt Quick Effects:** Recolours app icons in the workspace cells. Bundled with `qt6-declarative` on Arch; on Debian/Ubuntu install `qml6-module-qtquick-effects`.

## Getting Started

### 1. Run [Install Script](/install.sh)

On Hyprland, accept the optional **Hyprland session** step to start the bar on login (see [Extras](/README.md#installing)).

### 2. Run Quickshell

To run it manually or from another compositor's autostart:

```bash
# Set rounding policy to prevent anti-aliasing artifacts on fractional scales
QT_SCALE_FACTOR_ROUNDING_POLICY=Round qs --path /opt/ctos/bar.qml
```

> _Note_: Workspaces currently only support Hyprland.

<br>

## Configuration

The bar reads `~/.config/ctos/bar.config.json`. It is created with the defaults below on first run, and changes apply as soon as you save the file, no restart needed.

```jsonc
{
  "general": {
    /* The typeface used for all bar text */
    /* Output to show the bar on (e.g. "eDP-1"), empty uses the first screen */
    "monitor": ""
  },
  "modules": {
    /* Every module can be hidden with "enabled": false */
    "workspaces": { "enabled": true, "count": 5 }, // 1-10 workspace boxes
    /* Seconds between samples. The symbol turns to a warning "!!" while a process holds more than
       "threshold" percent of one core for two samples in a row (CPU), or of physical memory (MEM).
       Click either meter for its heaviest processes */
    "cpu": { "enabled": true, "interval": 2, "threshold": 80 },
    "memory": { "enabled": true, "interval": 1, "threshold": 20 },
    /* Hidden automatically on machines without a battery. Click it for battery details and the power profile (needs power-profiles-daemon) */
    "battery": { "enabled": true },
    /* Click the segment for the network menu. Command run by the menu's ADVANCED action (and for enterprise networks) */
    "network": { "enabled": true, "command": "kitty --class ctos-network -e nmtui" },
    /* Label shown instead of $USER. Click the segment for the session menu; each command runs from its row, and an empty command hides the row */
    "user": {
      "enabled": true,
      "label": "",
      "commands": {
        "lock": "loginctl lock-session",
        "logout": "hyprctl dispatch exit",
        "suspend": "systemctl suspend",
        "reboot": "systemctl reboot",
        "shutdown": "systemctl poweroff"
      }
    },
    /* Label after the clock, empty shows the system timezone (e.g. "PST") */
    "status": { "enabled": true, "timezone": "" }
  }
}
```

> _Note_: The file must be plain JSON, the comments above are for documentation only.
