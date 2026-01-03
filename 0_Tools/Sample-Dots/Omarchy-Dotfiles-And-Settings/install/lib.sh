#!/bin/bash

# ==============================================================================
#  Common Logging and Task Runner Functions
# ==============================================================================

# --- Global Log Configuration ---
LOG_DIR="$HOME/.cache/matcha"
FAILED_LOG_FILE="$LOG_DIR/failed_tasks.log"

# --- Print an info message (Blue)---
info() {
    printf "\e[1;34m[INFO]\e[m $1\n"
}

# --- Print a warning message (Yellow)---
warning() {
    printf "\e[1;33m[WARNING]\e[m $1\n"
}

# --- Print an error message and exit (Red)---
error() {
    printf "\e[1;33m[ERROR]\e[m $1\n" >&2
    exit 1
}

# --- Ask for user confirmation ---
# @param $1 Question to ask the user
# Returns 0 (true) if user confirms (y/Y), 1 (false) otherwise.
ask_confirmation() {
    # If in non-interactive mode, always return true
    if [ -n "$NON_INTERACTIVE" ] && [ "$NON_INTERACTIVE" = true ]; then
        return 0
    fi

    local question="$1"
    read -p "$question (y/n) " -n 1 -r
    echo # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0 # Confirmed
    else
        return 1 # Not confirmed
    fi
}

# --- Task Runner Function with Real-time Output ---
# Executes a command, displays its output in real-time, logs success or failure,
# and allows the script to continue on non-critical failures.
run_task() {
    local command_string="$*"
    
    mkdir -p "$LOG_DIR"

    local tmp_output_file
    tmp_output_file=$(mktemp)

    info "Executing task: $command_string"
    echo "--- Task Output Start ---"
    
    # Enable pipefail to get the exit code of 'eval', not 'tee'.
    set -o pipefail
    # Temporarily disable exit-on-error to handle the failure manually.
    set +e

    # Execute the command and pipe its combined output (stdout & stderr) to tee.
    # tee displays the output to the screen and simultaneously saves it to a temp file.
    eval "$command_string" 2>&1 | tee "$tmp_output_file"
    # Capture the exit code of the 'eval' command (the first command in the pipe).
    local exit_code=${PIPESTATUS[0]}

    # Restore default shell options.
    set +o pipefail
    set -e

    echo "--- Task Output End ---"

    if [ $exit_code -eq 0 ]; then
        info "  -> Success (Exit Code: $exit_code)."
        # On success, ensure the task is REMOVED from the failed log.
        if [ -f "$FAILED_LOG_FILE" ]; then
            grep -vFx "$command_string" "$FAILED_LOG_FILE" > "$FAILED_LOG_FILE.tmp" || true
            mv "$FAILED_LOG_FILE.tmp" "$FAILED_LOG_FILE"
        fi
    else
        # The error output was already displayed on screen by tee.
        # We just need to log the failure.
        warning "  -> FAILED (Exit Code: $exit_code)."
        warning "  -> This failed command has been logged to: $FAILED_LOG_FILE"
        
        # Add the failed command to the log, avoiding duplicates.
        if ! grep -Fxq "$command_string" "$FAILED_LOG_FILE"; then
            echo "$command_string" >> "$FAILED_LOG_FILE"
        fi
    fi
    
    # Cleanup the temp file.
    rm -f "$tmp_output_file"

    # Return the original exit code.
    return $exit_code
}

# --- Spinner and Spinner Task Runner ---

# A simple spinner function
# @param $1 PID of the background process to watch
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null; do
        local temp=${spinstr#?}
        printf "  [%c] Working..." "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "                \r" # Clear the spinner line
}

# Executes a command with a spinner for quiet, long-running tasks.
run_task_with_spinner() {
    local command_string="$*"
    mkdir -p "$LOG_DIR"
    local tmp_output_file=$(mktemp)

    #info "Executing task: $command_string"
    
    set +e
    # Run command in the background, redirecting all output.
    eval "$command_string" > "$tmp_output_file" 2>&1 &
    local pid=$!

    # Show spinner while the command runs.
    spinner $pid
    
    # Wait for the background process and get its exit code.
    local exit_code
    wait $pid
    exit_code=$?
    set -e

    local output=$(<"$tmp_output_file")
    rm -f "$tmp_output_file"

    # Log success or failure based on the exit code.
    if [ $exit_code -eq 0 ]; then
        info "  -> Success (Exit Code: $exit_code)."
        if [ -f "$FAILED_LOG_FILE" ]; then
            grep -vFx "$command_string" "$FAILED_LOG_FILE" > "$FAILED_LOG_FILE.tmp" || true
            mv "$FAILED_LOG_FILE.tmp" "$FAILED_LOG_FILE"
        fi
    else
        echo -e "\033[1;31m[ERROR]\033[0m -> FAILED (Exit Code: $exit_code)."
        warning "  -> Error output:"
        echo "$output" | sed 's/^/    | /' | while IFS= read -r line; do warning "$line"; done
        warning "  -> This failed command has been logged to: $FAILED_LOG_FILE"
        if ! grep -Fxq "$command_string" "$FAILED_LOG_FILE"; then
            echo "$command_string" >> "$FAILED_LOG_FILE"
        fi
    fi
    return $exit_code
}
