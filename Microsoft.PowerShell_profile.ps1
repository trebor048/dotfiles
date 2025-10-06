# =============================================================================
# ✨ PowerShell Profile ✨
# The Ultimate Development Environment - Clean, Logical, Fancy
# Features: AI Assistant, Interactive Menus, Cloud Integration, DevOps Tools
# =============================================================================

# -----------------------------------------------------------------------------
# 📋 CONFIGURATION & PARAMETERS
# -----------------------------------------------------------------------------
[CmdletBinding()]
param (
    [bool]$randomiseThemes = $false,
    [ValidateSet("default", "minimal", "git")]
    [string]$promptStyle = "default",
    [bool]$showWelcome = $true
)

# -----------------------------------------------------------------------------
# 🎯 SCRIPT-SCOPE VARIABLES
# -----------------------------------------------------------------------------
$script:isAdmin = $false
$script:ThemePreferenceFile = "$env:USERPROFILE\.powershell-theme-preference.json"
$script:ProfileStartTime = Get-Date
$script:EDITOR = $null

# -----------------------------------------------------------------------------
# 🔧 CORE UTILITIES & HELPERS
# -----------------------------------------------------------------------------
function Test-CommandExists {
    param ([string]$command)
    try { 
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true 
    }
    catch { 
        return $false 
    }
}

function Write-HostCenter {
    param([string]$Message, [string]$Color = "White")
    $width = $Host.UI.RawUI.BufferSize.Width
    $padLeft = [Math]::Max(0, [Math]::Floor(($width - $Message.Length) / 2))
    $padRight = [Math]::Max(0, $width - $Message.Length - $padLeft)
    Write-Host (" " * $padLeft + $Message + " " * $padRight) -ForegroundColor $Color
}


function Write-HostBoxCenter {
    param([string]$Message, [string]$Color = "White", [string]$BorderColor = "Magenta")
    $width = $Host.UI.RawUI.BufferSize.Width
    $padLeft = [Math]::Max(0, [Math]::Floor(($width - $Message.Length) / 2))
    $padRight = [Math]::Max(0, $width - $Message.Length - $padLeft)
    Write-Host (" " * $padLeft + $Message + " " * $padRight) -ForegroundColor $Color
}

function Write-HostFullWidth {
    param([string]$Message, [string]$Color = "White")
    $width = $Host.UI.RawUI.BufferSize.Width
    # If message is a single character, repeat it to fill width
    if ($Message.Length -eq 1) {
        $repeated = $Message * $width
        Write-Host $repeated -ForegroundColor $Color
    } else {
        # Otherwise, center the message and fill with spaces
        $padLeft = [Math]::Max(0, [Math]::Floor(($width - $Message.Length) / 2))
        $padRight = [Math]::Max(0, $width - $Message.Length - $padLeft)
        Write-Host (" " * $padLeft + $Message + " " * $padRight) -ForegroundColor $Color
    }
}

function Show-Spinner {
    param([int]$Duration = 2, [string]$Message = "Loading...")
    $chars = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $start = Get-Date
    $i = 0
    
    while (((Get-Date) - $start).TotalSeconds -lt $Duration) {
        Write-Host "`r$($chars[$i % $chars.Length]) $Message" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
        $i++
    }
    Write-Host "`r✅ Complete!`n" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# 🎨 WELCOME SYSTEM & UI
# -----------------------------------------------------------------------------
function Get-SystemMetrics {
    $metrics = @{}
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $metrics.Uptime = $os.LastBootUpTime
        $metrics.MemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $metrics.MemoryFreeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    }
    catch {
        $metrics.Uptime = "Unknown"
        $metrics.MemoryGB = "Unknown"
        $metrics.MemoryFreeGB = "Unknown"
    }

    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
        $metrics.CPU = $cpu.Name.Split('@')[0].Trim()
    }
    catch {
        $metrics.CPU = "Unknown"
    }

    try {
        $disk = Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
        $metrics.DiskFreeGB = [math]::Round($disk.SizeRemaining / 1GB, 1)
        $metrics.DiskTotalGB = [math]::Round($disk.Size / 1GB, 1)
    } 
    catch {
        $metrics.DiskFreeGB = "Unknown"
        $metrics.DiskTotalGB = "Unknown"
    }

    try { 
        $metrics.Weather = (Invoke-WebRequest "http://wttr.in/?format=1" -TimeoutSec 2 -ErrorAction Stop).Content.Trim() 
    }
    catch { 
        $metrics.Weather = "Weather unavailable" 
    }

    try { 
        $metrics.PublicIP = (Invoke-WebRequest "http://ifconfig.me/ip" -TimeoutSec 2 -ErrorAction Stop).Content.Trim() 
    }
    catch { 
        $metrics.PublicIP = "IP unavailable" 
    }

    return $metrics
}

function Show-WelcomeScreen {
    if (!$showWelcome) { return }

    Clear-Host
    Show-Spinner -Duration 1.2 -Message "Initializing PowerShell Environment"
    Clear-Host
    $metrics = Get-SystemMetrics

    Write-HostFullWidth "══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-HostBoxCenter "PowerShell Environment" -Color "White" -BorderColor "Magenta"
    Write-HostFullWidth "══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta

    Write-Host ""
    Write-Host "👋 Welcome " -NoNewline -ForegroundColor Yellow
    Write-Host "$([Environment]::UserName)" -NoNewline -ForegroundColor Green
    Write-Host " @ " -NoNewline -ForegroundColor Gray
    Write-Host "$env:COMPUTERNAME" -ForegroundColor Blue
    Write-Host ""

    Write-Host "📊 System Dashboard:" -ForegroundColor Cyan
    Write-Host "   💻 CPU: $($metrics.CPU)" -NoNewline -ForegroundColor White
    Write-Host "   |   🧠 RAM: $($metrics.MemoryFreeGB)GB / $($metrics.MemoryGB)GB free" -ForegroundColor White
    Write-Host "   ⏱️  Uptime: $($metrics.Uptime)" -NoNewline -ForegroundColor White
    Write-Host "   |   💾 Disk: $($metrics.DiskFreeGB)GB / $($metrics.DiskTotalGB)GB free" -ForegroundColor White
    Write-Host "   🌤️  Weather: $($metrics.Weather)" -NoNewline -ForegroundColor White
    Write-Host "   |   🌐 Public IP: $($metrics.PublicIP)" -ForegroundColor White
    Write-Host ""

    Write-Host "⚡ Quick Actions:" -ForegroundColor Yellow
    Write-Host "   🔧 pphelp | 🛠️ devmenu | 🤖 ai-help | 📊 sysinfo | 🎯 aliases" -ForegroundColor White
    Write-Host "   🎨 themes | 🔍 theme-test | 🔄 theme random | 🎭 theme-showcase" -ForegroundColor White
    Write-Host "   📁 gitdir | 🌐 ports | 📈 processes | 🔄 reload-profile" -ForegroundColor White
    Write-Host "   📦 pi | 🚀 dev-setup | 🐙 gs | 🐍 venv | 🌡️ weather" -ForegroundColor White
    Write-Host ""

}

# -----------------------------------------------------------------------------
# 🎭 THEME MANAGEMENT
# -----------------------------------------------------------------------------
function Get-AllThemes {
    return @(
        # Classic themes
        "star.omp.json", "paradox.omp.json", "jandedobbeleer.omp.json", "amro.omp.json", "minimal.omp.json",
        "material.omp.json", "robbyrussell.omp.json", "agnoster.omp.json", "powerlevel10k_classic.omp.json",

        # Modern themes
        "kali.omp.json", "montys.omp.json", "negligible.omp.json", "poshmon.omp.json", "remk.omp.json",
        "suvai.omp.json", "tokyo.omp.json", "zash.omp.json", "blueish.omp.json", "greeny.omp.json",

        # Fun and colorful themes
        "multiverse-neon.omp.json", "pure.omp.json", "space.omp.json", "unicorn.omp.json", "ys.omp.json",
        "pixelrobots.omp.json", "hunk.omp.json", "bubbles.omp.json", "bubblesextra.omp.json", "hul10.omp.json",

        # Minimal themes
        "pure.omp.json", "minimal.omp.json", "negligible.omp.json", "sobole.omp.json", "stelbent.minimal.omp.json",
        "lambda.omp.json", "microverse-power.omp.json", "slim.omp.json", "slimfat.omp.json"
    )
}

function Set-Theme {
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("classic", "modern", "fun", "minimal", "random")]
        [string]$Category,

        [Parameter(Mandatory=$false)]
        [string]$Name
    )

    try {
        if ($Name) {
            $themePath = "$env:POSH_THEMES_PATH\$Name"
            if (Test-Path $themePath) {
                oh-my-posh init pwsh --config $themePath | Invoke-Expression
                Write-Host "✅ Theme set to: $Name" -ForegroundColor Green
            } else {
                Write-Host "❌ Theme not found: $Name" -ForegroundColor Red
            }
        }
        elseif ($Category) {
            $themes = switch ($Category) {
                "classic" { @("star.omp.json", "paradox.omp.json", "jandedobbeleer.omp.json", "amro.omp.json", "minimal.omp.json", "material.omp.json", "robbyrussell.omp.json", "agnoster.omp.json") }
                "modern" { @("kali.omp.json", "montys.omp.json", "negligible.omp.json", "poshmon.omp.json", "remk.omp.json", "suvai.omp.json", "tokyo.omp.json", "zash.omp.json") }
                "fun" { @("multiverse-neon.omp.json", "space.omp.json", "unicorn.omp.json", "pixelrobots.omp.json", "bubbles.omp.json", "hul10.omp.json") }
                "minimal" { @("pure.omp.json", "minimal.omp.json", "negligible.omp.json", "sobole.omp.json", "lambda.omp.json", "slim.omp.json") }
                "random" { Get-AllThemes }
            }

            $theme = Get-Random $themes
            oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\$theme" | Invoke-Expression
            Write-Host "🎨 Theme category '$Category' - loaded: $theme" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Theme change failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-AvailableThemes {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🎨 AVAILABLE OH MY POSH THEMES" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    $themes = Get-AllThemes
    Write-Host "📊 Total Themes Available: $($themes.Count)" -ForegroundColor Cyan
    Write-Host ""

    $themeCategories = @{
        "Classic Themes" = $themes | Where-Object { $_ -match "(star|paradox|jandedobbeleer|amro|minimal|material|robbyrussell|agnoster|powerlevel10k)" }
        "Modern Themes" = $themes | Where-Object { $_ -match "(kali|montys|negligible|poshmon|remk|suvai|tokyo|zash|blueish|greeny)" }
        "Fun & Colorful" = $themes | Where-Object { $_ -match "(multiverse|space|unicorn|pixelrobots|bubbles|hul10|hunk|neon)" }
        "Minimal Themes" = $themes | Where-Object { $_ -match "(pure|minimal|negligible|sobole|lambda|slim|stelbent)" }
    }

    foreach ($category in $themeCategories.GetEnumerator()) {
        Write-Host "$($category.Key.ToUpper()):" -ForegroundColor Yellow
        $category.Value | Sort-Object | Format-Wide -Column 4
        Write-Host ""
    }

    Write-Host "💡 USAGE:" -ForegroundColor Green
    Write-Host "   • Set-Theme -Category classic   # Random classic theme" -ForegroundColor White
    Write-Host "   • Set-Theme -Category modern    # Random modern theme" -ForegroundColor White
    Write-Host "   • Set-Theme -Category fun       # Random fun theme" -ForegroundColor White
    Write-Host "   • Set-Theme -Category minimal   # Random minimal theme" -ForegroundColor White
    Write-Host "   • Set-Theme -Name 'star.omp.json' # Specific theme" -ForegroundColor White
    Write-Host "   • Set-Theme -Category random    # Random from all themes" -ForegroundColor White
    Write-Host ""
}

function Show-ThemeShowcase {
    param([int]$Duration = 4, [int]$Count = 5)

    Write-Host "🎨 THEME SHOWCASE - Previewing $Count random themes ($Duration seconds each)" -ForegroundColor Magenta
    Write-Host "Press Ctrl+C to stop the showcase" -ForegroundColor Yellow
    Write-Host ""

    $allThemes = Get-AllThemes
    $selectedThemes = Get-Random -InputObject $allThemes -Count $Count

    foreach ($theme in $selectedThemes) {
        try {
            Clear-Host
            oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\$theme" | Invoke-Expression

            Write-Host "🎨 Theme: $theme" -ForegroundColor Cyan
            Write-Host "📂 Path: $(Get-Location)" -ForegroundColor Green
            Write-Host "💻 Example: Hello from PowerShell with $theme theme!" -ForegroundColor Yellow
            Write-Host "⏰ Switching in $Duration seconds..." -ForegroundColor Gray
            Write-Host ""

            for ($i = $Duration; $i -gt 0; $i--) {
                Write-Host "`rNext theme in: $i seconds... (Current: $theme)" -NoNewline -ForegroundColor DarkGray
                Start-Sleep -Seconds 1
            }
            Write-Host ""
        }
        catch {
            Write-Host "❌ Failed to load theme: $theme" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }

    Clear-Host
    Write-Host "🔄 Restoring default theme..." -ForegroundColor Yellow
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kali.omp.json" | Invoke-Expression
    Write-Host "✅ Theme showcase complete! Default kali theme restored." -ForegroundColor Green
}

function Save-ThemePreference {
    param([string]$ThemeName, [string]$Category = "custom")

    $preference = @{
        ThemeName = $ThemeName
        Category = $Category
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    try {
        $preference | ConvertTo-Json | Out-File -FilePath $script:ThemePreferenceFile -Encoding UTF8
        Write-Verbose "Theme preference saved: $ThemeName"
    }
    catch {
        Write-Warning "Could not save theme preference: $($_.Exception.Message)"
    }
}

function Get-ThemePreference {
    if (Test-Path $script:ThemePreferenceFile) {
        try {
            return Get-Content $script:ThemePreferenceFile -Raw | ConvertFrom-Json
        }
        catch {
            Write-Verbose "Could not load theme preference file"
        }
    }
    return $null
}

function Test-ThemeSetup {
    Write-HostCenter "🔍 THEME SETUP DIAGNOSTICS" -ForegroundColor Magenta
    Write-HostFullWidth "===========================" -ForegroundColor Magenta


    Write-Host "📦 Checking Oh My Posh installation..." -ForegroundColor Cyan
    try {
        $ompVersion = oh-my-posh --version 2>$null
        Write-Host "✅ Oh My Posh installed: $ompVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Oh My Posh not found in PATH" -ForegroundColor Red
        return
    }

    Write-Host "`n📂 Checking themes directory..." -ForegroundColor Cyan
    Write-Host "   POSH_THEMES_PATH: $env:POSH_THEMES_PATH" -ForegroundColor White
    
    if (Test-Path $env:POSH_THEMES_PATH) {
        Write-Host "✅ Themes directory exists" -ForegroundColor Green
        $themeCount = (Get-ChildItem "$env:POSH_THEMES_PATH\*.omp.json").Count
        Write-Host "📊 Found $themeCount theme files" -ForegroundColor White
    } else {
        Write-Host "❌ Themes directory not found" -ForegroundColor Red
        return
    }

    Write-Host "`n🎨 Checking default themes..." -ForegroundColor Cyan
    $defaultThemes = @("kali.omp.json", "tokyo.omp.json", "star.omp.json")
    foreach ($theme in $defaultThemes) {
        $themePath = "$env:POSH_THEMES_PATH\$theme"
        if (Test-Path $themePath) {
            Write-Host "✅ $theme - Found" -ForegroundColor Green
        } else {
            Write-Host "❌ $theme - Missing" -ForegroundColor Red
        }
    }

    Write-Host "`n🧪 Testing theme loading..." -ForegroundColor Cyan
    try {
        $testTheme = "star.omp.json"
        $testPath = "$env:POSH_THEMES_PATH\$testTheme"
        if (Test-Path $testPath) {
            oh-my-posh init pwsh --config $testPath | Out-Null
            Write-Host "✅ Theme loading works" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Theme loading failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n🎯 DIAGNOSTICS COMPLETE" -ForegroundColor Magenta
}

# -----------------------------------------------------------------------------
# 🎨 ENVIRONMENT INITIALIZATION
# -----------------------------------------------------------------------------
function Initialize-Environment {
    # Admin check
    $script:isAdmin = [Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Window title
    $Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)"
    if ($script:isAdmin) { $Host.UI.RawUI.WindowTitle += " [ADMIN]" }
    try { Import-Module Terminal-Icons -ErrorAction Stop } catch { }
    try { Import-Module PSReadLine -ErrorAction Stop } catch { }
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    } catch { }
    try {
        oh-my-posh init pwsh --config "https://raw.githubusercontent.com/trebor048/dotfiles/refs/heads/main/thehell.omp.json" | Invoke-Expression
    } catch { }
}

# -----------------------------------------------------------------------------
# 💻 PROMPT CONFIGURATIONS
# -----------------------------------------------------------------------------
function Get-GitBranch {
    try {
        $branch = & git rev-parse --abbrev-ref HEAD 2>$null
        return $branch ? " ($branch)" : ""
    } 
    catch { 
        return "" 
    }
}

function prompt { 
    $gitBranch = Get-GitBranch
    $location = $PWD.Path.Replace($HOME, '~')

    if ($script:isAdmin) {
        Write-Host "🔴" -NoNewline -ForegroundColor Red
        Write-Host "[$location$gitBranch] # " -NoNewline -ForegroundColor Red
    } else {
        if ($gitBranch) {
            Write-Host "🟢" -NoNewline -ForegroundColor Green
            Write-Host "[$location$gitBranch] $ " -NoNewline -ForegroundColor Green
        } else {
            Write-Host "🔵" -NoNewline -ForegroundColor Blue
            Write-Host "[$location] $ " -NoNewline -ForegroundColor Blue
        }
    }
    return " "
}

function promptMinimal {
    "$([char]27)[32m$([Environment]::UserName)$([char]27)[0m@$([char]27)[34m$env:COMPUTERNAME.Split('.')[0]$([char]27)[0m $([char]27)[35m$(Split-Path $PWD -Leaf)$([char]27)[0m$ "
}

function promptGit {
    $gitBranch = Get-GitBranch
    if ($script:isAdmin) {
        "🔴[$(Split-Path $PWD -Leaf)$gitBranch] # "
    } else {
        "🟢[$(Split-Path $PWD -Leaf)$gitBranch] $ "
    }
}

function Set-PromptStyle {
    param([ValidateSet("default", "minimal", "git")][string]$style)
    switch ($style) {
        "minimal" { Set-Item -Path function:prompt -Value ${function:promptMinimal}.Clone() }
        "git" { Set-Item -Path function:prompt -Value ${function:promptGit}.Clone() }
        default { Set-Item -Path function:prompt -Value ${function:prompt}.Clone() }
    }
}

# -----------------------------------------------------------------------------
# 🔗 ALIASES & SHORTCUTS
# -----------------------------------------------------------------------------
function Initialize-Aliases {
    # Editor Setup
    $script:EDITOR = if (Test-CommandExists nvim) { 'nvim' }
                     elseif (Test-CommandExists pvim) { 'pvim' }
                     elseif (Test-CommandExists vim) { 'vim' }
                     elseif (Test-CommandExists vi) { 'vi' }
                     elseif (Test-CommandExists code) { 'code' }
                     else { 'notepad' }
    Set-Alias vim $script:EDITOR

    # System & Navigation
    Set-Alias su admin
    Set-Alias sudo admin
    Set-Alias c Clear-Host
    Set-Alias cl Clear-Host
    Set-Alias h Get-Help
    Set-Alias cat Get-Content
    Set-Alias pwd Get-Location
    Set-Alias ls Get-ChildItem
    Set-Alias la Get-ChildItem
    Set-Alias ll Get-ChildItem
    Set-Alias which Get-Command
    Set-Alias grep Select-String
    Set-Alias man Get-Help

    # Git Commands
    Set-Alias gs git-status
    Set-Alias ga git-add
    Set-Alias gc git-commit
    Set-Alias gp git-push
    Set-Alias gpl git-pull
    Set-Alias gl git-log
    Set-Alias gb git-branch
    Set-Alias gco git-checkout
    Set-Alias gcb git-checkout-branch
    Set-Alias gd git-diff

    # Theme aliases
    Set-Alias theme Set-Theme
    Set-Alias themes Show-AvailableThemes
    Set-Alias theme-showcase Show-ThemeShowcase
    Set-Alias theme-test Test-ThemeSetup

    # PowerType aliases
    # Note: PowerType is auto-imported in Initialize-Environment
    # Manual installation: Install-Module PowerType -Scope CurrentUser

    # Alias manager
    Set-Alias aliases Show-AliasManager
}

# -----------------------------------------------------------------------------
# 📁 DIRECTORY & NAVIGATION
# -----------------------------------------------------------------------------
function root { Set-Location / }
function home { Set-Location $env:USERPROFILE }
function docs { Set-Location "$env:USERPROFILE\Documents" }
function desk { Set-Location "$env:USERPROFILE\Desktop" }
function dls { Set-Location "$env:USERPROFILE\Downloads" }
function gitdir { Set-Location "$env:USERPROFILE\git" }
function github { Set-Location "$HOME\Documents\Github" }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function cd... { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }

# -----------------------------------------------------------------------------
# 🐙 GIT WORKFLOW
# -----------------------------------------------------------------------------
function gitStatus { git status $args }
function gitAdd { git add $args }
function gitCommit { git commit $args }
function gitPush { git push $args }
function gitPull { git pull $args }
function gitLog { git log --oneline $args }
function gitBranch { git branch $args }
function gitCheckout { git checkout $args }
function gitCheckoutBranch { git checkout -b $args }
function gitDiff { git diff $args }

function gcom {
    param([string]$message)
    if (!$message) {
        Write-Host "❌ Please provide a commit message: gcom 'your message'" -ForegroundColor Red
        return
    }
    git add .
    git commit -m $message
}

function lazyg {
    param([string]$message)
    if (!$message) {
        Write-Host "❌ Please provide a commit message: lazyg 'your message'" -ForegroundColor Red
        return
    }
    git add .
    git commit -m $message
    git push
}

# -----------------------------------------------------------------------------
# 🛠️ DEVELOPMENT WORKFLOW
# -----------------------------------------------------------------------------
function pi { pnpm install }
function venv {
    param([string]$name = "venv")
    & python -m venv $name
    Write-Host "✅ Virtual environment '$name' created. Run 'actv' to activate." -ForegroundColor Green
}

function actv {
    param([string]$name = "venv")

    $paths = @(
        ".\$name\Scripts\Activate.ps1",
        ".\.$name\Scripts\Activate.ps1",
        ".\venv\Scripts\Activate.ps1",
        ".\.venv\Scripts\Activate.ps1"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            & $path
            Write-Host "✅ Activated virtual environment: $path" -ForegroundColor Green
            return
        }
    }
    Write-Host "❌ No virtual environment found in current directory." -ForegroundColor Red
}

# -----------------------------------------------------------------------------
# 🎯 ALIAS MANAGER
# -----------------------------------------------------------------------------
function Show-AliasManager {
    param([string]$filter, [string]$name)

    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🎯 ALIAS MANAGER v2.0" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    $aliases = Get-Alias | Sort-Object Name

    if ($name) {
        $alias = $aliases | Where-Object { $_.Name -eq $name }
        if ($alias) {
            Write-Host "🎯 ALIAS FOUND:" -ForegroundColor Green
            Write-Host "   $name → $($alias.Definition)" -ForegroundColor White
            Write-Host "   Description: $(Get-AliasDescription $name)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Alias '$name' not found" -ForegroundColor Red
        }
        return
    }

    $categories = @{
        "System" = @('c', 'cl', 'h', 'cat', 'pwd', 'ls', 'la', 'll', 'which', 'grep', 'man')
        "Git" = @('gs', 'ga', 'gc', 'gp', 'gpl', 'gl', 'gb', 'gco', 'gcb', 'gd', 'gcom', 'lazyg')
        "Python" = @('py', 'py3', 'pipi', 'pipu')
        "Node/NPM" = @('nr', 'nd', 'nb', 'ns', 'ni', 'nrm', 'nrd', 'nrb', 'nrs', 'nrt')
        "PNPM" = @('pr', 'pd', 'pb', 'ps', 'px', 'pa', 'pad', 'prm', 'pu', 'pui')
        "Yarn" = @('y', 'yd', 'yb', 'ys', 'yt')
        "Admin" = @('su', 'sudo')
        "Editor" = @('vim')
    }

    if ($filter) {
        $categoryName = $filter
        $categoryAliases = $categories[$categoryName]
        if ($categoryAliases) {
            Write-Host "📂 $($categoryName.ToUpper()) ALIASES:" -ForegroundColor Cyan
            $categoryAliases | ForEach-Object {
                $alias = $aliases | Where-Object { $_.Name -eq $_ }
                if ($alias) {
                    Write-Host "   $_ → $($alias.Definition)" -ForegroundColor White
                }
            }
        }
        return
    }

    Write-Host "📊 ALIAS STATISTICS:" -ForegroundColor Cyan
    Write-Host "   Total Aliases: $($aliases.Count)" -ForegroundColor White
    Write-Host ""

    foreach ($category in $categories.GetEnumerator() | Sort-Object Name) {
        Write-Host "📂 $($category.Key.ToUpper()) ALIASES:" -ForegroundColor Cyan
        $category.Value | ForEach-Object {
            $alias = $aliases | Where-Object { $_.Name -eq $_ }
            if ($alias) {
                Write-Host "   $_ → $($alias.Definition)" -ForegroundColor White
            }
        }
        Write-Host ""
    }

    Write-Host "💡 USAGE:" -ForegroundColor Green
    Write-Host "   • Show-AliasManager -i 'git'    (show only Git aliases)" -ForegroundColor White
    Write-Host "   • Show-AliasManager -n 'gs'     (find specific alias)" -ForegroundColor White
    Write-Host ""
}

function Get-AliasDescription {
    param([string]$aliasName)

    $descriptions = @{
        "c" = "Clear screen"; "cl" = "Clear screen (alternative)"; "h" = "Get help"
        "cat" = "Display file contents"; "pwd" = "Show current directory"; "ls" = "List directory contents"
        "gs" = "Git status"; "ga" = "Git add files"; "gc" = "Git commit"; "gp" = "Git push"
        "gpl" = "Git pull"; "gl" = "Git log (oneline)"; "gb" = "Git branch list"
        "pi" = "Pnpm install"; "venv" = "Create Python virtual environment"; "actv" = "Activate Python venv"
    }

    return $descriptions[$aliasName] ?? "No description available"
}

# -----------------------------------------------------------------------------
# 🔧 UTILITY FUNCTIONS
# -----------------------------------------------------------------------------
function ll { Get-ChildItem -Path $pwd -File }
function la { Get-ChildItem -Path $pwd }
function l { Get-ChildItem -Path $pwd }
function touch {
    param([string]$file, [string]$content = "")
    $content | Out-File $file -Encoding UTF8
}
function mkcd {
    param([string]$path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}
function open { param([string]$file) Invoke-Item $file }
function tail { param([string]$file, [int]$lines = 10) Get-Content $file -Tail $lines }
function head { param([string]$file, [int]$lines = 10) Get-Content $file -Head $lines }
function which { param([string]$name) Get-Command $name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition }
function export { param([string]$name, [string]$value) Set-Item -Force -Path "env:$name" -Value $value }
function reloadP {
    Write-Host "🔄 Reloading PowerShell profile..." -ForegroundColor Cyan
    try {
        & $profile
        Write-Host "✅ Profile reloaded successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to reload profile: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# 🔍 SYSTEM MONITORING
# -----------------------------------------------------------------------------
function Get-PubIP {
    try { (Invoke-WebRequest "http://ifconfig.me/ip" -TimeoutSec 5).Content }
    catch { "Unable to fetch public IP" }
}

function ip {
    Get-NetIPAddress |
        Where-Object { $_.AddressFamily -eq "IPv4" -and $_.PrefixOrigin -ne "WellKnown" } |
        Select-Object IPAddress, InterfaceAlias |
        Format-Table -AutoSize
}

function ports {
    Get-NetTCPConnection |
        Where-Object { $_.State -eq "Listen" } |
        Select-Object LocalAddress, LocalPort, @{Name="Process"; Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name}} |
        Sort-Object LocalPort |
        Format-Table -AutoSize
}

function processes {
    Get-Process |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 10 Name, CPU, @{Name="Memory(MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 1)}} |
        Format-Table -AutoSize
}

function sysinfo {
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-HostCenter "🔍 System Information" -ForegroundColor Cyan
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "🖥️  HARDWARE:" -ForegroundColor Yellow
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
        Write-Host "   CPU: $($cpu.Name.Split('@')[0].Trim())" -ForegroundColor White
    } catch { Write-Host "   CPU: Information unavailable" -ForegroundColor Red }

    try {
        $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "   RAM: $([math]::Round($mem.TotalVisibleMemorySize / 1MB, 1))GB total, $([math]::Round($mem.FreePhysicalMemory / 1MB, 1))GB free" -ForegroundColor White
    } catch { Write-Host "   RAM: Information unavailable" -ForegroundColor Red }

    Write-Host "`n📦 SOFTWARE:" -ForegroundColor Yellow
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "   OS: $($os.Caption)" -ForegroundColor White
    } catch {
        Write-Host "   OS: Information unavailable" -ForegroundColor Red
    }
    Write-Host "   PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "   User: $env:USERNAME" -ForegroundColor White

    Write-Host "`n💾 STORAGE:" -ForegroundColor Yellow
    try {
        Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
            $used = [math]::Round(($_.Size - $_.SizeRemaining) / 1GB, 1)
            $free = [math]::Round($_.SizeRemaining / 1GB, 1)
            $total = [math]::Round($_.Size / 1GB, 1)
            $percent = [math]::Round($used / $total * 100, 1)
            Write-Host "   $($_.DriveLetter):\ ${used}GB used, ${free}GB free of ${total}GB (${percent}%)" -ForegroundColor White
        }
    } catch { Write-Host "   Storage: Information unavailable" -ForegroundColor Red }

    Write-Host "`n✅ System analysis complete!" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# 🤖 AI-POWERED ASSISTANT
# -----------------------------------------------------------------------------
function aiHelp {
    param([string]$query)

    if (!$query) {
        Write-Host "🤖 AI Assistant - Your intelligent PowerShell companion" -ForegroundColor Cyan
        Write-Host "Usage: aiHelp 'describe what you want to do'" -ForegroundColor Yellow
        return
    }

    Write-Host "🤖 AI analyzing: '$query'" -ForegroundColor Cyan

    $knowledgeBase = @{
        "find large files" = "Get-ChildItem -Recurse | Where-Object { `$_.Length -gt 100MB } | Sort-Object Length -Descending"
        "git workflow" = "gs → ga . → gc -m 'message' → gp"
        "python venv" = "venv → actv"
        "system info" = "sysinfo"
        "network info" = "ip"
        "running ports" = "ports"
    }

    $found = $false
    foreach ($key in $knowledgeBase.Keys) {
        if ($query -like "*$key*") {
            Write-Host "💡 Command: $($knowledgeBase[$key])" -ForegroundColor Green
            $found = $true
            break
        }
    }

    if (!$found) {
        Write-Host "🔍 Try: aiSearch '$query' or pphelp | grep '$query'" -ForegroundColor Cyan
    }
}

function aiExplain {
    param([string]$command)

    if (!$command) {
        Write-Host "Usage: aiExplain 'command to explain'" -ForegroundColor Yellow
        return
    }

    $commandHelp = @{
        "gs" = "Git status - shows current repository state, staged/unstaged changes"
        "ga" = "Git add - stages files for commit (ga . = add all)"
        "venv" = "Creates isolated Python environment in 'venv' folder"
        "sysinfo" = "Comprehensive system information display"
    }

    if ($commandHelp.ContainsKey($command)) {
        Write-Host "📖 $($commandHelp[$command])" -ForegroundColor Green
    } else {
        Write-Host "❓ Command not in knowledge base." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# 🎮 INTERACTIVE MENUS
# -----------------------------------------------------------------------------
function devMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "🚀 Development Menu" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. 📦 Package Management" -ForegroundColor Yellow
        Write-Host "2. 🐙 Git Operations" -ForegroundColor Yellow
        Write-Host "3. 🐍 Python Development" -ForegroundColor Yellow
        Write-Host "4. 🌐 Web Development" -ForegroundColor Yellow
        Write-Host "5. 🤖 AI Assistant" -ForegroundColor Yellow
        Write-Host "6. 🛠️  System Tools" -ForegroundColor Yellow
        Write-Host "7. 📊 Performance Monitor" -ForegroundColor Yellow
        Write-Host "8. 🔧 Settings & Profile" -ForegroundColor Yellow
        Write-Host "0. Exit to PowerShell" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select option (0-8)"

        switch ($choice) {
            "1" { Show-PackageMenu; Read-Host "`nPress Enter to continue" }
            "2" { Show-GitMenu; Read-Host "`nPress Enter to continue" }
            "3" { Show-PythonMenu; Read-Host "`nPress Enter to continue" }
            "4" { Show-WebMenu; Read-Host "`nPress Enter to continue" }
            "5" { Show-AIMenu; Read-Host "`nPress Enter to continue" }
            "6" { Show-SystemMenu; Read-Host "`nPress Enter to continue" }
            "7" { Show-PerformanceMenu; Read-Host "`nPress Enter to continue" }
            "8" { Show-SettingsMenu; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Show-GitMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
    Write-HostCenter "🐙 Git Operations" -ForegroundColor Cyan
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Path ".git") {
        Write-Host "📁 Git repository detected" -ForegroundColor Green
        gs
    } else {
        Write-Host "❌ Not a git repository" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "Git workflow commands:" -ForegroundColor Green
    Write-Host "• gs    - Status" -ForegroundColor White
    Write-Host "• ga .  - Add all files" -ForegroundColor White
    Write-Host "• gc -m 'message' - Commit" -ForegroundColor White
    Write-Host "• gp    - Push" -ForegroundColor White
}

function Show-PythonMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
    Write-HostCenter "🐍 Python Development" -ForegroundColor Cyan
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    if ($env:VIRTUAL_ENV) {
        Write-Host "✅ Virtual environment active: $($env:VIRTUAL_ENV)" -ForegroundColor Green
    } else {
        Write-Host "❌ No virtual environment active" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "Python commands:" -ForegroundColor Green
    Write-Host "• venv [name] - Create virtual environment" -ForegroundColor White
    Write-Host "• actv [name] - Activate virtual environment" -ForegroundColor White
    Write-Host "• pipi        - Install packages" -ForegroundColor White
}

# Additional menu functions would follow similar patterns...

# -----------------------------------------------------------------------------
# 📚 COMPREHENSIVE HELP SYSTEM
# -----------------------------------------------------------------------------
function pphelp {
    Write-HostCenter '  PowerShell Profile Help' -ForegroundColor Blue
    Write-HostFullWidth '  =======================' -ForegroundColor Blue
    Write-Host ''

    Write-Host '  DIRECTORY NAVIGATION' -ForegroundColor Yellow
    Write-Host '======================'
    Write-Host '  home       - Go to user profile directory'
    Write-Host '  docs       - Go to Documents folder'
    Write-Host '  gitdir     - Go to ~/git directory'
    Write-Host '  .. / ...   - Quick parent directory navigation'
    Write-Host ''

    Write-Host '  DEVELOPMENT' -ForegroundColor Yellow
    Write-Host '======================'
    Write-Host '  pi         - Run pnpm install'
    Write-Host '  venv       - Create Python virtual environment'
    Write-Host '  actv       - Activate Python virtual environment'
    Write-Host ''

    Write-Host '  GIT COMMANDS' -ForegroundColor Yellow
    Write-Host '======================'
    Write-Host '  gs  - git status | ga - git add | gc - git commit'
    Write-Host '  gp  - git push  | gpl - git pull | gl - git log'
    Write-Host '  gcom - Git add all & commit | lazyg - Add, commit & push'
    Write-Host ''

    Write-Host '  SYSTEM INFO' -ForegroundColor Yellow
    Write-Host '======================'
    Write-Host '  sysinfo    - Full system info | ip - Show local IPs'
    Write-Host '  ports      - Show listening ports | processes - Top processes'
    Write-Host ''

    Write-Host '  🤖 AI ASSISTANT' -ForegroundColor Magenta
    Write-Host '======================'
    Write-Host '  ai-help    - AI-powered command suggestions'
    Write-Host '  ai-explain - Explain complex commands'
    Write-Host ''

    Write-Host '  🎮 INTERACTIVE MENUS' -ForegroundColor Magenta
    Write-Host '======================'
    Write-Host '  devmenu    - Main development menu'
    Write-Host ''

    Write-Host '  🎨 THEME MANAGEMENT' -ForegroundColor Magenta
    Write-Host '======================'
    Write-Host '  Set-Theme  - Change Oh My Posh theme'
    Write-Host '  themes     - Browse available themes'
    Write-Host '  theme-showcase - Preview random themes'
    Write-Host ''
}

# -----------------------------------------------------------------------------
# 🚀 INITIALIZATION
# -----------------------------------------------------------------------------
function Initialize-PowerShellProfile {
    Initialize-Environment
    Initialize-Aliases
    
    if ($showWelcome) {
        Show-WelcomeScreen
    }

    # Load external completions if available

    # if (Test-Path '~/.inshellisense/pwsh/init.ps1') {
    #     . ~/.inshellisense/pwsh/init.ps1
    # }
    # if (Test-Path '~/.inshellisense/powershell/init.ps1') {
    #     . ~/.inshellisense/powershell/init.ps1
    # }

    Write-Verbose "PowerShell profile loaded successfully with $(Get-Command -CommandType Function | Measure-Object).Count functions"
}

# Prevent multiple profile loads
if ($script:ProfileLoaded) {
    Write-Host "⚠️ Profile already loaded, skipping..." -ForegroundColor Yellow
    return
}
$script:ProfileLoaded = $true

# Execute initialization
Initialize-PowerShellProfile
