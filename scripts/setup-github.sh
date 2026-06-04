#!/bin/bash

# GitHub Repository Setup Script
# This script helps you initialize git, create a GitHub repo, and push your code

set -e  # Exit on error

echo "======================================"
echo "GitHub Repository Setup Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
PROJECT_DIR="/Users/raxgomez/Documents/MBA/Tania"
if [ "$(pwd)" != "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}Warning: You're not in the project directory.${NC}"
    echo "Current directory: $(pwd)"
    echo "Project directory: $PROJECT_DIR"
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Setup cancelled.${NC}"
        exit 1
    fi
fi

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo -e "${BLUE}Step 1: Initializing Git repository...${NC}"
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
    echo ""
else
    echo -e "${GREEN}✓ Git repository already initialized${NC}"
    echo ""
fi

# Check if .github directory exists
if [ ! -d ".github" ]; then
    echo -e "${RED}Error: .github directory not found!${NC}"
    echo "Please ensure you're in the correct project directory."
    exit 1
fi

echo -e "${BLUE}Step 2: Checking GitHub Actions workflow...${NC}"
if [ -f ".github/workflows/build-windows.yml" ]; then
    echo -e "${GREEN}✓ GitHub Actions workflow found${NC}"
else
    echo -e "${RED}Error: GitHub Actions workflow not found!${NC}"
    exit 1
fi
echo ""

# Check if there are any uncommitted changes
echo -e "${BLUE}Step 3: Checking git status...${NC}"
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}You have uncommitted changes.${NC}"
    echo ""
    git status
    echo ""
    read -p "Do you want to commit these changes now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Committing changes...${NC}"
        git add .
        echo ""
        read -p "Enter commit message (default: 'Add GitHub Actions workflow for Windows builds'): " commit_msg
        commit_msg=${commit_msg:-"Add GitHub Actions workflow for Windows builds"}
        git commit -m "$commit_msg"
        echo -e "${GREEN}✓ Changes committed${NC}"
    else
        echo -e "${YELLOW}Skipping commit. Please commit manually before pushing.${NC}"
    fi
else
    echo -e "${GREEN}✓ No uncommitted changes${NC}"
fi
echo ""

# Ask for GitHub details
echo -e "${BLUE}Step 4: GitHub Repository Details${NC}"
echo ""
read -p "Enter your GitHub username: " github_username
read -p "Enter repository name (default: amerike_investment_sim): " repo_name
repo_name=${repo_name:-amerike_investment_sim}
read -p "Is the repository private? (Y/n): " -n 1 -r
echo ""
private_repo=""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    private_repo="--private"
fi

# Construct GitHub URL
github_url="https://github.com/$github_username/$repo_name.git"

echo ""
echo -e "${BLUE}Step 5: Setting up remote and pushing to GitHub${NC}"
echo ""

# Check if remote already exists
if git remote get-url origin > /dev/null 2>&1; then
    echo -e "${YELLOW}Remote 'origin' already exists.${NC}"
    current_remote=$(git remote get-url origin)
    echo "Current remote: $current_remote"
    read -p "Do you want to update it? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote set-url origin "$github_url"
        echo -e "${GREEN}✓ Remote updated${NC}"
    else
        echo -e "${YELLOW}Keeping existing remote${NC}"
    fi
else
    git remote add origin "$github_url"
    echo -e "${GREEN}✓ Remote 'origin' added${NC}"
fi
echo ""

# Instructions for creating GitHub repo
echo -e "${YELLOW}IMPORTANT: Before pushing, you need to create the GitHub repository${NC}"
echo ""
echo "1. Go to: https://github.com/new"
echo "2. Repository name: $repo_name"
echo "3. Description: Amerike Investment Simulator - Flutter Application"
echo "4. Set to: $([ -z "$private_repo" ] && echo "Public" || echo "Private")"
echo "5. **Do NOT** initialize with README, .gitignore, or license"
echo "6. Click 'Create repository'"
echo ""
read -p "Press Enter once you've created the repository..."
echo ""

# Push to GitHub
echo -e "${BLUE}Pushing to GitHub...${NC}"
echo ""

# Get current branch
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")

# Try to push
if git push -u origin "$current_branch" 2>/dev/null; then
    echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
else
    echo -e "${YELLOW}Push failed. Trying alternative method...${NC}"
    echo ""
    echo "You might need to:"
    echo "1. Create the repository on GitHub first"
    echo "2. Use a personal access token if you have 2FA enabled"
    echo ""
    read -p "Try again? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -u origin "$current_branch"
        echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
    else
        echo -e "${RED}Push cancelled. Please push manually.${NC}"
        echo ""
        echo "To push manually, run:"
        echo "  git push -u origin $current_branch"
        exit 1
    fi
fi
echo ""

# Success message
echo -e "${GREEN}======================================"
echo -e "Setup Complete! 🎉"
echo -e "======================================${NC}"
echo ""
echo "Your repository is now on GitHub:"
echo "  $github_url"
echo ""
echo "Next steps:"
echo ""
echo "1. Enable GitHub Actions:"
echo "   - Go to your repository on GitHub"
echo "   - Click the 'Actions' tab"
echo "   - Click 'I understand my workflows, go ahead and enable them'"
echo ""
echo "2. Trigger a build:"
echo "   - Either push new code (git push)"
echo "   - Or manually trigger from Actions tab"
echo ""
echo "3. Download the executable:"
echo "   - Go to Actions tab → Click on workflow run → Download artifact"
echo ""
echo "For detailed instructions, see: .github/GITHUB_ACTIONS_GUIDE.md"
echo ""
echo -e "${BLUE}Happy building! 🚀${NC}"
