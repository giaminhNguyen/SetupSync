# ============================================================
#  AI Config Backup  -  SetupSync / WindowTool
#  Sao lưu cấu hình Claude & Codex thành file .zip ra Desktop.
#  Giữ nguyên cấu trúc thư mục bên trong zip:
#     .claude.json
#     .claude\.credentials.json
#     .codex\auth.json
# ============================================================

param(
    [ValidateSet('claude', 'codex')]
    [string]$Mode,
    [string]$SaveDir
)

# --- UTF-8 để tiếng Việt + box-drawing hiển thị đúng ---
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
try { $OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
#  Cấu hình nguồn (sửa ở đây nếu đường dẫn thay đổi)
# ------------------------------------------------------------
$Sources = @{
    claude = @('.claude.json', '.claude\.credentials.json')
    codex  = @('.codex\auth.json')
}
# Danh sách hiển thị trạng thái (theo thứ tự)
$AllFiles = @('.claude.json', '.claude\.credentials.json', '.codex\auth.json')

$BoxW  = 60   # chiều rộng bên trong khung
$Indent = '  '

# Nơi lưu file zip: mặc định Desktop, có thể đổi trong menu ([3]) hoặc qua -SaveDir
if ($SaveDir -and (Test-Path -LiteralPath $SaveDir -PathType Container)) {
    $script:SaveDir = (Resolve-Path -LiteralPath $SaveDir).Path
} else {
    $script:SaveDir = [Environment]::GetFolderPath('Desktop')
}

function Get-Rels([string]$Mode) {
    switch ($Mode) {
        'claude' { return $Sources.claude }
        'codex'  { return $Sources.codex }
    }
}

# ------------------------------------------------------------
#  Vẽ khung / dòng có màu
# ------------------------------------------------------------
function Write-BoxTop    { Write-Host ($Indent + '╔' + ('═' * $BoxW) + '╗') -ForegroundColor Cyan }
function Write-BoxBottom { Write-Host ($Indent + '╚' + ('═' * $BoxW) + '╝') -ForegroundColor Cyan }

function Write-BoxLine([string]$Text) {
    $t = $Text
    if ($t.Length -gt $BoxW) { $t = $t.Substring(0, $BoxW) }
    $pad   = $BoxW - $t.Length
    $left  = [math]::Floor($pad / 2)
    $right = $pad - $left
    Write-Host ($Indent + '║') -ForegroundColor Cyan -NoNewline
    Write-Host ((' ' * $left) + $t + (' ' * $right)) -ForegroundColor White -NoNewline
    Write-Host '║' -ForegroundColor Cyan
}

function Write-Sep {
    Write-Host ($Indent + ' ' + ('─' * $BoxW)) -ForegroundColor DarkCyan
}

function Write-Section([string]$Title) {
    Write-Host ''
    Write-Host ($Indent + ' ' + $Title) -ForegroundColor Cyan
    Write-Sep
}

# ------------------------------------------------------------
#  Màn hình menu chính
# ------------------------------------------------------------
function Show-Menu {
    Clear-Host

    Write-Host ''
    Write-BoxTop
    Write-BoxLine ''
    Write-BoxLine 'AI  CONFIG  BACKUP'
    Write-BoxLine 'Sao lưu cấu hình Claude & Codex thành file .zip'
    Write-BoxLine ''
    Write-BoxBottom

    # --- Trạng thái file nguồn ---
    Write-Section 'TRẠNG THÁI FILE NGUỒN'
    foreach ($rel in $AllFiles) {
        $full = Join-Path $env:USERPROFILE $rel
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            Write-Host ($Indent + '  [') -ForegroundColor DarkGray -NoNewline
            Write-Host '✔' -ForegroundColor Green -NoNewline
            Write-Host '] ' -ForegroundColor DarkGray -NoNewline
            Write-Host $rel -ForegroundColor White
        } else {
            Write-Host ($Indent + '  [') -ForegroundColor DarkGray -NoNewline
            Write-Host '✘' -ForegroundColor Red -NoNewline
            Write-Host '] ' -ForegroundColor DarkGray -NoNewline
            Write-Host $rel -ForegroundColor Gray -NoNewline
            Write-Host '  — không tìm thấy' -ForegroundColor Red
        }
    }

    # --- Chức năng ---
    Write-Section 'CHỨC NĂNG'
    Write-MenuItem '1' 'Backup Claude' 'ClaudeBackup_<time>.zip'
    Write-MenuItem '2' 'Backup Codex' 'CodexBackup_<time>.zip'
    Write-Host ($Indent + '   [') -ForegroundColor DarkGray -NoNewline
    Write-Host '3' -ForegroundColor Yellow -NoNewline
    Write-Host ']  Đổi nơi lưu' -ForegroundColor White
    Write-Host ($Indent + '   [') -ForegroundColor DarkGray -NoNewline
    Write-Host '0' -ForegroundColor Yellow -NoNewline
    Write-Host ']  Thoát' -ForegroundColor White
    Write-Sep
    Write-Host ($Indent + '  Lưu tại: ') -ForegroundColor DarkGray -NoNewline
    Write-Host $script:SaveDir -ForegroundColor White
    Write-Host ''
}

function Write-MenuItem([string]$Key, [string]$Label, [string]$Target) {
    Write-Host ($Indent + '   [') -ForegroundColor DarkGray -NoNewline
    Write-Host $Key -ForegroundColor Yellow -NoNewline
    Write-Host ']  ' -ForegroundColor DarkGray -NoNewline
    $lbl = $Label.PadRight(18)
    Write-Host $lbl -ForegroundColor White -NoNewline
    Write-Host '→  ' -ForegroundColor DarkGray -NoNewline
    Write-Host $Target -ForegroundColor DarkGray
}

# ------------------------------------------------------------
#  Dọn sạch .claude.json: chỉ giữ các trường theo mẫu (.claude1.json).
#  Dữ liệu (giá trị) của từng tài khoản được giữ nguyên; chỉ lọc theo tên trường.
# ------------------------------------------------------------
# 'projects' được lược bỏ hoàn toàn khỏi bản backup (không giữ danh sách project)
$ClaudeTopKeys = @(
    'userID', 'oauthAccount', 'hasCompletedOnboarding', 'lastOnboardingVersion',
    'installMethod', 'autoUpdates', 'firstStartTime', 'numStartups'
)
$ClaudeOAuthKeys = @(
    'accountUuid', 'emailAddress', 'organizationUuid', 'hasExtraUsageEnabled',
    'billingType', 'accountCreatedAt', 'subscriptionCreatedAt', 'ccOnboardingFlags',
    'claudeCodeTrialEndsAt', 'claudeCodeTrialDurationDays', 'seatTier', 'displayName',
    'organizationRole', 'workspaceRole', 'organizationName', 'organizationType',
    'organizationRateLimitTier', 'userRateLimitTier'
)

# OrderedDictionary phân biệt hoa/thường (ConvertFrom-Json/[ordered]@{} không phân biệt
# hoa-thường nên dễ lỗi "duplicate key" với các path như D:/ và d:/ — dùng JavaScriptSerializer)
function New-OrderedDict {
    New-Object System.Collections.Specialized.OrderedDictionary ([System.StringComparer]::Ordinal)
}

# Giữ lại từ $src chỉ các key trong $Keys (theo thứ tự danh sách), value giữ nguyên
function Copy-Whitelisted($src, [string[]]$Keys) {
    $out = New-OrderedDict
    $d = $src -as [System.Collections.IDictionary]
    if ($d) {
        foreach ($k in $Keys) {
            # cast inline: Dictionary<string,object> implements IDictionary.Contains explicitly
            if (([System.Collections.IDictionary]$d).Contains($k)) { $out[$k] = $d[$k] }
        }
    }
    return $out
}

function Get-CleanClaudeJson([string]$Path) {
    Add-Type -AssemblyName System.Web.Extensions
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $jss = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $jss.MaxJsonLength = [int]::MaxValue
    $data = [System.Collections.IDictionary]$jss.DeserializeObject($raw)

    $clean = New-OrderedDict
    foreach ($k in $ClaudeTopKeys) {
        if (-not ([System.Collections.IDictionary]$data).Contains($k)) { continue }
        if ($k -eq 'oauthAccount') {
            $clean[$k] = Copy-Whitelisted $data[$k] $ClaudeOAuthKeys
        }
        else {
            $clean[$k] = $data[$k]
        }
    }
    return ($clean | ConvertTo-Json -Depth 100)
}

# ------------------------------------------------------------
#  Engine: validate -> staging (giữ cấu trúc) -> zip
# ------------------------------------------------------------
function Invoke-Backup([string]$Mode) {
    $userHome = $env:USERPROFILE
    $ts       = Get-Date -Format 'yyyyMMdd_HHmmss'
    $rels     = Get-Rels $Mode

    switch ($Mode) {
        'claude' { $zipName = "ClaudeBackup_$ts.zip" }
        'codex'  { $zipName = "CodexBackup_$ts.zip" }
    }

    $present = @()
    $missing = @()
    foreach ($r in $rels) {
        if (Test-Path -LiteralPath (Join-Path $userHome $r) -PathType Leaf) { $present += $r }
        else { $missing += $r }
    }

    $result = [ordered]@{
        Mode = $Mode; Zip = $null; Included = $present; Missing = $missing
        Ok = $false; Error = $null; Warn = $null; Cleaned = $false
    }

    if ($present.Count -eq 0) {
        $result.Error = 'Không tìm thấy file nguồn nào để backup.'
        return $result
    }

    $stage = Join-Path $env:TEMP ('aicfg_' + [guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $stage -Force | Out-Null
        foreach ($r in $present) {
            $src    = Join-Path $userHome $r
            $dst    = Join-Path $stage $r
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path -LiteralPath $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            if ($r -eq '.claude.json') {
                # Dọn sạch: chỉ giữ các trường theo mẫu, giữ nguyên giá trị của tài khoản
                try {
                    $json = Get-CleanClaudeJson $src
                    [System.IO.File]::WriteAllText($dst, $json, (New-Object System.Text.UTF8Encoding($false)))
                    $result.Cleaned = $true
                }
                catch {
                    Copy-Item -LiteralPath $src -Destination $dst -Force
                    $result.Warn = '.claude.json không đọc được dạng JSON — đã sao lưu nguyên bản (chưa dọn).'
                }
            }
            else {
                Copy-Item -LiteralPath $src -Destination $dst -Force
            }
        }

        # Nén các entry gốc trong staging (file + folder .claude/.codex -> giữ cấu trúc)
        $entries = Get-ChildItem -LiteralPath $stage -Force | Select-Object -ExpandProperty FullName
        $dest    = Join-Path $script:SaveDir $zipName
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
        Compress-Archive -Path $entries -DestinationPath $dest -Force

        $result.Zip = $dest
        $result.Ok  = $true
    }
    catch {
        $result.Error = $_.Exception.Message
    }
    finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    }
    return $result
}

# ------------------------------------------------------------
#  Chạy backup rồi quay lại menu ngay, KHÔNG hiện thông báo.
#  Chỉ hiện dòng đỏ ngắn khi backup thất bại (tránh lỗi âm thầm).
# ------------------------------------------------------------
function Invoke-BackupQuiet([string]$Mode) {
    $r = Invoke-Backup $Mode
    if (-not $r.Ok) {
        Write-Host ''
        Write-Host ($Indent + '  [!] Backup thất bại: ' + $r.Error) -ForegroundColor Red
        Start-Sleep -Milliseconds 1500
    }
}

# ------------------------------------------------------------
#  Hộp thoại chọn thư mục (đồ hoạ). Trả về:
#    đường dẫn  -> đã chọn
#    $null      -> người dùng bấm Cancel
#    __NODIALOG__ -> không tải được hộp thoại
# ------------------------------------------------------------
function Show-FolderDialog([string]$InitialDir) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description         = 'Chọn thư mục lưu file zip backup'
        $dlg.ShowNewFolderButton = $true
        if ($InitialDir -and (Test-Path -LiteralPath $InitialDir -PathType Container)) {
            $dlg.SelectedPath = $InitialDir
        }
        # đưa hộp thoại lên trước cửa sổ console
        $owner = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true; ShowInTaskbar = $false }
        $res   = $dlg.ShowDialog($owner)
        $owner.Dispose()
        if ($res -eq [System.Windows.Forms.DialogResult]::OK) { return $dlg.SelectedPath }
        return $null
    }
    catch {
        return '__NODIALOG__'
    }
}

# ------------------------------------------------------------
#  Đổi nơi lưu: Enter -> hộp thoại; gõ đường dẫn -> dùng luôn; 0 -> giữ nguyên
# ------------------------------------------------------------
function Select-SaveDir {
    Clear-Host
    Write-Host ''
    Write-BoxTop
    Write-BoxLine ''
    Write-BoxLine 'ĐỔI NƠI LƯU FILE ZIP'
    Write-BoxLine ''
    Write-BoxBottom
    Write-Host ''
    Write-Host ($Indent + '  Nơi lưu hiện tại: ') -ForegroundColor DarkGray -NoNewline
    Write-Host $script:SaveDir -ForegroundColor White
    Write-Host ''
    Write-Host ($Indent + '  - Nhấn Enter để mở hộp thoại chọn thư mục') -ForegroundColor Gray
    Write-Host ($Indent + '  - Hoặc dán/gõ đường dẫn thư mục rồi Enter') -ForegroundColor Gray
    Write-Host ($Indent + '  - Gõ 0 để giữ nguyên') -ForegroundColor Gray
    Write-Host ''
    Write-Host ($Indent + '  ➜ Lựa chọn / đường dẫn: ') -ForegroundColor Yellow -NoNewline
    $inp = (Read-Host).Trim().Trim('"')

    if ($inp -eq '0') { return }

    if ($inp -eq '') {
        $picked = Show-FolderDialog $script:SaveDir
        if ($picked -eq '__NODIALOG__') {
            Write-Host ($Indent + '  Không mở được hộp thoại. Hãy gõ đường dẫn thủ công.') -ForegroundColor Red
            Start-Sleep -Milliseconds 1300
            return
        }
        if ($picked) {
            $script:SaveDir = $picked
            Write-Host ($Indent + '  ✔ Đã đổi nơi lưu: ') -ForegroundColor Green -NoNewline
            Write-Host $script:SaveDir -ForegroundColor White
            Start-Sleep -Milliseconds 900
        }
        return
    }

    # Người dùng gõ/dán đường dẫn
    if (Test-Path -LiteralPath $inp -PathType Container) {
        $script:SaveDir = (Resolve-Path -LiteralPath $inp).Path
        Write-Host ($Indent + '  ✔ Đã đổi nơi lưu: ') -ForegroundColor Green -NoNewline
        Write-Host $script:SaveDir -ForegroundColor White
        Start-Sleep -Milliseconds 900
        return
    }

    # Thư mục chưa tồn tại -> hỏi tạo
    Write-Host ($Indent + '  Thư mục không tồn tại. Tạo mới? (Y/N): ') -ForegroundColor Yellow -NoNewline
    $yn = (Read-Host).Trim()
    if ($yn -match '^[yY]') {
        try {
            New-Item -ItemType Directory -Path $inp -Force | Out-Null
            $script:SaveDir = (Resolve-Path -LiteralPath $inp).Path
            Write-Host ($Indent + '  ✔ Đã tạo & chọn: ') -ForegroundColor Green -NoNewline
            Write-Host $script:SaveDir -ForegroundColor White
        }
        catch {
            Write-Host ($Indent + '  ✘ Không tạo được thư mục: ' + $_.Exception.Message) -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 1100
    }
}

# ------------------------------------------------------------
#  Nếu chạy với -Mode: backup 1 phát rồi thoát (tiện debug/tự động)
# ------------------------------------------------------------
if ($Mode) {
    $r = Invoke-Backup $Mode
    if ($r.Ok) { Write-Host "OK: $($r.Zip)" } else { Write-Host "FAIL: $($r.Error)" }
    return
}

# ------------------------------------------------------------
#  Vòng lặp chính
# ------------------------------------------------------------
$exit = $false
while (-not $exit) {
    Show-Menu
    Write-Host ($Indent + '  ➜ Chọn chức năng: ') -ForegroundColor Yellow -NoNewline
    $choice = (Read-Host).Trim()

    switch ($choice) {
        '1' { Invoke-BackupQuiet 'claude' }
        '2' { Invoke-BackupQuiet 'codex' }
        '3' { Select-SaveDir }
        '0' { $exit = $true }
        ''  { }
        default {
            Write-Host ($Indent + '  Lựa chọn không hợp lệ.') -ForegroundColor Red
            Start-Sleep -Milliseconds 900
        }
    }
}
