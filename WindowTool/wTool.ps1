Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Window Tool Launcher'
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false

$panel = New-Object System.Windows.Forms.FlowLayoutPanel
$panel.Dock = 'Fill'; $panel.FlowDirection = 'TopDown'
$panel.WrapContents = $false; $panel.AutoScroll = $true
$panel.Padding = New-Object System.Windows.Forms.Padding(6)
$form.Controls.Add($panel)

$count = 0
foreach ($dir in Get-ChildItem -Path $PSScriptRoot -Directory | Sort-Object Name) {
    $bat = Get-ChildItem -Path $dir.FullName -Filter *.bat | Select-Object -First 1
    if (-not $bat) { continue }
    $ico = Get-ChildItem -Path $dir.FullName -Filter *.ico | Select-Object -First 1

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = '   ' + ($dir.Name -creplace '(?<=[a-z])(?=[A-Z])',' ')
    $btn.Width = 320; $btn.Height = 44
    $btn.TextAlign = 'MiddleLeft'; $btn.ImageAlign = 'MiddleLeft'
    $btn.TextImageRelation = 'ImageBeforeText'
    $btn.Font = New-Object System.Drawing.Font('Segoe UI', 11)
    if ($ico) {
        try {
            $raw = New-Object System.Drawing.Bitmap($ico.FullName)
            $btn.Image = New-Object System.Drawing.Bitmap($raw, 32, 32)
            $raw.Dispose()
        } catch {}
    }

    $batPath = $bat.FullName; $dirPath = $dir.FullName
    $btn.Add_Click({ Start-Process -FilePath $batPath -WorkingDirectory $dirPath }.GetNewClosure())
    $panel.Controls.Add($btn)
    $count++
}

if ($count -eq 0) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = 'Không tìm thấy tool nào (không có folder chứa .bat).'
    $lbl.AutoSize = $true; $lbl.Padding = New-Object System.Windows.Forms.Padding(12)
    $panel.Controls.Add($lbl)
    $count = 1
}

$formHeight = [Math]::Min($count, 8) * 52 + 16
$form.ClientSize = New-Object System.Drawing.Size(348, $formHeight)
[void]$form.ShowDialog()
