# 1. Environment Variables
$env:EDITOR = "nvim"
$env:FZF_DEFAULT_OPTS = @"
--layout=reverse --cycle --scroll-off=5 --border --preview-window=right,60%,border-left
--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
--bind alt-f:preview-page-down,alt-b:preview-page-up
--bind ctrl-g:preview-top,ctrl-h:preview-bottom
--bind alt-w:toggle-preview-wrap,ctrl-e:toggle-preview
--color='header:italic:cyan' --header='History Search (Enter to Select, Ctrl+C to Cancel)'
"@

# 2. Modules & Shell Integration (แก้ไขให้ถูกต้องตาม Usage)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # ใช้การ Cache ตัว init script ไว้ในตัวแปร เพื่อไม่ต้องให้ oh-my-posh คำนวณใหม่ทุกครั้งที่เปิด Terminal
    if (-not $global:OhMyPoshInit) {
        $global:OhMyPoshInit = oh-my-posh init pwsh --config "C:\Program Files (x86)\oh-my-posh\themes\clean-detailed.omp.json" --print | Out-String
    }
    Invoke-Expression $global:OhMyPoshInit
}

# โหลด Module สำคัญ (ลดการใช้ try-catch พร่ำเพรื่อ)
Import-Module Microsoft.WinGet.CommandNotFound -ErrorAction SilentlyContinue
Import-Module PSCompletions -ArgumentList 'no-banner' -ErrorAction SilentlyContinue

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    # ตั้งค่า PSFzf ครั้งเดียวให้ครบ (ระบุชื่อเต็มสำหรับ 7.6.0)
    Set-PsFzfOption -EnableTabExpansion -EnableHistoryBackup -EnableLocationBackup `
                    -EnableAliasFuzzyEdit -EnableAliasFuzzyKillProcess -EnableAliasFuzzyScoop `
                    -TabCompletionPreviewWindow 'right|down|hidden'
    
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
}

# 3. Functions (Refactored)
function _fzf_open_path {
    param (
        [Parameter(Mandatory=$true)]
        [string]$input_path
    )

    # 1. Clean Path: รองรับรูปแบบ filename:line:col จาก ripgrep
    if ($input_path -match "^([^:]+):\d+:.*$") {
        $input_path = $Matches[1]
    }

    # ตรวจสอบว่ามีไฟล์อยู่จริงไหม (เผื่อ fzf คืนค่าว่าง)
    if (-not (Test-Path $input_path)) { return }

    $cmds = @{
        'bat'    = { bat --color=always --style=plain $input_path }
        'cat'    = { Get-Content $input_path }
        'nvim'   = { nvim $input_path }
        'remove' = { Remove-Item -Recurse -Force -Confirm $input_path }
        'echo'   = { Write-Output $input_path }
        'cd'     = {
            # หา Directory ปลายทาง
            $target = if (Test-Path $input_path -PathType Leaf) { 
                Split-Path $input_path -Parent 
            } else { 
                $input_path 
            }
            Set-Location $target
        }
    }

    $selected_key = $cmds.Keys | fzf --prompt 'Action> ' --height 40% --layout=reverse
    
    if ($selected_key) {
        # สำคัญมาก: ใช้ . (Dot Sourcing) แทน & 
        # เพื่อให้คำสั่ง (โดยเฉพาะ cd) มีผลกับ Session ปัจจุบัน
        . $cmds[$selected_key]
    }
}

function _fzf_get_path_using_fd {
    if (-not (Get-Command fd -ErrorAction SilentlyContinue)) {
        Write-Host "Error: fd is not installed." -ForegroundColor Red
        return $null
    }

    $fd_file = "fd --type f --follow --hidden --exclude .git --absolute-path"
    $fd_dir  = "fd --type d --follow --hidden --exclude .git --absolute-path"

    $input_path = Invoke-Expression $fd_file | fzf --prompt 'Files> ' `
        --header 'CTRL-D: Dirs | CTRL-F: Files' `
        --bind "ctrl-d:reload($fd_dir)+change-prompt(Dirs> )" `
        --bind "ctrl-f:reload($fd_file)+change-prompt(Files> )" `
        --preview 'powershell -NoProfile -Command "
            if (Test-Path -LiteralPath \"{}\" -PathType Container) {
                if (Get-Command eza -EA 0) { eza -T --level=2 --color=always --icons=always \"{}\" } else { ls \"{}\" }
            } else {
                if (Get-Command bat -EA 0) { bat --color=always --style=plain \"{}\" } else { cat \"{}\" }
            }"'

    return $input_path
}

function _fzf_get_path_using_rg {
    if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
        Write-Host "Error: rg is not installed." -ForegroundColor Red
        return $null
    }

    # ใช้ $args แทน ${*:-} เพื่อรับค่าจาก function rgg
    $query = if ($args) { $args -join ' ' } else { "" }
    
    $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"

    $input_path = fzf --ansi --disabled --query "$query" `
        --bind "start:reload:$RG_PREFIX {q} || true" `
        --bind "change:reload:$RG_PREFIX {q} || true" `
        --delimiter ':' `
        --prompt 'ripgrep> ' `
        --preview 'bat --color=always {1} --highlight-line {2} --style=plain' `
        --preview-window 'up,60%,border-bottom,+{2}+3/3'

    return $input_path
}

# --- Main Functions ---

function fdg {
    $path = _fzf_get_path_using_fd
    if ($path) { _fzf_open_path $path }
}

function rgg {
    # ส่งต่อ arguments ทั้งหมดไปยัง helper
    $path = _fzf_get_path_using_rg @args
    if ($path) { _fzf_open_path $path }
}

function compress-project {
    [CmdletBinding()]
    param([Alias("l")][switch]$Local)
    $script = 'D:\script\python\compress_project\compress_project.py'
    $args_list = @($script)
    if ($Local) { $args_list += @('--chdir', (Get-Location).ProviderPath) }
    python @args_list $args
}

# 4. Aliases & Key Handlers
#Set-Alias cpj compress-project #python script for compact project code

# ใช้ฟังก์ชันของ PSFzf และ Custom Function ผสมกัน
Set-PSReadLineKeyHandler -Key "Ctrl+r" -ScriptBlock { Invoke-FuzzyHistory }
Set-PSReadLineKeyHandler -Key "Tab"    -ScriptBlock { Invoke-FzfTabCompletion }
Set-PSReadLineKeyHandler -Key "Ctrl+f" -ScriptBlock { [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert("fdg"); [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine() }
Set-PSReadLineKeyHandler -Key "Ctrl+g" -ScriptBlock { [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine(); [Microsoft.PowerShell.PSConsoleReadLine]::Insert("rgg"); [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine() }

# 5. UI & Style
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{
    Selection = "`e[48;5;238;38;5;255m"
    Member    = "`e[38;5;255m"
    Comment   = "`e[38;5;244m"
}

# 6. Maintenance (Manual call only)
function update-shell-tools {
    Write-Host "Checking for updates..." -ForegroundColor Cyan
    Update-Module PSCompletions, PSFzf -Force
    psc update *
    oh-my-posh upgrade
}
