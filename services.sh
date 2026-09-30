#!/usr/bin/env bash

# Initialize variables with default values
SHOW_RUNNING=false
SHOW_ACTIVE=false
SHOW_BOOT=false
VERBOSE=false
SEARCH_NAME=""
KILL_NAME=""
START_NAME=""
DISABLE_NAME=""

# Color definitions
GREEN="\e[92m"  # Bright Green
RED="\e[31m"    # Red
RESET="\e[0m"
BOLD="\e[1m"

# Usage help function with bold options
usage() {
    echo -e "Usage: $0 [OPTIONS]"
    echo -e "  ${BOLD}-s, --search NAME${RESET}  Search for a service, show its configuration status, and describe it"
    echo -e "  ${BOLD}-t, --start NAME${RESET}   Start a systemd service by name"
    echo -e "  ${BOLD}-k, --kill NAME${RESET}    Kill (stop) a running service by name"
    echo -e "  ${BOLD}-d, --disable NAME${RESET}  Disable a service from starting at boot"
    echo -e "  ${BOLD}-v, --verbose${RESET}      Enable verbose mode (describe listed services)"
    echo -e "  ${BOLD}-b, --boot${RESET}         List all services enabled at boot (Default)"
    echo -e "  ${BOLD}-r, --running${RESET}      List running systemd services"
    echo -e "  ${BOLD}-a, --active${RESET}       List all active systemd services"
    echo -e "  ${BOLD}-h, --help${RESET}         Display this help message"
    exit 1
}

# If no arguments are provided, default to showing boot services
if [ $# -eq 0 ]; then
    SHOW_BOOT=true
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--search)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Argument for $1 is missing." >&2
                exit 1
            fi
            SEARCH_NAME="$2"
            shift 2
            ;;
        -t|--start)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Argument for $1 is missing." >&2
                exit 1
            fi
            START_NAME="$2"
            shift 2
            ;;
        -k|--kill)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Argument for $1 is missing." >&2
                exit 1
            fi
            KILL_NAME="$2"
            shift 2
            ;;
        -d|--disable)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: Argument for $1 is missing." >&2
                exit 1
            fi
            DISABLE_NAME="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -b|--boot)
            SHOW_BOOT=true
            shift
            ;;
        -r|--running)
            SHOW_RUNNING=true
            shift
            ;;
        -a|--active)
            SHOW_ACTIVE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

# Helper function to describe services when verbose mode is enabled
describe_services() {
    local command_output="$1"
    local state_type="$2"

    if [ "$VERBOSE" = true ]; then
        echo -e "\n--- Detailed Service Descriptions ($state_type) ---"
        echo "$command_output" | awk '/\.service/ {print $1}' | while read -r service; do
            if [ -n "$service" ]; then
                local desc
                desc=$(systemctl show "$service" --no-pager --property=Description --value)
                echo -e "${BOLD}$service${RESET}: $desc"
            fi
        done
    fi
}

# --- Core Script Logic ---

# 1. Start Functionality
if [ -n "$START_NAME" ]; then
    SERVICE_START="$START_NAME"
    if [[ "$SERVICE_START" != *.service ]]; then
        SERVICE_START="${SERVICE_START}.service"
    fi

    echo "Attempting to start service: $SERVICE_START"
    
    if systemctl list-unit-files "$SERVICE_START" --type=service &>/dev/null; then
        if sudo systemctl start "$SERVICE_START"; then
            echo -e "Successfully sent start command to ${BOLD}$SERVICE_START${RESET}."
        else
            echo "Error: Failed to start service '$SERVICE_START'. You might need root privileges." >&2
        fi
    else
        echo "Error: Service '$SERVICE_START' could not be found on this system." >&2
    fi
    echo ""
fi

# 2. Kill Functionality
if [ -n "$KILL_NAME" ]; then
    SERVICE_KILL="$KILL_NAME"
    if [[ "$SERVICE_KILL" != *.service ]]; then
        SERVICE_KILL="${SERVICE_KILL}.service"
    fi

    echo "Attempting to stop service: $SERVICE_KILL"
    
    if systemctl list-unit-files "$SERVICE_KILL" --type=service &>/dev/null; then
        if sudo systemctl stop "$SERVICE_KILL"; then
            echo -e "Successfully sent stop command to ${BOLD}$SERVICE_KILL${RESET}."
        else
            echo "Error: Failed to stop service '$SERVICE_KILL'. You might need root privileges." >&2
        fi
    else
        echo "Error: Service '$SERVICE_KILL' could not be found on this system." >&2
    fi
    echo ""
fi

# 3. Disable Functionality
if [ -n "$DISABLE_NAME" ]; then
    SERVICE_DISABLE="$DISABLE_NAME"
    if [[ "$SERVICE_DISABLE" != *.service ]]; then
        SERVICE_DISABLE="${SERVICE_DISABLE}.service"
    fi

    echo "Attempting to disable service at boot: $SERVICE_DISABLE"
    
    if systemctl list-unit-files "$SERVICE_DISABLE" --type=service &>/dev/null; then
        if sudo systemctl disable "$SERVICE_DISABLE"; then
            echo -e "Successfully disabled ${BOLD}$SERVICE_DISABLE${RESET} from booting automatically."
        else
            echo "Error: Failed to disable service '$SERVICE_DISABLE'. You might need root privileges." >&2
        fi
    else
        echo "Error: Service '$SERVICE_DISABLE' could not be found on this system." >&2
    fi
    echo ""
fi

# 4. Search & Detailed Description Functionality
if [ -n "$SEARCH_NAME" ]; then
    SERVICE_QUERY="$SEARCH_NAME"
    if [[ "$SERVICE_QUERY" != *.service ]]; then
        SERVICE_QUERY="${SERVICE_QUERY}.service"
    fi

    echo "Searching configuration status for: $SERVICE_QUERY"
    
    UNIT_STATUS=$(systemctl list-unit-files "$SERVICE_QUERY" --type=service 2>/dev/null)
    
    if echo "$UNIT_STATUS" | grep -q "$SERVICE_QUERY"; then
        BOOT_STATE=$(echo "$UNIT_STATUS" | grep "$SERVICE_QUERY" | awk '{print $2}')
        
        case "$BOOT_STATE" in
            enabled)
                BOOT_DESC="${GREEN}Yes (Starts at boot)${RESET}"
                ;;
            disabled)
                BOOT_DESC="${RED}No (Will not start at boot)${RESET}"
                ;;
            static)
                BOOT_DESC="${RED}Static (No boot trigger; started on demand by other units)${RESET}"
                ;;
            masked)
                BOOT_DESC="${RED}Masked (Completely locked down and forbidden from booting)${RESET}"
                ;;
            *)
                BOOT_DESC="Unknown / Custom ($BOOT_STATE)"
                ;;
        esac
        
        echo -e "\n--- ${BOLD}Detailed Service Profile${RESET} ---"
        
        desc=$(systemctl show "$SERVICE_QUERY" --no-pager --property=Description --value)
        active_state=$(systemctl show "$SERVICE_QUERY" --property=ActiveState --value)
        sub_state=$(systemctl show "$SERVICE_QUERY" --property=SubState --value)
        pid=$(systemctl show "$SERVICE_QUERY" --property=MainPID --value)
        exec_start=$(systemctl show "$SERVICE_QUERY" --no-pager --property=ExecStart --value)
        memory=$(systemctl show "$SERVICE_QUERY" --property=MemoryCurrent --value)

        # Parse memory if active
        if [[ -n "$memory" && "$memory" != "[not set]" && "$memory" != "18446744073709551615" ]]; then
            memory_mb=$(( memory / 1024 / 1024 ))
            memory_display="${memory_mb} MB (${memory} bytes)"
        else
            memory_display="N/A"
        fi

        # Determine color layout for status metrics
        if [ "$active_state" = "active" ] || [ "$sub_state" = "running" ]; then
            STATUS_COLOR="$GREEN"
        else
            STATUS_COLOR="$RED"
        fi

        # Output the structural breakdown
        echo "Description:    $desc"
        echo -e "Starts at Boot: $BOOT_DESC"
        echo -e "Status:         ${STATUS_COLOR}$active_state ($sub_state)${RESET}"
        echo "Main PID:       $pid"
        echo "Memory Usage:   $memory_display"
        echo "Exec Command:   $(echo "$exec_start" | awk -F' path=' '{print $2}' | awk -F';' '{print $1}')"
    else
        echo "Error: Service '$SERVICE_QUERY' could not be found on this system." >&2
    fi
    echo "" 
fi

# 5. Boot Services (Default action)
if [ "$SHOW_BOOT" = true ]; then
    echo "Listing systemd services enabled at boot..."
    OUTPUT=$(systemctl list-unit-files --type=service --state=enabled)
    echo "$OUTPUT"
    describe_services "$OUTPUT" "Boot"
fi

# 6. Running Services
if [ "$SHOW_RUNNING" = true ]; then
    echo "Listing running systemd services..."
    OUTPUT=$(systemctl list-units --type=service --state=running)
    echo "$OUTPUT"
    describe_services "$OUTPUT" "Running"
fi

# 7. Active Services
if [ "$SHOW_ACTIVE" = true ]; then
    echo "Listing all active systemd services..."
    OUTPUT=$(systemctl list-units --type=service --state=active)
    echo "$OUTPUT"
    describe_services "$OUTPUT" "Active"
fi

