Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ResourceNames = @(
"Logs","Planks","Stone","Meat","Grain","Flour","Fish","Ham","Bread","Water","Beer",
"Coal","Iron ore","Gold","Iron","Coins","Tongs","Axes","Saws","Pickaxes","Hammers",
"Shovels","Crucibles","Fishing rods","Scythes","Cleavers","Rolling pins","Bows",
"Swords","Shields","Boats","Helpers","Woodcutters","Fishermen","Foresters",
"Carpenters","Stonecutters","Hunters","Farmers","Millers","Bakers","Butchers",
"Miners","Brewers","Pig farmers","Donkey breeders","Iron founders","Goldsmiths",
"Locksmiths","Smiths","Builders","Planers","Scholars","Archers","Privates",
"Sergeants","Officers","Generals","Explorers","Shipbuilders","Donkeys"
)

$script:Bytes = $null
$script:FilePath = $null
$script:InventoryOffset = $null

function Find-HQInventory([byte[]]$data) {
    # The documented Gold/v1.51 structure is:
    # 8A 1B = own HQ marker
    # 00 00 = two reserved bytes
    # 61 x UInt16 little-endian inventory values
    for ($i=0; $i -le $data.Length - 126; $i++) {
        if ($data[$i] -eq 0x8A -and $data[$i+1] -eq 0x1B -and
            $data[$i+2] -eq 0 -and $data[$i+3] -eq 0) {
            return ($i + 4)
        }
    }
    return -1
}

function Read-UInt16LE([byte[]]$data, [int]$offset) {
    return [BitConverter]::ToUInt16($data, $offset)
}

function Write-UInt16LE([byte[]]$data, [int]$offset, [int]$value) {
    $b = [BitConverter]::GetBytes([UInt16]$value)
    $data[$offset] = $b[0]
    $data[$offset+1] = $b[1]
}

function Refresh-List {
    $list.Items.Clear()
    if ($null -eq $script:Bytes -or $script:InventoryOffset -lt 0) { return }
    for ($i=0; $i -lt 61; $i++) {
        $v = Read-UInt16LE $script:Bytes ($script:InventoryOffset + ($i*2))
        [void]$list.Items.Add(("{0,-20} {1,5}" -f $ResourceNames[$i], $v))
    }
    $status.Text = "Loaded: $($script:FilePath)    HQ inventory found at file offset $($script:InventoryOffset)"
}

function Load-File($path) {
    try {
        $script:Bytes = [System.IO.File]::ReadAllBytes($path)
        $script:InventoryOffset = Find-HQInventory $script:Bytes
        if ($script:InventoryOffset -lt 0) {
            throw "Could not find the Settlers II Gold HQ inventory marker (8A 1B 00 00)."
        }
        $script:FilePath = $path
        Refresh-List
        $saveButton.Enabled = $true
        $setButton.Enabled = $true
        $allButton.Enabled = $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Settlers II Resource Editor",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

function Save-File {
    if ($null -eq $script:Bytes) { return }
    try {
        $backup = "$($script:FilePath).bak"
        if (-not (Test-Path $backup)) {
            [System.IO.File]::Copy($script:FilePath, $backup, $false)
        }

        [System.IO.File]::WriteAllBytes($script:FilePath, $script:Bytes)
        [System.Windows.Forms.MessageBox]::Show(
            "Saved successfully.`r`n`r`nA backup was created at:`r`n$backup",
            "Settlers II Resource Editor",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        Refresh-List
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Save failed",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Settlers II Gold - Resource Editor"
$form.Size = New-Object System.Drawing.Size(560, 690)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "Open TRANSxxx.DAT"
$openButton.Location = New-Object System.Drawing.Point(15,15)
$openButton.Size = New-Object System.Drawing.Size(170,32)
$form.Controls.Add($openButton)

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save changes"
$saveButton.Location = New-Object System.Drawing.Point(195,15)
$saveButton.Size = New-Object System.Drawing.Size(130,32)
$saveButton.Enabled = $false
$form.Controls.Add($saveButton)

$setLabel = New-Object System.Windows.Forms.Label
$setLabel.Text = "Set selected to:"
$setLabel.Location = New-Object System.Drawing.Point(15,62)
$setLabel.AutoSize = $true
$form.Controls.Add($setLabel)

$valueBox = New-Object System.Windows.Forms.TextBox
$valueBox.Location = New-Object System.Drawing.Point(105,59)
$valueBox.Size = New-Object System.Drawing.Size(90,25)
$valueBox.Text = "500"
$form.Controls.Add($valueBox)

$setButton = New-Object System.Windows.Forms.Button
$setButton.Text = "Set selected"
$setButton.Location = New-Object System.Drawing.Point(205,57)
$setButton.Size = New-Object System.Drawing.Size(120,30)
$setButton.Enabled = $false
$form.Controls.Add($setButton)

$allButton = New-Object System.Windows.Forms.Button
$allButton.Text = "Set goods to value"
$allButton.Location = New-Object System.Drawing.Point(340,57)
$allButton.Size = New-Object System.Drawing.Size(145,30)
$allButton.Enabled = $false
$form.Controls.Add($allButton)

$list = New-Object System.Windows.Forms.ListBox
$list.Location = New-Object System.Drawing.Point(15,100)
$list.Size = New-Object System.Drawing.Size(470,500)
$list.Font = New-Object System.Drawing.Font("Consolas",10)
$form.Controls.Add($list)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Open a TRANSxxx.DAT save file to begin."
$status.Location = New-Object System.Drawing.Point(15,615)
$status.Size = New-Object System.Drawing.Size(510,35)
$form.Controls.Add($status)

$openButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Settlers II TRANS files (TRANS*.DAT)|TRANS*.DAT|DAT files (*.DAT)|*.DAT|All files (*.*)|*.*"
    $dlg.Title = "Select a Settlers II Gold TRANSxxx.DAT file"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Load-File $dlg.FileName
    }
})

$setButton.Add_Click({
    if ($list.SelectedIndex -lt 0) {
        [System.Windows.Forms.MessageBox]::Show("Select a resource first.") | Out-Null
        return
    }
    $v = 0
    if (-not [int]::TryParse($valueBox.Text, [ref]$v) -or $v -lt 0 -or $v -gt 65535) {
        [System.Windows.Forms.MessageBox]::Show("Enter a whole number from 0 to 65535.") | Out-Null
        return
    }
    $idx = $list.SelectedIndex
    Write-UInt16LE $script:Bytes ($script:InventoryOffset + ($idx*2)) $v
    Refresh-List
    $list.SelectedIndex = $idx
})

$allButton.Add_Click({
    $v = 0
    if (-not [int]::TryParse($valueBox.Text, [ref]$v) -or $v -lt 0 -or $v -gt 65535) {
        [System.Windows.Forms.MessageBox]::Show("Enter a whole number from 0 to 65535.") | Out-Null
        return
    }
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Set all 31 goods (not settlers) to $v?",
        "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
        for ($i=0; $i -lt 31; $i++) {
            Write-UInt16LE $script:Bytes ($script:InventoryOffset + ($i*2)) $v
        }
        Refresh-List
    }
})

$saveButton.Add_Click({ Save-File })

$form.Add_FormClosing({
    # No automatic save: changes are only written when the user presses Save changes.
})

[void]$form.ShowDialog()
