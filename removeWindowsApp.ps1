Add-Type -AssemblyName System.Windows.Forms
function Reload-Script {& "$PSCommandPath"
    exit
}
$form = New-Object System.Windows.Forms.Form -Property @{Text = "Desinstalar Aplicaciones" 
Size = New-Object System.Drawing.Size(1320, 800)}
#Listar paquetes
$packageNames = @()
$dataGridView = New-Object System.Windows.Forms.DataGridView -Property @{Size = New-Object System.Drawing.Size(1300, 400) 
Location = New-Object System.Drawing.Point(0, 50)}
$columns = @(
    @{ HeaderText = "Seleccionar"; Type = [System.Windows.Forms.DataGridViewCheckBoxColumn] } 
    @{ HeaderText = "Nombre"; Type = [System.Windows.Forms.DataGridViewTextBoxColumn] }
    @{ HeaderText = "Package Full Name"; Type = [System.Windows.Forms.DataGridViewTextBoxColumn] }
    @{ HeaderText = "Ubicación de Instalación"; Type = [System.Windows.Forms.DataGridViewTextBoxColumn] }
    @{ HeaderText = "Dependencias"; Type = [System.Windows.Forms.DataGridViewTextBoxColumn] }
    @{ HeaderText = "Es Eliminable"; Type = [System.Windows.Forms.DataGridViewTextBoxColumn] }
   @{ HeaderText = "Abrir Carpeta"; Type = [System.Windows.Forms.DataGridViewButtonColumn]}
)
$columns | ForEach-Object {$column = New-Object $_.Type
    $column.HeaderText = $_.HeaderText
    $dataGridView.Columns.Add($column)
}
$packages = Get-AppxPackage
foreach ($package in $packages) {
$row = $dataGridView.Rows.Add($false, $package.Name, $package.PackageFullName, $package.InstallLocation, $package.Dependencies -join ", ", !$package.NonRemovable,"Abrir")
# Agregar el nombre del paquete a la lista
    $packageName = $package.Name
    $packageNames += $packageName
}
$dataGridView_CellContentClick = {
    param($sender, $e)
     Write-Host $e.ColumnIndex
     Write-Host $dataGridView.Rows[$e.RowIndex].Cells[3].Value
    if ($e.RowIndex -ge 0 -and $e.ColumnIndex -eq 6) {
        $installLocation = $dataGridView.Rows[$e.RowIndex].Cells[3].Value
        if (-not [string]::IsNullOrWhiteSpace($installLocation)) {Invoke-Item $installLocation }}}
$dataGridView.Add_CellContentClick($dataGridView_CellContentClick)
#Listas de resultados
$removedItemsLabel = New-Object System.Windows.Forms.Label -Property @{Text = "Objetos Eliminados:"
    Size = New-Object System.Drawing.Size(200, 20)
    Location = New-Object System.Drawing.Point(30, 480)}
$removedItemsListBox = New-Object System.Windows.Forms.ListBox -Property @{Size = New-Object System.Drawing.Size(400, 150)
    Location = New-Object System.Drawing.Point(30, 500)}
$nonRemovableItemsLabel = New-Object System.Windows.Forms.Label -Property @{Text = "Objetos no Eliminables:"
    Size = New-Object System.Drawing.Size(200, 20)
    Location = New-Object System.Drawing.Point(440, 480)}
$nonRemovableItemsListBox = New-Object System.Windows.Forms.ListBox -Property @{Size = New-Object System.Drawing.Size(400, 150)
    Location = New-Object System.Drawing.Point(440, 500)}
$uninstallButton = New-Object System.Windows.Forms.Button -Property @{Text = "Desinstalar Seleccionados"
    Size = New-Object System.Drawing.Size(180, 30)
    Location = New-Object System.Drawing.Point(30, 650)} 
$uninstallButton.Add_Click({
    $removedItems = @()
    $nonRemovableItems = @()
    foreach ($row in $dataGridView.Rows) {
        if ($row.Cells[0].Value -eq $true) {
            $packageFullName = $row.Cells[2].Value
            if ($packageFullName -ne $null) {
                $result = Remove-AppxPackage -Package $packageFullName -ErrorAction SilentlyContinue
                if ($result) {$removedItems += $row.Cells[1].Value} else {$nonRemovableItems += $row.Cells[1].Value}}}}
    [System.Windows.Forms.MessageBox]::Show("Proceso de desinstalación completado.")
    foreach ($item in $removedItems) {$removedItemsListBox.Items.Add($item)}
    foreach ($item in $nonRemovableItems) {$nonRemovableItemsListBox.Items.Add($item)}})

$exportButton = New-Object System.Windows.Forms.Button -Property @{Text = "Exportar Nombres"
    Size = New-Object System.Drawing.Size(180, 30)
    Location = New-Object System.Drawing.Point(220, 650)
}
$exportButton.Add_Click({
     $filePath = Join-Path -Path $PSScriptRoot -ChildPath "package_names.txt"
    $packageNames | Out-File -FilePath $filePath
    [System.Windows.Forms.MessageBox]::Show("Nombres exportados correctamente.")
    $folderPath = $PSScriptRoot
    $fileToOpen = Join-Path -Path $folderPath -ChildPath "package_names.txt"
    Invoke-Item $fileToOpen
    Invoke-Item $folderPath
})
$refreshButton = New-Object System.Windows.Forms.Button -Property @{ Text = "Refrescar"
    Size = New-Object System.Drawing.Size(100, 30)
    Location = New-Object System.Drawing.Point(440, 650)
}
$refreshButton.Add_Click({$form.Close()
    Reload-Script
})
$form.Controls.Add($dataGridView)
$form.Controls.Add($uninstallButton)
$form.Controls.Add($removedItemsLabel)
$form.Controls.Add($removedItemsListBox)
$form.Controls.Add($nonRemovableItemsLabel)
$form.Controls.Add($nonRemovableItemsListBox)
$form.Controls.Add($exportButton)
$form.Controls.Add($refreshButton)
$form.ShowDialog()
