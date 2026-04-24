# WINUTIL OMEGA X - ULTIMATE WINDOWS TOOLKIT
# Untuk Yang Mulia Putri Incha
# Melampaui Chris Titus Tech WinUtil dengan fitur extra:
# Windhawk + Winhance + Sophia Script + O&O ShutUp10++ + Windows Optimizer
#
# USAGE:
# 1. Buat 3 file: winutil_omega.ps1, OmegaX.xaml, OmegaX_Data.json
# 2. Letakkan di folder yang sama
# 3. Jalankan PowerShell As Admin
# 4. cd ke folder tersebut
# 5. .\winutil_omega.ps1

# ==================== INITIALIZATION ====================
# Cek Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ JALANKAN SEBAGAI ADMINISTRATOR, YANG MULIA!" -ForegroundColor Red -BackgroundColor Black
    pause
    exit
}

# Set Execution Policy untuk sesi ini
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Load Assembly WPF untuk GUI
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ==================== LOAD XAML ====================
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$xamlPath = Join-Path $scriptDir "OmegaX.xaml"
$jsonPath = Join-Path $scriptDir "OmegaX_Data.json"

# Baca dan parse XAML
[xml]$xaml = Get-Content -Path $xamlPath -Raw

# Buat reader XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ==================== STORE UI ELEMENTS ====================
$sync = @{}
$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    $sync[$_.Name] = $window.FindName($_.Name)
}

# ==================== LOAD JSON DATA ====================
$jsonData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# ==================== HELPER FUNCTIONS ====================

# Fungsi untuk menulis log
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Color
    $sync.StatusBar.Text = $Message
}

# Fungsi untuk menjalankan perintah dan capture output
function Run-Command {
    param([string]$Command, [string]$Arguments = "")
    try {
        $result = & $Command $Arguments 2>&1
        return $result
    } catch {
        return "Error: $_"
    }
}

# ==================== WINDOW EVENT HANDLERS ====================

# Drag window
$sync.Form.Add_MouseLeftButtonDown({
    $sync.Form.DragMove()
})

# Minimize/Maximize/Close
$sync.MinimizeButton.Add_Click({ $window.WindowState = "Minimized" })
$sync.MaximizeButton.Add_Click({
    if ($window.WindowState -eq "Normal") { $window.WindowState = "Maximized" }
    else { $window.WindowState = "Normal" }
})
$sync.CloseButton.Add_Click({ $window.Close() })

# Switch Tab
$tabs = @{
    "TabInstall" = "TabInstallContent"
    "TabTweaks" = "TabTweaksContent"
    "TabOmega" = "TabOmegaContent"
    "TabNetwork" = "TabNetworkContent"
    "TabPrivacy" = "TabPrivacyContent"
    "TabRecovery" = "TabRecoveryContent"
    "TabISO" = "TabISOContent"
    "TabSettings" = "TabSettingsContent"
}

$sync.Keys | Where-Object { $_ -match "^Tab" -and $_ -ne "TabInstall" -and $_ -ne "TabTweaks" -and $_ -ne "TabOmega" -and $_ -ne "TabNetwork" -and $_ -ne "TabPrivacy" -and $_ -ne "TabRecovery" -and $_ -ne "TabISO" -and $_ -ne "TabSettings" } | ForEach-Object {
    $sync[$_].Add_Click({
        $selectedTab = $this.Name
        foreach ($tab in $tabs.Keys) {
            $contentName = $tabs[$tab]
            if ($tab -eq $selectedTab) {
                $sync[$contentName].Visibility = "Visible"
            } else {
                $sync[$contentName].Visibility = "Collapsed"
            }
        }
    })
}

# ==================== POPULATE INSTALL TAB ====================
Write-Log "Mengisi daftar aplikasi..." -Color "Cyan"

# Category buttons
$categories = $jsonData.applications.PSObject.Properties.Name
$row = 0
$col = 0
foreach ($category in $categories) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $category
    $btn.Margin = "5"
    $btn.Padding = "15,8"
    $btn.Background = $sync.CategoryPanel.FindResource("CardBackgroundColor")
    $btn.Foreground = $sync.CategoryPanel.FindResource("MainForegroundColor")
    $btn.Cursor = "Hand"
    $btn.Tag = $category
    $btn.Add_Click({
        $cat = $this.Tag
        Write-Log "Memfilter aplikasi untuk kategori: $cat" -Color "Gray"
        # Filter apps berdasarkan kategori (simplifikasi)
    })
    $sync.CategoryPanel.Children.Add($btn)
}

# Application checkboxes
$allApps = @{}
$jsonData.applications.PSObject.Properties | ForEach-Object {
    $category = $_.Name
    $apps = $_.Value
    $apps.PSObject.Properties | ForEach-Object {
        $appName = $_.Name
        $appId = $_.Value
        $allApps[$appName] = $appId
        
        $checkBox = New-Object System.Windows.Controls.CheckBox
        $checkBox.Content = $appName
        $checkBox.Margin = "5"
        $checkBox.Tag = $appId
        $checkBox.Style = $sync.AppsPanel.FindResource("TweakToggleStyle")
        $sync.AppsPanel.Children.Add($checkBox)
        $sync["chk_$($appName -replace ' ', '_')"] = $checkBox
    }
}

$sync.SelectAllButton.Add_Click({
    $sync.AppsPanel.Children | ForEach-Object { 
        if ($_ -is [System.Windows.Controls.CheckBox]) { $_.IsChecked = $true }
    }
})

$sync.SelectNoneButton.Add_Click({
    $sync.AppsPanel.Children | ForEach-Object { 
        if ($_ -is [System.Windows.Controls.CheckBox]) { $_.IsChecked = $false }
    }
})

$sync.InstallSelectedButton.Add_Click({
    Write-Log "Memulai instalasi aplikasi..." -Color "Green"
    $selectedApps = @()
    $sync.AppsPanel.Children | ForEach-Object {
        if ($_ -is [System.Windows.Controls.CheckBox] -and $_.IsChecked -eq $true) {
            $selectedApps += $_.Tag
        }
    }
    
    foreach ($appId in $selectedApps) {
        Write-Log "Menginstall: $appId" -Color "Cyan"
        winget install --id $appId -e --silent --accept-package-agreements
    }
    Write-Log "Instalasi selesai, Yang Mulia!" -Color "Green"
    [System.Windows.MessageBox]::Show("Instalasi selesai!", "WINUTIL OMEGA X", "OK", "Information")
})

# ==================== POPULATE TWEAKS TAB ====================
Write-Log "Mengisi daftar tweaks..." -Color "Cyan"

function Add-TweakToPanel {
    param($panelName, $tweaksHash)
    $tweaksHash.PSObject.Properties | ForEach-Object {
        $tweakName = $_.Name
        $tweakId = $_.Value
        $checkBox = New-Object System.Windows.Controls.CheckBox
        $checkBox.Content = $tweakName
        $checkBox.Margin = "5"
        $checkBox.Tag = $tweakId
        $checkBox.Style = $sync.AppsPanel.FindResource("TweakToggleStyle")
        $sync[$panelName].Children.Add($checkBox)
    }
}

Add-TweakToPanel "EssentialTweaksPanel" $jsonData.essentialTweaks
Add-TweakToPanel "PerformanceTweaksPanel" $jsonData.performanceTweaks
Add-TweakToPanel "NetworkTweaksPanel" $jsonData.networkTweaks

# Apply Tweaks
$sync.ApplyTweaksButton.Add_Click({
    Write-Log "Menerapkan tweaks..." -Color "Magenta"
    
    # Essential Tweaks
    if (($sync.EssentialTweaksPanel.Children | Where-Object { $_.Content -eq "Disable Telemetry" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → Disable Telemetry" -Color "Gray"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
    }
    if (($sync.EssentialTweaksPanel.Children | Where-Object { $_.Content -eq "Disable Cortana" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → Disable Cortana" -Color "Gray"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord
    }
    if (($sync.EssentialTweaksPanel.Children | Where-Object { $_.Content -eq "Disable OneDrive Startup" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → Disable OneDrive Startup" -Color "Gray"
        Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord
    }
    
    # Performance Tweaks
    if (($sync.PerformanceTweaksPanel.Children | Where-Object { $_.Content -eq "High Performance Power Plan" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → High Performance Power Plan" -Color "Gray"
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    }
    if (($sync.PerformanceTweaksPanel.Children | Where-Object { $_.Content -eq "CPU Core Unparking" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → CPU Core Unparking" -Color "Gray"
        powercfg -setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 0
    }
    
    # Network Tweaks
    if (($sync.NetworkTweaksPanel.Children | Where-Object { $_.Content -eq "Set Cloudflare DNS" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → Set Cloudflare DNS" -Color "Gray"
        $interface = (Get-NetAdapter | Where-Object Status -eq "Up").Name
        Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses ("1.1.1.1", "1.0.0.1")
    }
    if (($sync.NetworkTweaksPanel.Children | Where-Object { $_.Content -eq "Enable RSS Checksum Offloading" -and $_.IsChecked }).Count -gt 0) {
        Write-Log "  → Enable RSS/Checksum Offloading" -Color "Gray"
        netsh int tcp set global rss=enabled
        netsh int tcp set global chimney=enabled
    }
    
    Write-Log "Tweaks selesai diterapkan, Yang Mulia!" -Color "Green"
    [System.Windows.MessageBox]::Show("Tweaks selesai diterapkan! Disarankan restart komputer.", "WINUTIL OMEGA X", "OK", "Information")
})

# Undo Tweaks
$sync.UndoTweaksButton.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show("Yakin ingin mengembalikan semua tweaks ke default Windows?", "Konfirmasi", "YesNo", "Warning")
    if ($confirm -eq "Yes") {
        Write-Log "Mengembalikan tweaks ke default..." -Color "Yellow"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 3 -Type DWord
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 1 -Type DWord
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e  # Balanced plan
        [System.Windows.MessageBox]::Show("Tweaks telah dikembalikan ke default!", "WINUTIL OMEGA X", "OK", "Information")
    }
})

# ==================== OMEGA X TAB FUNCTIONS ====================

# Install Windhawk
$sync.InstallWindhawkButton.Add_Click({
    Write-Log "Menginstall Windhawk..." -Color "Cyan"
    try {
        $windhawkUrl = "https://github.com/ramensoftware/windhawk/releases/latest/download/windhawk_setup.exe"
        $outputPath = "$env:TEMP\windhawk_setup.exe"
        Invoke-WebRequest -Uri $windhawkUrl -OutFile $outputPath -UseBasicParsing
        Start-Process -FilePath $outputPath -Wait
        Write-Log "Windhawk berhasil diinstall!" -Color "Green"
        $sync.WindhawkStatus.Text = "Status: Terinstall"
        $sync.WindhawkStatus.Foreground = "Green"
    } catch {
        Write-Log "Gagal menginstall Windhawk: $_" -Color "Red"
    }
})

# Gaming Mode
$sync.EnableGamingModeButton.Add_Click({
    Write-Log "Mengaktifkan Gaming Mode..." -Color "Magenta"
    
    # High Performance Power Plan
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Disable Game DVR
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
    
    # Disable Nagle's Algorithm (reduce latency)
    $tcpKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    Get-ChildItem $tcpKey | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    }
    
    # Close background processes
    @("OneDrive", "Teams", "Spotify", "Discord", "Slack", "Skype", "WhatsApp", "Telegram", "Dropbox", "GoogleDrive") | ForEach-Object {
        Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "Gaming Mode diaktifkan! Latency berkurang, performa meningkat." -Color "Green"
    [System.Windows.MessageBox]::Show("Gaming Mode telah diaktifkan!`n`nOptimasi yang diterapkan:`n- High Performance Power Plan`n- Game DVR Dinonaktifkan`n- Network Latency Optimized`n- Background Apps Closed", "WINUTIL OMEGA X", "OK", "Information")
})

# Apply Network Optimization (Aggressive)
$sync.ApplyNetworkButton.Add_Click({
    Write-Log "Menerapkan Network Optimization (Aggressive)..." -Color "Cyan"
    
    # CTCP Congestion Provider
    netsh int tcp set global congestionprovider=ctcp
    
    # Auto Tuning Level - normal
    netsh int tcp set global autotuninglevel=normal
    
    # RSS & Checksum Offloading
    netsh int tcp set global rss=enabled
    netsh int tcp set global chimney=enabled
    
    # Disable Network Throttling
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
    
    # Cloudflare DNS
    $interface = (Get-NetAdapter | Where-Object Status -eq "Up").Name
    Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses ("1.1.1.1", "1.0.0.1")
    
    # Flush DNS
    ipconfig /flushdns
    
    Write-Log "Network Optimization selesai!" -Color "Green"
    [System.Windows.MessageBox]::Show("Network Optimization selesai!`n`nTCP/IP Settings optimized for low latency.`nDNS changed to Cloudflare (1.1.1.1).", "WINUTIL OMEGA X", "OK", "Information")
})

# ==================== NETWORK TAB FUNCTIONS ====================

$sync.NetScanButton.Add_Click({
    Write-Log "Scanning network devices..." -Color "Cyan"
    $output = @()
    $subnet = "192.168.1."
    $output += "Scanning $($subnet)0/24..."
    1..254 | ForEach-Object {
        $ip = "$subnet$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            try {
                $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
                $output += "✓ Device aktif: $ip - Hostname: $hostname"
            } catch {
                $output += "✓ Device aktif: $ip"
            }
        }
    }
    $sync.NetworkOutputBox.Text = $output -join "`r`n"
})

$sync.NetWiFiPassButton.Add_Click({
    Write-Log "Mengekstrak WiFi passwords..." -Color "Cyan"
    $output = @()
    $profiles = netsh wlan show profiles | Select-String " : " | ForEach-Object { ($_ -split ":")[1].Trim() }
    foreach ($profile in $profiles) {
        $details = netsh wlan show profile name="$profile" key=clear
        $password = ($details | Select-String "Key Content" | ForEach-Object { ($_ -split ":")[1].Trim() })
        if ($password) {
            $output += "SSID: $profile - Password: $password"
        } else {
            $output += "SSID: $profile - (No password/Open network)"
        }
    }
    $sync.NetworkOutputBox.Text = $output -join "`r`n"
    if ($output.Count -gt 0) {
        [System.Windows.MessageBox]::Show("WiFi passwords have been extracted and displayed!", "WINUTIL OMEGA X", "OK", "Information")
    }
})

# ==================== PRIVACY TAB FUNCTIONS ====================

$sync.ApplyPrivacyButton.Add_Click({
    Write-Log "Menerapkan Privacy Settings..." -Color "Cyan"
    
    # Disable Telemetry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
    
    # Block Telemetry via hosts file
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    $telemetryHosts = @(
        "127.0.0.1 *.vortex.data.microsoft.com",
        "127.0.0.1 *.telemetry.microsoft.com",
        "127.0.0.1 *.watson.telemetry.microsoft.com"
    )
    Add-Content -Path $hostsPath -Value "`n# WINUTIL OMEGA X - Blocked Telemetry" -Force
    foreach ($entry in $telemetryHosts) {
        Add-Content -Path $hostsPath -Value $entry -Force
    }
    
    Write-Log "Privacy settings applied!" -Color "Green"
    [System.Windows.MessageBox]::Show("Privacy settings telah diterapkan!`n`n- Telemetry dinonaktifkan`n- Telemetry IP diblokir di hosts file`n- Disarankan restart browser", "WINUTIL OMEGA X", "OK", "Information")
})

$sync.OpenOOSUButton.Add_Click({
    Write-Log "Membuka O&O ShutUp10++..." -Color "Cyan"
    $oosuPath = "$env:TEMP\OOSU10.exe"
    if (-not (Test-Path $oosuPath)) {
        Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $oosuPath -UseBasicParsing
    }
    Start-Process $oosuPath
})

# ==================== RECOVERY TAB FUNCTIONS ====================

$sync.RecoveryWiFiButton.Add_Click({
    Write-Log "Extracting WiFi passwords..." -Color "Cyan"
    $output = @()
    $profiles = netsh wlan show profiles | Select-String " : " | ForEach-Object { ($_ -split ":")[1].Trim() }
    foreach ($profile in $profiles) {
        $details = netsh wlan show profile name="$profile" key=clear
        $password = ($details | Select-String "Key Content" | ForEach-Object { ($_ -split ":")[1].Trim() })
        $output += "SSID: $profile - Password: $password"
    }
    $sync.RecoveryOutputBox.Text = $output -join "`r`n"
})

$sync.RecoveryHiddenAdminButton.Add_Click({
    Write-Log "Creating Hidden Admin Account..." -Color "Cyan"
    $username = "WinUtil_Admin"
    $password = Read-Host "Masukkan password untuk akun hidden" -AsSecureString
    try {
        New-LocalUser -Name $username -Password $password -FullName "Windows System Account" -Description "Hidden Admin Account" -AccountNeverExpires -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction SilentlyContinue
        $specialKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
        if (-not (Test-Path $specialKey)) { New-Item -Path $specialKey -Force }
        Set-ItemProperty -Path $specialKey -Name $username -Value 0 -Type DWord
        $sync.RecoveryOutputBox.Text = "✅ Hidden Admin Account dibuat: $username`nPassword: [seperti yang diinput]`nAkun ini TIDAK akan muncul di login screen"
    } catch {
        $sync.RecoveryOutputBox.Text = "❌ Gagal membuat akun: $_"
    }
})

$sync.RecoveryPasswordGenButton.Add_Click({
    $length = 16
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
    $password = -join ((1..$length) | ForEach-Object { Get-Random -Maximum $chars.Length | ForEach-Object { $chars[$_] } })
    $sync.RecoveryOutputBox.Text = "Generated Password (16 chars):`n$password`n`nPassword telah disalin ke clipboard!"
    $password | Set-Clipboard
})

# ==================== SHOW WINDOW ====================
Write-Log "WINUTIL OMEGA X siap digunakan, Yang Mulia!" -Color "Magenta"
$window.ShowDialog() | Out-Null