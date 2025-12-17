# Digi Expense Tracker - Installer Edition

## 📦 What's New in This Release?

This is the **installable version** of Digi Expense Tracker with a professional Windows installer!

### 🎯 Two Versions Available:

1. **DigiExpenseTracker-Setup-v1.0.0.exe** (10.34 MB) - **RECOMMENDED**
   - Professional installer with setup wizard
   - Installs to Program Files
   - Creates Start Menu shortcuts
   - Creates Desktop shortcut (optional)
   - Includes uninstaller
   - One-click installation

2. **DigiExpenseTracker-Windows-v1.0.0.zip** (11.68 MB)
   - Portable version (no installation required)
   - Extract and run anywhere
   - Good for USB drives or temporary use

---

## 🚀 Installation Instructions (Installer Version)

### Step 1: Download
Download `DigiExpenseTracker-Setup-v1.0.0.exe` from the GitHub releases page.

### Step 2: Run the Installer
1. Double-click the downloaded `.exe` file
2. Windows may show a security warning - click **"More info"** then **"Run anyway"**
   (This happens because the app isn't digitally signed yet)

### Step 3: Follow the Setup Wizard
1. **Welcome Screen** - Click "Next"
2. **License Agreement** - Review and click "Next"
3. **Select Destination** - Choose where to install (default: `C:\Program Files\Digi Expense Tracker\`)
4. **Select Start Menu Folder** - Choose folder name (default is fine)
5. **Select Additional Tasks**:
   - ☑️ Create a desktop icon (recommended)
   - ☑️ Create a Quick Launch icon (optional)
6. **Ready to Install** - Review settings and click "Install"
7. **Completing Setup** - Choose to launch the app now

### Step 4: Launch the App
After installation, you can launch the app from:
- **Start Menu**: Search for "Digi Expense Tracker"
- **Desktop Icon**: Double-click the icon (if you created one)
- **Installation Folder**: `C:\Program Files\Digi Expense Tracker\digi_expense_tracker.exe`

---

## 🗑️ Uninstallation

To uninstall the application:

**Method 1: Windows Settings**
1. Open Windows Settings (Win + I)
2. Go to **Apps** → **Installed apps**
3. Find **"Digi Expense Tracker"**
4. Click the three dots and select **"Uninstall"**

**Method 2: Start Menu**
1. Open Start Menu
2. Find **"Digi Expense Tracker"** folder
3. Click **"Uninstall Digi Expense Tracker"**

**Method 3: Control Panel**
1. Open Control Panel
2. Go to **Programs** → **Programs and Features**
3. Find **"Digi Expense Tracker"**
4. Click **"Uninstall"**

---

## 📋 System Requirements

- **Operating System**: Windows 10 or later (64-bit)
- **RAM**: Minimum 4GB recommended
- **Storage**: ~30MB free disk space
- **Permissions**: Administrator rights (for installation only)

---

## ✨ Features

- ✅ Track your daily expenses
- ✅ Categorize transactions
- ✅ View expense charts and analytics
- ✅ Beautiful, user-friendly interface
- ✅ Offline data storage using Hive
- ✅ No internet connection required

---

## 🔧 Troubleshooting

### Windows SmartScreen Warning
**Issue**: "Windows protected your PC" message appears  
**Solution**: 
1. Click **"More info"**
2. Click **"Run anyway"**
3. This happens because the app isn't code-signed (requires expensive certificate)

### Installation Requires Admin Rights
**Issue**: "You need administrator privileges to install"  
**Solution**: Right-click the installer and select **"Run as administrator"**

### App Won't Start After Installation
**Issue**: Application doesn't launch  
**Solution**: 
1. Make sure installation completed successfully
2. Try running from Start Menu instead of desktop icon
3. Check Windows Event Viewer for error details

---

## 🔄 Updating to a New Version

When a new version is released:
1. Download the new installer
2. Run it - it will automatically uninstall the old version
3. Follow the installation wizard

**Note**: Your data is stored in your user profile and will be preserved during updates!

---

## 📊 Data Storage Location

Your expense data is stored locally at:
```
C:\Users\<YourUsername>\AppData\Local\digi_expense_tracker\
```

To backup your data, copy this folder to a safe location.

---

## 🐛 Report Issues

If you encounter any issues, please report them on GitHub:
https://github.com/Munavvar-kavanur/Digi-Wallet/issues

---

## 📝 Version History

### v1.0.0 (December 14, 2025)
- ✨ **NEW**: Professional Windows installer
- ✨ Initial release with installable package
- ✨ Core expense tracking features
- ✨ Data visualization with charts
- ✨ Local data storage with Hive

---

## 🎨 Built With

- **Flutter** - Google's UI toolkit for beautiful native applications
- **Hive** - Fast, lightweight local database
- **Riverpod** - State management
- **FL Chart** - Beautiful charts and graphs

---

Made with ❤️ by Munavvar Kavanur
