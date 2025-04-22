# Easy-mouse-transition 1.0.1
# A utility to help with cursor movement between multiple monitors

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables to store positions
$script:lastKnownPosition = $null
$script:previousPosition = $null
$script:isOnPrimaryMonitor = $true
$script:primary = [System.Windows.Forms.Screen]::PrimaryScreen
$script:isEnabled = $true  # Flag to enable/disable the script functionality

# Function to get current mouse position
function Get-MousePosition {
    [System.Windows.Forms.Cursor]::Position
}

# Function to set mouse position
function Set-MousePosition([System.Drawing.Point]$point) {
    [System.Windows.Forms.Cursor]::Position = $point
    # Return nothing to suppress output
    return
}

# Function to check if point is on primary monitor
function Test-PointOnPrimaryMonitor([System.Drawing.Point]$point) {
    return $script:primary.Bounds.Contains($point)
}

# Function to check if position change is abrupt (indicates monitor switch)
function Test-AbruptChange([System.Drawing.Point]$current, [System.Drawing.Point]$previous) {
    if ($null -eq $previous) { return $false }
    $threshold = 100  # Adjust this value to determine what constitutes an "abrupt" change
    $deltaX = [Math]::Abs($current.X - $previous.X)
    $deltaY = [Math]::Abs($current.Y - $previous.Y)
    return ($deltaX -gt $threshold) -or ($deltaY -gt $threshold)
}

# Function to calculate relative position on secondary monitor
function Get-RelativePosition([System.Drawing.Point]$point) {
    $primaryHeight = $script:primary.Bounds.Height
    $relativeY = $point.Y / $primaryHeight  # Get percentage position (0-1)

    # Get secondary monitor
    $secondary = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary }
    if ($secondary) {
        # Calculate new Y position maintaining same relative height
        $newY = [Math]::Round($relativeY * $secondary.Bounds.Height)
        # Position at left edge of secondary monitor
        $newX = $secondary.Bounds.X
        return New-Object System.Drawing.Point($newX, $newY)
    }
    return $point
}

# Create global variables for tray icon components
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:contextMenu = New-Object System.Windows.Forms.ContextMenu
$script:menuEnable = New-Object System.Windows.Forms.MenuItem
$script:menuExit = New-Object System.Windows.Forms.MenuItem

# Function to toggle enabled/disabled state
function Toggle-EnabledState {
    if ($script:isEnabled) {
        $script:isEnabled = $false
        $script:menuEnable.Text = "Enable"
        $script:notifyIcon.Text = "Monitor Position Tracker (Disabled)"
    } else {
        $script:isEnabled = $true
        $script:menuEnable.Text = "Disable"
        $script:notifyIcon.Text = "Monitor Position Tracker (Enabled)"
    }
}

# Function to exit the application
function Exit-Application {
    $script:notifyIcon.Visible = $false
    $script:notifyIcon.Dispose()
    $script:contextMenu.Dispose()
    [System.Windows.Forms.Application]::Exit()
}

# Function to create a bitmap from base64 string
function ConvertFrom-Base64ToBitmap {
    param([string]$base64String)

    try {
        $bytes = [System.Convert]::FromBase64String($base64String)
        $stream = New-Object System.IO.MemoryStream($bytes, 0, $bytes.Length)
        $bitmap = [System.Drawing.Bitmap]::FromStream($stream)
        $stream.Close()
        return $bitmap
    }
    catch {
        Write-Error "Failed to convert base64 to bitmap: $_"
        return $null
    }
}

# Function to create icon from bitmap
function ConvertFrom-BitmapToIcon {
    param([System.Drawing.Bitmap]$bitmap)

    try {
        # Create a memory stream to save the icon
        $memoryStream = New-Object System.IO.MemoryStream

        # Save bitmap as icon to the memory stream
        $bitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Icon)

        # Reset stream position
        $memoryStream.Position = 0

        # Create icon from stream
        $icon = New-Object System.Drawing.Icon($memoryStream)
        $memoryStream.Close()

        return $icon
    }
    catch {
        Write-Error "Failed to convert bitmap to icon: $_"
        return $null
    }
}

# Function to create tray icon
function Initialize-TrayIcon {
    # Set up the notify icon
    $script:notifyIcon.Text = "Monitor Position Tracker (Enabled)"

    # Try to load the icon from the icon.base64 file
    $iconBase64 = ""
    $iconBase64FilePath = "icon.base64"

    # Try to find the icon.base64 file in various locations
    $possibleLocations = @()

    # Add current directory
    $possibleLocations += (Get-Location).Path

    # Add script directory if available
    if ($PSScriptRoot) {
        $possibleLocations += $PSScriptRoot
    }

    # Add execution path if available
    if ($MyInvocation.MyCommand.Path) {
        $possibleLocations += (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }

    # Add the directory where the EXE is located when compiled
    if ($MyInvocation.MyCommand.Path -match '\.exe$') {
        $possibleLocations += (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }

    # Try to find and load the icon.base64 file
    $iconBase64FileFound = $false
    foreach ($location in $possibleLocations) {
        $iconBase64FilePath = Join-Path -Path $location -ChildPath "icon.base64"
        if (Test-Path -Path $iconBase64FilePath) {
            try {
                $iconBase64 = Get-Content -Path $iconBase64FilePath -Raw
                $iconBase64FileFound = $true
                break
            }
            catch {
                Write-Host ("Error reading icon.base64 file from {0}: {1}" -f $iconBase64FilePath, $_.Exception.Message)
            }
        }
    }

    # The rest of your Initialize-TrayIcon function
    try {
        # Method 1: Create icon directly from Base64
        if ($iconBase64FileFound) {
                        $iconBytes = [System.Convert]::FromBase64String($iconBase64)

            $iconStream = New-Object System.IO.MemoryStream($iconBytes, 0, $iconBytes.Length)

            $script:notifyIcon.Icon = New-Object System.Drawing.Icon($iconStream)

        }
        else {
            throw "icon.base64 file not found"
        }
    }
    catch {
        Write-Host ("Error creating icon from base64: {0}" -f $_.Exception.Message)

        try {
            # Method 2: Convert Base64 to bitmap first, then to icon
            if ($iconBase64FileFound) {
                $bitmap = ConvertFrom-Base64ToBitmap -base64String $iconBase64
                if ($bitmap) {
                    $icon = ConvertFrom-BitmapToIcon -bitmap $bitmap
                    if ($icon) {
                        $script:notifyIcon.Icon = $icon
                    }
                }
            }
            else {
                throw "icon.base64 file not found"
            }
        }
        catch {
            Write-Host ("Error converting bitmap to icon: {0}" -f $_.Exception.Message)

            try {
                # Method 3: Try to load from file locations

                # Try to find icon in possible locations
                $iconFound = $false
                foreach ($location in $possibleLocations) {
                    $iconFile = Join-Path -Path $location -ChildPath "Easy-mouse.ico"
                    if (Test-Path -Path $iconFile) {
                        $script:notifyIcon.Icon = New-Object System.Drawing.Icon($iconFile)
                        $iconFound = $true
                        Write-Host "Loaded icon from $iconFile"
                        break
                    }
                }

                # Add the system32 directory as a source of default icons
                if (-not $iconFound) {
                    $iconFile = "$env:SystemRoot\System32\Easy-mouse.ico"
                    if (Test-Path -Path $iconFile) {
                        $script:notifyIcon.Icon = New-Object System.Drawing.Icon($iconFile)
                        $iconFound = $true
                        Write-Host "Loaded icon from $iconFile"
                    }
                }

                # If icon still not found, use embedded resource approach
                if (-not $iconFound) {
                    # Method 4: Try to extract icon from the executable itself
                    if ($MyInvocation.MyCommand.Path -match '\.exe$') {
                        $exePath = $MyInvocation.MyCommand.Path
                        $extractIcon = Add-Type -MemberDefinition @'
                        [DllImport("shell32.dll", CharSet = CharSet.Auto)]
                        public static extern IntPtr ExtractIcon(IntPtr hInst, string lpszExeFileName, int nIconIndex);
'@ -Name ExtractIcon -Namespace Shell32 -PassThru

                        $hIcon = $extractIcon::ExtractIcon([IntPtr]::Zero, $exePath, 0)
                        if ($hIcon -ne [IntPtr]::Zero) {
                            $script:notifyIcon.Icon = [System.Drawing.Icon]::FromHandle($hIcon)
                            Write-Host "Extracted icon from executable"
                        }
                    }
                }
            }
            catch {
                Write-Host ("Error loading icon from file: {0}" -f $_.Exception.Message)
            }
        }
    }

    # If all else fails, use default system icon
    if ($null -eq $script:notifyIcon.Icon) {
        $script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
        Write-Host "Using default system icon"
    }

    # Set up menu items
    $script:menuEnable.Text = "Disable"
    $script:menuEnable.Add_Click({ Toggle-EnabledState })

    $script:menuExit.Text = "Exit"
    $script:menuExit.Add_Click({ Exit-Application })

    # Add menu items to context menu
    $script:contextMenu.MenuItems.Add($script:menuEnable) | Out-Null
    $script:contextMenu.MenuItems.Add($script:menuExit) | Out-Null

    # Finish setting up the notify icon
    $script:notifyIcon.ContextMenu = $script:contextMenu
    $script:notifyIcon.Visible = $true
}

# Create and show the tray icon
[void](Initialize-TrayIcon)

# Create a form to process Windows messages
$form = New-Object System.Windows.Forms.Form
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.ShowInTaskbar = $false
$form.Width = 0
$form.Height = 0

# Set up a timer to handle the mouse monitoring
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10
$timer.Add_Tick({
    if (-not $script:isEnabled) {
        # Skip processing when disabled
        return
    }

    $currentPosition = Get-MousePosition
    $onPrimary = Test-PointOnPrimaryMonitor $currentPosition

    # Check for abrupt position change while leaving primary
    if ($script:isOnPrimaryMonitor -and -not $onPrimary) {
        if (Test-AbruptChange $currentPosition $script:previousPosition) {
            $script:lastKnownPosition = $script:previousPosition
            $script:isOnPrimaryMonitor = $false
            # Set relative position on secondary monitor
            $relativePos = Get-RelativePosition $script:previousPosition
            [void](Set-MousePosition $relativePos)
        }
    }
    # Mouse returning to primary monitor
    elseif (-not $script:isOnPrimaryMonitor -and $onPrimary) {
        if ($script:lastKnownPosition) {
            Set-MousePosition $script:lastKnownPosition
        }
        $script:isOnPrimaryMonitor = $true
    }

    $script:previousPosition = $currentPosition
})

# Start the timer
[void]($timer.Start())

# Main application loop
try {
    # Start the Windows Forms message loop
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    # Clean up resources
    if ($null -ne $script:notifyIcon) {
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
    }
    if ($null -ne $script:contextMenu) {
        $script:contextMenu.Dispose()
    }
    if ($null -ne $timer) {
        $timer.Stop()
        $timer.Dispose()
    }
    if ($null -ne $form) {
        $form.Dispose()
    }
}