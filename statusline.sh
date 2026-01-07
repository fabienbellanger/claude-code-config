#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
YELLOW='\033[33m'
GRAY='\033[0;90m'
LIGHT_GRAY='\033[0;37m'
RESET='\033[0m'

# Read JSON input from stdin
input=$(cat)

# Extract current session ID and model info from Claude Code input
session_id=$(echo "$input" | jq -r '.session_id // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Get current git branch with error handling
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo "detached")
    if [ -z "$branch" ]; then
        branch="detached"
    fi

    # Check for pending changes (staged or unstaged)
    if ! git diff-index --quiet HEAD -- 2>/dev/null || ! git diff-index --quiet --cached HEAD -- 2>/dev/null; then
        branch="$branch*"
    fi
else
    branch="no-git"
fi

# Get basename of current directory
dir_name=$(basename "$current_dir")

# Get today's date in YYYYMMDD format
today=$(date +%Y%m%d)

# Format tokens
format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000000 ]; then
        printf "%.1fM" "$(echo "scale=1; $tokens / 1000000" | bc -l)"
    elif [ "$tokens" -ge 1000 ]; then
        printf "%.1fK" "$(echo "scale=1; $tokens / 1000" | bc -l)"
    else
        printf "%d" "$tokens"
    fi
}

# Format time
format_time() {
    local minutes=$1
    local hours=$((minutes / 60))
    local mins=$((minutes % 60))
    if [ "$hours" -gt 0 ]; then
        printf "%dh %dm" "$hours" "$mins"
    else
        printf "%dm" "$mins"
    fi
}

# Initialize variables with defaults
session_cost="0.00"
session_tokens=0
block_cost="0.00"
remaining_time="N/A"

# Get current session data by finding the session JSONL file
if command -v ccusage >/dev/null 2>&1 && [ -n "$session_id" ] && [ "$session_id" != "empty" ]; then
    # Look for the session JSONL file in Claude project directories
    session_jsonl_file=""

    # Check common Claude paths
    claude_paths=(
        "$HOME/.config/claude"
        "$HOME/.claude"
    )

    for claude_path in "${claude_paths[@]}"; do
        if [ -d "$claude_path/projects" ]; then
            # Use find to search for the session file
            session_jsonl_file=$(find "$claude_path/projects" -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)
            if [ -n "$session_jsonl_file" ]; then
                break
            fi
        fi
    done

    # Parse the session file if found
    if [ -n "$session_jsonl_file" ] && [ -f "$session_jsonl_file" ]; then
        # Count lines and estimate cost (simple approximation)
        # Each line is a usage entry, we can count tokens and estimate
        session_tokens=0
        session_entries=0

        while IFS= read -r line; do
            if [ -n "$line" ]; then
                session_entries=$((session_entries + 1))
                # Extract token usage from message.usage field (only count input + output tokens)
                # Cache tokens shouldn't be added up as they're reused/shared across messages
                input_tokens=$(echo "$line" | jq -r '.message.usage.input_tokens // 0' 2>/dev/null || echo "0")
                output_tokens=$(echo "$line" | jq -r '.message.usage.output_tokens // 0' 2>/dev/null || echo "0")

                line_tokens=$((input_tokens + output_tokens))
                session_tokens=$((session_tokens + line_tokens))
            fi
        done < "$session_jsonl_file"

        # Use ccusage statusline to get the accurate cost for this session
        ccusage_statusline=$(echo "$input" | ccusage statusline 2>/dev/null)
        current_session_cost=$(echo "$ccusage_statusline" | sed -n 's/.*💰 \([^[:space:]]*\) session.*/\1/p')

        if [ -n "$current_session_cost" ] && [ "$current_session_cost" != "N/A" ]; then
            session_cost=$(echo "$current_session_cost" | sed 's/\$//g')
        fi
    fi
fi

# Get daily and block data
if command -v ccusage >/dev/null 2>&1; then
    # Get active block data
    block_data=$(ccusage blocks --active --json 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$block_data" ]; then
        active_block=$(echo "$block_data" | jq -r '.blocks[] | select(.isActive == true) // empty')
        if [ -n "$active_block" ] && [ "$active_block" != "null" ]; then
            remaining_minutes=$(echo "$active_block" | jq -r '.projection.remainingMinutes // 0')
            if [ "$remaining_minutes" != "0" ] && [ "$remaining_minutes" != "null" ]; then
                remaining_time=$(format_time "$remaining_minutes")
            fi
        fi
    fi
fi

# Format the output
formatted_session_cost=$(format_cost "$session_cost")
formatted_tokens=$(format_tokens "$session_tokens")

# Build the status line with colors (light gray as default)
status_line="${BLUE}$dir_name${GRAY} (${YELLOW}$branch${GRAY}) | ${LIGHT_GRAY}🤖 ${GREEN}$model_name${GRAY} / ${LIGHT_GRAY}"

if [ "$remaining_time" != "N/A" ]; then
    status_line="$status_line 🕓 $remaining_time"
fi

status_line="$status_line${GRAY} | ${LIGHT_GRAY}🧩 ${formatted_tokens}${GRAY} tokens${RESET}"

printf "%b\n" "$status_line"
