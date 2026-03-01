#!/bin/bash

# ui.sh - Interface utilities for SetupOpenClaw installer
# Provides colors, logging, spinners, and menu functions

# ANSI color codes
export COLOR_RESET='\033[0m'
export COLOR_INFO='\033[0;36m'      # Cyan
export COLOR_SUCCESS='\033[0;32m'   # Green
export COLOR_ERROR='\033[0;31m'     # Red
export COLOR_WARN='\033[0;33m'      # Yellow
export COLOR_BOLD='\033[1m'
export COLOR_DIM='\033[2m'

# Log file
LOG_FILE="/var/log/setup-openclaw/install.log"

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
}

# Log with timestamp
log_raw() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# Log info message
log_info() {
    local message="$1"
    echo -e "${COLOR_INFO}ℹ${COLOR_RESET} $message"
    log_raw "[INFO] $message"
}

# Log success message
log_success() {
    local message="$1"
    echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} $message"
    log_raw "[SUCCESS] $message"
}

# Log error message
log_error() {
    local message="$1"
    echo -e "${COLOR_ERROR}✗${COLOR_RESET} $message" >&2
    log_raw "[ERROR] $message"
}

# Log warning message
log_warn() {
    local message="$1"
    echo -e "${COLOR_WARN}⚠${COLOR_RESET} $message"
    log_raw "[WARN] $message"
}

# Show spinner while command runs
show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    echo -n "$message "
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Show progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percentage"
}

# Display a menu using whiptail or dialog
show_menu() {
    local title="$1"
    local message="$2"
    shift 2
    local options=("$@")
    
    if command -v whiptail &> /dev/null; then
        # Build whiptail menu items (tag description pairs)
        local menu_items=()
        local index=1
        for option in "${options[@]}"; do
            menu_items+=("$index" "$option")
            ((index++))
        done
        
        whiptail --title "$title" --menu "$message" 20 70 10 "${menu_items[@]}" 3>&1 1>&2 2>&3
    elif command -v dialog &> /dev/null; then
        local menu_items=()
        local index=1
        for option in "${options[@]}"; do
            menu_items+=("$index" "$option")
            ((index++))
        done
        
        dialog --title "$title" --menu "$message" 20 70 10 "${menu_items[@]}" 3>&1 1>&2 2>&3
    else
        # Fallback to simple text menu
        echo "$title"
        echo "$message"
        echo
        local index=1
        for option in "${options[@]}"; do
            echo "  $index) $option"
            ((index++))
        done
        echo
        read -r -p "Select option: " choice
        echo "$choice"
    fi
}

# Display yes/no prompt
prompt_yes_no() {
    local message="$1"
    local default="${2:-y}"
    
    if command -v whiptail &> /dev/null; then
        if [ "$default" = "y" ]; then
            whiptail --title "Confirmation" --yesno "$message" 10 60 --defaultno
        else
            whiptail --title "Confirmation" --yesno "$message" 10 60
        fi
        return $?
    else
        local prompt="[y/N]"
        [ "$default" = "y" ] && prompt="[Y/n]"
        
        read -r -p "$message $prompt: " response
        response=${response,,} # to lowercase
        
        if [ "$default" = "y" ]; then
            [[ "$response" =~ ^(yes|y|)$ ]]
        else
            [[ "$response" =~ ^(yes|y)$ ]]
        fi
    fi
}

# Display input box
prompt_input() {
    local message="$1"
    local default="$2"
    
    if command -v whiptail &> /dev/null; then
        whiptail --title "Input" --inputbox "$message" 10 60 "$default" 3>&1 1>&2 2>&3
    else
        read -r -p "$message [$default]: " response
        echo "${response:-$default}"
    fi
}

# Display password input
prompt_password() {
    local message="$1"
    
    if command -v whiptail &> /dev/null; then
        whiptail --title "Password" --passwordbox "$message" 10 60 3>&1 1>&2 2>&3
    else
        read -r -s -p "$message: " password
        echo >&2
        echo "$password"
    fi
}

# Display message box
show_message() {
    local title="$1"
    local message="$2"
    
    if command -v whiptail &> /dev/null; then
        whiptail --title "$title" --msgbox "$message" 15 70
    else
        echo "=== $title ==="
        echo "$message"
        read -r -p "Press Enter to continue..."
    fi
}

# Display error box
show_error() {
    local message="$1"
    log_error "$message"
    
    if command -v whiptail &> /dev/null; then
        whiptail --title "Error" --msgbox "$message" 12 70
    else
        echo "ERROR: $message" >&2
        read -r -p "Press Enter to continue..."
    fi
}

# Print banner
print_banner() {
    echo -e "${COLOR_BOLD}${COLOR_INFO}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║          SetupOpenClaw - Instalador Oficial          ║
║                                                       ║
║     Sistema profissional de instalação Docker        ║
║              para OpenClaw Gateway                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${COLOR_RESET}"
}

# Print section header
print_section() {
    local title="$1"
    echo
    echo -e "${COLOR_BOLD}${COLOR_INFO}▶ $title${COLOR_RESET}"
    echo -e "${COLOR_DIM}$(printf '─%.0s' {1..60})${COLOR_RESET}"
}

# Initialize UI
init_ui() {
    init_logging
    
    # Install whiptail if not present
    if ! command -v whiptail &> /dev/null && ! command -v dialog &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            log_info "Installing whiptail for better UI..."
            apt-get update -qq && apt-get install -y whiptail -qq > /dev/null 2>&1
        fi
    fi
}
