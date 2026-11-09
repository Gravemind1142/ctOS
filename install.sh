#!/usr/bin/env bash

# Get script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

NAMESPACE="ctos"

# main directories
CONFIG_DIR="/etc/$NAMESPACE"
INSTALL_DIR="/opt/$NAMESPACE"
STATE_DIR="/var/lib/$NAMESPACE"

declare -l COMPOSITOR="" # lowercase only

# configs
GREETER_CONFIG_FILEPATH="$CONFIG_DIR/greeter.config.json"

FRESH_INSTALL=1
if [[ -d "$CONFIG_DIR" ]]; then
  FRESH_INSTALL=0
fi

graceful_exit() {
  echo
  echo
  echo -e "[EXIT] Process interrupted or failed."
  exit 1
}

detect_compositor() {

  COMPOSITOR="$XDG_CURRENT_DESKTOP"

  if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
    echo
    echo "[ERROR] CTOS only supports Wayland sessions."
    exit 1
  fi
}

setup_state_dir_for_greetd() {
  if [[ -d "$STATE_DIR" ]]; then
    echo "[ITEM]   found: $STATE_DIR (skipping)"
    return 0
  fi

  local cfg="/etc/greetd/config.toml"

  if [[ ! -f "$cfg" ]]; then
    echo "[!][ERROR] /etc/greetd/config not found; cannot set up $STATE_DIR"
    return 0
  fi

  local line=$(grep -E '^[[:space:]]*user[[:space:]]*=' "$cfg" | head -n1 || true)
  if [[ -z "$line" ]]; then
    echo "[ITEM]     n/a: $STATE_DIR (no user in /etc/greetd/config)"
    return 0
  fi

  local user=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*user[[:space:]]*=[[:space:]]*"?([^"]*)"?/\1/')

  sudo mkdir -p "$STATE_DIR"
  sudo chown "$user":"$user" "$STATE_DIR"
  echo "[ITEM] added: $STATE_DIR (owner: $user)"
}

generate_greeter_config() {
  local monitor="$1"

  cat <<EOF
{
  "general": {
    "animations": "all",
    "monitor": "$monitor",
    "exitOverride": [],
    "launchOverride": [],
    "modes": {
      "greetd": {
        "animations": "all",
        "monitor": ""
      },
      "lockd": {
        "animations": "reduced",
        "monitor": ""
      },
      "test": {
        "animations": "all",
        "monitor": ""
      },
      "kiosk": {
        "animations": "all",
        "monitor": ""
      }
    }
  }
}
EOF
}

install_output() {
  local contents="$1"
  local target_path="$2"

  if [[ -f "$target_path" ]]; then
    echo "[ITEM]   found: $target_path (skipping)"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"

  if [[ -z "$contents" ]]; then
    echo
    echo "[!][ERROR] empty input"
    exit 1
  fi

  echo "$contents" | sudo tee "$target_path" >/dev/null

  if [[ $? -eq 0 ]]; then
    echo "[ITEM] added: $target_path"
    return 0
  fi

  echo "error: $target_path"
}

install_file() {
  local source_path="$1"
  local target_path="$2"

  if [[ -f "$target_path" ]]; then
    echo "[ITEM]   found: $target_path (skipping)"
    return 0
  fi

  if [[ ! -f "$source_path" ]]; then
    echo
    echo "[!][ERROR] file not found '$source_path'"
    exit 1
  fi

  local contents
  contents=$(cat "$source_path")

  install_output "$contents" "$target_path"
}

function detect_monitor() {
  case "$COMPOSITOR" in
  "hyprland")
    DEFAULT_MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null)
    ;;
  "niri")
    DEFAULT_MONITOR=$(niri msg -j outputs 2>/dev/null | jq -r 'keys[0]' 2>/dev/null)
    ;;
  esac
}

function run_setup_wizard() {
  echo
  echo "[CTOS INSTALLER]"
  echo

  DEFAULT_USER=$(whoami)
  read -p "[Q] ENTER TARGET USER [$DEFAULT_USER]: " SELECTED_USER
  SELECTED_USER=${SELECTED_USER:-$DEFAULT_USER}

  detect_monitor
  MONITOR_PROMPT=${DEFAULT_MONITOR:+ [$DEFAULT_MONITOR]}
  read -p "[Q] ENTER PRIMARY MONITOR$MONITOR_PROMPT: " SELECTED_MONITOR
  SELECTED_MONITOR=${SELECTED_MONITOR:-$DEFAULT_MONITOR}

  echo
  echo "[BASIC SETTINGS]"
  echo "COMPOSITOR=${COMPOSITOR:-n/a}"
  echo "USER=$SELECTED_USER"
  echo "MONITOR=$SELECTED_MONITOR"
  echo

  read -rp "[Q] Proceed with installation? (y/n) "

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "[EXIT] Installation aborted."
    exit 1
  fi

}

function install_greeter_compositor_config() {
  local scaffold_dir="$SCRIPT_DIR/greeter/examples/"

  declare -A templates=(
    ["hyprland"]="$scaffold_dir/greeter.hyprland.conf"
    ["niri"]="$scaffold_dir/greeter.niri.kdl"
  )

  local config_src=${templates[$COMPOSITOR]}

  local config_dest="$CONFIG_DIR/$(basename "$config_src")"

  if [[ -z "$config_src" ]]; then
    echo "[ITEM]     n/a: $CONFIG_DIR/greeter.<compositor>.<filetype>"
    echo
    echo "  [!] Note: You can ignore above item being n/a if you are using cage."
    echo "      https://github.com/TSM-061/ctOS/tree/main/greeter#other-environments"
    echo
  fi

  if [[ -n "$config_src" ]]; then
    install_file "$config_src" "$config_dest"
    if [[ "$COMPOSITOR" == "hyprland" && -f "$scaffold_dir/greeter.hyprland.lua" ]]; then
      # install lua configuration alongside .conf
      install_file "$scaffold_dir/greeter.hyprland.lua" "$CONFIG_DIR/greeter.hyprland.lua"
    fi
    return 0
  fi
}

function sync_project_files() {
  sudo mkdir -p "$INSTALL_DIR"

  # --delay-updates swaps every file in at the end, so a running bar that hot-reloads mid-sync
  # never sees a half-copied tree (a component whose new dependency hasn't landed yet)
  sudo rsync -ahq \
    --delay-updates \
    --exclude=".git" \
    --exclude=".assets" \
    --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r \
    "$SCRIPT_DIR/" "$INSTALL_DIR"

  # Quickshell only watches files it already loaded: touch the entry points so a running bar or
  # greeter reloads once more with the complete tree, picking up any newly added components
  sudo touch "$INSTALL_DIR/bar.qml" "$INSTALL_DIR/greeter.qml"

  if [[ "$FRESH_INSTALL" -eq 1 ]]; then
    echo "[ITEM]   added: $INSTALL_DIR"
  else
    echo "[ITEM] updated: $INSTALL_DIR"
  fi
}

# --------------------------------------------------------------------------------
# SECTION Optional user setup (runs as the invoking user, no sudo)
# --------------------------------------------------------------------------------

USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_DIR="$USER_CONFIG_DIR/hypr"
CTOS_HYPR_SNIPPET="$HYPR_DIR/ctos.conf"

function ask() {
  local reply

  # no terminal to answer from (e.g. piped or run from a tool): treat as "no", visibly
  if [[ ! -t 0 ]]; then
    echo "[Q] $1 (y/n) -> no terminal input, answering 'n'"
    return 1
  fi

  read -rp "[Q] $1 (y/n) " reply
  [[ $reply =~ ^[Yy]$ ]]
}

# copy a template into the user's config, never overwriting an existing file
function install_user_file() {
  local source_path="$1"
  local target_path="$2"

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    echo "[ITEM]   found: $target_path (skipping)"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"
  cp "$source_path" "$target_path"
  echo "[ITEM]   added: $target_path"
}

# symlink into the install dir so updates apply, never replacing an existing config
function link_user_file() {
  local source_path="$1"
  local target_path="$2"

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    echo "[ITEM]   found: $target_path (skipping)"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  echo "[ITEM]  linked: $target_path -> $source_path"
}

function find_polkit_agent() {
  local candidate
  for candidate in /usr/libexec/hyprpolkitagent /usr/lib/hyprpolkitagent/hyprpolkitagent /usr/lib/hyprpolkitagent; do
    if [[ -f "$candidate" && -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
}

function generate_hyprland_snippet() {
  local polkit_agent="$1"
  local prefix=""

  # launch as uwsm apps when available so they live in the session's systemd scope
  if command -v uwsm >/dev/null; then
    prefix="uwsm app -- "
  fi

  echo "# ctOS session setup, generated by install.sh"
  echo "# sourced from hyprland.conf, delete the 'source' line there to disable"
  echo
  echo "exec-once = ${prefix}env QT_SCALE_FACTOR_ROUNDING_POLICY=Round qs --path $INSTALL_DIR/bar.qml"

  if command -v hyprpaper >/dev/null; then
    echo "exec-once = ${prefix}hyprpaper"
  fi

  if command -v hypridle >/dev/null; then
    echo "exec-once = ${prefix}hypridle"
    echo
    echo "# lock with the ctOS greeter (lock_cmd in hypridle.conf)"
    echo "bind = SUPER, L, exec, loginctl lock-session"
  fi

  if [[ -n "$polkit_agent" ]]; then
    echo
    echo "exec-once = ${prefix}$polkit_agent"
  fi

  if command -v nmtui >/dev/null && command -v kitty >/dev/null; then
    echo
    echo "# full network manager: SUPER+N, or ADVANCED in the bar's network menu"
    echo "bind = SUPER, N, exec, kitty --class ctos-network -e nmtui"
    echo "windowrule {"
    echo "    name = ctos-network"
    echo "    match:class = ^(ctos-network)\$"
    echo "    float = true"
    echo "    size = 900 600"
    echo "    center = true"
    echo "}"
  fi

  if ! command -v hyprland-dialog >/dev/null; then
    echo
    echo "# hyprland-guiutils is not installed; hide the missing-dependency warning"
    echo "misc:disable_hyprland_guiutils_check = true"
  fi
}

# Some distros (e.g. Ubuntu) enable these as systemd user services for every session,
# including other desktops. ctOS starts them from Hyprland instead, so mask the units
# to avoid duplicates. Undo with: systemctl --user unmask <unit>
function mask_duplicate_user_services() {
  local unit state
  for unit in "$@"; do
    state=$(systemctl --user is-enabled "$unit" 2>/dev/null || true)
    if [[ "$state" == "enabled" ]]; then
      systemctl --user mask "$unit" >/dev/null 2>&1
      echo "[ITEM]  masked: $unit (started by ctos.conf instead)"
    fi
  done
}

function setup_hyprland_session() {
  local hypr_conf="$HYPR_DIR/hyprland.conf"

  if ! command -v Hyprland >/dev/null; then
    echo "[ITEM]     n/a: $CTOS_HYPR_SNIPPET (Hyprland not installed)"
    return 0
  fi

  # creating hyprland.conf ourselves would stop Hyprland generating its default config
  if [[ ! -f "$hypr_conf" ]]; then
    echo "[ITEM]     n/a: $CTOS_HYPR_SNIPPET (no $hypr_conf, log into Hyprland once then re-run)"
    return 0
  fi

  if grep -qF "$CTOS_HYPR_SNIPPET" "$hypr_conf"; then
    echo "[ITEM]   found: $CTOS_HYPR_SNIPPET (sourced, skipping)"
    return 0
  fi

  echo
  echo "  Hyprland session: autostart the bar, wallpaper (hyprpaper), idle lock"
  echo "  (hypridle -> ctOS lockscreen) and polkit agent. Adds a 'source' line"
  echo "  to hyprland.conf, a backup is made first."
  echo

  if ! ask "Set up ctOS in your Hyprland session?"; then
    echo "[ITEM] skipped: $CTOS_HYPR_SNIPPET"
    return 0
  fi

  local polkit_agent
  polkit_agent=$(find_polkit_agent)

  if [[ -e "$CTOS_HYPR_SNIPPET" ]]; then
    echo "[ITEM]   found: $CTOS_HYPR_SNIPPET (keeping)"
  else
    generate_hyprland_snippet "$polkit_agent" >"$CTOS_HYPR_SNIPPET"
    echo "[ITEM]   added: $CTOS_HYPR_SNIPPET"
  fi

  local backup="$hypr_conf.bak.$(date +%Y%m%d%H%M%S)"
  cp "$hypr_conf" "$backup"
  echo "[ITEM]  backup: $backup"

  # the autogenerated flag only shows a warning banner
  sed -i '/^[[:space:]]*autogenerated[[:space:]]*=[[:space:]]*1/d' "$hypr_conf"
  printf '\n# ctOS\nsource = %s\n' "$CTOS_HYPR_SNIPPET" >>"$hypr_conf"
  echo "[ITEM] updated: $hypr_conf"

  local services=()

  if command -v hyprpaper >/dev/null; then
    install_user_file "$INSTALL_DIR/extras/.config/hypr/hyprpaper.conf" "$HYPR_DIR/hyprpaper.conf"
    services+=(hyprpaper.service)
  fi

  if command -v hypridle >/dev/null; then
    install_user_file "$INSTALL_DIR/extras/.config/hypr/hypridle.conf" "$HYPR_DIR/hypridle.conf"
    services+=(hypridle.service)
  fi

  if [[ -n "$polkit_agent" ]]; then
    services+=(hyprpolkitagent.service)
  fi

  if [[ ${#services[@]} -gt 0 ]]; then
    mask_duplicate_user_services "${services[@]}"
  fi
}

# append 'source = <file>' to hyprland.conf once, after a backup
function add_hypr_source() {
  local file="$1"
  local hypr_conf="$HYPR_DIR/hyprland.conf"

  local backup="$hypr_conf.bak.$(date +%Y%m%d%H%M%S)"
  cp "$hypr_conf" "$backup"
  echo "[ITEM]  backup: $backup"

  printf 'source = %s\n' "$file" >>"$hypr_conf"
  echo "[ITEM] updated: $hypr_conf (sources $file)"
}

function setup_hyprland_look() {
  local look="$INSTALL_DIR/extras/.config/hypr/ctos-look.conf"
  local hypr_conf="$HYPR_DIR/hyprland.conf"

  if ! command -v Hyprland >/dev/null || [[ ! -f "$hypr_conf" ]]; then
    echo "[ITEM]     n/a: ctOS window look (Hyprland or $hypr_conf missing)"
    return 0
  fi

  if grep -qF "$look" "$hypr_conf"; then
    echo "[ITEM]   found: $look (sourced, skipping)"
    return 0
  fi

  echo
  echo "  Window look: square 2px frames, narrow gaps, no shadows or blur, ctOS"
  echo "  animation curves. Overrides those settings in hyprland.conf, a backup is"
  echo "  made first."
  echo

  if ! ask "Apply the ctOS window look?"; then
    echo "[ITEM] skipped: $look"
    return 0
  fi

  add_hypr_source "$look"
}

function setup_hyprbars() {
  local bars="$INSTALL_DIR/extras/.config/hypr/ctos-hyprbars.conf"
  local hypr_conf="$HYPR_DIR/hyprland.conf"

  if ! command -v hyprpm >/dev/null || [[ ! -f "$hypr_conf" ]]; then
    echo "[ITEM]     n/a: ctOS title strips (hyprpm or $hypr_conf missing)"
    return 0
  fi

  if grep -qF "$bars" "$hypr_conf"; then
    echo "[ITEM]   found: $bars (sourced, skipping)"
    return 0
  fi

  # hyprpm compiles the plugin; check its build tools before offering it
  local tool missing=()
  for tool in cmake cpio pkg-config git g++ gcc; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  if ((${#missing[@]})); then
    echo "[ITEM]     n/a: ctOS title strips (hyprpm needs: ${missing[*]})"
    return 0
  fi

  echo
  echo "  Title strips: a thin ctOS title strip on every window, drawn by the"
  echo "  hyprbars plugin. Builds the plugin with hyprpm (asks for sudo, needs"
  echo "  build tools). Plugins can break on Hyprland updates: if that happens,"
  echo "  remove the 'source' line for ctos-hyprbars.conf from hyprland.conf."
  echo

  if ! ask "Install hyprbars title strips?"; then
    echo "[ITEM] skipped: $bars"
    return 0
  fi

  if ! hyprpm update ||
    ! { hyprpm list | grep -q hyprbars || hyprpm add https://github.com/hyprwm/hyprland-plugins; } ||
    ! hyprpm enable hyprbars; then
    echo "[ITEM]  failed: hyprbars (see hyprpm output above, skipping)"
    return 0
  fi
  echo "[ITEM] enabled: hyprbars"

  add_hypr_source "$bars"
}

function install_terminal_extras() {
  local extras="$INSTALL_DIR/extras/.config"
  local -a links=(
    "$extras/kitty/kitty.conf:$USER_CONFIG_DIR/kitty/kitty.conf"
    "$extras/kitty/themes:$USER_CONFIG_DIR/kitty/themes"
    "$extras/fastfetch/config.jsonc:$USER_CONFIG_DIR/fastfetch/config.jsonc"
    "$extras/fastfetch/dedsec.txt:$USER_CONFIG_DIR/fastfetch/dedsec.txt"
  )

  local pair missing=0
  for pair in "${links[@]}"; do
    if [[ ! -e "${pair#*:}" && ! -L "${pair#*:}" ]]; then
      missing=1
    fi
  done

  if [[ "$missing" -eq 0 ]]; then
    echo "[ITEM]   found: kitty/fastfetch extras (skipping)"
    return 0
  fi

  echo
  echo "  Terminal extras: kitty theme (Monoglow) and fastfetch (DedSec logo)."
  echo "  Existing configs are left untouched."
  echo

  if ! ask "Install terminal extras?"; then
    echo "[ITEM] skipped: kitty/fastfetch extras"
    return 0
  fi

  for pair in "${links[@]}"; do
    link_user_file "${pair%%:*}" "${pair#*:}"
  done
}

# --------------------------------------------------------------------------------
# SECTION Main
# --------------------------------------------------------------------------------

trap graceful_exit ERR SIGINT SIGTERM

detect_compositor

if [[ "$FRESH_INSTALL" -eq 1 || ! -f "$GREETER_CONFIG_FILEPATH" ]]; then
  run_setup_wizard
  sudo mkdir -p "$CONFIG_DIR"
fi

echo

install_output "$(generate_greeter_config "$SELECTED_MONITOR")" "$GREETER_CONFIG_FILEPATH"

setup_state_dir_for_greetd

install_greeter_compositor_config

sync_project_files

# user configs belong to the invoking user, skip if the script itself was run as root
if [[ "$EUID" -ne 0 ]]; then
  echo
  echo "[OPTIONAL]"
  setup_hyprland_session
  setup_hyprland_look
  setup_hyprbars
  install_terminal_extras
else
  echo
  echo "[ITEM]     n/a: optional user setup (run install.sh as your user, not with sudo)"
fi

if [[ "$FRESH_INSTALL" -eq 1 ]]; then
  echo
  echo "[WARN] This installation assumes you are using 'uwsm', if not "
  echo "       change the launch/exit commands in $(basename "$GREETER_CONFIG_FILEPATH")."
fi

echo
echo "[EXIT] SUCCESSFULLY COMPLETED."
