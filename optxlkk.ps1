[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$GitHubApi = "https://api.github.com/repos/xrngo/winxlkk/contents"

Clear-Host
function Show-GameProfileMenu {

    param (
        $selectedFolder
    )

    while ($true) {

        Clear-Host

        Write-Host "========================================"
        Write-Host "       Профиль игры: $($selectedFolder.name)"
        Write-Host "========================================"
        Write-Host ""

        try {

            $nipProfiles = @(
                Invoke-RestMethod $selectedFolder.url |
                Where-Object {
                    $_.type -eq "file" -and
                    $_.name -like "*.nip"
                }
            )

        }
        catch {

            Write-Host ""
            Write-Host "Не удалось получить профили с GitHub!" -ForegroundColor Red

            Read-Host "Нажмите Enter, чтобы продолжить"

            return $false
        }

        if ($nipProfiles.Count -gt 0) {

            Write-Host "NVIDIA Profile Inspector"
            Write-Host ""

            for ($i = 0; $i -lt $nipProfiles.Count; $i++) {

                Write-Host "[$($i + 1)] $($nipProfiles[$i].name)"
            }

        }
        else {

            Write-Host "Профили .nip не найдены!" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "[0] Назад"
        Write-Host ""

        $choice = Read-Host "Выберите профиль"

        if ($choice -eq "0") {
            return $false
        }

        try {

            $index = [int]$choice - 1

            if ($index -ge 0 -and $index -lt $nipProfiles.Count) {

                $selectedProfile = $nipProfiles[$index]

                Clear-Host

                Write-Host "========================================"
                Write-Host "          Выбран профиль"
                Write-Host "========================================"
                Write-Host ""

                Write-Host "Игра:    $($selectedFolder.name)"
                Write-Host "Профиль: $($selectedProfile.name)"
                Write-Host ""

                $confirm = Read-Host "Скачать этот профиль на Рабочий стол? (Y/N)"

                if ($confirm -match '^[YyДд]') {

                    Write-Host ""
                    Write-Host "Скачивание профиля..." -ForegroundColor Yellow

                    $downloadUrl = $selectedProfile.download_url

                    $desktopPath = [Environment]::GetFolderPath("Desktop")

                    $savePath = Join-Path `
                        -Path $desktopPath `
                        -ChildPath $selectedProfile.name

                    try {

                        Invoke-WebRequest `
                            -Uri $downloadUrl `
                            -OutFile $savePath

                        Write-Host ""
                        Write-Host "Файл успешно скачан!" -ForegroundColor Green
                        Write-Host "Сохранен сюда: $savePath" -ForegroundColor Cyan
                        Write-Host ""

                        Read-Host "Нажмите Enter для возврата в Главное меню"

                        return $true
                    }
                    catch {

                        Write-Host ""
                        Write-Host "Ошибка при скачивании:" -ForegroundColor Red
                        Write-Host $_.Exception.Message -ForegroundColor Red

                        Read-Host "Нажмите Enter, чтобы продолжить"
                    }
                }
                else {

                    Write-Host ""
                    Write-Host "Скачивание отменено." -ForegroundColor Yellow

                    Read-Host "Нажмите Enter, чтобы продолжить"
                }
            }
            else {

                Write-Host ""
                Write-Host "Неверный номер профиля!" -ForegroundColor Red

                Read-Host "Нажмите Enter, чтобы продолжить"
            }
        }
        catch {

            Write-Host ""
            Write-Host "Нужно ввести число!" -ForegroundColor Red

            Read-Host "Нажмите Enter, чтобы продолжить"
        }
    }
}
function Show-SystemInfo {

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $gpu = Get-CimInstance Win32_VideoController
    $ram = Get-CimInstance Win32_ComputerSystem
    $ramGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    


    Clear-Host
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

    Read-Host "Нажмите Enter, чтобы вернуться в меню"

    
    # нет сообщения о завершении очистки
    # нет сообщения о завершении очистки
    # нет сообщения о завершении очистки
    # нет сообщения о завершении очистки
    # нет сообщения о завершении очистки
   
}
function Show-GamingProfiles {

    while ($true) {

        Clear-Host

        Write-Host "========================================"
        Write-Host "          Профили для игр"
        Write-Host "========================================"
        Write-Host ""

        try {

            $response = Invoke-RestMethod "$GitHubApi/GameProfiles"

        $profiles = @()

        foreach ($item in $response) {

                if ($item.type -eq "dir") {
                    $profiles += $item
                }
         }
        }
        catch {

            Write-Host ""
            Write-Host "Ошибка подключения к GitHub!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host ""

            Read-Host "Нажмите Enter, чтобы вернуться"

            return
        }

    for ($i = 0; $i -lt $profiles.Count; $i++) {

            Write-Host "[$($i + 1)] $($profiles[$i].name)"
        }

        Write-Host ""
        Write-Host "[0] Назад"
        Write-Host ""

        $choice = Read-Host "Выберите игру"

        if ($choice -eq "0") {
            return
        }

        try {

            $index = [int]$choice - 1

            if ($index -ge 0 -and $index -lt $profiles.Count) {

                $selectedFolder = $profiles[$index]

                $goHome = Show-GameProfileMenu $selectedFolder

                if ($goHome -eq $true) {
                    return
                }
            }
            else {

                Write-Host ""
                Write-Host "Неверный номер игры!" -ForegroundColor Red

                Read-Host "Нажмите Enter, чтобы продолжить"
           }
        }
        catch {

            Write-Host ""
            Write-Host "Нужно ввести число!" -ForegroundColor Red

            Read-Host "Нажмите Enter, чтобы продолжить"
        }
    }
}
function Show-Applications {
    
    $apps = @(
        [PSCustomObject]@{ Name = "7-Zip"; Id = "7zip.7zip"; IsWinget = $true }
        [PSCustomObject]@{ Name = "brave"; Id = "Brave.Brave"; IsWinget = $true }
        [PSCustomObject]@{ Name = "msi afterburner"; Id = "Guru3D.Afterburner"; IsWinget = $true }
        [PSCustomObject]@{ Name = "fan control"; Id = "Rem0o.FanControl"; IsWinget = $true }
        [PSCustomObject]@{ Name = "bcuninstaller"; Id = "Klocman.BulkCrapUninstaller"; IsWinget = $true }
        [PSCustomObject]@{ Name = "cru"; Id = "ToastyX.CustomResolutionUtility"; IsWinget = $true }
        [PSCustomObject]@{ Name = "ddu"; Id = "Wagnardsoft.DisplayDriverUninstaller"; IsWinget = $true }
        [PSCustomObject]@{ Name = "nvidia profile inspector"; Id = "Orbmu2k.nvidiaProfileInspector"; IsWinget = $true }
        [PSCustomObject]@{ Name = "autoruns"; Id = "Microsoft.Sysinternals.Autoruns"; IsWinget = $true }
        [PSCustomObject]@{ Name = "NVCleinstal"; Id = "TechPowerUp.NVCleanstall"; IsWinget = $true }
        [PSCustomObject]@{ Name = "VLC media"; Id = "VideoLAN.VLC"; IsWinget = $true }
        [PSCustomObject]@{ Name = "ISLC"; Id = "Wagnardsoft.ISLC"; IsWinget = $true }
        [PSCustomObject]@{ Name = "VS code"; Id = "Microsoft.VisualStudioCode"; IsWinget = $true }
        [PSCustomObject]@{ Name = "discord"; Id = "Discord.Discord"; IsWinget = $true }
        [PSCustomObject]@{ Name = "steam"; Id = "Valve.Steam"; IsWinget = $true }
        [PSCustomObject]@{ Name = "spotify"; Id = "Spotify.Spotify"; IsWinget = $true }
        [PSCustomObject]@{ Name = "equalizer APO"; Id = "jthedering.EqualizerAPO"; IsWinget = $true }
        [PSCustomObject]@{ Name = "peace Equalizer"; Id = "PeterVerbeek.Peace"; IsWinget = $true }
        [PSCustomObject]@{ Name = "MSI Mode Utility"; Id = "https://forums.guru3d.com/threads/windows-7-8-8-1-10-msi-line-based-vs-message-signaled-based-interrupts.378044/"; IsWinget = $false }
    )

    while ($true) {
        Clear-Host
        Write-Host "========================================"
        Write-Host "          Библиотека приложений"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Доступно для автоматической установки:" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $apps.Count; $i++) {
            Write-Host "[$($i + 1)] $($apps[$i].Name)"
        }

        Write-Host ""
        Write-Host "[0] Назад"
        Write-Host ""

        $choice = Read-Host "Выберите программу для установки"

        if ($choice -eq "0") {
            return
        }

        try {
            $index = [int]$choice - 1

            if ($index -ge 0 -and $index -lt $apps.Count) {
                $selectedApp = $apps[$index]

                Clear-Host
                Write-Host "========================================"
                Write-Host "          Установка программы"
                Write-Host "========================================"
                Write-Host ""

                if ($selectedApp.IsWinget) {
                    Write-Host "Скачивание и установка: $($selectedApp.Name)..." -ForegroundColor Yellow
                    Write-Host "Пожалуйста, подождите. Может появиться окно контроля учетных записей (UAC)." -ForegroundColor DarkGray
                    Write-Host ""

                    $wingetArgs = "install --id `"$($selectedApp.Id)`" --exact --silent --accept-package-agreements --accept-source-agreements"
                    $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru

                    if ($process.ExitCode -eq 0) {
                        Write-Host "`nУстановка успешно завершена!" -ForegroundColor Green
                        Write-Host ""
                        Read-Host "Нажмите Enter для возврата в Главное меню"
                        return 
                    } else {
                        Write-Host "`nПрограмма уже установлена, либо установка отменена (Код: $($process.ExitCode))." -ForegroundColor Yellow
                        Write-Host ""
                        Read-Host "Нажмите Enter, чтобы вернуться к списку приложений"
                    }
                } else {
                    Write-Host "$($selectedApp.Name) недоступна в winget." -ForegroundColor Yellow
                    Write-Host "Открыть официальный сайт для скачивания? (Y/N): " -NoNewline -ForegroundColor White

                    # --- ИСПРАВЛЕННЫЙ БЛОК ---
                    # Ждем нажатия реальной буквы, пропуская служебные клавиши (Shift/Alt/Ctrl)
                    do {
                        $keyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    } while ($keyInfo.Character -eq 0)

                    $key = $keyInfo.Character
                    Write-Host $key 

                    if ($key -match '[yYдДнН]') {
                        Write-Host "`nОткрываю браузер..." -ForegroundColor Green
                        Start-Process $selectedApp.Id
                        
                        Write-Host ""
                        return 
                    } else {
                        Write-Host "`nДействие отменено. Возврат к списку." -ForegroundColor DarkGray
                        Start-Sleep -Seconds 2
                    }
                    # -------------------------
                }
            }
            else {
                Write-Host ""
                Write-Host "Неверный номер!" -ForegroundColor Red
                Read-Host "Нажмите Enter, чтобы продолжить"
            }
        }
        catch {
            Write-Host ""
            Write-Host "Нужно ввести число!" -ForegroundColor Red
            Read-Host "Нажмите Enter, чтобы продолжить"
        }
    }
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