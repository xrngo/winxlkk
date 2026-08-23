[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

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
    Write-Host "========== Информация о системе =========="
    Write-Host ""
    Write-Host "Компьютер: $($os.CSName)"
    Write-Host "Windows:  $($os.Caption)"
    Write-Host "Версия:  $($os.Version)"
    Write-Host "CPU: $($cpu.Name)"
    Write-Host "GPU: $($gpu.Name)"
    Write-Host "RAM: $($ramGB) GB"
    Write-Host ""
}
function Show-Cleanup {
    Clear-Host
    Write-Host "========================================"
    Write-Host "         Очистка системы"
    Write-Host "========================================"
    Write-Host ""

    # 1. ОЧИСТКА ВРЕМЕННЫХ ПАПОК
    Write-Host "[1/2] Очистка системных папок..." -ForegroundColor Yellow

    # Останавливаем службу обновлений, чтобы разблокировать файлы в SoftwareDistribution
    Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue

    $foldersToClean = @(
        $env:TEMP,                                       # %temp%
        "$env:SystemRoot\Temp",                         # C:\Windows\Temp
        "$env:SystemRoot\Prefetch",                     # C:\Windows\Prefetch
        "$env:SystemRoot\SoftwareDistribution\Download" # Кэш обновлений
    )

    foreach ($folder in $foldersToClean) {
        if (Test-Path $folder) {
            Write-Host "Очищаем: $folder"
            # Удаляем содержимое папки, не удаляя саму папку
            Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Включаем службу обновлений обратно
    Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

    # 2. АВТОМАТИЧЕСКАЯ "ОЧИСТКА ДИСКА" (CLEANMGR)
    Write-Host "`n[2/2] Запуск автоматической очистки диска Windows..." -ForegroundColor Yellow

    # Проставляем галочки (StateFlags0001 = 2) на всех пунктах очистки диска в реестре
    $volumeCaches = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Get-ChildItem -Path $volumeCaches | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "StateFlags0001" -Value 2 -ErrorAction SilentlyContinue
    }

    # Запускаем очистку диска с созданными галочками в фоновом режиме
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden

    Write-Host "Очистка полностью завершена!" -ForegroundColor Green
}

function Show-GamingProfiles {
Clear-Host
Write-Host "========================================"
Write-Host "          Профили для игр "
Write-Host "========================================"
Write-Host ""

$profiles = @(Get-ChildItem ".\GameProfiles" -Directory)

    for ($i = 0; $i -lt $profiles.Count; $i++) {
        Write-Host "[$($i + 1)] $($profiles[$i].Name)"
    }
    
    Write-Host "[0] Назад"
    Write-Host ""

    $choice = Read-Host "Выберите игру"

    if ($choice -eq "0") {
        return
    }

    $index = [int]$choice - 1 
    if ($index -ge 0 -and $index -lt $profiles.Count) {
        $selectedFolder = $profiles[$index]
        Write-Host "Вы выбрали игру: $($selectedFolder.Name)"
    }

            Read-Host "Нажмите Enter, чтобы вернуться в меню"   
}    
function Show-Applications {

}



function Show-MainMenu {

      while ($true) {

Clear-Host
Write-Host "========================================"
Write-Host "          winxlkk"
Write-Host "========================================"
Write-Host ""
Write-Host "[1] Информация о системе"
Write-Host "[2] Очистка"
Write-Host "[3] Профили для игр"
Write-Host "[4] Приложения"
Write-Host "[0] Выход"
Write-Host ""

$choice = Read-Host "Выберите опцию"

switch ($choice) {

    "1" { 

        Show-SystemInfo
        Read-Host "Нажмите Enter, чтобы вернуться в меню"

    }

    "2" {
        
        Show-Cleanup 
        Read-Host "Нажмите Enter, чтобы вернуться в меню"

    }

    "3" {
        
        Show-GamingProfiles
        Read-Host "Нажмите Enter, чтобы вернуться в меню"
    
    }

    "4" {
        
        Show-Applications 
        Read-Host "Нажмите Enter, чтобы вернуться в меню"
    
    }

    "0" {

        Write-Host "Выход из программы..."
        exit

        }

    default {

        Write-Host ""
        Write-Host "Неизвестная опция!"
        Read-Host "Нажмите Enter, чтобы продолжить"

    }
}
}   
}
Show-MainMenu