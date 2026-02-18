function monitorear_DHCP {
    Write-Host "=== MONITOREO DE DHCP ==="
    
    # 1. Estado del servicio
    $status = Get-Service -Name DHCPServer
    Write-Host "[1] Estado del Proceso: $($status.Status)"

    # 2. Equipos Conectados (Leases)
    Write-Host "`n[2] Equipos Conectados (Concesiones Activas):"
    $scopes = Get-DhcpServerv4Scope
    foreach ($s in $scopes) {
        Write-Host "Ámbito: $($s.ScopeId) ($($s.Name))"
        Get-DhcpServerv4Lease -ScopeId $s.ScopeId | Select-Object IPAddress, ClientId, HostName | Format-Table
    }

    # 3. Logs (Visor de eventos de Windows)
    $verLogs = Read-Host "¿Desea ver los ultimos 10 eventos de DHCP? (s/n)"
    if ($verLogs -eq "s") {
        Get-EventLog -LogName System -Source "Microsoft-Windows-DHCP-Server" -Newest 10
    }

    Read-Host "Presione Enter para volver al menu..."
}