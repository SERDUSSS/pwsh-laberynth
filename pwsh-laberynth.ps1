# Set global variables for rendering
$global:FOV = [math]::PI / 3  # Field of view (60 degrees)
$global:maxDepth = 64  # Max raycasting depth
# Expanded shading array with block characters for solid walls
$global:shading = @(
    ".", ".", ".", ".", ".", ".", ".", ".", ".", ".", ":", ":", ":", ":", "*", "*", "*", "*", "o", "$", "#"#, "▓", "█", "▒", "░"
)

$global:sleepTime = 0
$Red    = "`e[31m"  # Red color
$Green  = "`e[32m"  # Green color
$Yellow = "`e[33m"  # Yellow color
$Blue   = "`e[34m"  # Blue color
$Reset  = "`e[0m"   # Reset color

# Color mode
$global:colorActive = $true

# Debug mode
$global:debugActive = $false

# Example map (you can modify it)
$global:mapActive = $false

function Main-Menu {
    while ($done -ne $true) {
        Clear-Host
        Write-Host "Controls:"
        Write-Host "`tW`tWalk"
        Write-Host "`tA`tRotate Left"
        Write-Host "`tS`tWalk Backwards"
        Write-Host "`tD`tRotate Right"
        Write-Host "`tB`tOpen Debug"
        Write-Host "`tM`tOpen Map"
        Write-Host "`tC`tColor mode (on/off)"
        Write-Host
        Write-Host "Select map dimensions:"
        Write-Host "`t1.`t8x8       (Sandbox)"
        Write-Host "`t2.`t16x16     (Very Easy)"
        Write-Host "`t3.`t32x32     (Easy)"
        Write-Host "`t4.`t64x64     (Medium)"
        Write-Host "`t5.`t128x128   (Hard)"
        Write-Host "`t6.`t256x256   (Very Hard)"
        Write-Host "`t7.`t512x512   (Extreme)"
        Write-Host "`t8.`t1024x1024 (Brainfuck)"
        Write-Host "`t9.`tCustom"
        Write-Host "`t0.`tExit"
        Write-Host
        $choice = Read-Host "Select option (1, 2, 3...)"

        switch ($choice) {
            "1" {
                $global:mapWidth  = 7
                $global:mapHeight = 7
                $done = $true
            }
            "2" {
                $global:mapWidth  = 15
                $global:mapHeight = 15
                $done = $true
            }
            "3" {
                $global:mapWidth  = 31
                $global:mapHeight = 31
                $done = $true
            }
            "4" {
                $global:mapWidth  = 63
                $global:mapHeight = 63
                $done = $true
            }
            "5" {
                $global:mapWidth  = 127
                $global:mapHeight = 127
                $done = $true
            }
            "6" {
                $global:mapWidth  = 255
                $global:mapHeight = 255
                $done = $true
            }
            "7" {
                $global:mapWidth  = 511
                $global:mapHeight = 511
                $done = $true
            }
            "8" {
                $global:mapWidth  = 1023
                $global:mapHeight = 1023
                $done = $true
            }
            "9" {
                [int]$inputWidth  = Read-Host "Enter width (Has to be a power of 2)"
                if (($inputWidth -gt 0) -and (($inputWidth -band ($inputWidth - 1)) -eq 0)) {
                    if ($inputWidth -ge 8) {
                        $global:mapWidth = $inputWidth - 1
                    } else {
                        Write-Host "$Red[!] The minimum dimensions are 8x8$Reset"
                        Pause
                        Main-Menu
                    }
                } else {
                    Write-Host "$Red[!] The number has to be a power of 2$Reset"
                    Pause
                    Main-Menu
                }
                
                [int]$inputHeight = Read-Host "Enter height (Has to be a power of 2)"
                if (($inputHeight -gt 0) -and (($inputHeight -band ($inputHeight - 1)) -eq 0)) {
                    if ($inputHeight -ge 8) {
                        $global:mapHeight = $inputHeight - 1
                    } else {
                        Write-Host "$Red[!] The minimum dimensions are 8x8$Reset"
                        Pause
                        Main-Menu
                    }
                } else {
                    Write-Host "$Red[!] The number has to be a power of 2$Reset"
                    Pause
                    Main-Menu
                }
                $done = $true
            }
            "0" {
                Exit
            }
            default {
                Write-Host "$Red[!] Invalid option$Reset"
                pause
            }
        }
    }
}

Main-Menu

function Generate-Maze {
    param(
        [int]$width,  # Keep odd for symmetry
        [int]$height
    )

    Write-Host "$Green[+] Generating Map...$Reset"
    Write-Host "Generating canvas"

    if ($width % 2 -eq 0) { $width++ }
    if ($height % 2 -eq 0) { $height++ }

    $maze = @()
    for ($y = 0; $y -lt $height; $y++) {
        $maze += ("#" * $width)
    }

    function Carve-Maze {
        param($x, $y)

        $directions = @( [array]@(2,0), [array]@(0,2), [array]@(-2,0), [array]@(0,-2) ) | Sort-Object { Get-Random }

        foreach ($dir in $directions) {
            $nx = $x + $dir[0]
            $ny = $y + $dir[1]

            if ($nx -gt 0 -and $ny -gt 0 -and $nx -lt ($width - 1) -and $ny -lt ($height - 1) -and $maze[$ny][$nx] -eq "#") {
                $maze[$y] = $maze[$y].Substring(0, $x) + " " + $maze[$y].Substring($x + 1)
                $maze[$ny] = $maze[$ny].Substring(0, $nx) + " " + $maze[$ny].Substring($nx + 1)

                $wx = $x + ($dir[0] / 2)
                $wy = $y + ($dir[1] / 2)
                $maze[$wy] = $maze[$wy].Substring(0, $wx) + " " + $maze[$wy].Substring($wx + 1)

                Carve-Maze -x $nx -y $ny
            }
        }
    }

    $startX = [math]::Floor($width / 2)
    $startY = [math]::Floor($height / 2)
    Write-Host "Carving maze"
    Carve-Maze -x $startX -y $startY

    function Place-Exit {
        Write-Host "Placing exit"
        $exitX = $width - 1  
        $exitY = $height - 2

        $rowChars = $maze[$exitY].ToCharArray()
        $rowChars[$exitX] = "E"
        $maze[$exitY] = -join $rowChars

        return $maze -replace 'E', "$red`E$reset"
    }

    $maze = Place-Exit

    # **Remove 1 in 6 walls randomly (excluding outer walls)**
    Write-Host "Removing wall randomly"
    for ($y = 1; $y -lt $height - 1; $y++) {
        for ($x = 1; $x -lt $width - 1; $x++) {
            if ($maze[$y][$x] -eq "#" -and (Get-Random -Minimum 1 -Maximum 7) -eq 1) {
                $maze[$y] = $maze[$y].Substring(0, $x) + " " + $maze[$y].Substring($x + 1)
            }
        }
    }

    return $maze
}

# Generate the maze
$global:map = Generate-Maze -width $global:mapWidth -height $global:mapHeight

# Global variables for player position and angle
Write-Host "$Green[+] Calculating initial position...$Reset"
$global:playerX = $global:mapWidth / 2
$global:playerY = $global:mapHeight / 2

# Function to calculate angle to a target point (x, y)
function Calculate-Angle {
    param ($targetX, $targetY)

    Write-Host "Calculating angle"
    
    # Calculate the angle between the player and the target (in radians)
    $angle = [math]::Atan2($targetY - $global:playerY, $targetX - $global:playerX)

    # Round the angle to 1 decimal place (rounding correctly to the nearest 0.5)
    return $angle
}

# Function to find the first empty space around the player in cardinal directions (up, right, down, left)
function Find-InitialAngle {
    # Cardinal direction offsets (right, down, left, up)
    $directions = @(
        [array]@(1, 0),  # Right
        [array]@(0, 1),  # Down
        [array]@(-1, 0), # Left
        [array]@(0, -1)  # Up
    )

    Write-Host "$Green[+] Calculating Initial Angle...$Reset"

    # Search for the first empty space around the player
    foreach ($dir in $directions) {
        $testX = $global:playerX + $dir[0]
        $testY = $global:playerY + $dir[1]
        Write-Host "Checking position: $([math]::Floor($testX)), $([math]::Floor($testY)) - Value: $($global:map[[math]::Floor($testY)][[math]::Floor($testX)])"

        # Ensure the new position is within bounds
        if ($testX -ge 0 -and $testX -lt $global:mapWidth -and $testY -ge 0 -and $testY -lt $global:mapHeight) {
            if ($global:map[[math]::Floor($testY)][[math]::Floor($testX)] -eq " ") {
                # Found an empty space, calculate the angle and return it
                Write-Host "Found empty space at $([math]::Floor($testX)), $([math]::Floor($testY))"
                
                $angle = Calculate-Angle -targetX $testX -targetY $testY
                Write-Host "Initial Angle: $angle"
                return $angle
            }
        }
    }

    # There's no empty space, rerun
    Write-Host "$Red[!] Could not find any open space, regenerating maze...$Reset"
    $map = Generate-Maze -width $global:mapWidth -height $global:mapHeight
    Find-InitialAngle
}

# Set the player's initial angle
$global:playerAngle = Find-InitialAngle

# Function to get terminal size
function Get-TerminalSize {
    $terminalHeight = $Host.UI.RawUI.WindowSize.Height
    if ($global:mapActive -eq $true) {
    	$mapLength = $global:map.Length
    	return @{
        	Width  = $Host.UI.RawUI.WindowSize.Width
        	Height = $terminalHeight - $mapLength - 1 - $debugActive
    	}
    } else {
	    return @{
		    Width  = $Host.UI.RawUI.WindowSize.Width
		    Height = $terminalHeight - 1 - $debugActive
    	}
    }
}

# Function to render the 3D raycasting frame with minimap
function Render-Frame {
    # Get the terminal size
    $terminalSize = Get-TerminalSize
    $screenWidth = $terminalSize.Width
    $screenHeight = $terminalSize.Height

    $frame = @()

    if ($mapActive -and [int]$screenHeight -gt 0 -and [int]$screenWidth -gt 0 -or -not $mapActive) {
        for ($x = 0; $x -lt $screenWidth; $x++) {
            # Ray angle based on field of view and screen position
            $rayAngle = ($global:playerAngle - $global:FOV / 2) + ($x / $screenWidth) * $global:FOV

            # Ray direction
            $rayDirX = [math]::Cos($rayAngle)
            $rayDirY = [math]::Sin($rayAngle)

            # Current player grid position
            $mapX = [math]::Floor($global:playerX)
            $mapY = [math]::Floor($global:playerY)

            # Length of ray from one x-side to next x-side
            $deltaDistX = [math]::Abs(1 / $rayDirX)
            $deltaDistY = [math]::Abs(1 / $rayDirY)

            # Step direction (+1 or -1) and initial side distance
            if ($rayDirX -lt 0) {
                $stepX = -1
                $sideDistX = ($global:playerX - $mapX) * $deltaDistX
            } else {
                $stepX = 1
                $sideDistX = ($mapX + 1 - $global:playerX) * $deltaDistX
            }

            if ($rayDirY -lt 0) {
                $stepY = -1
                $sideDistY = ($global:playerY - $mapY) * $deltaDistY
            } else {
                $stepY = 1
                $sideDistY = ($mapY + 1 - $global:playerY) * $deltaDistY
            }

            # Perform DDA (Digital Differential Analyzer) stepping
            $hit = $false
            $side = 0  # 0 for X-side, 1 for Y-side

            while (-not $hit -and $mapX -ge 0 -and $mapX -lt $global:mapWidth -and $mapY -ge 0 -and $mapY -lt $global:mapHeight) {
                # Step in X or Y direction
                if ($sideDistX -lt $sideDistY) {
                    $sideDistX += $deltaDistX
                    $mapX += $stepX
                    $side = 0
                } else {
                    $sideDistY += $deltaDistY
                    $mapY += $stepY
                    $side = 1
                }

                # Check if we've hit a wall
                if ($global:map[$mapY][$mapX] -eq "#") {
                    $hit = $true
                }
            }

            # Calculate distance to wall
            if ($side -eq 0) {
                $distance = ($mapX - $global:playerX + (1 - $stepX) / 2) / $rayDirX
            } else {
                $distance = ($mapY - $global:playerY + (1 - $stepY) / 2) / $rayDirY
            }

            # Reverse shading for closer objects
            $shadingScale = ($shading.Length - 1) / $global:maxDepth
            $shadeIndex = [math]::Min([math]::Floor(($global:maxDepth - $distance) * $shadingScale), $shading.Length - 1)
            $wallChar = if ($hit) { $shading[$shadeIndex] } else { " " }

            # Calculate wall height
            $wallHeight = [math]::Floor($screenHeight / $distance)

            # Create an empty column
            $column = @(" " * $screenHeight) -split ""

            # Populate the column with the wall character
            for ($y = 0; $y -lt $screenHeight; $y++) {
                if ($y -gt ($screenHeight / 2 - $wallHeight) -and $y -lt ($screenHeight / 2 + $wallHeight)) {
                    $column[$y] = $wallChar
                }
            }

            # Add the column to the frame
            $frame += ($column -join "")
        }

        # Render frame
        $renderOutput = New-Object System.Text.StringBuilder
        for ($y = 0; $y -lt $screenHeight; $y++) {
            for ($x = 0; $x -lt $screenWidth; $x++) {
                $renderOutput.Append($frame[$x][$y]) > $null
            }
            $renderOutput.Append("`n") > $null
        }
    }
    
    Clear-Host

    if ($mapActive -and [int]$screenHeight -gt 0 -and [int]$screenWidth -gt 0 -or -not $mapActive) {
        [System.Console]::Write($renderOutput.ToString())
    }

    # Display player information and map below the 3D view
    if ($debugActive -eq $true) {
        Write-Host "Player Position: X = $([math]::Round($global:playerX, 2)), Y = $([math]::Round($global:playerY, 2)), Angle = $([math]::Round($global:playerAngle, 2))"
    }

    function Get-PlayerArrow {
        # Normalize the angle to be between 0 and 2π (handles negative angles correctly)
        $normalizedAngle = $global:playerAngle % (2 * [math]::PI)

        # If the angle is negative, add 2π to bring it into the positive range
        if ($normalizedAngle -lt 0) {
            $normalizedAngle += 2 * [math]::PI
        }

        # Check if the player is facing down, left, up, or right (shifted clockwise)
        if (($normalizedAngle -lt [math]::PI / 4) -or ($normalizedAngle -ge 7 * [math]::PI / 4)) {
            return ">"  # Facing Right (0 to π/4 or 7π/4 to 2π)
        } elseif ($normalizedAngle -ge [math]::PI / 4 -and $normalizedAngle -lt 3 * [math]::PI / 4) {
            return "v"  # Facing Down (π/4 to 3π/4)
        } elseif ($normalizedAngle -ge 3 * [math]::PI / 4 -and $normalizedAngle -lt 5 * [math]::PI / 4) {
            return "<"  # Facing Left (3π/4 to 5π/4)
        } else {
            return "^"  # Facing Up (5π/4 to 7π/4)
        }
    }

    if ($global:mapActive -eq $true) {
        # Display map with player position and direction
        for ($y = 0; $y -lt $global:map.Length; $y++) {
            $row = $global:map[$y]

            # Mark the player's position with the arrow depending on direction
            $mapRow = ""
            for ($x = 0; $x -lt $row.Length; $x++) {
                if ($y -eq [math]::Floor($global:playerY) -and $x -eq [math]::Floor($global:playerX)) {
                    # Replace 'P' with the arrow for the player's facing direction
                    $arrow = Get-PlayerArrow
                    $mapRow += "$green$arrow$reset"
                } else {
                    $mapRow += $row[$x]
                }
            }

            Write-Host $mapRow
        }
    }

    if ($mapActive -and $screenHeight -lt 0 -or $screenWidth -lt 0) {
        Write-Host "$Red[!] Not enough space. Disable map, zoom out or make the screen bigger to display game frames.$Reset"
    }
}

# Move the player and check for walls
function Move-Player {
    param($direction)
    $moveSpeed = 0.2  # Movement speed
    $turnSpeed = [math]::PI / 16  # Turn speed (angle change when turning)
    $collisionBuffer = 0.3  # Small buffer to prevent corner clipping

    # Calculate proposed new position
    $newX = $global:playerX
    $newY = $global:playerY

    if ($direction -eq "W") {
        # Move forward
        $newX += [math]::Cos($global:playerAngle) * $moveSpeed
        $newY += [math]::Sin($global:playerAngle) * $moveSpeed
    } elseif ($direction -eq "S") {
        # Move backward
        $newX -= [math]::Cos($global:playerAngle) * $moveSpeed
        $newY -= [math]::Sin($global:playerAngle) * $moveSpeed
    } elseif ($direction -eq "A") {
        # Turn left
        $global:playerAngle -= $turnSpeed
        return  # No need to check movement on turning
    } elseif ($direction -eq "D") {
        # Turn right
        $global:playerAngle += $turnSpeed
        return  # No need to check movement on turning
    }

    # Check collision for new X position
    $floorX = [math]::Floor($newX)
    $floorY = [math]::Floor($global:playerY)  # Keep Y the same for now

    if ($global:map[$floorY][$floorX] -ne "#") {
        $global:playerX = $newX  # Move in X direction only if no collision
    }

    # Check collision for new Y position
    $floorX = [math]::Floor($global:playerX)  # Keep new X from previous check
    $floorY = [math]::Floor($newY)

    if ($global:map[$floorY][$floorX] -ne "#") {
        $global:playerY = $newY  # Move in Y direction only if no collision
    }
}

# Start a stopwatch to track time
Write-Host "$Green[+] Started timer$Reset"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "$Green[+] Game ready$Reset"

# Game loop
while ($true) {
    # Render the current frame
    Render-Frame

    # Check if the player reached the exit
    $floorX = [math]::Floor($global:playerX)
    $floorY = [math]::Floor($global:playerY)
    if ($global:map[$floorY][$floorX] -eq "`e") {
        Clear-Host
        $stopwatch.Stop()
        $timeTaken = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
        Write-Host "`n🎉 You Won! Time: $timeTaken seconds 🎉" -ForegroundColor Green
        break
    }

    # Read input for movement
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

    switch -wildcard ($key) {
        '[WASDwasd]' { Move-Player -direction $key }
        '[Mm]'       { $global:mapActive = -not $global:mapActive }
        '[Bb]'       { $global:debugActive = -not $global:debugActive }
        '[Qq]' {
            Clear-Host
            Write-Host "`n$Green[+] Leaving game...$Reset"
            exit
        }
        '[Cc]' {
            $global:colorActive = -not $global:colorActive
            if ($global:colorActive) {
                $Red    = "`e[31m"
                $Green  = "`e[32m"
                $Yellow = '`e[33m'
                $Blue   = "`e[34m"
                $Reset  = "`e[0m"
            } elseif (-not $global:colorActive) {
                $Red    = ""
                $Green  = ""
                $Yellow = ""
                $Blue   = ""
                $Reset  = ""
            }
        }
    }

    Start-Sleep -Milliseconds $global:sleepTime
}
