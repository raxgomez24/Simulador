# GitHub Actions - Quick Start Guide

## 🚀 Get Your Windows Executable in 5 Minutes

### What's Already Set Up

You now have:
- ✅ GitHub Actions workflow (`.github/workflows/build-windows.yml`)
- ✅ Complete guide (`.github/GITHUB_ACTIONS_GUIDE.md`)
- ✅ Setup script (`scripts/setup-github.sh`)

### Option 1: Automated Setup (Recommended)

**Run the setup script:**

```bash
cd /Users/raxgomez/Documents/MBA/Tania
./scripts/setup-github.sh
```

The script will:
1. Initialize git (if needed)
2. Check the workflow files
3. Commit changes
4. Guide you through creating a GitHub repo
5. Push your code to GitHub

### Option 2: Manual Setup

**Step 1: Initialize Git**
```bash
cd /Users/raxgomez/Documents/MBA/Tania
git init
git add .
git commit -m "Add GitHub Actions workflow"
```

**Step 2: Create GitHub Repository**
1. Go to https://github.com/new
2. Name: `amerike_investment_sim`
3. Don't initialize with README
4. Click "Create repository"

**Step 3: Push to GitHub**
```bash
git remote add origin https://github.com/YOUR_USERNAME/amerike_investment_sim.git
git push -u origin main
```

**Step 4: Enable Actions**
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Click "I understand my workflows, go ahead and enable them"

**Step 5: Build Your Executable**
- Automatic: Just push to `main` branch
- Manual: Actions → Build Windows Executable → Run workflow

**Step 6: Download**
- Actions → Latest run → Artifacts → Download
- Unzip and run `amerike_investment_sim.exe`

## 📋 What Gets Built

- **amerike_investment_sim.exe** - Your Windows executable
- **All dependencies** - SQLite, Flutter engine, DLLs
- **Ready to run** - No installation needed

## 🎯 Key Features

- **Automatic builds** on every push to main/master
- **Manual triggers** anytime you want
- **Version tracking** with build numbers
- **30-day retention** for downloads
- **Complete dependencies** included

## 🔧 How It Works

```
Push to GitHub → GitHub Actions starts
                ↓
                Install Flutter
                ↓
                Build Windows Release
                ↓
                Package with dependencies
                ↓
                Upload as artifact
                ↓
                Download and run!
```

## 📖 Documentation

- **Quick start**: This file
- **Complete guide**: `.github/GITHUB_ACTIONS_GUIDE.md`
- **Workflow file**: `.github/workflows/build-windows.yml`

## 🐛 Troubleshooting

### Build fails?
- Check the Actions logs on GitHub
- Ensure your code builds locally first
- Verify `pubspec.yaml` dependencies

### Can't download?
- Wait a few minutes and refresh
- Ensure the workflow completed successfully
- Check the Artifacts section

### Windows blocks the exe?
- Click "More info" → "Run anyway"
- Windows Defender flags unsigned apps (this is normal)

## 🎉 Next Steps

Once comfortable:
1. Add automated tests
2. Create GitHub Releases
3. Add other platforms (macOS, Linux)
4. Set up scheduled builds

## 💡 Tips

- **Test locally** first: `flutter build windows --release`
- **Use main branch** for production builds
- **Create branches** for development to avoid unnecessary builds
- **Monitor build time** (typically 5-10 minutes)

## 📞 Support

Check the detailed guide: `.github/GITHUB_ACTIONS_GUIDE.md`

---

**Ready? Run this:**

```bash
cd /Users/raxgomez/Documents/MBA/Tania
./scripts/setup-github.sh
```

**Or do it manually** - see Option 2 above.

🚀 Happy building!
