function verificar_instalacion_DHCP {
    Write-Host "=== Verificando Estado de DHCP Server ==="

    # 1. Verificar si el Rol está instalado
    $feature = Get-WindowsFeature -Name DHCP
    if ($feature.Installed) {
        Write-Host "Instalacion: SOFTWARE INSTALADO"
    } else {
        Write-Host "Instalacion: SOFTWARE NO ENCONTRADO"
        Write-Host "--------------------------------"
        return
    }

    # 2. Verificar estado del servicio (dhcp)
    $service = Get-Service -Name DHCPServer -ErrorAction SilentlyContinue
    if ($service.Status -eq "Running") {
        Write-Host "Estado:      EN EJECUCION"
    } else {
        Write-Host "Estado:      DETENIDO ($($service.Status))"
    }

    # 3. Verificar tipo de inicio
    Write-Host "Inicio automatico: $($service.StartType)"
    Write-Host "--------------------------------"
    Read-Host "Presione Enter para seguir..."
}
