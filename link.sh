#!/usr/bin/env bash
#
# Sevens-Dots Installer - Refactored with Defensive Bash Principles
# Version: 2.0
#
set -Eeuo pipefail
IFS=$'\n\t'

# ==========================
# CONFIGURATION
# ==========================

#readonly REPO_URL="https://github.com/saatvik333/niri-dotfiles.git"
readonly DOTDIR="${HOME}/niri-dots"
readonly CONFIG_DIR="${HOME}/.config"
readonly BACKUP_DIR="${HOME}/.config_backup_$(date +%Y%m%d_%H%M%S)"
readonly LOG_DIR="${HOME}/.cache"
readonly LOG_FILE="${LOG_DIR}/niri-dots-install-$(date +%Y%m%d_%H%M%S).log"

# Temporary directory for builds (will be cleaned up)
TEMP_BUILD_DIR=""

# AUR helper choice (will be set interactively)
AUR_HELPER=""

# Progress tracking
CURRENT_STEP=0
readonly TOTAL_STEPS=19

# Installation summary tracking
declare -a INSTALL_SUMMARY=()

# Shell configuration choices (will be set interactively)
CONFIGURE_FISH=false
CONFIGURE_ZSH=false

# Process ID for sudo keep-alive
SUDO_PID=""

# Expected configuration folders in the repo
readonly CONFIG_FOLDERS=(
  niri waybar fish zsh fastfetch mako alacritty kitty starship
  nvim yazi vicinae zathura wallust rofi scripts hypr sunsetr
  matugen gtk-3.0 gtk-4.0 fresh
)

# Optional dependencies that waybar modules depend on
readonly OPTIONAL_AUDIO_PACKAGES=("pulseaudio" "pipewire-pulse")
readonly OPTIONAL_BLUETOOTH_PACKAGES=("bluez" "bluez-utils")

# AUR packages to install
readonly AUR_PACKAGES=(
  vicinae-bin
  wallust
  dust
  eza
  niri-switch
  ttf-nerd-fonts-symbols
  pavucontrol
  thunar
  minizip
  awww-git
)

# Official repository packages
readonly PACMAN_PACKAGES=(
  niri waybar fish fastfetch mako alacritty kitty starship neovim yazi
  zathura zathura-pdf-mupdf ttf-jetbrains-mono-nerd
  qt5-wayland qt6-wayland polkit-gnome ffmpeg imagemagick unzip jq
  gtklock rofi curl libnotify
)

# ==========================
# COLOR OUTPUT
# ==========================

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'


# ==========================
# LOGGING & OUTPUT FUNCTIONS
# ==========================

log() {
  local timestamp
  timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
  printf "[%s] %s\n" "${timestamp}" "$*" >> "${LOG_FILE}" 2>/dev/null || true
}

msg() {
  printf "${GREEN}==>${NC} %s\n" "$1"
  log "INFO: $1"
}

info() {
  printf "${BLUE}==>${NC} %s\n" "$1"
  log "INFO: $1"
}

warn() {
  printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
  log "WARNING: $1"
}

error() {
  printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
  log "ERROR: $1"
}

fatal() {
  error "$1"
  error "Installation failed. Check log file: ${LOG_FILE}"
  exit 1
}

step() {
  ((++CURRENT_STEP)) || true
  printf "\n"
  printf "${CYAN}${BOLD}[Step %d/%d]${NC} ${MAGENTA}%s${NC}\n" "${CURRENT_STEP}" "${TOTAL_STEPS}" "$1"
  printf "${CYAN}─────────────────────────────────────────────────────────${NC}\n"
  log "STEP ${CURRENT_STEP}/${TOTAL_STEPS}: $1"
}

separator() {
  printf "\n"
  printf "${BLUE}═════════════════════════════════════════════════════════${NC}\n"
  printf "\n"
}

add_summary() {
  INSTALL_SUMMARY+=("$1")
}


# ==========================
# USAGE & HELP
# ==========================

usage() {
  cat << EOF
Usage: ${0##*/} [OPTIONS]

Sevens-Dots Installer - Automated setup for Niri window manager configuration

OPTIONS:
  -h, --help     Display this help message and exit
  -v, --version  Display version information

DESCRIPTION:
  This script automates the installation and configuration of a complete
  Niri-based desktop environment on Arch Linux systems.

REQUIREMENTS:
  - Arch Linux or Arch-based distribution
  - Active internet connection
  - Sudo privileges
  - At least 5GB free disk space

CONFIGURATION:
  The script will clone dotfiles from:
    ${REPO_URL}

  Installation directory:
    ${DOTDIR}

  Configuration will be symlinked to:
    ${CONFIG_DIR}

LOG FILE:
  Installation logs are saved to:
    ${LOG_FILE}

EXAMPLES:
  ${0##*/}              # Run interactive installation
  ${0##*/} --help       # Display this help message

REPORT BUGS:
  https://github.com/saatvik333/niri-dotfiles/issues

EOF
}

version() {
  printf "Sevens-Dots Installer v2.0\n"
  printf "Defensive Bash Refactored Edition\n"
}

# ==========================
# CLEANUP FUNCTIONS
# ==========================

cleanup_temp_files() {
  if [[ -n "${TEMP_BUILD_DIR}" ]] && [[ -d "${TEMP_BUILD_DIR}" ]]; then
    info "Cleaning up temporary build directory..."
    rm -rf "${TEMP_BUILD_DIR}" 2>/dev/null || true
  fi
}

cleanup_sudo_keepalive() {
  if [[ -n "${SUDO_PID}" ]] && kill -0 "${SUDO_PID}" 2>/dev/null; then
    kill "${SUDO_PID}" 2>/dev/null || true
    wait "${SUDO_PID}" 2>/dev/null || true
  fi
}

cleanup_on_exit() {
  local exit_code=$?
  cleanup_sudo_keepalive
  cleanup_temp_files

  if [[ ${exit_code} -ne 0 ]]; then
    error "Script exited with error code: ${exit_code}"
  fi
}

cleanup_on_error() {
  local line_no=$1
  error "Error occurred on line ${line_no}"
  offer_restore
  cleanup_on_exit
}

# ==========================
# UTILITY FUNCTIONS
# ==========================

retry_command() {
  local max_attempts="$1"
  shift
  local cmd=("$@")
  local attempt=1

  while [[ ${attempt} -le ${max_attempts} ]]; do
    if "${cmd[@]}"; then
      return 0
    fi

    if [[ ${attempt} -lt ${max_attempts} ]]; then
      local wait_time=$((attempt * 2))
      warn "Command failed (attempt ${attempt}/${max_attempts}). Retrying in ${wait_time} seconds..."
      sleep "${wait_time}"
    fi
    ((attempt++)) || true
  done

  return 1
}

check_internet() {
  info "Checking internet connectivity..."

  if ! command -v curl &>/dev/null; then
    warn "curl not found, will be installed with base tools"
    return 0
  fi

  local endpoints=(
    "https://archlinux.org"
    "https://google.com"
    "https://cloudflare.com"
  )
  local connected=false

  for endpoint in "${endpoints[@]}"; do
    if curl -s --connect-timeout 5 --max-time 10 "${endpoint}" >/dev/null 2>&1; then
      connected=true
      break
    fi
  done

  if [[ "${connected}" == "false" ]]; then
    fatal "No internet connection. Please connect to the internet and try again."
  fi

  msg "Internet connection verified."

  info "Testing connection quality..."
  if ! curl -s --connect-timeout 2 --max-time 5 https://archlinux.org >/dev/null 2>&1; then
    warn "Network connection appears slow. Installation may take longer than usual."
  fi
}

check_arch_based() {
  info "Verifying Arch-based system..."

  if ! command -v pacman &>/dev/null; then
    fatal "This script requires pacman package manager (Arch-based distribution)."
  fi

  local distro_name="Unknown"
  local is_arch_based=false

  if [[ -f /etc/os-release ]]; then
    distro_name="$(grep -E '^NAME=' /etc/os-release | cut -d'"' -f2)"

    if grep -qE '^ID=arch$' /etc/os-release || \
       grep -qE '^ID_LIKE=.*arch.*' /etc/os-release || \
       [[ -f /etc/arch-release ]]; then
      is_arch_based=true
    fi

    if [[ "${is_arch_based}" == "false" ]]; then
      fatal "This script is designed for Arch-based distributions only. Detected: ${distro_name}"
    fi
  fi

  msg "Arch-based system detected: ${distro_name}"
}

check_disk_space() {
  info "Checking available disk space..."
  local available_mb
  available_mb="$(df -P -BM "${HOME}" | tail -n 1 | awk '{print $4}' | sed 's/M//')"

  if [[ ${available_mb} -lt 5000 ]]; then
    warn "Low disk space detected: ${available_mb}MB available"
    warn "Installation requires at least 5GB free space for packages and builds"
    warn "You may encounter issues during installation"
    printf "\n"

    local reply
    read -r -p "Continue anyway? (y/N): " reply < /dev/tty
    printf "\n"

    if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
      fatal "Installation cancelled by user"
    fi
  else
    msg "Sufficient disk space available: ${available_mb}MB"
  fi
}

check_not_root() {
  if [[ ${EUID} -eq 0 ]]; then
    fatal "Do not run this script as root. Run as a regular user with sudo privileges."
  fi
}

check_sudo() {
  info "Verifying sudo privileges..."
  if ! sudo -v; then
    fatal "Sudo privileges required. Please ensure you have sudo access."
  fi

  (
    while true; do
      sudo -v
      sleep 50
    done
  ) &
  SUDO_PID=$!

  msg "Sudo privileges verified."
}

check_optional_dependencies() {
  info "Checking optional dependencies for waybar modules..."

  local missing_audio=true
  local missing_bluetooth=true
  local warnings=()

  # Check for audio backend
  for pkg in "${OPTIONAL_AUDIO_PACKAGES[@]}"; do
    if pacman -Qi "${pkg}" &>/dev/null; then
      missing_audio=false
      break
    fi
  done

  # Check for Bluetooth backend
  for pkg in "${OPTIONAL_BLUETOOTH_PACKAGES[@]}"; do
    if pacman -Qi "${pkg}" &>/dev/null; then
      missing_bluetooth=false
      break
    fi
  done

  # Display warnings if dependencies are missing
  if [[ "${missing_audio}" == "true" ]] || [[ "${missing_bluetooth}" == "true" ]]; then
    printf "\n"
    warn "Missing optional dependencies detected:"
    printf "\n"

    if [[ "${missing_audio}" == "true" ]]; then
      warnings+=("Audio backend (PulseAudio/PipeWire)")
      printf "${YELLOW}⚠${NC}  ${BOLD}Audio Backend:${NC} Not detected\n"
      printf "   Waybar's audio module will not display.\n"
      printf "   Install one of: ${CYAN}pulseaudio${NC} or ${CYAN}pipewire-pulse${NC}\n"
      printf "   Example: ${CYAN}sudo pacman -S pipewire-pulse${NC}\n"
      printf "\n"
    fi

    if [[ "${missing_bluetooth}" == "true" ]]; then
      warnings+=("Bluetooth backend (bluez)")
      printf "${YELLOW}⚠${NC}  ${BOLD}Bluetooth Backend:${NC} Not detected\n"
      printf "   Waybar's Bluetooth module will not display.\n"
      printf "   Install: ${CYAN}bluez bluez-utils${NC}\n"
      printf "   Example: ${CYAN}sudo pacman -S bluez bluez-utils${NC}\n"
      printf "\n"
    fi

    printf "${BLUE}${BOLD}Note:${NC} These are workflow-dependent choices:\n"
    printf "  • Some users prefer PipeWire, others prefer PulseAudio\n"
    printf "  • Not everyone needs Bluetooth functionality\n"
    printf "  • You can install these manually later if needed\n"
    printf "\n"

    local reply
    read -r -p "Continue installation without these optional dependencies? (Y/n): " reply < /dev/tty
    printf "\n"

    if [[ "${reply}" =~ ^[Nn]$ ]]; then
      fatal "Installation cancelled by user. Please install required dependencies and re-run."
    fi

    msg "Continuing with installation (missing: ${warnings[*]})"
  else
    msg "All optional dependencies for waybar modules are installed."
  fi
}

verify_binary() {
  local binary="$1"
  if ! command -v "${binary}" &>/dev/null; then
    error "Binary '${binary}' not found in PATH."
    return 1
  fi
  return 0
}

# ==========================
# BACKUP FUNCTIONS
# ==========================

create_backup() {
  msg "Creating backup of existing configurations..."
  mkdir -p "${BACKUP_DIR}"
  mkdir -p "${CONFIG_DIR}"

  local backed_up=0
  local symlinks_found=0

  for folder in "${CONFIG_FOLDERS[@]}"; do
    local target="${CONFIG_DIR}/${folder}"
    if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
      if [[ -L "${target}" ]]; then
        local link_target
        link_target="$(readlink "${target}")"
        warn "Symlink detected: ${folder} -> ${link_target}"
        ((++symlinks_found)) || true
        rm "${target}"
        info "Removed symlink: ${folder}"
      elif cp -rL "${target}" "${BACKUP_DIR}/" 2>/dev/null; then
        rm -rf "${target}"
        info "Backed up: ${folder}"
        ((++backed_up)) || true
      else
        warn "Failed to backup: ${folder}"
      fi
    fi
  done

  if [[ ${symlinks_found} -gt 0 ]]; then
    warn "Found ${symlinks_found} symlink(s). These were removed without backup."
    warn "If they pointed to important data, you may want to restore them manually."
  fi

  if [[ ${backed_up} -gt 0 ]]; then
    msg "Backed up ${backed_up} configuration(s) to: ${BACKUP_DIR}"
  else
    info "No existing configurations found to backup."
  fi
}

offer_restore() {
  if [[ -d "${BACKUP_DIR}" ]] && [[ -n "$(ls -A "${BACKUP_DIR}" 2>/dev/null)" ]]; then
    printf "\n"
    warn "Installation encountered an error."
    printf "${YELLOW}Your previous configurations are backed up at:${NC}\n"
    printf "  %s\n" "${BACKUP_DIR}"
    printf "\n"

    local reply
    read -r -p "Would you like to restore your backup now? (y/N): " reply < /dev/tty
    printf "\n"

    if [[ "${reply}" =~ ^[Yy]$ ]]; then
      restore_backup
    fi
  fi
}

restore_backup() {
  info "Restoring backup..."

  for folder in "${BACKUP_DIR}"/*; do
    if [[ -e "${folder}" ]]; then
      local basename
      basename="$(basename "${folder}")"
      rm -rf "${CONFIG_DIR:?}/${basename}"
      mv "${folder}" "${CONFIG_DIR}/"
      info "Restored: ${basename}"
    fi
  done

  msg "Backup restored successfully."
}

# ==========================
# PACKAGE MANAGEMENT
# ==========================

update_system() {
  info "Updating system packages..."
  if sudo pacman -Syu --noconfirm >>"${LOG_FILE}" 2>&1; then
    msg "System updated successfully."
  else
    fatal "Failed to update system packages."
  fi
}

install_base_tools() {
  info "Installing base development tools..."
  if sudo pacman -S --needed --noconfirm git base-devel curl >>"${LOG_FILE}" 2>&1; then
    msg "Base tools installed."
  else
    fatal "Failed to install base development tools."
  fi
}

choose_aur_helper() {
  info "Checking for AUR helper..."

  if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    msg "yay AUR helper already installed."
    return 0
  fi

  AUR_HELPER="yay"
  install_yay
}

install_yay() {
  info "Installing yay AUR helper..."

  if sudo pacman -S --noconfirm yay >>"${LOG_FILE}" 2>&1; then
    msg "yay installed from official repository."
    return 0
  fi

  info "yay not in official repos, building from AUR..."
  TEMP_BUILD_DIR="$(mktemp -d)"

  if [[ ! -d "${TEMP_BUILD_DIR}" ]]; then
    fatal "Failed to create temporary directory for yay build"
  fi

  info "Cloning yay repository (this may take a moment)..."
  if ! retry_command 3 git clone --depth=1 https://aur.archlinux.org/yay-bin.git "${TEMP_BUILD_DIR}" >>"${LOG_FILE}" 2>&1; then
    fatal "Failed to clone yay repository after multiple attempts."
  fi

  info "Building yay package (this may take a few minutes)..."
  if ! (cd "${TEMP_BUILD_DIR}" && makepkg -si --noconfirm >>"${LOG_FILE}" 2>&1); then
    fatal "Failed to build and install yay."
  fi

  info "Cleaning up yay build directory..."
  cleanup_temp_files
  TEMP_BUILD_DIR=""

  if verify_binary yay; then
    msg "yay installed successfully from AUR."
  else
    fatal "yay installation completed but binary not found."
  fi
}

install_pacman_packages() {
  info "Installing official repository packages..."
  info "This may take several minutes..."

  if sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}" 2>&1 | tee -a "${LOG_FILE}"; then
    msg "Official packages installed successfully."
  else
    fatal "Failed to install official repository packages."
  fi
}

cargo_fix() {
  info "Checking Rust toolchain configuration..."

  # Check if rustup is installed
  if ! command -v rustup &> /dev/null; then
    info "rustup not found, installing..."
    if sudo pacman -S --needed --noconfirm rustup >> "$LOG_FILE" 2>&1; then
      msg "rustup installed successfully."
    else
      warn "Failed to install rustup. Some AUR packages may fail to build."
      return 1
    fi
  fi

  # Set default toolchain to stable
  info "Setting Rust default toolchain to stable..."
  if rustup default stable >> "$LOG_FILE" 2>&1; then
    msg "Rust toolchain configured: stable (default)"
  else
    warn "Failed to set default Rust toolchain. Some AUR packages may fail to build."
    return 1
  fi

  return 0
}

install_aur_packages() {
  info "Installing AUR packages using ${AUR_HELPER}..."
  info "This may take several minutes..."

  if "${AUR_HELPER}" -S --needed --noconfirm "${AUR_PACKAGES[@]}" 2>&1 | tee -a "${LOG_FILE}"; then
    msg "AUR packages installed successfully."
  else
    fatal "Failed to install AUR packages."
  fi
}

install_colloid_theme() {
  local theme_dir
  theme_dir="$(mktemp -d)"

  if [[ ! -d "${theme_dir}" ]]; then
    warn "Failed to create temporary directory for Colloid theme"
    return 1
  fi

  info "Installing Colloid GTK theme..."
  info "Cloning Colloid theme repository (this may take a moment)..."

  if ! retry_command 3 git clone --depth=1 https://github.com/vinceliuice/Colloid-gtk-theme "${theme_dir}" >>"${LOG_FILE}" 2>&1; then
    rm -rf "${theme_dir}"
    warn "Failed to clone Colloid theme repository after multiple attempts."
    return 1
  fi

  info "Installing Colloid theme variants..."
  if ! (cd "${theme_dir}" && ./install.sh --libadwaita --tweaks all rimless >>"${LOG_FILE}" 2>&1); then
    rm -rf "${theme_dir}"
    warn "Failed to install Colloid theme (default variant)."
    return 1
  fi

  info "Installing Colloid theme (grey-black variant)..."
  if ! (cd "${theme_dir}" && ./install.sh --libadwaita --theme grey --tweaks black rimless >>"${LOG_FILE}" 2>&1); then
    rm -rf "${theme_dir}"
    warn "Failed to install Colloid theme (grey-black variant)."
    return 1
  fi

  rm -rf "${theme_dir}"
  msg "Colloid GTK theme installed successfully."
  return 0
}

install_rosepine_theme() {
  local theme_dir
  theme_dir="$(mktemp -d)"

  if [[ ! -d "${theme_dir}" ]]; then
    warn "Failed to create temporary directory for Rose Pine theme"
    return 1
  fi

  info "Installing Rose Pine GTK theme..."
  info "Cloning Rose Pine theme repository (this may take a moment)..."

  if ! retry_command 3 git clone --depth=1 https://github.com/Fausto-Korpsvart/Rose-Pine-GTK-Theme "${theme_dir}" >>"${LOG_FILE}" 2>&1; then
    rm -rf "${theme_dir}"
    warn "Failed to clone Rose Pine theme repository after multiple attempts."
    return 1
  fi

  info "Installing Rose Pine theme with moon variant..."
  if ! (cd "${theme_dir}/themes" && ./install.sh --libadwaita --tweaks moon macos >>"${LOG_FILE}" 2>&1); then
    rm -rf "${theme_dir}"
    warn "Failed to install Rose Pine theme."
    return 1
  fi

  rm -rf "${theme_dir}"
  msg "Rose Pine GTK theme installed successfully."
  return 0
}

install_osaka_theme() {
  local theme_dir
  theme_dir="$(mktemp -d)"

  if [[ ! -d "${theme_dir}" ]]; then
    warn "Failed to create temporary directory for Osaka theme"
    return 1
  fi

  info "Installing Osaka GTK theme..."
  info "Cloning Osaka theme repository (this may take a moment)..."

  if ! retry_command 3 git clone --depth=1 https://github.com/Fausto-Korpsvart/Osaka-GTK-Theme "${theme_dir}" >>"${LOG_FILE}" 2>&1; then
    rm -rf "${theme_dir}"
    warn "Failed to clone Osaka theme repository after multiple attempts."
    return 1
  fi

  info "Installing Osaka theme with solarized variant..."
  if ! (cd "${theme_dir}/themes" && ./install.sh --libadwaita --tweaks solarized macos >>"${LOG_FILE}" 2>&1); then
    rm -rf "${theme_dir}"
    warn "Failed to install Osaka theme."
    return 1
  fi

  rm -rf "${theme_dir}"
  msg "Osaka GTK theme installed successfully."
  return 0
}

install_gtk_themes() {
  info "Installing GTK themes..."
  info "This may take several minutes..."

  local themes_dir="${HOME}/.themes"
  mkdir -p "${themes_dir}"

  local installed_themes=()
  local failed_themes=()

  if install_colloid_theme; then
    installed_themes+=("Colloid")
  else
    failed_themes+=("Colloid")
  fi

  if install_rosepine_theme; then
    installed_themes+=("Rose-Pine")
  else
    failed_themes+=("Rose-Pine")
  fi

  if install_osaka_theme; then
    installed_themes+=("Osaka")
  else
    failed_themes+=("Osaka")
  fi

  if [[ ${#installed_themes[@]} -gt 0 ]]; then
    msg "Successfully installed ${#installed_themes[@]} GTK theme(s): ${installed_themes[*]}"
  fi

  if [[ ${#failed_themes[@]} -gt 0 ]]; then
    warn "Failed to install ${#failed_themes[@]} GTK theme(s): ${failed_themes[*]}"
    warn "You can manually install these themes later if needed."
  fi

  if [[ ${#installed_themes[@]} -eq 0 ]]; then
    error "All GTK themes failed to install."
    return 1
  fi

  return 0
}

install_colloid_icons() {
  local icons_dir
  icons_dir="$(mktemp -d)"

  if [[ ! -d "${icons_dir}" ]]; then
    warn "Failed to create temporary directory for Colloid icons"
    return 1
  fi

  info "Installing Colloid icon theme..."
  info "Cloning Colloid icon theme repository (this may take a moment)..."

  if ! retry_command 3 git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme "${icons_dir}" >>"${LOG_FILE}" 2>&1; then
    rm -rf "${icons_dir}"
    warn "Failed to clone Colloid icon theme repository after multiple attempts."
    return 1
  fi

  info "Installing Colloid icon theme with all schemes (bold)..."
  if ! (cd "${icons_dir}" && ./install.sh --scheme all --bold >>"${LOG_FILE}" 2>&1); then
    rm -rf "${icons_dir}"
    warn "Failed to install Colloid icon theme."
    return 1
  fi

  rm -rf "${icons_dir}"
  msg "Colloid icon theme installed successfully."
  return 0
}

install_icon_themes() {
  info "Installing icon themes..."
  info "This may take several minutes..."

  local icons_dir="${HOME}/.icons"
  mkdir -p "${icons_dir}"

  local installed_icons=()
  local failed_icons=()

  if install_colloid_icons; then
    installed_icons+=("Colloid")
  else
    failed_icons+=("Colloid")
  fi

  if [[ ${#installed_icons[@]} -gt 0 ]]; then
    msg "Successfully installed ${#installed_icons[@]} icon theme(s): ${installed_icons[*]}"
  fi

  if [[ ${#failed_icons[@]} -gt 0 ]]; then
    warn "Failed to install ${#failed_icons[@]} icon theme(s): ${failed_icons[*]}"
    warn "You can manually install these icon themes later if needed."
  fi

  if [[ ${#installed_icons[@]} -eq 0 ]]; then
    error "All icon themes failed to install."
    return 1
  fi

  return 0
}

verify_all_binaries() {
  info "Verifying all required binaries are installed..."
  local missing_binaries=()
  local binaries_to_check=(
    niri waybar fish fastfetch mako alacritty kitty starship
    nvim yazi vicinae gtklock zathura wallust awww rofi
  )

  for binary in "${binaries_to_check[@]}"; do
    if ! verify_binary "${binary}"; then
      missing_binaries+=("${binary}")
    fi
  done

  if [[ ${#missing_binaries[@]} -gt 0 ]]; then
    error "The following required binaries are missing:"
    printf '  - %s\n' "${missing_binaries[@]}"
    fatal "Please install missing packages manually and re-run the script."
  fi

  msg "All required binaries verified."
}

# ==========================
# SHELL MANAGEMENT
# ==========================

configure_shells() {
  info "Shell configuration setup..."
  printf "\n"
  printf "${BLUE}${BOLD}Which shell configuration(s) would you like to set up?${NC}\n"
  printf "\n"
  printf "${CYAN}This will install and configure the selected shell(s) with the dotfiles.${NC}\n"
  printf "\n"
  printf "  1) Fish only      - Modern, user-friendly shell with auto-suggestions\n"
  printf "  2) Zsh only       - Powerful, highly customizable shell\n"
  printf "  3) Both Fish & Zsh - Set up both shell configurations\n"
  printf "  4) Neither        - Skip shell configuration (keep current setup)\n"
  printf "\n"

  local reply
  read -r -p "Enter your choice (1-4) [default: 3]: " reply < /dev/tty
  printf "\n"

  case "${reply}" in
    1)
      CONFIGURE_FISH=true
      CONFIGURE_ZSH=false
      msg "Selected: Fish shell configuration"
      ;;
    2)
      CONFIGURE_FISH=false
      CONFIGURE_ZSH=true
      msg "Selected: Zsh shell configuration"
      ;;
    4)
      CONFIGURE_FISH=false
      CONFIGURE_ZSH=false
      msg "Selected: No shell configuration"
      info "Skipping shell setup. You can configure shells manually later."
      return 0
      ;;
    *)
      CONFIGURE_FISH=true
      CONFIGURE_ZSH=true
      msg "Selected: Both Fish and Zsh configurations"
      ;;
  esac

  local shells_to_install=()

  if [[ "${CONFIGURE_FISH}" == "true" ]] && ! verify_binary fish; then
    shells_to_install+=("fish")
  fi

  if [[ "${CONFIGURE_ZSH}" == "true" ]] && ! verify_binary zsh; then
    shells_to_install+=("zsh")
  fi

  if [[ ${#shells_to_install[@]} -gt 0 ]]; then
    info "Installing selected shell(s): ${shells_to_install[*]}"
    if sudo pacman -S --needed --noconfirm "${shells_to_install[@]}" >>"${LOG_FILE}" 2>&1; then
      msg "Shell(s) installed successfully."
    else
      warn "Failed to install some shells. They may already be installed."
    fi
  else
    info "Selected shell(s) already installed."
  fi

  local configured_shells=()
  [[ "${CONFIGURE_FISH}" == "true" ]] && configured_shells+=("Fish")
  [[ "${CONFIGURE_ZSH}" == "true" ]] && configured_shells+=("Zsh")

  if [[ ${#configured_shells[@]} -gt 0 ]]; then
    msg "Shell configuration(s) ready: ${configured_shells[*]}"
  fi

  if [[ "${CONFIGURE_ZSH}" == "true" ]]; then
    info "Configuring Zsh..."
    local zshrc="${HOME}/.zshrc"

    # Backup existing .zshrc if it exists and is not a symlink to our config
    if [[ -f "${zshrc}" ]] && ! grep -q "source.*config.zsh" "${zshrc}"; then
      mv "${zshrc}" "${zshrc}.backup.$(date +%s)"
      info "Backed up existing .zshrc"
    fi

    # Create .zshrc with just the source command and skip wizard magic
    cat > "${zshrc}" <<EOF
# Source sevens-dots configuration
source \${HOME}/.config/zsh/config.zsh

# Prevent zsh-newuser-install wizard
zstyle :compinstall filename '${HOME}/.zshrc'
EOF
    msg "Configured .zshrc to source config.zsh"
  fi
}

set_default_shell() {
  if [[ "${CONFIGURE_FISH}" == "false" ]] && [[ "${CONFIGURE_ZSH}" == "false" ]]; then
    info "No shell configurations were set up. Skipping default shell selection."
    return 0
  fi

  info "Checking default shell..."
  local current_shell
  current_shell="$(getent passwd "${USER}" | cut -d: -f7)"
  local current_shell_name
  current_shell_name="$(basename "${current_shell}")"

  printf "\n"
  printf "${BLUE}Your current shell is:${NC} %s (%s)\n" "${current_shell_name}" "${current_shell}"
  printf "\n"
  printf "${YELLOW}Would you like to change your default shell?${NC}\n"

  local option_num=1
  declare -A shell_options

  printf "  %d) Keep current shell (%s)\n" "${option_num}" "${current_shell_name}"
  ((option_num++)) || true

  if [[ "${CONFIGURE_ZSH}" == "true" ]]; then
    shell_options[${option_num}]="zsh"
    printf "  %d) zsh   - Z Shell (powerful, highly customizable)\n" "${option_num}"
    ((option_num++)) || true
  fi

  if [[ "${CONFIGURE_FISH}" == "true" ]]; then
    shell_options[${option_num}]="fish"
    printf "  %d) fish  - Friendly Interactive Shell (user-friendly, modern)\n" "${option_num}"
    ((option_num++)) || true
  fi

  local max_option=$((option_num - 1))
  printf "\n"

  local reply
  read -r -p "Enter your choice (1-${max_option}) [default: 1]: " reply < /dev/tty
  printf "\n"

  if [[ -z "${reply}" ]] || [[ "${reply}" == "1" ]]; then
    msg "Keeping current shell: ${current_shell_name}"
    return 0
  fi

  if [[ ! "${reply}" =~ ^[0-9]+$ ]] || [[ ${reply} -lt 1 ]] || [[ ${reply} -gt ${max_option} ]]; then
    warn "Invalid selection. Keeping current shell: ${current_shell_name}"
    return 0
  fi

  local shell_name="${shell_options[${reply}]}"
  if [[ -z "${shell_name}" ]]; then
    msg "Keeping current shell: ${current_shell_name}"
    return 0
  fi

  local selected_shell
  selected_shell="$(command -v "${shell_name}")"

  if [[ -z "${selected_shell}" ]]; then
    warn "${shell_name} is not installed. Installing it now..."

    if sudo pacman -S --needed --noconfirm "${shell_name}" >>"${LOG_FILE}" 2>&1; then
      selected_shell="$(command -v "${shell_name}")"
      msg "${shell_name} installed successfully."
    else
      error "Failed to install ${shell_name}."
      return 1
    fi
  fi

  if [[ "${current_shell}" == "${selected_shell}" ]]; then
    msg "${shell_name} is already your default shell."
    return 0
  fi

  info "Changing default shell to ${shell_name}..."

  if ! grep -q "^${selected_shell}\$" /etc/shells 2>/dev/null; then
    info "Adding ${shell_name} to /etc/shells..."
    printf "%s\n" "${selected_shell}" | sudo tee -a /etc/shells >>"${LOG_FILE}" 2>&1
  fi

  if chsh -s "${selected_shell}"; then
    msg "Default shell changed to ${shell_name} successfully."
    warn "You'll need to log out and back in for this to take effect."
  else
    error "Failed to change default shell."
    info "You can manually change it later with: chsh -s ${selected_shell}"
  fi
}

# ==========================
# DOTFILES MANAGEMENT
# ==========================

clone_or_update_dotfiles() {
  if [[ -d "${DOTDIR}/.git" ]]; then
    msg "Dotfiles directory exists. Updating..."
    if ! retry_command 3 git -C "${DOTDIR}" pull --rebase >>"${LOG_FILE}" 2>&1; then
      warn "Failed to update dotfiles after retries. Removing and re-cloning..."
      rm -rf "${DOTDIR}"
      clone_dotfiles
    else
      msg "Dotfiles updated successfully."
    fi
  elif [[ -d "${DOTDIR}" ]]; then
    warn "Dotfiles directory exists but is not a git repository. Removing and re-cloning..."
    rm -rf "${DOTDIR}"
    clone_dotfiles
  else
    clone_dotfiles
  fi

  info "Updating git submodules..."
  if retry_command 3 git -C "${DOTDIR}" submodule update --init --recursive >>"${LOG_FILE}" 2>&1; then
    msg "Submodules updated."
  else
    warn "Failed to update submodules after retries. Continuing anyway..."
  fi
}

clone_dotfiles() {
  info "Cloning dotfiles repository (this may take a moment)..."
  if ! retry_command 3 git clone --depth=1 "${REPO_URL}" "${DOTDIR}" >>"${LOG_FILE}" 2>&1; then
    fatal "Failed to clone dotfiles repository after multiple attempts. Check your internet connection."
  fi

  if [[ ! -d "${DOTDIR}/.git" ]]; then
    fatal "Repository cloned but .git directory not found. Clone may be corrupted."
  fi

  msg "Dotfiles cloned successfully."
}


create_symlinks() {
  msg "Creating symbolic links to ~/.config..."
  local linked=0
  local skipped=0

  for folder in "${CONFIG_FOLDERS[@]}"; do
      #info "$target"
      #info "${DOTDIR}/${folder}"
    if [[ -d "${DOTDIR}/${folder}" ]]; then
      local target="${CONFIG_DIR}/${folder}"


      if [[ -e "${target}" ]] || [[ -L "${target}" ]]; then
        warn "Target still exists: ${folder} (removing)"
        rm -rf "${target}"
      fi

      if ln -s "${DOTDIR}/${folder}" "${target}" 2>>"${LOG_FILE}"; then
        info "Linked: ${folder}"
        ((++linked)) || true
      else
        error "Failed to link: ${folder} (check log for details)"
      fi
    else
      info "Skipping: ${folder} (not found in repository)"
      ((++skipped)) || true
    fi
  done

  msg "Created ${linked} symlink(s), skipped ${skipped}."
}


main() {
  create_symlinks
}

# ==========================
# ARGUMENT PARSING
# ==========================

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -v|--version)
        version
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done
}

# ==========================
# ERROR HANDLING & EXECUTION
# ==========================

trap 'cleanup_on_error ${LINENO}' ERR
trap 'cleanup_on_exit' EXIT INT TERM

parse_arguments "$@"
main
