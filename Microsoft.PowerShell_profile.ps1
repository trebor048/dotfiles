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
$script:ProfileLoaded = $false
$script:OllamaModel = "llama2"
$script:OllamaBaseUrl = "http://localhost:11434"

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
    $border = "═" * ($Message.Length + 4)
    Write-HostCenter "╔$border╗" -Color $BorderColor
    Write-HostCenter "║  $Message  ║" -Color $BorderColor
    Write-HostCenter "╚$border╝" -Color $BorderColor
}

function Write-HostFullWidth {
    param([string]$Message, [string]$Color = "White")
    $width = $Host.UI.RawUI.BufferSize.Width
    if ($Message.Length -eq 1) {
        $repeated = $Message * $width
        Write-Host $repeated -ForegroundColor $Color
    } else {
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
        $metrics.Uptime = (Get-Date) - $os.LastBootUpTime
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
        $disk = Get-PSDrive -Name C -ErrorAction Stop
        $metrics.DiskFreeGB = [math]::Round($disk.Free / 1GB, 1)
        $metrics.DiskTotalGB = [math]::Round($disk.Used / 1GB + $disk.Free / 1GB, 1)
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
    Write-Host "   🔧 pshelp | 🛠️ devmenu | 🤖 aihelp | 📊 sysinfo | 🎯 aliases" -ForegroundColor White
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
                Save-ThemePreference -ThemeName $Name
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
            Save-ThemePreference -ThemeName $theme -Category $Category
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
    
    try { Import-Module Terminal-Icons -ErrorAction SilentlyContinue } catch { }
    try { Import-Module PSReadLine -ErrorAction SilentlyContinue } catch { }
    
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    } catch { }
    
    try {
        oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kali.omp.json" | Invoke-Expression
    } catch { 
        Write-Host "⚠️ Oh My Posh not configured. Run 'Test-ThemeSetup' to diagnose." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# 💻 PROMPT CONFIGURATIONS
# -----------------------------------------------------------------------------
function Get-GitBranch {
    try {
        $branch = & git rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) { return " ($branch)" } else { return "" }
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
            Write-Host "[$location$gitBranch] `$ " -NoNewline -ForegroundColor Green
        } else {
            Write-Host "🔵" -NoNewline -ForegroundColor Blue
            Write-Host "[$location] `$ " -NoNewline -ForegroundColor Blue
        }
    }
    return " "
}

function promptMinimal {
    "$([char]27)[32m$([Environment]::UserName)$([char]27)[0m@$([char]27)[34m$env:COMPUTERNAME.Split('.')[0]$([char]27)[0m $([char]27)[35m$(Split-Path $PWD -Leaf)$([char]27)[0m`$ "
}

function promptGit {
    $gitBranch = Get-GitBranch
    if ($script:isAdmin) {
        "🔴[$(Split-Path $PWD -Leaf)$gitBranch] # "
    } else {
        "🟢[$(Split-Path $PWD -Leaf)$gitBranch] `$ "
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
    Set-Alias gs gstatus
    Set-Alias ga gadd
    Set-Alias gc gcommit
    Set-Alias gp gpush
    Set-Alias gpl gpull
    Set-Alias gl glog
    Set-Alias gb gbranch
    Set-Alias gco gcheckout
    Set-Alias gcb gcheckoutbranch
    Set-Alias gd gdiff

    # Theme aliases
    Set-Alias theme Set-Theme
    Set-Alias themes Show-AvailableThemes
    Set-Alias theme-showcase Show-ThemeShowcase
    Set-Alias theme-test Test-ThemeSetup

    # Utility aliases
    Set-Alias reload-profile reloadP
    Set-Alias aliases Show-AliasManager
    Set-Alias sysinfo Get-SystemInfo
    Set-Alias pshelp Show-ProfileHelp
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
function gstatus { git status $args }
function gadd { git add $args }
function gcommit { git commit $args }
function gpush { git push $args }
function gpull { git pull $args }
function glog { git log --oneline $args }
function gbranch { git branch $args }
function gcheckout { git checkout $args }
function gcheckoutbranch { git checkout -b $args }
function gdiff { git diff $args }

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
    param([string]$Filter, [string]$Name)

    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🎯 ALIAS MANAGER v2.0" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    $aliases = Get-Alias | Sort-Object Name

    if ($Name) {
        $alias = $aliases | Where-Object { $_.Name -eq $Name }
        if ($alias) {
            Write-Host "🎯 ALIAS FOUND:" -ForegroundColor Green
            Write-Host "   $Name → $($alias.Definition)" -ForegroundColor White
            Write-Host "   Description: $(Get-AliasDescription $Name)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Alias '$Name' not found" -ForegroundColor Red
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

    if ($Filter) {
        $categoryName = $Filter
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
    Write-Host "   • Show-AliasManager -Filter 'git'    (show only Git aliases)" -ForegroundColor White
    Write-Host "   • Show-AliasManager -Name 'gs'     (find specific alias)" -ForegroundColor White
    Write-Host ""
}

function Get-AliasDescription {
    param([string]$aliasName)

    $descriptions = @{
        "c" = "Clear screen"; "cl" = "Clear screen (alternative)"; "h" = "Get help"
        "cat" = "Display file contents"; "pwd" = "Show current directory"; "ls" = "List directory contents"
        "gs" = "Git status"; "ga" = "Git add files"; "gc" = "Git commit"; "gp" = "Git push"
        "gpl" = "Git pull"; "gl" = "Git log (oneline)"; "gb" = "Git branch list"
        "gco" = "Git checkout"; "gcb" = "Git checkout new branch"; "gd" = "Git diff"
        "pi" = "Pnpm install"; "venv" = "Create Python virtual environment"; "actv" = "Activate Python venv"
    }

    $desc = $descriptions[$aliasName]
    if ($null -ne $desc) { return $desc } else { return "No description available" }
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

function Get-SystemInfo {
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
            Write-Host "   $($_.DriveLetter):\ ${used}GB used, ${free}GB free of ${total}GB (${percent}%%)" -ForegroundColor White
        }
    } catch { Write-Host "   Storage: Information unavailable" -ForegroundColor Red }

    Write-Host "`n✅ System analysis complete!" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# 🤖 AI-POWERED ASSISTANT (OLLAMA INTEGRATION)
# -----------------------------------------------------------------------------
function Test-OllamaConnection {
    try {
        Invoke-WebRequest -Uri "$script:OllamaBaseUrl/api/version" -Method GET -TimeoutSec 3 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-OllamaChat {
    param(
        [string]$Prompt,
        [string]$Model = $script:OllamaModel
    )

    if (!(Test-OllamaConnection)) {
        Write-Host "❌ Ollama not running. Please start Ollama first." -ForegroundColor Red
        Write-Host "💡 Run: ollama serve" -ForegroundColor Yellow
        return $null
    }

    try {
        $body = @{
            model = $Model
            prompt = $Prompt
            stream = $false
        } | ConvertTo-Json

        $response = Invoke-WebRequest -Uri "$script:OllamaBaseUrl/api/generate" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 30

        if ($response.StatusCode -eq 200) {
            $result = $response.Content | ConvertFrom-Json
            return $result.response
        }
    }
    catch {
        Write-Host "❌ Error calling Ollama: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }

    return $null
}

function aihelp {
    param([string]$query)

    if (!$query) {
        Write-Host "🤖 AI Assistant - Ollama-powered PowerShell companion" -ForegroundColor Cyan
        Write-Host "Usage: aihelp 'describe what you want to do'" -ForegroundColor Yellow
        Write-Host "Model: $script:OllamaModel" -ForegroundColor Gray
        return
    }

    Write-Host "🤖 AI analyzing: '$query'" -ForegroundColor Cyan

    # First check local knowledge base for quick answers
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
        Write-Host "🔍 Consulting Ollama AI..." -ForegroundColor Cyan
        $aiResponse = Invoke-OllamaChat -Prompt "Help with PowerShell command for: $query. Provide a concise, practical solution."
        if ($aiResponse) {
            Write-Host "🤖 AI Response:" -ForegroundColor Green
            Write-Host $aiResponse -ForegroundColor White
        } else {
            Write-Host "❌ Could not get AI response. Try: pphelp | grep '$query'" -ForegroundColor Red
        }
    }
}

function aiex {
    param([string]$command)

    if (!$command) {
        Write-Host "Usage: aiex 'command to explain'" -ForegroundColor Yellow
        Write-Host "Model: $script:OllamaModel" -ForegroundColor Gray
        return
    }

    # First check local knowledge base
    $commandHelp = @{
        "gs" = "Git status - shows current repository state, staged/unstaged changes"
        "ga" = "Git add - stages files for commit (ga . = add all)"
        "venv" = "Creates isolated Python environment in 'venv' folder"
        "sysinfo" = "Comprehensive system information display"
        "pi" = "PNPM install - installs packages using PNPM"
        "actv" = "Activates Python virtual environment"
        "lazyg" = "Git add all, commit, and push in one command"
        "ports" = "Shows listening ports and their processes"
    }

    if ($commandHelp.ContainsKey($command)) {
        Write-Host "📖 $($commandHelp[$command])" -ForegroundColor Green
        return
    }

    # Fall back to Ollama for unknown commands
    Write-Host "🔍 Consulting Ollama AI for explanation..." -ForegroundColor Cyan
    $aiResponse = Invoke-OllamaChat -Prompt "Explain the PowerShell command or alias '$command' in detail. What does it do? When would you use it?"
    if ($aiResponse) {
        Write-Host "🤖 AI Explanation:" -ForegroundColor Green
        Write-Host $aiResponse -ForegroundColor White
    } else {
        Write-Host "❌ Could not get AI explanation." -ForegroundColor Red
    }
}

function Set-AIModel {
    param([string]$model)
    $script:OllamaModel = $model
    Write-Host "✅ AI Model set to: $model" -ForegroundColor Green
}

function Get-AIModel {
    Write-Host "Current AI Model: $script:OllamaModel" -ForegroundColor Cyan
    Write-Host "Ollama Base URL: $script:OllamaBaseUrl" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# 🎮 INTERACTIVE MENUS
# -----------------------------------------------------------------------------
function devmenu {
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
        git status
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
    Write-Host "• pip install - Install packages" -ForegroundColor White
}

# -----------------------------------------------------------------------------
# 📚 COMPREHENSIVE HELP SYSTEM
# -----------------------------------------------------------------------------
function Show-ProfileHelp {
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
    Write-Host "  gcom - Git add all & commit | lazyg - Add, commit & push"
    Write-Host ''

    Write-Host '  SYSTEM INFO' -ForegroundColor Yellow
    Write-Host '======================'
    Write-Host '  sysinfo    - Full system info | ip - Show local IPs'
    Write-Host '  ports      - Show listening ports | processes - Top processes'
    Write-Host ''

    Write-Host '  🤖 AI ASSISTANT' -ForegroundColor Magenta
    Write-Host '======================'
    Write-Host '  aihelp    - AI-powered command suggestions'
    Write-Host '  aiex - Explain complex commands'
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
# 📦 PACKAGE MANAGEMENT MENUS
# -----------------------------------------------------------------------------
function Show-PackageMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "📦 Package Management" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. 📦 NPM/Node.js" -ForegroundColor Yellow
        Write-Host "2. 🐍 Python (pip)" -ForegroundColor Yellow
        Write-Host "3. 🍃 PNPM" -ForegroundColor Yellow
        Write-Host "4. 🧶 Yarn" -ForegroundColor Yellow
        Write-Host "5. 🦀 Rust (Cargo)" -ForegroundColor Yellow
        Write-Host "6. 🐙 Git/Version Control" -ForegroundColor Yellow
        Write-Host "7. 🪟 Windows Features" -ForegroundColor Yellow
        Write-Host "8. 📋 Package Diagnostics" -ForegroundColor Yellow
        Write-Host "0. Back to Main Menu" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select package type (0-8)"

        switch ($choice) {
            "1" { Show-NPMMenu; Read-Host "`nPress Enter to continue" }
            "2" { Show-PythonMenu; Read-Host "`nPress Enter to continue" }
            "3" { Show-PNPMMenu; Read-Host "`nPress Enter to continue" }
            "4" { Show-YarnMenu; Read-Host "`nPress Enter to continue" }
            "5" { Show-RustMenu; Read-Host "`nPress Enter to continue" }
            "6" { Show-GitMenu; Read-Host "`nPress Enter to continue" }
            "7" { Show-WindowsMenu; Read-Host "`nPress Enter to continue" }
            "8" { Show-PackageDiagnostics; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Show-NPMMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "📦 NPM/Node.js Package Management" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    if (Test-CommandExists node) {
        Write-Host "✅ Node.js $(node --version) detected" -ForegroundColor Green
    } else {
        Write-Host "❌ Node.js not found in PATH" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "NPM Commands:" -ForegroundColor Green
    Write-Host "• ni   - npm install" -ForegroundColor White
    Write-Host "• nr   - npm run" -ForegroundColor White
    Write-Host "• ns   - npm start" -ForegroundColor White
    Write-Host "• nt   - npm test" -ForegroundColor White
    Write-Host ""
}

function Show-PNPMMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "🍃 PNPM Package Management" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    if (Test-CommandExists pnpm) {
        Write-Host "✅ PNPM $(pnpm --version) detected" -ForegroundColor Green
    } else {
        Write-Host "❌ PNPM not found in PATH" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "PNPM Commands:" -ForegroundColor Green
    Write-Host "• pi   - pnpm install" -ForegroundColor White
    Write-Host "• pr   - pnpm run" -ForegroundColor White
    Write-Host "• pd   - pnpm dev" -ForegroundColor White
    Write-Host "• pb   - pnpm build" -ForegroundColor White
    Write-Host "• ps   - pnpm start" -ForegroundColor White
    Write-Host ""
}

function Show-YarnMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "🧶 Yarn Package Management" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    if (Test-CommandExists yarn) {
        Write-Host "✅ Yarn $(yarn --version) detected" -ForegroundColor Green
    } else {
        Write-Host "❌ Yarn not found in PATH" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Yarn Commands:" -ForegroundColor Green
    Write-Host "• y    - yarn" -ForegroundColor White
    Write-Host "• yd   - yarn dev" -ForegroundColor White
    Write-Host "• yb   - yarn build" -ForegroundColor White
    Write-Host "• ys   - yarn start" -ForegroundColor White
    Write-Host "• yt   - yarn test" -ForegroundColor White
    Write-Host ""
}

function Show-RustMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🦀 Rust (Cargo) Management" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    if (Test-CommandExists cargo) {
        Write-Host "✅ Cargo $(cargo --version) detected" -ForegroundColor Green
    } else {
        Write-Host "❌ Cargo not found in PATH" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Cargo Commands:" -ForegroundColor Green
    Write-Host "• cargo build   - Build project" -ForegroundColor White
    Write-Host "• cargo run     - Build and run" -ForegroundColor White
    Write-Host "• cargo test    - Run tests" -ForegroundColor White
    Write-Host "• cargo check   - Check code without building" -ForegroundColor White
    Write-Host ""
}

function Show-WindowsMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "🪟 Windows Features Management" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "Windows Features:" -ForegroundColor Green
    Write-Host "• Get-WindowsOptionalFeature -Online - List features" -ForegroundColor White
    Write-Host "• Enable-WindowsOptionalFeature -Online -FeatureName <name>" -ForegroundColor White
    Write-Host "• Disable-WindowsOptionalFeature -Online -FeatureName <name>" -ForegroundColor White
    Write-Host ""
}

function Show-PackageDiagnostics {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "📋 Package Manager Diagnostics" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    $managers = @(
        @{Name="Node.js"; Command="node"; Version="--version"},
        @{Name="NPM"; Command="npm"; Version="--version"},
        @{Name="PNPM"; Command="pnpm"; Version="--version"},
        @{Name="Yarn"; Command="yarn"; Version="--version"},
        @{Name="Python"; Command="python"; Version="--version"},
        @{Name="Pip"; Command="pip"; Version="--version"},
        @{Name="Cargo"; Command="cargo"; Version="--version"},
        @{Name="Git"; Command="git"; Version="--version"}
    )

    foreach ($manager in $managers) {
        if (Test-CommandExists $manager.Command) {
            try {
                $version = & $manager.Command $manager.Version.Split() 2>$null
                Write-Host "✅ $($manager.Name): $version" -ForegroundColor Green
            } catch {
                Write-Host "⚠️ $($manager.Name): Found but version check failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ $($manager.Name): Not installed" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# -----------------------------------------------------------------------------
# 🌐 WEB DEVELOPMENT MENU
# -----------------------------------------------------------------------------
function Show-WebMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "🌐 Web Development Tools" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. ⚛️ React Development" -ForegroundColor Yellow
        Write-Host "2. 🅰️ Angular Development" -ForegroundColor Yellow
        Write-Host "3. 🅅 Vue.js Development" -ForegroundColor Yellow
        Write-Host "4. 🐳 Docker Containers" -ForegroundColor Yellow
        Write-Host "5. 📡 API Testing" -ForegroundColor Yellow
        Write-Host "6. 🔧 Build Tools" -ForegroundColor Yellow
        Write-Host "7. 📊 Development Servers" -ForegroundColor Yellow
        Write-Host "8. 🔍 Web Diagnostics" -ForegroundColor Yellow
        Write-Host "0. Back to Main Menu" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select web development tool (0-8)"

        switch ($choice) {
            "1" { Show-ReactMenu; Read-Host "`nPress Enter to continue" }
            "2" { Show-AngularMenu; Read-Host "`nPress Enter to continue" }
            "3" { Show-VueMenu; Read-Host "`nPress Enter to continue" }
            "4" { Show-DockerMenu; Read-Host "`nPress Enter to continue" }
            "5" { Show-APIMenu; Read-Host "`nPress Enter to continue" }
            "6" { Show-BuildMenu; Read-Host "`nPress Enter to continue" }
            "7" { Show-ServerMenu; Read-Host "`nPress Enter to continue" }
            "8" { Show-WebDiagnostics; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Show-ReactMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "⚛️ React Development" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "React Commands:" -ForegroundColor Green
    Write-Host "• npx create-react-app 'name' - Create new React app" -ForegroundColor White
    Write-Host "• npm start                  - Start development server" -ForegroundColor White
    Write-Host "• npm run build              - Build for production" -ForegroundColor White
    Write-Host "• npm test                   - Run tests" -ForegroundColor White
    Write-Host ""
}

function Show-AngularMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🅰️ Angular Development" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    Write-Host "Angular Commands:" -ForegroundColor Green
    Write-Host "• npx @angular/cli new 'name' - Create new Angular app" -ForegroundColor White
    Write-Host "• ng serve                    - Start development server" -ForegroundColor White
    Write-Host "• ng build                    - Build for production" -ForegroundColor White
    Write-Host "• ng test                     - Run tests" -ForegroundColor White
    Write-Host "• ng generate component 'name' - Generate component" -ForegroundColor White
    Write-Host ""
}

function Show-VueMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "🅅 Vue.js Development" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "Vue Commands:" -ForegroundColor Green
    Write-Host "• npm create vue@latest <name> - Create new Vue app" -ForegroundColor White
    Write-Host "• npm run dev                 - Start development server" -ForegroundColor White
    Write-Host "• npm run build               - Build for production" -ForegroundColor White
    Write-Host "• npm test                    - Run tests" -ForegroundColor White
    Write-Host ""
}

function Show-DockerMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "🐳 Docker Container Management" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    if (Test-CommandExists docker) {
        Write-Host "✅ Docker detected" -ForegroundColor Green
        Write-Host "Docker Commands:" -ForegroundColor Green
        Write-Host "• docker ps              - List running containers" -ForegroundColor White
        Write-Host "• docker ps -a           - List all containers" -ForegroundColor White
        Write-Host "• docker images          - List images" -ForegroundColor White
        Write-Host "• docker build -t 'name' . - Build image" -ForegroundColor White
        Write-Host "• docker run 'image'     - Run container" -ForegroundColor White
        Write-Host "• docker-compose up      - Start services" -ForegroundColor White
    } else {
        Write-Host "❌ Docker not found in PATH" -ForegroundColor Red
    }
    Write-Host ""
}

function Show-APIMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "📡 API Testing Tools" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "API Testing Commands:" -ForegroundColor Green
    Write-Host "• curl <url>             - Test API endpoint" -ForegroundColor White
    Write-Host "• Invoke-WebRequest <url> - PowerShell web request" -ForegroundColor White
    Write-Host "• Test-NetConnection      - Test connectivity" -ForegroundColor White
    Write-Host ""
}

function Show-BuildMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-HostCenter "🔧 Build Tools" -ForegroundColor Yellow
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Build Commands:" -ForegroundColor Green
    Write-Host "• npm run build          - Node.js build" -ForegroundColor White
    Write-Host "• pnpm build             - PNPM build" -ForegroundColor White
    Write-Host "• yarn build             - Yarn build" -ForegroundColor White
    Write-Host "• dotnet build           - .NET build" -ForegroundColor White
    Write-Host "• cargo build            - Rust build" -ForegroundColor White
    Write-Host "• ng build               - Angular build" -ForegroundColor White
    Write-Host ""
}

function Show-ServerMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "📊 Development Servers" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "Server Commands:" -ForegroundColor Green
    Write-Host "• npm start              - Start Node.js server" -ForegroundColor White
    Write-Host "• npm run dev            - Start development server" -ForegroundColor White
    Write-Host "• pnpm dev               - PNPM dev server" -ForegroundColor White
    Write-Host "• yarn dev               - Yarn dev server" -ForegroundColor White
    Write-Host "• python -m http.server  - Simple HTTP server" -ForegroundColor White
    Write-Host ""
}

function Show-WebDiagnostics {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🔍 Web Development Diagnostics" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "🔧 Checking web development tools..." -ForegroundColor Cyan

    $webtools = @(
        @{Name="Node.js"; Command="node"; Test="--version"},
        @{Name="NPM"; Command="npm"; Test="--version"},
        @{Name="Git"; Command="git"; Test="--version"},
        @{Name="Python"; Command="python"; Test="--version"}
    )

    foreach ($tool in $webtools) {
        if (Test-CommandExists $tool.Command) {
            try {
                $version = & $tool.Command $tool.Test.Split() 2>$null
                Write-Host "✅ $($tool.Name): $version" -ForegroundColor Green
            } catch {
                Write-Host "⚠️ $($tool.Name): Found but version check failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ $($tool.Name): Not installed" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "🌐 Network connectivity:" -ForegroundColor Cyan
    try {
        $test = Test-NetConnection -ComputerName "google.com" -Port 80 -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($test) {
            Write-Host "✅ Internet connection: OK" -ForegroundColor Green
        } else {
            Write-Host "❌ Internet connection: Failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Internet connection: Error" -ForegroundColor Red
    }
    Write-Host ""
}

# -----------------------------------------------------------------------------
# 🤖 AI ASSISTANT MENU
# -----------------------------------------------------------------------------
function Show-AIMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "🤖 AI Assistant & Intelligence" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. 💬 Chat with AI" -ForegroundColor Yellow
        Write-Host "2. 🔍 AI Search" -ForegroundColor Yellow
        Write-Host "3. 📝 Code Explanation" -ForegroundColor Yellow
        Write-Host "4. 🐛 Debug Assistant" -ForegroundColor Yellow
        Write-Host "5. 📚 Knowledge Base" -ForegroundColor Yellow
        Write-Host "6. 🎯 Command Suggestions" -ForegroundColor Yellow
        Write-Host "7. 🔧 AI Configuration" -ForegroundColor Yellow
        Write-Host "8. 📊 AI Analytics" -ForegroundColor Yellow
        Write-Host "0. Back to Main Menu" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select AI feature (0-8)"

        switch ($choice) {
            "1" { Start-AIChat; Read-Host "`nPress Enter to continue" }
            "2" { Start-AISearch; Read-Host "`nPress Enter to continue" }
            "3" { Start-CodeExplanation; Read-Host "`nPress Enter to continue" }
            "4" { Start-DebugAssistant; Read-Host "`nPress Enter to continue" }
            "5" { Show-KnowledgeBase; Read-Host "`nPress Enter to continue" }
            "6" { Show-CommandSuggestions; Read-Host "`nPress Enter to continue" }
            "7" { Show-AIConfig; Read-Host "`nPress Enter to continue" }
            "8" { Show-AIAnalytics; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Start-AIChat {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "💬 Ollama AI Chat Interface" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "🤖 Ollama AI Chat System" -ForegroundColor Cyan
    Write-Host "Model: $script:OllamaModel" -ForegroundColor Gray
    Write-Host ""

    if (!(Test-OllamaConnection)) {
        Write-Host "❌ Ollama not running!" -ForegroundColor Red
        Write-Host "💡 Start Ollama with: ollama serve" -ForegroundColor Yellow
        Write-Host "🔗 Install Ollama from: https://ollama.com" -ForegroundColor Blue
        return
    }

    Write-Host "✅ Ollama connected successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "💬 Interactive AI Chat:" -ForegroundColor Green
    Write-Host "• Type your questions or requests" -ForegroundColor White
    Write-Host "• Type 'exit' or 'quit' to return to menu" -ForegroundColor White
    Write-Host "• Type 'model' to change AI model" -ForegroundColor White
    Write-Host ""

    do {
        $query = Read-Host "🤖 AI> "

        if ($query -eq 'exit' -or $query -eq 'quit') {
            break
        }
        elseif ($query -eq 'model') {
            $newModel = Read-Host "Enter new model name (current: $script:OllamaModel)"
            if ($newModel) {
                Set-AIModel -model $newModel
            }
            continue
        }
        elseif ([string]::IsNullOrWhiteSpace($query)) {
            continue
        }

        Write-Host "🔄 Thinking..." -ForegroundColor Cyan
        $response = Invoke-OllamaChat -Prompt $query
        if ($response) {
            Write-Host "🤖 $response" -ForegroundColor White
        } else {
            Write-Host "❌ Failed to get AI response" -ForegroundColor Red
        }
        Write-Host ""
    } while ($true)

    Write-Host "👋 Goodbye!" -ForegroundColor Yellow
}

function Start-AISearch {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "🔍 Ollama AI-Powered Search" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "🔍 AI Search Features:" -ForegroundColor Cyan
    Write-Host "• Semantic search across documentation" -ForegroundColor White
    Write-Host "• Code pattern matching" -ForegroundColor White
    Write-Host "• Context-aware suggestions" -ForegroundColor White
    Write-Host ""
    Write-Host "Current search capabilities:" -ForegroundColor Green
    Write-Host "• File content search with grep" -ForegroundColor White
    Write-Host "• Command history search" -ForegroundColor White
    Write-Host "• Alias lookup with Show-AliasManager" -ForegroundColor White
    Write-Host "• AI-powered search with Ollama" -ForegroundColor White
    Write-Host ""

    $query = Read-Host "🔍 Enter search query"
    if ($query) {
        Write-Host "🔄 Searching with AI..." -ForegroundColor Cyan
        $response = Invoke-OllamaChat -Prompt "Search for PowerShell commands, documentation, or solutions related to: $query. Provide relevant examples and explanations."
        if ($response) {
            Write-Host "🔍 AI Search Results:" -ForegroundColor Green
            Write-Host $response -ForegroundColor White
        } else {
            Write-Host "❌ AI search failed" -ForegroundColor Red
        }
    }
}

function Start-CodeExplanation {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "📝 Ollama AI Code Explanation" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "📝 Code Analysis Features:" -ForegroundColor Cyan
    Write-Host "• Function documentation generation" -ForegroundColor White
    Write-Host "• Code complexity analysis" -ForegroundColor White
    Write-Host "• Best practices suggestions" -ForegroundColor White
    Write-Host ""
    Write-Host "Current capabilities:" -ForegroundColor Green
    Write-Host "• aiex 'command' - AI-powered explanations" -ForegroundColor White
    Write-Host "• Get-Help for PowerShell cmdlets" -ForegroundColor White
    Write-Host ""

    $code = Read-Host "📝 Enter code/command to explain"
    if ($code) {
        Write-Host "🔄 Analyzing code..." -ForegroundColor Cyan
        $aiResponse = Invoke-OllamaChat -Prompt "Explain this PowerShell code/command in detail: $code. What does it do? How does it work? Are there any best practices or improvements?"
        if ($aiResponse) {
            Write-Host "📝 AI Code Explanation:" -ForegroundColor Green
            Write-Host $aiResponse -ForegroundColor White
        } else {
            Write-Host "❌ AI explanation failed" -ForegroundColor Red
        }
    }
}

function Start-DebugAssistant {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🐛 Ollama AI Debug Assistant" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    Write-Host "🐛 AI Debugging Tools:" -ForegroundColor Cyan
    Write-Host "• Error pattern recognition" -ForegroundColor White
    Write-Host "• Stack trace analysis" -ForegroundColor White
    Write-Host "• Performance issue detection" -ForegroundColor White
    Write-Host "• Code debugging assistance" -ForegroundColor White
    Write-Host ""
    Write-Host "Current debugging commands:" -ForegroundColor Green
    Write-Host "• Get-Error for recent errors" -ForegroundColor White
    Write-Host "• Debug-Process for process issues" -ForegroundColor White
    Write-Host "• Test-NetConnection for network issues" -ForegroundColor White
    Write-Host ""

    $issue = Read-Host "🐛 Describe your error/issue"
    if ($issue) {
        Write-Host "🔄 Analyzing error..." -ForegroundColor Cyan
        $response = Invoke-OllamaChat -Prompt "Help debug this PowerShell issue: $issue. Provide step-by-step troubleshooting guidance and potential solutions."
        if ($response) {
            Write-Host "🐛 AI Debug Analysis:" -ForegroundColor Green
            Write-Host $response -ForegroundColor White
        } else {
            Write-Host "❌ AI debugging failed" -ForegroundColor Red
        }
    }
}

function Show-KnowledgeBase {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-HostCenter "📚 Ollama AI Knowledge Base" -ForegroundColor Yellow
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "📚 Knowledge Categories:" -ForegroundColor Cyan
    Write-Host "• PowerShell Commands & Syntax" -ForegroundColor White
    Write-Host "• Development Workflows" -ForegroundColor White
    Write-Host "• System Administration" -ForegroundColor White
    Write-Host "• Troubleshooting Guides" -ForegroundColor White
    Write-Host "• Best Practices" -ForegroundColor White
    Write-Host ""
    Write-Host "Current knowledge base:" -ForegroundColor Green
    Write-Host "• Built-in help: Get-Help" -ForegroundColor White
    Write-Host "• Command explanations: aiex" -ForegroundColor White
    Write-Host "• Profile help: Show-ProfileHelp" -ForegroundColor White
    Write-Host "• AI-powered knowledge: Ollama integration" -ForegroundColor White
    Write-Host ""

    $topic = Read-Host "📚 Enter topic to learn about"
    if ($topic) {
        Write-Host "🔄 Querying AI knowledge..." -ForegroundColor Cyan
        $response = Invoke-OllamaChat -Prompt "Provide comprehensive information about $topic in the context of PowerShell, development, or system administration. Include examples and best practices."
        if ($response) {
            Write-Host "📚 AI Knowledge:" -ForegroundColor Green
            Write-Host $response -ForegroundColor White
        } else {
            Write-Host "❌ AI knowledge query failed" -ForegroundColor Red
        }
    }
}

function Show-CommandSuggestions {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🎯 Ollama AI Command Suggestions" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "🎯 Smart Suggestions:" -ForegroundColor Cyan
    Write-Host "• Context-aware command recommendations" -ForegroundColor White
    Write-Host "• Workflow optimization" -ForegroundColor White
    Write-Host "• Alternative command suggestions" -ForegroundColor White
    Write-Host ""
    Write-Host "Current suggestion system:" -ForegroundColor Green
    Write-Host "• aihelp 'what you want to do'" -ForegroundColor White
    Write-Host "• Tab completion in PowerShell" -ForegroundColor White
    Write-Host "• Get-Command for discovery" -ForegroundColor White
    Write-Host "• AI-powered suggestions" -ForegroundColor White
    Write-Host ""

    $task = Read-Host "🎯 Describe what you want to accomplish"
    if ($task) {
        Write-Host "🔄 Getting AI suggestions..." -ForegroundColor Cyan
        $response = Invoke-OllamaChat -Prompt "Suggest PowerShell commands or workflows for: $task. Provide multiple approaches with explanations of when to use each."
        if ($response) {
            Write-Host "🎯 AI Command Suggestions:" -ForegroundColor Green
            Write-Host $response -ForegroundColor White
        } else {
            Write-Host "❌ AI suggestions failed" -ForegroundColor Red
        }
    }
}

function Show-AIConfig {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "🔧 Ollama AI Configuration" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "🔧 Ollama AI Settings:" -ForegroundColor Cyan
    Write-Host "• Model Selection" -ForegroundColor White
    Write-Host "• Connection Status" -ForegroundColor White
    Write-Host "• Response Configuration" -ForegroundColor White
    Write-Host ""
    Write-Host "Current Configuration:" -ForegroundColor Green
    Write-Host "• Model: $script:OllamaModel" -ForegroundColor White
    Write-Host "• Base URL: $script:OllamaBaseUrl" -ForegroundColor White
    Write-Host "• Connection: $(if (Test-OllamaConnection) { '✅ Connected' } else { '❌ Disconnected' })" -ForegroundColor $(if (Test-OllamaConnection) { 'Green' } else { 'Red' })
    Write-Host ""

    Write-Host "Available Actions:" -ForegroundColor Yellow
    Write-Host "• Set-AIModel 'model-name' - Change AI model" -ForegroundColor White
    Write-Host "• Get-AIModel - Show current model" -ForegroundColor White
    Write-Host "• Test-OllamaConnection - Check connection" -ForegroundColor White
}

function Show-AIAnalytics {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "📊 Ollama AI Usage Analytics" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "📊 AI Analytics Dashboard:" -ForegroundColor Cyan
    Write-Host "• Query frequency" -ForegroundColor White
    Write-Host "• Success rates" -ForegroundColor White
    Write-Host "• Popular topics" -ForegroundColor White
    Write-Host "• Response times" -ForegroundColor White
    Write-Host ""
    Write-Host "Current tracking:" -ForegroundColor Green
    Write-Host "• Command usage statistics" -ForegroundColor White
    Write-Host "• Error patterns" -ForegroundColor White
    Write-Host "• Performance metrics" -ForegroundColor White
    Write-Host "• Ollama model usage" -ForegroundColor White
    Write-Host ""

    Write-Host "💡 To implement analytics, use:" -ForegroundColor Yellow
    Write-Host "• Track AI usage in your scripts" -ForegroundColor White
    Write-Host "• Log responses for analysis" -ForegroundColor White
    Write-Host "• Monitor model performance" -ForegroundColor White
}

# -----------------------------------------------------------------------------
# 🔧 SYSTEM MANAGEMENT MENU
# -----------------------------------------------------------------------------
function Show-SystemMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "🛠️ System Management Tools" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. 💾 Disk Management" -ForegroundColor Yellow
        Write-Host "2. 🔧 Process Management" -ForegroundColor Yellow
        Write-Host "3. 🌐 Network Tools" -ForegroundColor Yellow
        Write-Host "4. 🔐 Security Tools" -ForegroundColor Yellow
        Write-Host "5. 📦 Windows Updates" -ForegroundColor Yellow
        Write-Host "6. 🔧 Services" -ForegroundColor Yellow
        Write-Host "7. 📊 Performance Monitor" -ForegroundColor Yellow
        Write-Host "8. 🔍 System Diagnostics" -ForegroundColor Yellow
        Write-Host "0. Back to Main Menu" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select system tool (0-8)"

        switch ($choice) {
            "1" { Show-DiskMenu; Read-Host "`nPress Enter to continue" }
            "2" { Show-ProcessMenu; Read-Host "`nPress Enter to continue" }
            "3" { Show-NetworkMenu; Read-Host "`nPress Enter to continue" }
            "4" { Show-SecurityMenu; Read-Host "`nPress Enter to continue" }
            "5" { Show-UpdateMenu; Read-Host "`nPress Enter to continue" }
            "6" { Show-ServiceMenu; Read-Host "`nPress Enter to continue" }
            "7" { Show-PerformanceMenu; Read-Host "`nPress Enter to continue" }
            "8" { Show-SystemDiagnostics; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Show-DiskMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "💾 Disk Management" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "💾 Disk Commands:" -ForegroundColor Green
    Write-Host "• Get-Volume              - Show disk volumes" -ForegroundColor White
    Write-Host "• Get-Disk                - Show physical disks" -ForegroundColor White
    Write-Host "• Get-Partition           - Show disk partitions" -ForegroundColor White
    Write-Host "• Optimize-Volume         - Optimize drives" -ForegroundColor White
    Write-Host "• Clear-RecycleBin        - Empty recycle bin" -ForegroundColor White
    Write-Host ""
}

function Show-ProcessMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🔧 Process Management" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    Write-Host "🔧 Process Commands:" -ForegroundColor Green
    Write-Host "• Get-Process             - List all processes" -ForegroundColor White
    Write-Host "• Stop-Process -Name <name> - Stop process" -ForegroundColor White
    Write-Host "• Start-Process <command> - Start new process" -ForegroundColor White
    Write-Host "• processes               - Show top processes" -ForegroundColor White
    Write-Host ""
}

function Show-NetworkMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "🌐 Network Tools" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "🌐 Network Commands:" -ForegroundColor Green
    Write-Host "• ip                      - Show IP addresses" -ForegroundColor White
    Write-Host "• ports                   - Show listening ports" -ForegroundColor White
    Write-Host "• Test-NetConnection      - Test connectivity" -ForegroundColor White
    Write-Host "• Get-NetAdapter          - Show network adapters" -ForegroundColor White
    Write-Host "• Resolve-DnsName         - DNS lookup" -ForegroundColor White
    Write-Host ""
}

function Show-SecurityMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🔐 Security Tools" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    Write-Host "🔐 Security Commands:" -ForegroundColor Green
    Write-Host "• Get-LocalUser           - List local users" -ForegroundColor White
    Write-Host "• Get-LocalGroup          - List local groups" -ForegroundColor White
    Write-Host "• Get-EventLog Security   - Security events" -ForegroundColor White
    Write-Host "• Get-MpComputerStatus    - Windows Defender status" -ForegroundColor White
    Write-Host ""
}

function Show-UpdateMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "📦 Windows Updates" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "📦 Update Commands:" -ForegroundColor Green
    Write-Host "• Get-WindowsUpdate       - Check for updates" -ForegroundColor White
    Write-Host "• Install-WindowsUpdate   - Install updates" -ForegroundColor White
    Write-Host "• Get-HotFix              - Show installed updates" -ForegroundColor White
    Write-Host "• wuauclt /detectnow      - Force update check" -ForegroundColor White
    Write-Host ""
}

function Show-ServiceMenu {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-HostCenter "🔧 Windows Services" -ForegroundColor Yellow
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "🔧 Service Commands:" -ForegroundColor Green
    Write-Host "• Get-Service             - List all services" -ForegroundColor White
    Write-Host "• Start-Service <name>    - Start service" -ForegroundColor White
    Write-Host "• Stop-Service <name>     - Stop service" -ForegroundColor White
    Write-Host "• Restart-Service <name>  - Restart service" -ForegroundColor White
    Write-Host "• Set-Service <name>      - Configure service" -ForegroundColor White
    Write-Host ""
}

function Show-SystemDiagnostics {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🔍 System Diagnostics" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "🔍 Diagnostic Commands:" -ForegroundColor Green
    Write-Host "• Get-EventLog            - System event logs" -ForegroundColor White
    Write-Host "• Get-WmiObject Win32_*   - WMI diagnostics" -ForegroundColor White
    Write-Host "• sfc /scannow            - System file check" -ForegroundColor White
    Write-Host "• chkdsk C:               - Check disk" -ForegroundColor White
    Write-Host "• dism /online /cleanup-image - Repair system image" -ForegroundColor White
    Write-Host ""
}

# -----------------------------------------------------------------------------
# 📊 PERFORMANCE MONITORING MENU
# -----------------------------------------------------------------------------
function Show-PerformanceMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "📊 Performance Monitoring" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. 📈 Real-time Performance" -ForegroundColor Yellow
        Write-Host "2. 🧠 Memory Analysis" -ForegroundColor Yellow
        Write-Host "3. 💽 Disk Performance" -ForegroundColor Yellow
        Write-Host "4. 🌐 Network Performance" -ForegroundColor Yellow
        Write-Host "5. 🔧 Process Performance" -ForegroundColor Yellow
        Write-Host "6. 📊 Performance Reports" -ForegroundColor Yellow
        Write-Host "7. ⚡ Optimization Tips" -ForegroundColor Yellow
        Write-Host "8. 📋 Performance Logs" -ForegroundColor Yellow
        Write-Host "0. Back to Main Menu" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select performance tool (0-8)"

        switch ($choice) {
            "1" { Show-RealTimePerf; Read-Host "`nPress Enter to continue" }
            "2" { Show-MemoryAnalysis; Read-Host "`nPress Enter to continue" }
            "3" { Show-DiskPerformance; Read-Host "`nPress Enter to continue" }
            "4" { Show-NetworkPerformance; Read-Host "`nPress Enter to continue" }
            "5" { Show-ProcessPerformance; Read-Host "`nPress Enter to continue" }
            "6" { Show-PerformanceReports; Read-Host "`nPress Enter to continue" }
            "7" { Show-OptimizationTips; Read-Host "`nPress Enter to continue" }
            "8" { Show-PerformanceLogs; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Show-RealTimePerf {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "📈 Real-time Performance Monitor" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "📊 Performance Counters:" -ForegroundColor Cyan
    Write-Host "• Get-Counter '\Processor(_Total)\% Processor Time'" -ForegroundColor White
    Write-Host "• Get-Counter '\Memory\Available MBytes'" -ForegroundColor White
    Write-Host "• Get-Counter '\PhysicalDisk(_Total)\Avg. Disk Queue Length'" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Use Performance Monitor (perfmon) for GUI monitoring" -ForegroundColor Yellow
}

function Show-MemoryAnalysis {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "🧠 Memory Analysis" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "🧠 Memory Commands:" -ForegroundColor Green
    Write-Host "• Get-Process | Sort-Object -Property WorkingSet -Descending" -ForegroundColor White
    Write-Host "• Get-WmiObject Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory" -ForegroundColor White
    Write-Host "• [System.GC]::GetTotalMemory($true)" -ForegroundColor White
    Write-Host ""
}

function Show-DiskPerformance {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-HostCenter "💽 Disk Performance" -ForegroundColor Yellow
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "💽 Disk Commands:" -ForegroundColor Green
    Write-Host "• Get-PhysicalDisk | Get-StorageReliabilityCounter" -ForegroundColor White
    Write-Host "• Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Read'" -ForegroundColor White
    Write-Host "• Optimize-Volume -DriveLetter C" -ForegroundColor White
    Write-Host ""
}

function Show-NetworkPerformance {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "🌐 Network Performance" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "🌐 Network Commands:" -ForegroundColor Green
    Write-Host "• Test-NetConnection -ComputerName google.com -TraceRoute" -ForegroundColor White
    Write-Host "• Get-NetAdapter | Select-Object Name,Status,Speed,Duplex" -ForegroundColor White
    Write-Host "• Get-Counter '\Network Interface(*)\Bytes Total/sec'" -ForegroundColor White
    Write-Host ""
}

function Show-ProcessPerformance {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🔧 Process Performance" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    Write-Host "🔧 Process Commands:" -ForegroundColor Green
    Write-Host "• Get-Process | Sort-Object CPU -Descending | Select-Object -First 10" -ForegroundColor White
    Write-Host "• Get-Process 'name' | Select-Object CPU,WorkingSet,PeakWorkingSet" -ForegroundColor White
    Write-Host "• Start-Process powershell -ArgumentList '-NoExit -Command Get-Process'" -ForegroundColor White
    Write-Host ""
}

function Show-PerformanceReports {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "📊 Performance Reports" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "📊 Report Commands:" -ForegroundColor Green
    Write-Host "• Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 5 -MaxSamples 10" -ForegroundColor White
    Write-Host "• Export-Counter -Path perf.log -FileFormat CSV" -ForegroundColor White
    Write-Host "• Import-Counter perf.log | Export-Csv perf_report.csv" -ForegroundColor White
    Write-Host ""
}

function Show-OptimizationTips {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
    Write-HostCenter "⚡ Performance Optimization Tips" -ForegroundColor Cyan
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "⚡ Optimization Tips:" -ForegroundColor Green
    Write-Host "• Close unnecessary applications" -ForegroundColor White
    Write-Host "• Disable startup programs" -ForegroundColor White
    Write-Host "• Update Windows and drivers" -ForegroundColor White
    Write-Host "• Run disk cleanup regularly" -ForegroundColor White
    Write-Host "• Use SSD for system drive" -ForegroundColor White
    Write-Host "• Monitor resource usage with Task Manager" -ForegroundColor White
    Write-Host ""
}

function Show-PerformanceLogs {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "📋 Performance Logs" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "📋 Log Commands:" -ForegroundColor Green
    Write-Host "• Get-EventLog -LogName Application -Newest 50" -ForegroundColor White
    Write-Host "• Get-WinEvent -LogName Microsoft-Windows-Diagnostics-Performance/Operational" -ForegroundColor White
    Write-Host "• Export-Csv -Path perf_log.csv -NoTypeInformation" -ForegroundColor White
    Write-Host ""
}

# -----------------------------------------------------------------------------
# ⚙️ SETTINGS & PROFILE MENU
# -----------------------------------------------------------------------------
function Show-SettingsMenu {
    do {
        Clear-Host
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-HostCenter "⚙️ Settings & Profile Management" -ForegroundColor Cyan
        Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1. 🎨 Theme Settings" -ForegroundColor Yellow
        Write-Host "2. 💻 Prompt Configuration" -ForegroundColor Yellow
        Write-Host "3. 🔗 Alias Management" -ForegroundColor Yellow
        Write-Host "4. 🔧 Environment Variables" -ForegroundColor Yellow
        Write-Host "5. 📦 Module Management" -ForegroundColor Yellow
        Write-Host "6. 🔒 Security Settings" -ForegroundColor Yellow
        Write-Host "7. 📁 Profile Backup" -ForegroundColor Yellow
        Write-Host "8. 🔍 Profile Diagnostics" -ForegroundColor Yellow
        Write-Host "0. Back to Main Menu" -ForegroundColor Red
        Write-Host ""

        $choice = Read-Host "Select settings option (0-8)"

        switch ($choice) {
            "1" { Show-ThemeSettings; Read-Host "`nPress Enter to continue" }
            "2" { Show-PromptSettings; Read-Host "`nPress Enter to continue" }
            "3" { Show-AliasSettings; Read-Host "`nPress Enter to continue" }
            "4" { Show-EnvironmentSettings; Read-Host "`nPress Enter to continue" }
            "5" { Show-ModuleSettings; Read-Host "`nPress Enter to continue" }
            "6" { Show-SecuritySettings; Read-Host "`nPress Enter to continue" }
            "7" { Show-ProfileBackup; Read-Host "`nPress Enter to continue" }
            "8" { Show-ProfileDiagnostics; Read-Host "`nPress Enter to continue" }
            "0" { return }
            default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "0")
}

function Show-ThemeSettings {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🎨 Theme Management Settings" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "🎨 Theme Commands:" -ForegroundColor Green
    Write-Host "• themes                - Show available themes" -ForegroundColor White
    Write-Host "• Set-Theme -Category random - Set random theme" -ForegroundColor White
    Write-Host "• theme-showcase        - Preview themes" -ForegroundColor White
    Write-Host "• Test-ThemeSetup       - Diagnose theme issues" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 Current theme preference file: $script:ThemePreferenceFile" -ForegroundColor Cyan
}

function Show-PromptSettings {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "💻 Prompt Configuration" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "💻 Prompt Commands:" -ForegroundColor Green
    Write-Host "• Set-PromptStyle default  - Default prompt" -ForegroundColor White
    Write-Host "• Set-PromptStyle minimal  - Minimal prompt" -ForegroundColor White
    Write-Host "• Set-PromptStyle git      - Git-focused prompt" -ForegroundColor White
    Write-Host ""
}

function Show-AliasSettings {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "🔗 Alias Management" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "🔗 Alias Commands:" -ForegroundColor Green
    Write-Host "• Show-AliasManager      - Browse all aliases" -ForegroundColor White
    Write-Host "• Get-Alias              - List PowerShell aliases" -ForegroundColor White
    Write-Host "• New-Alias 'name' 'command' - Create alias" -ForegroundColor White
    Write-Host "• Remove-Alias 'name'    - Remove alias" -ForegroundColor White
    Write-Host ""
}

function Show-EnvironmentSettings {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-HostCenter "🔧 Environment Variables" -ForegroundColor Yellow
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "🔧 Environment Commands:" -ForegroundColor Green
    Write-Host "• Get-ChildItem Env:     - List all environment variables" -ForegroundColor White
    Write-Host "• $env:VARIABLE_NAME    - Access specific variable" -ForegroundColor White
    Write-Host "• [Environment]::SetEnvironmentVariable('name', 'value') - Set variable" -ForegroundColor White
    Write-Host ""
}

function Show-ModuleSettings {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-HostCenter "📦 PowerShell Module Management" -ForegroundColor Blue
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    Write-Host "📦 Module Commands:" -ForegroundColor Green
    Write-Host "• Get-Module             - List loaded modules" -ForegroundColor White
    Write-Host "• Install-Module 'name'  - Install from PSGallery" -ForegroundColor White
    Write-Host "• Update-Module 'name'   - Update module" -ForegroundColor White
    Write-Host "• Uninstall-Module 'name' - Remove module" -ForegroundColor White
    Write-Host ""
}

function Show-SecuritySettings {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-HostCenter "🔒 Security Settings" -ForegroundColor Red
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Red
    Write-Host ""

    Write-Host "🔒 Security Commands:" -ForegroundColor Green
    Write-Host "• Get-ExecutionPolicy    - Check current policy" -ForegroundColor White
    Write-Host "• Set-ExecutionPolicy RemoteSigned - Set policy" -ForegroundColor White
    Write-Host "• Get-LocalUser          - List local users" -ForegroundColor White
    Write-Host "• Enable-PSRemoting      - Enable remote PowerShell" -ForegroundColor White
    Write-Host ""
}

function Show-ProfileBackup {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-HostCenter "📁 Profile Backup & Restore" -ForegroundColor Green
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "💾 Backup Commands:" -ForegroundColor Green
    Write-Host "• Copy-Item $PROFILE -Destination backup_profile.ps1" -ForegroundColor White
    Write-Host "• Copy-Item $PROFILE -Destination $env:USERPROFILE\Documents\" -ForegroundColor White
    Write-Host "• git add $PROFILE; git commit -m 'Profile update'" -ForegroundColor White
    Write-Host ""
    Write-Host "🔄 Restore Commands:" -ForegroundColor Yellow
    Write-Host "• Copy-Item backup_profile.ps1 -Destination $PROFILE -Force" -ForegroundColor White
    Write-Host ""
}

function Show-ProfileDiagnostics {
    Clear-Host
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-HostCenter "🔍 Profile Diagnostics" -ForegroundColor Magenta
    Write-HostFullWidth "══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "🔍 Diagnostic Information:" -ForegroundColor Cyan
    Write-Host "• Profile path: $PROFILE" -ForegroundColor White
    Write-Host "• PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "• Profile size: $((Get-Item $PROFILE).Length) bytes" -ForegroundColor White
    Write-Host "• Last modified: $(Get-Date)" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ Profile loaded successfully" -ForegroundColor Green
    Write-Host "✅ Functions loaded successfully!" -ForegroundColor Green
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

# -----------------------------------------------------------------------------
# 🎉 FINAL SETUP COMPLETE
# -----------------------------------------------------------------------------
Write-Host "🎉 PowerShell Profile v2.0 loaded successfully!" -ForegroundColor Green
Write-Host "💡 Type 'devmenu' to explore all features or 'pshelp' for quick help" -ForegroundColor Cyan
