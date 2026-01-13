#!/bin/bash
#
# Run all integration tests for Claude Agent SDK Java Tutorial
#
# Usage: ./scripts/run-integration-tests.sh [--parallel N]
#
# Options:
#   --parallel N    Run N tests in parallel (default: sequential)
#

set -e

# Get the integration-testing directory (parent of scripts/)
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
IT_DIR="${SCRIPT_DIR%/*}"
CONFIGS_DIR="$IT_DIR/configs"

# If running from integration-testing dir directly
if [[ "$IT_DIR" == "." || "$IT_DIR" == "" ]]; then
    IT_DIR="."
    CONFIGS_DIR="./configs"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
PARALLEL=1
while [[ $# -gt 0 ]]; do
    case $1 in
        --parallel)
            PARALLEL="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--parallel N]"
            echo "  --parallel N    Run N tests in parallel (default: sequential)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check we're in the right place
if [[ ! -d "$CONFIGS_DIR" ]]; then
    echo -e "${RED}Error: configs directory not found at $CONFIGS_DIR${NC}"
    echo "Are you running from the integration-testing directory?"
    exit 1
fi

# Check JBang is installed - use explicit path to avoid env lookup issues
JBANG="/home/mark/.jbang/bin/jbang"
if [[ ! -x "$JBANG" ]]; then
    # Try alternative locations
    if [[ -x "$HOME/.jbang/bin/jbang" ]]; then
        JBANG="$HOME/.jbang/bin/jbang"
    elif command -v jbang &> /dev/null; then
        JBANG="jbang"
    else
        echo -e "${RED}Error: JBang not found${NC}"
        echo "Install with: curl -Ls https://sh.jbang.dev | bash -s - app setup"
        exit 1
    fi
fi

# Get list of config files (ls already sorts alphabetically)
CONFIG_FILES=("$CONFIGS_DIR"/*.json)

if [[ ${#CONFIG_FILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No config files found in $CONFIGS_DIR${NC}"
    exit 0
fi

echo "═══════════════════════════════════════════════════════════════"
echo " Integration Tests - Claude Agent SDK Java Tutorial"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Found ${#CONFIG_FILES[@]} module(s) to test"
echo ""

# Track results
PASSED=0
FAILED=0
FAILED_MODULES=()

cd "$IT_DIR"

# Run tests
for config in "${CONFIG_FILES[@]}"; do
    # Extract module ID from filename (remove path and .json extension)
    filename="${config##*/}"  # basename equivalent
    module_id="${filename%.json}"

    echo "───────────────────────────────────────────────────────────────"
    echo -e "${YELLOW}Running: $module_id${NC}"
    echo "───────────────────────────────────────────────────────────────"

    if "$JBANG" RunIntegrationTest.java "$module_id"; then
        echo -e "${GREEN}✓ PASSED: $module_id${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: $module_id${NC}"
        FAILED=$((FAILED + 1))
        FAILED_MODULES+=("$module_id")
    fi

    echo ""
done

# Summary
echo "═══════════════════════════════════════════════════════════════"
echo " Summary"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo "  Total:  $((PASSED + FAILED))"

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed modules:${NC}"
    for module in "${FAILED_MODULES[@]}"; do
        echo "  - $module"
    done
    echo ""
    exit 1
else
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
