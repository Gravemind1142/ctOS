## Dependencies

To use the bar, you must have the following core components installed on your system:

### Required

- **[Quickshell](https://quickshell.org):** The engine used to render the QML interface and provide the necessary Wayland desktop shell integrations.

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
    "fontFamily": "JetBrainsMono Nerd Font",
    /* Output to show the bar on (e.g. "eDP-1"), empty uses the first screen */
    "monitor": ""
  },
  "modules": {
    /* Every module can be hidden with "enabled": false */
    "workspaces": { "enabled": true, "count": 5 }, // 1-10 workspace boxes
    "cpu": { "enabled": true, "interval": 2 }, // seconds between samples
    "memory": { "enabled": true, "interval": 1 },
    /* Hidden automatically on machines without a battery */
    "battery": { "enabled": true },
    "network": { "enabled": true },
    /* Label shown instead of $USER */
    "user": { "enabled": true, "label": "" },
    /* Label after the clock, empty shows the system timezone (e.g. "PST") */
    "status": { "enabled": true, "timezone": "" }
  }
}
```

> _Note_: The file must be plain JSON, the comments above are for documentation only.
