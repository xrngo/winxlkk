Clear-Host

function Show-SystemInfo {

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $gpu = Get-CimInstance Win32_VideoController
    $ram = Get-CimInstance Win32_ComputerSystem
    $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    $profiles = Get-ChildItem ".\GameProfiles" -Directory

    for ($i = 0; $i -lt $profiles.Count; $i++) {
    Write-Host "[$($i + 1)] $($profiles[$i].Name)"
    }

    Write-Host ""
    Write-Host "========== SYSTEM INFORMATION =========="
    Write-Host ""
    Write-Host "Computer: $($os.CSName)"
    Write-Host "Windows:  $($os.Caption)"
    Write-Host "Version:  $($os.Version)"
    Write-Host "CPU: $($cpu.Name)"
    Write-Host "GPU: $($gpu.Name)"
    Write-Host "RAM: $($ramGB) GB"
    Write-Host ""
}
function Show-Cleanup {
    # здесь потом будет очистка
}
function Show-GamingProfiles {
Clear-Host
Write-Host "========================================"
Write-Host "          GAMINGPROFILES"
Write-Host "========================================"
Write-Host ""
Get-ChildItem ".\GameProfiles"
Write-Host "[0] Back"
Write-Host ""

            switch ($choice) { 


                "0" { 

                    return }

                    default {
                        Write-Host "Unknown option!"
                    }

            }
            Read-Host "Press Enter to return to menu"   
}    
function Show-Applications {

}



function Show-MainMenu {

      while ($true) {

Clear-Host
Write-Host "========================================"
Write-Host "          WIN OPTIMIZER v0.1"
Write-Host "========================================"
Write-Host ""
Write-Host "[1] System Information"
Write-Host "[2] Cleanup"
Write-Host "[3] GamingProfiles"
Write-Host "[4] Applications"
Write-Host "[0] Exit"
Write-Host ""

$choice = Read-Host "Select option"

switch ($choice) {

    "1" { 

        Show-SystemInfo
        Read-Host "Press Enter to return to menu"

    }

    "2" {
        
        Show-Cleanup 
        Read-Host "Press Enter to return to menu"

    }

    "3" {
        
        Show-GamingProfiles
        Read-Host "Press Enter to return to menu"
    
    }

    "4" {
        
        Show-Applications 
        Read-Host "Press Enter to return to menu"
    
    }

    "0" {

        Write-Host "Exit..."
        exit

        }

    default {

        Write-Host ""
        Write-Host "Unknown option!"
        Read-Host "Press Enter to continue"

    }
}
}   
}
Show-MainMenu