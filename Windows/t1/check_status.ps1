Write-Host "======================="
Write-Host "Informacion del sistema"
Write-Host "======================="

Write-Host "[1] Nombre del equipo"
hostname

Write-Host ""
Write-Host "======================="

Write-Host "[2] Direccion IP de la red_interna"
Get-NetIPAddress -AddressFamily IPv4 | where InterfaceAlias -like "*Red-interna*" | Select IPAddress | Format-Table -HideTableHeaders

Write-Host ""
Write-Host "======================="

$OS = Get-CimInstance Win32_OperatingSystem
$TotalRam = [Math]::Round($OS.TotalVisibleMemorySize / 1MB,2)
$FreeRam = [Math]::Round($OS.FreePhysicalMemorySize / 1MB,2)

Write-Host "[3] Memoria RAM"
Write-Host "Total: $TotalRam GB "
Write-Host "Libre: $FreeRam GB "

Write-Host ""
Write-Host "======================="

$Disk = Get-PSDrive C |Select-Object @{Name="Used(GB)";Expression={[math]::round(($_.Used/1GB),2)}},@{Name="Free(GB)";Expression={[math]::round(($_.Free/1GB),2)}}
Write-Host "[4] Espacio en disco"
$Disk | Format-Table

Write-Host "======================="