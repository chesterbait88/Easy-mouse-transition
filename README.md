# Mouse Monitor Position Tracker

A simple utility that helps seamlessly control cursor movement between multiple monitors, particularly useful for multi-monitor setups where the monitors have different resolutions or physical alignments.

## What It Does

This utility runs in the system tray and tracks your mouse position to help make cursor movement between monitors more intuitive:

- When moving from your primary monitor to a secondary monitor, it maintains the cursor's relative vertical position
- When moving back to the primary monitor, it returns the cursor to the position where you last left the primary monitor
- Automatically detects when the cursor has moved between monitors based on position changes
- Can be enabled/disabled through the system tray icon

## Features

- Runs silently in the system tray with minimal resource usage
- Maintains relative cursor position between monitors
- Toggle functionality on/off via the system tray icon
- No installation required - runs as a standalone executable
- Works with Windows multi-monitor setups

## Running the Application

### Pre-built Executable

Simply download the `Easy-mouse-transition.exe` file and run it. No installation is required.

1. Double-click on `Easy-mouse-transition.exe`
2. Look for the application icon in the system tray
3. Right-click the icon to enable/disable tracking or exit the application

### Auto-start with Windows

To have the application start automatically with Windows:

1. Create a shortcut to the `Easy-mouse-transition.exe` file
2. Press `Win+R` to open the Run dialog
3. Type `shell:startup` and press Enter
4. Move the shortcut to this Startup folder

## Creating the Executable from PowerShell Script

If you want to create the executable yourself from the PowerShell script:

### Requirements

- Windows PowerShell 5.0 or later
- PS2EXE module (PowerShell module for converting scripts to executables)

### Steps

1. Install the PS2EXE module if you don't have it already:
   ```powershell
   Install-Module -Name ps2exe -Scope CurrentUser -Force
   ```

2. Navigate to the directory containing the script:
   ```powershell
   cd "path\to\script\directory"
   ```

3. Run the following command to convert the PowerShell script to an executable:
   ```powershell
   Invoke-ps2exe -InputFile "Easy-mouse-transition.ps1" -OutputFile "Easy-mouse-transition.exe" -NoConsole -IconFile "Easy-mouse.ico"
   ```

## Using the Installer Batch File

The project includes an installer batch file (`Installer-Easy-mouse-transition.bat`) that provides an interactive menu with the following options:

1. Run PowerShell script directly
2. Create EXE file (automatically installs PS2EXE if needed)
3. Run the created EXE file
4. Exit

This is the recommended way to build and run the application, as it handles all dependencies and setup automatically.

## Technical Details

- The mouse position tracking runs on a 10ms timer interval (configurable in the PowerShell script)
- The system tray icon is embedded in the executable as a Base64 string
- The current implementation only maintains vertical position mapping when moving from primary to secondary monitor
- The system tray menu provides Disable and Exit options

## Understanding the Code

### PowerShell Script Overview

The script (`Easy-mouse-transition.ps1`) performs the following main functions:

- **Monitor Detection**: Identifies your primary and secondary monitors
- **Position Tracking**: Constantly monitors cursor position to detect monitor transitions
- **Position Adjustment**: When crossing monitor boundaries, adjusts cursor position based on relative screen heights*
- **System Tray Interface**: Provides a simple interface to enable/disable or exit the application

Key technical components:
- Uses Windows Forms for the system tray interface
- Employs a timer to monitor mouse position at regular intervals
- Handles multi-monitor setups using the `System.Windows.Forms.Screen` class

## Future Enhancements

The following improvements are planned for future versions:

### True Bi-directional Relative Positioning
- Currently, the application only maintains relative vertical positions when moving from primary to secondary monitor
- Future versions will implement true bi-directional relative positioning that preserves cursor position relationships in both directions
- This will create a more intuitive experience when moving back and forth between monitors

### Custom Application Icon
- Add visual indication of enabled/disabled state through the icon

### Support for Three or More Monitors
- Current implementation focuses on primary and one secondary monitor
- Future enhancement will intelligently handle 3+ monitor setups
- Will track positions across all monitor boundaries

### Additional Planned Improvements
- Configuration UI to adjust sensitivity and behavior
- Hotkey support for quickly toggling functionality
- Screen edge detection improvements to better handle different monitor arrangements
- Remember settings between application launches
- Support for portrait and landscape monitor mixing


## Contributing

Contributions to improve the Mouse Monitor Position Tracker are welcome!

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Guidelines

- Keep the code simple and efficient
- Maintain the silent operation (no console output)
- Test thoroughly with different monitor configurations
- Document any new features or significant changes
- Follow the existing code style



## Acknowledgments

- Inspired by the need for smoother cursor transitions in multi-monitor setups
- Built using PowerShell and PS2EXE
