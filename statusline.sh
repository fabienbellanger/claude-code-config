#!/bin/bash
input=$(cat)

user=$(whoami)
dir=$(basename "$(pwd)")
branch=$(git -c core.useBuiltinFSMonitor=false -c advice.detachedHead=false rev-parse --abbrev-ref HEAD 2>/dev/null)
model=$(echo "$input" | jq -r '.model.display_name')
usage=$(echo "$input" | jq '.context_window.current_usage')

if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
    context_info="${pct}%"
else
    context_info=""
fi

# ANSI color codes
GREEN='\033[32m'
BLUE='\033[34m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

# Format with colors
if [ -n "$branch" ]; then
    printf "${GREEN}%s${RESET} in ${BLUE}%s${RESET} on ${RED}%s${RESET} | ${YELLOW}%s${RESET} (%s)" "$user" "$dir" "$branch" "$model" "$context_info"
else
    printf "${GREEN}%s${RESET} in ${BLUE}%s${RESET} | ${YELLOW}%s${RESET} (%s)" "$user" "$dir" "$model" "$context_info"
fi
