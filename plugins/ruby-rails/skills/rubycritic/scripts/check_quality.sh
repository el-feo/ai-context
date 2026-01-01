#!/bin/bash

# RubyCritic Quality Check Script
# Automatically installs RubyCritic if needed and runs quality analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if RubyCritic is installed
check_rubycritic_installed() {
    if command_exists rubycritic; then
        return 0
    fi

    # Check if it's available via bundler
    if [ -f "Gemfile" ] && command_exists bundle; then
        if bundle exec rubycritic --version >/dev/null 2>&1; then
            return 0
        fi
    fi

    return 1
}

# Function to install RubyCritic
install_rubycritic() {
    echo -e "${YELLOW}RubyCritic is not installed. Installing now...${NC}"

    # Check if we're in a bundler project
    if [ -f "Gemfile" ]; then
        echo -e "${BLUE}Detected Gemfile. Checking if rubycritic is in Gemfile...${NC}"

        if grep -q "rubycritic" Gemfile; then
            echo -e "${BLUE}RubyCritic found in Gemfile. Running bundle install...${NC}"
            bundle install
        else
            echo -e "${YELLOW}RubyCritic not in Gemfile. Adding it to development group...${NC}"

            # Add to Gemfile
            if grep -q "group :development do" Gemfile; then
                # Insert after the development group line
                sed -i "/group :development do/a \ \ gem 'rubycritic', require: false" Gemfile
            else
                # Append at the end
                echo "" >> Gemfile
                echo "group :development do" >> Gemfile
                echo "  gem 'rubycritic', require: false" >> Gemfile
                echo "end" >> Gemfile
            fi

            bundle install
        fi
    else
        echo -e "${BLUE}No Gemfile found. Installing RubyCritic as a system gem...${NC}"
        gem install rubycritic
    fi

    echo -e "${GREEN}✓ RubyCritic installed successfully!${NC}"
    echo ""
}

# Function to run RubyCritic
run_rubycritic() {
    local target_path="${1:-.}"

    echo -e "${BLUE}Running RubyCritic analysis on: ${target_path}${NC}"
    echo ""

    # Determine how to run RubyCritic
    local cmd="rubycritic"
    if [ -f "Gemfile" ] && command_exists bundle; then
        cmd="bundle exec rubycritic"
    fi

    # Run RubyCritic with console format and no browser
    # Use --no-browser to prevent opening HTML report
    # Use --format console for immediate feedback
    $cmd --format console --no-browser "$target_path"

    local exit_code=$?

    echo ""

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Quality check complete!${NC}"
        echo -e "${BLUE}Tip: For detailed HTML report, run: $cmd --format html $target_path${NC}"
    else
        echo -e "${YELLOW}⚠ Quality check completed with warnings${NC}"
        echo -e "${BLUE}Review the output above for issues to address${NC}"
    fi

    return $exit_code
}

# Main execution
main() {
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo -e "${BLUE}    RubyCritic Code Quality Analyzer${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
    echo ""

    # Check for Ruby
    if ! command_exists ruby; then
        echo -e "${RED}Error: Ruby is not installed${NC}"
        echo "Please install Ruby before running this script"
        exit 1
    fi

    # Check and install RubyCritic if needed
    if ! check_rubycritic_installed; then
        install_rubycritic
    fi

    # Run the analysis
    run_rubycritic "$@"
}

# Run main function with all arguments
main "$@"
