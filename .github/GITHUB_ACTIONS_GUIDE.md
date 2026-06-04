# GitHub Actions - Build Windows Executable Guide

This guide explains how to use the GitHub Actions workflow to automatically build Windows executables for your Amerike Investment Simulator.

## Overview

The workflow automatically builds a Windows `.exe` file when you:
- Push code to the `main` or `master` branch
- Manually trigger the workflow from GitHub Actions

## Workflow Features

- **Automated building**: Compiles your Flutter app for Windows in release mode
- **Artifact generation**: Creates a ZIP file containing the executable and all dependencies
- **Version tracking**: Automatically assigns version numbers based on workflow run numbers
- **Build verification**: Validates that all required files are present
- **Executable naming**: Outputs `amerike_investment_sim.exe`

## Quick Start Instructions

### 1. Initialize Git Repository (if not already done)

```bash
cd /Users/raxgomez/Documents/MBA/Tania
git init
git add .
git commit -m "Initial commit with GitHub Actions workflow"
```

### 2. Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in
2. Click the `+` icon → "New repository"
3. Name it: `amerike_investment_sim` (or your preferred name)
4. Set to "Private" if you don't want it public
5. **Don't** initialize with README (you already have one)
6. Click "Create repository"

### 3. Push to GitHub

```bash
# Add the remote repository (replace with your actual URL)
git remote add origin https://github.com/YOUR_USERNAME/amerike_investment_sim.git

# Push to main branch
git push -u origin main
```

### 4. Enable GitHub Actions

1. Go to your repository on GitHub
2. Click the "Actions" tab
3. If prompted, click "I understand my workflows, go ahead and enable them"
4. GitHub Actions is now enabled!

## Using the Workflow

### Automatic Build (On Push)

Simply push to the `main` branch:

```bash
# Make changes to your code
git add .
git commit -m "Update app features"
git push origin main
```

The workflow will automatically start building the Windows executable.

### Manual Build

1. Go to your repository on GitHub
2. Click the "Actions" tab
3. Select "Build Windows Executable" from the left sidebar
4. Click "Run workflow"
5. Select the branch (usually `main`)
6. Optionally add a version tag
7. Click "Run workflow" button

### Downloading the Executable

1. Go to the "Actions" tab in your repository
2. Click on the most recent "Build Windows Executable" run
3. Scroll down to the "Artifacts" section
4. Download `amerike_investment_sim-windows`
5. Unzip the downloaded file
6. Run `amerike_investment_sim.exe`

## Workflow Files Created

```
.github/
└── workflows/
    └── build-windows.yml    # Main workflow configuration
```

## What Gets Built

The workflow produces:
- **amerike_investment_sim.exe**: The main executable
- **All runtime dependencies**: Including SQLite, Flutter engine, etc.
- **Required DLLs**: Windows-specific libraries
- **Data directory structure**: For local database storage

## Build Process Details

The workflow:
1. Checks out your code
2. Installs Flutter 3.24.5 (latest stable)
3. Enables Windows desktop support
4. Downloads all dependencies (`flutter pub get`)
5. Builds in release mode (`flutter build windows --release`)
6. Creates a distribution directory
7. Renames the executable
8. Packages everything into a ZIP file
9. Uploads the artifact (kept for 30 days)

## Troubleshooting

### Build Fails

Check the workflow logs:
1. Click on the failed workflow run
2. Expand each step to see where it failed
3. Common issues:
   - **Flutter version mismatch**: The workflow uses Flutter 3.24.5
   - **Missing dependencies**: Ensure all dependencies in `pubspec.yaml` are compatible
   - **Windows-specific errors**: Check that your code runs locally on Windows first

### Download Issues

- **Artifact not appearing**: Wait a few minutes and refresh the page
- **Artifact expired**: Artifacts are kept for 30 days. Re-run the workflow if needed
- **Corrupted download**: Try downloading again or use a different browser

### Executable Won't Run

- **Windows Defender**: Windows may flag unsigned executables. Click "More info" → "Run anyway"
- **Missing dependencies**: The ZIP should include all dependencies. Ensure you extracted all files
- **Database errors**: The app will create the database on first run

## Advanced Configuration

### Change Flutter Version

Edit `.github/workflows/build-windows.yml`:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.5' # Change this version
```

### Modify Artifact Retention

Edit `.github/workflows/build-windows.yml`:

```yaml
- name: Upload build artifacts
  uses: actions/upload-artifact@v4
  with:
    name: amerike_investment_sim-windows
    path: amerike_investment_sim-v*-windows.zip
    retention-days: 30 # Change this value (1-90 days)
```

### Add More Platforms

You can extend the workflow to build for other platforms by adding more jobs:
- macOS (`.dmg` or `.app`)
- Linux (AppImage or tarball)
- Android (APK or AAB)
- iOS (IPA)

## CI/CD Best Practices

1. **Test before building**: The workflow currently builds directly. You can add test steps:
   ```yaml
   - name: Run tests
     run: flutter test
   ```

2. **Branch protection**: Enable branch protection rules to require passing workflows before merge

3. **Scheduled builds**: Add a schedule to build nightly:
   ```yaml
   on:
     schedule:
       - cron: '0 0 * * *' # Daily at midnight
   ```

4. **Release automation**: Create GitHub Releases automatically with the executable

## Support

For issues with:
- **GitHub Actions**: Check [GitHub Actions Documentation](https://docs.github.com/en/actions)
- **Flutter Windows builds**: Check [Flutter Desktop Support](https://flutter.dev/desktop)
- **This workflow**: Review the workflow logs and verify your local build works first

## Next Steps

Once comfortable with the basic workflow, consider:
1. Adding automated tests before the build step
2. Creating GitHub Releases for versioned releases
3. Adding code quality checks (linting, formatting)
4. Implementing automated changelog generation
5. Setting up multi-platform builds (macOS, Linux)
