# 🐍 Python Virtual Environment Setup Guide

This guide will help you set up a Python virtual environment to run the fountain downloader scripts safely and efficiently.

## 🚀 Quick Setup (Recommended)

### Windows Users
1. **Double-click** `setup_venv.bat`
2. **Wait** for the setup to complete
3. **Run** the fountain downloader scripts

### Mac/Linux Users
1. **Make executable**: `chmod +x setup_venv.sh`
2. **Run setup**: `./setup_venv.sh`
3. **Run** the fountain downloader scripts

## 🔧 Manual Setup

If you prefer to set up manually or the automated setup fails:

### 1. Install Python
- **Download** Python 3.7+ from [python.org](https://python.org)
- **Verify installation**: `python --version` or `python3 --version`

### 2. Create Virtual Environment
```bash
# Navigate to scripts directory
cd scripts

# Create virtual environment
python -m venv .venv
# OR
python3 -m venv .venv
```

### 3. Activate Virtual Environment

**Windows:**
```cmd
.venv\Scripts\activate.bat
```

**Mac/Linux:**
```bash
source .venv/bin/activate
```

**PowerShell:**
```powershell
.venv\Scripts\Activate.ps1
```

### 4. Install Dependencies
```bash
# Upgrade pip
python -m pip install --upgrade pip

# Install requirements
pip install -r requirements.txt
```

## ✅ Verify Setup

After setup, you should see:
- `(.venv)` prefix in your terminal prompt
- Python packages installed successfully
- No error messages

## 🚰 Running the Scripts

### Activate Environment First
```bash
# Windows
.venv\Scripts\activate.bat

# Mac/Linux
source .venv/bin/activate
```

### Run Fountain Downloaders
```bash
# Download all fountains (worldwide)
python download_fountains.py

# Download Italy fountains only
python download_italy_fountains.py

# Download with custom options
python download_fountains.py --bbox "40.4774,-74.2591,40.9176,-73.7004" --limit 100
```

### Deactivate When Done
```bash
deactivate
```

## 📁 Project Structure

After setup, your directory should look like:
```
scripts/
├── .venv/                    # Virtual environment (created)
├── data/                     # Output directory (created)
├── download_fountains.py     # Main downloader
├── download_italy_fountains.py # Italy-specific downloader
├── requirements.txt          # Python dependencies
├── setup_venv.bat           # Windows setup
├── setup_venv.sh            # Mac/Linux setup
└── SETUP_GUIDE.md           # This file
```

## 🔍 Troubleshooting

### "Python not found" error
- Install Python from [python.org](https://python.org)
- Add Python to your system PATH
- Restart your terminal/command prompt

### "pip not found" error
- Upgrade pip: `python -m pip install --upgrade pip`
- Use: `python -m pip install -r requirements.txt`

### Virtual environment activation fails
- **Windows**: Use `call .venv\Scripts\activate.bat`
- **Mac/Linux**: Use `source .venv/bin/activate`
- **PowerShell**: Use `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Permission errors (Mac/Linux)
```bash
chmod +x setup_venv.sh
chmod +x download_italy_fountains.sh
```

### Package installation fails
- Check internet connection
- Try: `pip install --upgrade pip setuptools wheel`
- Then: `pip install -r requirements.txt`

## 🌍 Environment Variables

The virtual environment automatically sets:
- `VIRTUAL_ENV`: Path to virtual environment
- `PATH`: Includes virtual environment's Python and scripts
- `PYTHONPATH`: Includes virtual environment's packages

## 🔄 Updating Dependencies

To update packages in your virtual environment:
```bash
# Activate environment
source .venv/bin/activate  # Mac/Linux
# OR
.venv\Scripts\activate.bat  # Windows

# Update packages
pip install --upgrade -r requirements.txt
```

## 🗑️ Cleanup

To remove the virtual environment:
```bash
# Deactivate first
deactivate

# Remove directory
rm -rf .venv  # Mac/Linux
# OR
rmdir /s .venv  # Windows
```

## 📱 IDE Integration

### VS Code
1. Open the `scripts` folder in VS Code
2. Press `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac)
3. Type "Python: Select Interpreter"
4. Choose `.venv/bin/python` (Mac/Linux) or `.venv\Scripts\python.exe` (Windows)

### PyCharm
1. Open the `scripts` folder in PyCharm
2. Go to `File > Settings > Project > Python Interpreter`
3. Click the gear icon → "Add"
4. Choose "Existing Environment"
5. Select `.venv/bin/python` (Mac/Linux) or `.venv\Scripts\python.exe` (Windows)

## 🚨 Security Notes

- The virtual environment is isolated from your system Python
- Dependencies are installed only in the virtual environment
- No system-wide changes are made
- Safe to delete and recreate

## 📞 Getting Help

If you still have issues:

1. **Check Python version**: `python --version`
2. **Check pip version**: `pip --version`
3. **Verify virtual environment**: Look for `(.venv)` in your prompt
4. **Check requirements**: `pip list`
5. **Try manual setup** instead of automated scripts

## 🎯 Next Steps

After successful setup:

1. **Test the environment**: Run `python download_fountains.py --limit 5`
2. **Download Italy fountains**: Run `python download_italy_fountains.py`
3. **Import to Firebase**: Use the generated JSON files
4. **Explore other regions**: Use the main downloader with custom bounding boxes

Happy fountain hunting! 🚰🗺️
