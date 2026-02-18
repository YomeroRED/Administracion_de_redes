function Desinstalar_DHCP {
    Write-Host "Eliminando rol de Servidor DHCP..."
    Uninstall-WindowsFeature -Name DHCP -Remove -IncludeManagementTools -ErrorAction SilentlyContinue -Restart:$false
    Write-Host "Limpiando archivos residuales en System32..."
    $dhcpPath = "$env:SystemRoot\System32\dhcp"
	if (Test-Path $dhcpPath) {
    		Remove-Item -Path "$dhcpPath\*" -Recurse -Force -ErrorAction SilentlyContinue
	}
    Write-Host "Limpiando llaves del registro..."
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\DHCPServer\Parameters"
	if (Test-Path $regPath) {
    		Remove-ItemTree -Path $regPath -Force -ErrorAction SilentlyContinue
	}
    Write-Host "Desinstalacion completada."
    Write-Host "--------------------------------"
Write-Host ""
}

function instalar_DHCP {
    Write-Host "=== Inicio de proceso de instalacion ==="

    # 1. Verificar si ya existe
    $feature = Get-WindowsFeature -Name DHCP
    Write-Host ""
    if ($feature.Installed) {
        Write-Host "AVISO: El rol DHCP ya esta instalado." 
        $resp = Read-Host "¿Desea desinstalar y reinstalar? (s/n)"
        if ($resp -eq "s") {
	    Write-Host ""
            Desinstalar_DHCP
            Write-Host "Procediendo con la instalacion..."
	    Write-Host ""
	    Write-Host ""
        } else {
            return
        }
    }

    # 2. Instalar Rol y Herramientas de administración
    Write-Host "Instalando Rol DHCP..."
    try {
    	$resultado = Install-WindowsFeature -Name DHCP -Source https://www.microsoft.com -IncludeManagementTools -ErrorAction Stop
    	if ($resultado.Success) {
        	Write-Host "¡Instalacion exitosa!"
    	} else {
        	Write-Host "La instalacion fallo. Revisa el error arriba."
        	return
    	}
    } catch {
    	Write-Host "Ocurrio un error critico: $($_.Exception.Message)"
    	return
    }
    
    # Autorizar en AD (opcional, solo si es Server en Dominio)
    # Add-DhcpServerInDC -DnsName "nombre.dominio"
    
    Write-Host ""
    $opcion = Read-Host "Es necesario reiniciar el servidor para terminar el proceso. Quiere reiniciar ahora? (s/n)"
    Write-Host ""
	if ($opcion -eq "s") {
		Write-Host "Reiniciando..."
		shutdown /r/t 0
	} else {
		Write-Host "Espero que consideres hacerlo despues..."
	}
	Write-Host ""
	Write-Host "--------------------------------"
    Read-Host "Presione Enter para seguir..."
}
